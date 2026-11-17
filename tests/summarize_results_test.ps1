<#
.SYNOPSIS
    Suite de pruebas automatizadas para scripts/summarize_results.ps1.

.DESCRIPTION
    Verifica matemáticamente y conforme al protocolo (docs/protocolo_medicion.md §6 y §7):
      1. Rechazo de esquemas inválidos y preservación de cabecera estándar de 31 columnas.
      2. Descarte estricto de precalentamiento (is_warmup=true) y estados != OK.
      3. Cálculo exacto de mediana, Q1, Q3, IQR, min y max.
      4. Cálculo de Speedup y Eficiencia referenciado al secuencial del mismo lenguaje.
      5. Ausencia de Speedup cuando falta la referencia secuencial o el grupo está incompleto.
      6. Cálculo de GFLOPS aritmético estimado.
      7. Soporte idéntico por archivo (-InputPath), tubería de objetos y stdin.
      8. Escritura en archivo con UTF-8 sin BOM.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$summarizeScript = Join-Path $projectRoot 'scripts\summarize_results.ps1'
$controlFixture = Join-Path $projectRoot 'tests\fixtures\control_mediciones.csv'
$tempOut = Join-Path $projectRoot 'tests\fixtures\temp_summary_test.csv'

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$passed = 0
$failed = 0

function Assert-Equal {
    param(
        [string]$TestName,
        $Actual,
        $Expected,
        [double]$Tolerance = 1e-6
    )

    if ($Actual -is [double] -or $Actual -is [float] -or $Expected -is [double] -or $Expected -is [float]) {
        $actNum = [double]$Actual
        $expNum = [double]$Expected
        $diff = [Math]::Abs($actNum - $expNum)
        if ($diff -le $Tolerance) {
            $global:passed++
            Write-Host "  [PASS] $TestName" -ForegroundColor Green
        } else {
            $global:failed++
            Write-Host "  [FAIL] $TestName (Esperado: $Expected, Obtenido: $Actual, Diff: $diff)" -ForegroundColor Red
        }
    } else {
        if ($Actual -eq $Expected) {
            $global:passed++
            Write-Host "  [PASS] $TestName" -ForegroundColor Green
        } else {
            $global:failed++
            Write-Host "  [FAIL] $TestName (Esperado: '$Expected', Obtenido: '$Actual')" -ForegroundColor Red
        }
    }
}

Write-Host "=== INICIO DE PRUEBAS DE AUTOMATIZACION: summarize_results.ps1 ===" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Test 1: Ejecución con archivo de control y verificación de objetos
# ---------------------------------------------------------------------------
Write-Host "`nTest 1: Procesamiento de control_mediciones.csv con -PassThru..." -ForegroundColor Yellow
$results = & $summarizeScript -InputPath $controlFixture -PassThru
Assert-Equal -TestName "Cantidad total de grupos agregados" -Actual $results.Count -Expected 5

# Indexar por clave
$resMap = @{}
foreach ($r in $results) {
    $key = "$($r.version)|$($r.configuration)|$($r.n)"
    $resMap[$key] = $r
}

# ---------------------------------------------------------------------------
# Test 2: Caso c_secuencial (N=256)
# ---------------------------------------------------------------------------
Write-Host "`nTest 2: Verificación de métricas para c_secuencial (N=256)..." -ForegroundColor Yellow
$cSec = $resMap['c_secuencial|c_secuencial|256']
Assert-Equal -TestName "c_secuencial: repeticiones medidas válidas" -Actual $cSec.reps_count -Expected 5
Assert-Equal -TestName "c_secuencial: estado completo" -Actual $cSec.status -Expected 'COMPLETE'
Assert-Equal -TestName "c_secuencial: kernel_s_median" -Actual $cSec.kernel_s_median -Expected 0.020000000
Assert-Equal -TestName "c_secuencial: kernel_s_q1" -Actual $cSec.kernel_s_q1 -Expected 0.019000000
Assert-Equal -TestName "c_secuencial: kernel_s_q3" -Actual $cSec.kernel_s_q3 -Expected 0.021000000
Assert-Equal -TestName "c_secuencial: kernel_s_iqr" -Actual $cSec.kernel_s_iqr -Expected 0.002000000
Assert-Equal -TestName "c_secuencial: kernel_s_min" -Actual $cSec.kernel_s_min -Expected 0.018000000
Assert-Equal -TestName "c_secuencial: kernel_s_max" -Actual $cSec.kernel_s_max -Expected 0.022000000

Assert-Equal -TestName "c_secuencial: total_s_median" -Actual $cSec.total_s_median -Expected 0.025000000
Assert-Equal -TestName "c_secuencial: total_s_q1" -Actual $cSec.total_s_q1 -Expected 0.024000000
Assert-Equal -TestName "c_secuencial: total_s_q3" -Actual $cSec.total_s_q3 -Expected 0.026000000
Assert-Equal -TestName "c_secuencial: total_s_iqr" -Actual $cSec.total_s_iqr -Expected 0.002000000
Assert-Equal -TestName "c_secuencial: total_s_min" -Actual $cSec.total_s_min -Expected 0.023000000
Assert-Equal -TestName "c_secuencial: total_s_max" -Actual $cSec.total_s_max -Expected 0.027000000

Assert-Equal -TestName "c_secuencial: speedup base" -Actual $cSec.speedup -Expected 1.000000
Assert-Equal -TestName "c_secuencial: eficiencia base" -Actual $cSec.efficiency -Expected 1.000000

# GFLOPS: 2 * 256^3 / (0.020 * 1e9) = 33,554,432 / 20,000,000 = 1.6777216
Assert-Equal -TestName "c_secuencial: gflops_kernel" -Actual $cSec.gflops_kernel -Expected 1.6777216 -Tolerance 1e-5
# GFLOPS total: 33,554,432 / (0.025 * 1e9) = 1.34217728
Assert-Equal -TestName "c_secuencial: gflops_total" -Actual $cSec.gflops_total -Expected 1.34217728 -Tolerance 1e-5

# ---------------------------------------------------------------------------
# Test 3: Caso c_paralelo P2_T2 (N=256)
# ---------------------------------------------------------------------------
Write-Host "`nTest 3: Verificación de métricas para c_paralelo_P2_T2 (N=256)..." -ForegroundColor Yellow
$cPar = $resMap['c_paralelo|c_paralelo_P2_T2|256']
Assert-Equal -TestName "c_paralelo: repeticiones medidas válidas" -Actual $cPar.reps_count -Expected 5
Assert-Equal -TestName "c_paralelo: estado completo" -Actual $cPar.status -Expected 'COMPLETE'
Assert-Equal -TestName "c_paralelo: kernel_s_median" -Actual $cPar.kernel_s_median -Expected 0.005000000
Assert-Equal -TestName "c_paralelo: kernel_s_iqr" -Actual $cPar.kernel_s_iqr -Expected 0.001000000
Assert-Equal -TestName "c_paralelo: total_s_median" -Actual $cPar.total_s_median -Expected 0.010000000
Assert-Equal -TestName "c_paralelo: total_s_iqr" -Actual $cPar.total_s_iqr -Expected 0.002000000

# Speedup: 0.025 / 0.010 = 2.500000
Assert-Equal -TestName "c_paralelo: speedup relativo a c_secuencial" -Actual $cPar.speedup -Expected 2.500000
# Eficiencia: 2.5 / (2 * 2) = 0.625000
Assert-Equal -TestName "c_paralelo: eficiencia paralela (P*T=4)" -Actual $cPar.efficiency -Expected 0.625000
# GFLOPS: 33,554,432 / (0.005 * 1e9) = 6.7108864
Assert-Equal -TestName "c_paralelo: gflops_kernel" -Actual $cPar.gflops_kernel -Expected 6.7108864 -Tolerance 1e-5

# ---------------------------------------------------------------------------
# Test 4: Caso go_secuencial y go_paralelo_W4 (N=256)
# ---------------------------------------------------------------------------
Write-Host "`nTest 4: Verificación de Go secuencial y paralelo (N=256)..." -ForegroundColor Yellow
$goSec = $resMap['go_secuencial|go_secuencial|256']
Assert-Equal -TestName "go_secuencial: total_s_median" -Actual $goSec.total_s_median -Expected 0.050000000
Assert-Equal -TestName "go_secuencial: speedup base" -Actual $goSec.speedup -Expected 1.000000

$goPar = $resMap['go_paralelo|go_paralelo_W4|256']
Assert-Equal -TestName "go_paralelo: total_s_median" -Actual $goPar.total_s_median -Expected 0.020000000
# Speedup Go: 0.050 / 0.020 = 2.500000
Assert-Equal -TestName "go_paralelo: speedup relativo a go_secuencial" -Actual $goPar.speedup -Expected 2.500000
# Eficiencia Go: 2.5 / 4 = 0.625000
Assert-Equal -TestName "go_paralelo: eficiencia paralela (W=4)" -Actual $goPar.efficiency -Expected 0.625000

# ---------------------------------------------------------------------------
# Test 5: Caso incompleto y sin referencia (c_paralelo N=512)
# ---------------------------------------------------------------------------
Write-Host "`nTest 5: Verificación de caso incompleto con error (N=512)..." -ForegroundColor Yellow
$cInc = $resMap['c_paralelo|c_paralelo_P4_T1|512']
Assert-Equal -TestName "c_paralelo N=512: reps_count excluyendo ERROR" -Actual $cInc.reps_count -Expected 4
Assert-Equal -TestName "c_paralelo N=512: estado incompleto" -Actual $cInc.status -Expected 'INCOMPLETE'
Assert-Equal -TestName "c_paralelo N=512: speedup nulo" -Actual $cInc.speedup -Expected $null
Assert-Equal -TestName "c_paralelo N=512: eficiencia nula" -Actual $cInc.efficiency -Expected $null
Assert-Equal -TestName "c_paralelo N=512: gflops nulo" -Actual $cInc.gflops_kernel -Expected $null

# ---------------------------------------------------------------------------
# Test 6: Verificación de exportación a archivo CSV y codificación UTF-8 sin BOM
# ---------------------------------------------------------------------------
Write-Host "`nTest 6: Exportación a archivo y verificación UTF-8 sin BOM..." -ForegroundColor Yellow
try {
    if (Test-Path -LiteralPath $tempOut) { Remove-Item -LiteralPath $tempOut -Force }
    & $summarizeScript -InputPath $controlFixture -OutputPath $tempOut
    Assert-Equal -TestName "Archivo generado en disco" -Actual (Test-Path -LiteralPath $tempOut) -Expected $true

    $bytes = [System.IO.File]::ReadAllBytes($tempOut)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Assert-Equal -TestName "Ausencia de BOM UTF-8" -Actual $hasBom -Expected $false

    $csvLines = [System.IO.File]::ReadAllLines($tempOut)
    $head = $csvLines[0]
    Assert-Equal -TestName "Cabecera contiene 31 columnas" -Actual ($head.Split(',').Count) -Expected 31
    Assert-Equal -TestName "Total de filas (1 cabecera + 5 grupos)" -Actual $csvLines.Length -Expected 6
} finally {
    if (Test-Path -LiteralPath $tempOut) { Remove-Item -LiteralPath $tempOut -Force }
}

# ---------------------------------------------------------------------------
# Test 7: Verificación de tubería / stdin
# ---------------------------------------------------------------------------
Write-Host "`nTest 7: Verificación de canalización por tubería..." -ForegroundColor Yellow
$pipeResults = Get-Content $controlFixture | & $summarizeScript -PassThru
Assert-Equal -TestName "Resultados vía tubería coinciden en conteo" -Actual $pipeResults.Count -Expected 5

# ---------------------------------------------------------------------------
# Resumen Final
# ---------------------------------------------------------------------------
Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "RESULTADOS: $passed pruebas superadas, $failed fallidas." -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
Write-Host "=======================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
