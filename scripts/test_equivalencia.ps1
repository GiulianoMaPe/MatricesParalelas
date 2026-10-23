param(
    [ValidateSet('Release', 'Debug')][string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$comparator = Join-Path $projectRoot 'scripts\compare_results.ps1'
$fixturesDir = Join-Path $projectRoot 'tests\fixtures'
$fixtures = @('escalar', 'identidad', 'cero', 'producto2', 'impar3')
$tempDir = Join-Path $projectRoot 'temp_equivalencia'

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   SUITE DE EQUIVALENCIA NUMERICA Y FUNCIONAL (SPRINT 4)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$results = @()

# 1. Probar Go Secuencial
$goSecExe = Join-Path $projectRoot "go_secuencial\build\$Configuration\go_secuencial.exe"
if (Test-Path $goSecExe) {
    Write-Host "`n[1/3] Evaluando go_secuencial..." -ForegroundColor Yellow
    foreach ($f in $fixtures) {
        $in = Join-Path $fixturesDir "$f.input.txt"
        $exp = Join-Path $fixturesDir "$f.expected.txt"
        $out = Join-Path $tempDir "go_sec_$f.txt"
        
        & $goSecExe --input $in --output $out 2>$null
        $comp = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $comparator -Expected $exp -Actual $out
        $status = if ($LASTEXITCODE -eq 0) { "OK" } else { "FAIL" }
        Write-Host "  -> $f : $comp" -ForegroundColor $(if ($status -eq "OK") { "Green" } else { "Red" })
        $results += [PSCustomObject]@{ Version = "go_secuencial"; Configuracion = "Secuencial"; Fixture = $f; Estado = $status }
    }
}

# 2. Probar C Secuencial (si existe el binario)
$cSecExe = Join-Path $projectRoot "c_secuencial\build\$Configuration\c_secuencial.exe"
if (Test-Path $cSecExe) {
    Write-Host "`n[2/3] Evaluando c_secuencial..." -ForegroundColor Yellow
    foreach ($f in $fixtures) {
        $in = Join-Path $fixturesDir "$f.input.txt"
        $exp = Join-Path $fixturesDir "$f.expected.txt"
        $out = Join-Path $tempDir "c_sec_$f.txt"
        
        & $cSecExe --input $in --output $out 2>$null
        $comp = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $comparator -Expected $exp -Actual $out
        $status = if ($LASTEXITCODE -eq 0) { "OK" } else { "FAIL" }
        Write-Host "  -> $f : $comp" -ForegroundColor $(if ($status -eq "OK") { "Green" } else { "Red" })
        $results += [PSCustomObject]@{ Version = "c_secuencial"; Configuracion = "Secuencial"; Fixture = $f; Estado = $status }
    }
}

# 3. Probar Go Paralelo con W = 1, 2, 4, 8
$goParExe = Join-Path $projectRoot "go_paralelo\build\$Configuration\go_paralelo.exe"
if (Test-Path $goParExe) {
    Write-Host "`n[3/3] Evaluando go_paralelo (W = 1, 2, 4, 8)..." -ForegroundColor Yellow
    foreach ($w in @(1, 2, 4, 8)) {
        Write-Host "  Configuracion Workers = $w" -ForegroundColor Magenta
        foreach ($f in $fixtures) {
            $in = Join-Path $fixturesDir "$f.input.txt"
            $exp = Join-Path $fixturesDir "$f.expected.txt"
            $out = Join-Path $tempDir "go_par_w${w}_$f.txt"
            
            & $goParExe --workers $w --input $in --output $out 2>$null
            $comp = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $comparator -Expected $exp -Actual $out
            $status = if ($LASTEXITCODE -eq 0) { "OK" } else { "FAIL" }
            Write-Host "    -> $f (W=$w): $comp" -ForegroundColor $(if ($status -eq "OK") { "Green" } else { "Red" })
            $results += [PSCustomObject]@{ Version = "go_paralelo"; Configuracion = "W=$w"; Fixture = $f; Estado = $status }
        }
    }
}

Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                 RESUMEN DE EQUIVALENCIA                  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize
