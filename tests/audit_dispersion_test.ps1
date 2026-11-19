<#
.SYNOPSIS
    Suite de pruebas automatizadas para scripts/audit_dispersion.ps1.

.DESCRIPTION
    Verifica las métricas y clasificaciones de auditoría de dispersión (Sprint 8 - I7):
      1. Generación correcta de reportes CSV y Markdown sin BOM.
      2. Cálculo preciso de RSD_IQR = (IQR / mediana) * 100%.
      3. Clasificación correcta de estabilidad (EXCELENTE, ESTABLE, MODERADA, ALTA).
      4. Asignación correcta del dictamen CONSERVAR_CONFORME bajo las reglas del protocolo §6.3.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$auditScript = Join-Path $projectRoot 'scripts\audit_dispersion.ps1'
$provisionalCsv = Join-Path $projectRoot 'resultados\resumen\resumen_provisional.csv'
$tempOutCsv = Join-Path $projectRoot 'tests\fixtures\temp_dispersion_test.csv'
$tempOutMd = Join-Path $projectRoot 'tests\fixtures\temp_dispersion_test.md'

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$passed = 0
$failed = 0

function Assert-Equal {
    param(
        [string]$TestName,
        $Actual,
        $Expected,
        [double]$Tolerance = 1e-4
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

Write-Host "=== INICIO DE PRUEBAS: audit_dispersion.ps1 ===" -ForegroundColor Cyan

# Test 1: Ejecución con PassThru
Write-Host "`nTest 1: Ejecución con -PassThru..." -ForegroundColor Yellow
$results = & $auditScript -InputPath $provisionalCsv -PassThru
Assert-Equal -TestName "Cantidad de grupos analizados" -Actual $results.Count -Expected 9

$map = @{}
foreach ($r in $results) {
    $key = "$($r.version)|$($r.configuration)|$($r.n)"
    $map[$key] = $r
}

# Test 2: Caso N=512 W=1 (Estabilidad Excelente)
Write-Host "`nTest 2: Caso N=512 W=1..." -ForegroundColor Yellow
$g512w1 = $map['go_paralelo|go_paralelo_W1|512']
Assert-Equal -TestName "N=512 W=1: reps_count" -Actual $g512w1.reps_count -Expected 5
Assert-Equal -TestName "N=512 W=1: estabilidad EXCELENTE" -Actual $g512w1.stability -Expected 'EXCELENTE'
Assert-Equal -TestName "N=512 W=1: RSD_IQR < 1%" -Actual ($g512w1.rsd_iqr_total_pct -lt 1.0) -Expected $true
Assert-Equal -TestName "N=512 W=1: dictamen" -Actual $g512w1.verdict -Expected 'CONSERVAR_CONFORME'

# Test 3: Caso N=1024 W=2 (Dispersión Alta detectada)
Write-Host "`nTest 3: Caso N=1024 W=2..." -ForegroundColor Yellow
$g1024w2 = $map['go_paralelo|go_paralelo_W2|1024']
Assert-Equal -TestName "N=1024 W=2: estabilidad ALTA" -Actual $g1024w2.stability -Expected 'ALTA'
# RSD_IQR = (0.0645422 / 0.6026577) * 100 = 10.70959...
Assert-Equal -TestName "N=1024 W=2: RSD_IQR ~ 10.71%" -Actual $g1024w2.rsd_iqr_total_pct -Expected 10.70959 -Tolerance 0.05
Assert-Equal -TestName "N=1024 W=2: dictamen CONSERVAR_CONFORME" -Actual $g1024w2.verdict -Expected 'CONSERVAR_CONFORME'

# Test 4: Caso N=1024 W=4 (Dispersión Alta detectada)
Write-Host "`nTest 4: Caso N=1024 W=4..." -ForegroundColor Yellow
$g1024w4 = $map['go_paralelo|go_paralelo_W4|1024']
Assert-Equal -TestName "N=1024 W=4: estabilidad ALTA" -Actual $g1024w4.stability -Expected 'ALTA'
# RSD_IQR = (0.0361229 / 0.3169191) * 100 = 11.3981...
Assert-Equal -TestName "N=1024 W=4: RSD_IQR ~ 11.40%" -Actual $g1024w4.rsd_iqr_total_pct -Expected 11.39814 -Tolerance 0.05
Assert-Equal -TestName "N=1024 W=4: dictamen CONSERVAR_CONFORME" -Actual $g1024w4.verdict -Expected 'CONSERVAR_CONFORME'

# Test 5: Caso N=2048 W=1 (Alta estabilidad en carga pesada)
Write-Host "`nTest 5: Caso N=2048 W=1..." -ForegroundColor Yellow
$g2048w1 = $map['go_paralelo|go_paralelo_W1|2048']
Assert-Equal -TestName "N=2048 W=1: estabilidad EXCELENTE" -Actual $g2048w1.stability -Expected 'EXCELENTE'
Assert-Equal -TestName "N=2048 W=1: RSD_IQR < 1%" -Actual ($g2048w1.rsd_iqr_total_pct -lt 1.0) -Expected $true

# Test 6: Verificación de exportación de archivos
Write-Host "`nTest 6: Exportación de archivos y ausencia de BOM..." -ForegroundColor Yellow
try {
    if (Test-Path -LiteralPath $tempOutCsv) { Remove-Item -LiteralPath $tempOutCsv -Force }
    if (Test-Path -LiteralPath $tempOutMd) { Remove-Item -LiteralPath $tempOutMd -Force }

    & $auditScript -InputPath $provisionalCsv -OutputPath $tempOutCsv -MarkdownPath $tempOutMd

    Assert-Equal -TestName "CSV generado" -Actual (Test-Path -LiteralPath $tempOutCsv) -Expected $true
    Assert-Equal -TestName "Markdown generado" -Actual (Test-Path -LiteralPath $tempOutMd) -Expected $true

    $bytes = [System.IO.File]::ReadAllBytes($tempOutCsv)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Assert-Equal -TestName "CSV sin BOM" -Actual $hasBom -Expected $false

    $mdBytes = [System.IO.File]::ReadAllBytes($tempOutMd)
    $mdHasBom = ($mdBytes.Length -ge 3 -and $mdBytes[0] -eq 0xEF -and $mdBytes[1] -eq 0xBB -and $mdBytes[2] -eq 0xBF)
    Assert-Equal -TestName "Markdown sin BOM" -Actual $mdHasBom -Expected $false
} finally {
    if (Test-Path -LiteralPath $tempOutCsv) { Remove-Item -LiteralPath $tempOutCsv -Force }
    if (Test-Path -LiteralPath $tempOutMd) { Remove-Item -LiteralPath $tempOutMd -Force }
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "RESULTADOS: $passed pruebas superadas, $failed fallidas." -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
Write-Host "=======================================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
