param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug'
)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
$failures = @()

function Assert-MatrixFixture([string]$Actual, [string]$Expected) {
    $actualValues = [regex]::Split((Get-Content -LiteralPath $Actual -Raw).Trim(), '\s+')
    $expectedValues = [regex]::Split((Get-Content -LiteralPath $Expected -Raw).Trim(), '\s+')
    if ($actualValues.Length -ne $expectedValues.Length -or $actualValues[0] -ne $expectedValues[0]) {
        throw "Dimensiones o cantidad de datos incorrectas: $Actual"
    }
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    for ($index = 1; $index -lt $expectedValues.Length; $index++) {
        $obtained = [double]::Parse($actualValues[$index], $culture)
        $expected = [double]::Parse($expectedValues[$index], $culture)
        if ([double]::IsNaN($obtained) -or [double]::IsInfinity($obtained) -or
            [double]::IsNaN($expected) -or [double]::IsInfinity($expected) -or
            [Math]::Abs($obtained - $expected) -gt (1e-9 + 1e-9 * [Math]::Abs($expected))) {
            throw "Producto incorrecto en el elemento $index de $Actual"
        }
    }
}

function Assert-SequentialCSV($Lines) {
    $rows = @($Lines | ConvertFrom-Csv)
    if ($rows.Count -ne 1 -or $rows[0].validation_status -ne 'OK' -or
        $rows[0].gomaxprocs -ne '1' -or $rows[0].repetition -ne '1' -or
        $rows[0].is_warmup -ne 'false' -or $rows[0].commit -notmatch '^[0-9a-f]{7,40}$') {
        throw 'CSV Go secuencial incorrecto.'
    }
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $kernel = [double]::Parse($rows[0].kernel_s, $culture)
    $total = [double]::Parse($rows[0].total_s, $culture)
    if ([double]::IsNaN($kernel) -or [double]::IsInfinity($kernel) -or
        [double]::IsNaN($total) -or [double]::IsInfinity($total) -or
        $kernel -lt 0 -or $total -lt $kernel) { throw 'Tiempos Go secuencial incorrectos.' }
}

foreach ($item in $selected) {
    try {
        Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\build_windows.ps1",'-Version',$item,'-Configuration',$Configuration,'-Tests')
        $module = Join-Path $script:ProjectRoot $item
        $build = Join-Path $module "build\$Configuration"
        $exe = Join-Path $build "$item.exe"
        if ($item.StartsWith('go_')) {
            $go = Initialize-Go
            Push-Location $module
            try {
                Invoke-Native $go @('fmt','./...')
                Invoke-Native $go @('vet','./...')
                Invoke-Native $go @('test','-count=1','-timeout=30s','./...')
            } finally { Pop-Location }
        } else {
            Push-Location $script:ProjectRoot
            try { Invoke-Native (Join-Path $build 'tests\pending_test.exe') }
            finally { Pop-Location }
        }
        if ($item -eq 'c_paralelo') {
            Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\run_hybrid_windows.ps1",'-Configuration',$Configuration)
        } else { Invoke-Native $exe @('--smoke-test') }
        if ($item -eq 'go_secuencial') {
            $csvLines = @(& $exe --n 2 --seed 42)
            if ($LASTEXITCODE -ne 0) { throw 'Go secuencial debe completar el calculo con codigo 0.' }
            Assert-SequentialCSV $csvLines
            $outputs = Join-Path $build 'fixture-results'
            New-Item -ItemType Directory -Force -Path $outputs | Out-Null
            foreach ($fixture in @('producto2','escalar','identidad','cero','impar3')) {
                $inputPath = Join-Path $script:ProjectRoot "tests\fixtures\$fixture.input.txt"
                $expectedPath = Join-Path $script:ProjectRoot "tests\fixtures\$fixture.expected.txt"
                $outputPath = Join-Path $outputs "$fixture.output.txt"
                $csvLines = @(& $exe --input $inputPath --output $outputPath)
                if ($LASTEXITCODE -ne 0) { throw "Go secuencial fallo en $fixture." }
                Assert-SequentialCSV $csvLines
                Assert-MatrixFixture $outputPath $expectedPath
            }
            Write-Host 'OK: go_secuencial (producto real, cinco fixtures y CSV validado).'
        } else {
            & $exe --n 2 --seed 42
            if ($LASTEXITCODE -ne 2) { throw 'El esqueleto debe rechazar el calculo pendiente con codigo 2.' }
            Write-Host "OK: $item (entorno y rechazo de operaciones pendientes; no valida multiplicacion)."
        }
    } catch {
        $failures += $item
        Write-Warning "$item : $($_.Exception.Message)"
    }
}
if ($failures.Count) { [Console]::Error.WriteLine("Pruebas incompletas: $($failures -join ', ')."); exit 1 }
exit 0
