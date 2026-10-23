param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug'
)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$scriptsRoot = $PSScriptRoot
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
$failures = @()

Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$script:ProjectRoot\tests\compare_results_test.ps1")

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

function Assert-ParallelCSV($Lines, $Workers, [int]$Repetition = 1) {
    $rows = @($Lines | ConvertFrom-Csv)
    if ($rows.Count -ne 1) { throw "CSV Go paralelo: se esperaba una fila por ejecucion, hay $($rows.Count)." }
    $measure = $rows[0]
    $expectedWarmup = if ($Repetition -eq 0) { 'true' } else { 'false' }
    if ($measure.repetition -ne $Repetition.ToString() -or $measure.is_warmup -ne $expectedWarmup) {
        throw "CSV Go paralelo: repeticion o calentamiento incorrectos. rep=$($measure.repetition), warmup=$($measure.is_warmup)"
    }
    if ($measure.validation_status -ne 'OK' -or
        $measure.workers -ne $Workers.ToString() -or
        $measure.gomaxprocs -ne $Workers.ToString() -or
        $measure.configuration -ne "go_paralelo_W$Workers" -or
        $measure.commit -notmatch '^[0-9a-f]{7,40}$') {
        throw "CSV Go paralelo: campos incorrectos en medición. workers=$($measure.workers), gomaxprocs=$($measure.gomaxprocs), config=$($measure.configuration)"
    }
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $kernel = [double]::Parse($measure.kernel_s, $culture)
    $total = [double]::Parse($measure.total_s, $culture)
    if ([double]::IsNaN($kernel) -or [double]::IsInfinity($kernel) -or
        [double]::IsNaN($total) -or [double]::IsInfinity($total) -or
        $kernel -lt 0 -or $total -lt $kernel) { throw 'Tiempos Go paralelo incorrectos.' }
}

function Assert-HybridCSV($Lines, [int]$Processes, [int]$Threads) {
    $rows = @($Lines | ConvertFrom-Csv)
    if ($rows.Count -ne 1) { throw 'CSV c_paralelo debe contener una fila.' }
    $row = $rows[0]
    if ($row.version -ne 'c_paralelo' -or
        $row.processes -ne "$Processes" -or
        $row.threads -ne "$Threads" -or
        $row.observed_threads -ne "$Threads" -or
        $row.configuration -ne "c_paralelo_P${Processes}_T${Threads}" -or
        $row.n -ne '2' -or $row.seed -ne '42' -or
        $row.workers -ne '1' -or $row.repetition -ne '1' -or
        $row.is_warmup -ne 'false' -or
        $row.validation_status -ne 'OK' -or
        $row.commit -notmatch '^[0-9a-fA-F]{7,40}$') {
        throw 'CSV c_paralelo incorrecto.'
    }
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $kernel = [double]::Parse($row.kernel_s, $culture)
    $total = [double]::Parse($row.total_s, $culture)
    if ([double]::IsNaN($kernel) -or [double]::IsInfinity($kernel) -or
        [double]::IsNaN($total) -or [double]::IsInfinity($total) -or
        $kernel -lt 0 -or $total -lt $kernel) { throw 'Tiempos c_paralelo incorrectos.' }
}

function Invoke-HybridFixture {
    param([int]$Processes, [int]$Threads, [string]$InputPath, [string]$OutputPath)
    Invoke-Native powershell.exe @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',"$scriptsRoot\run_hybrid_windows.ps1",
        '-Configuration',$Configuration,
        '-Processes',"$Processes",
        '-Threads',"$Threads",
        '-InputPath',$InputPath,
        '-OutputPath',$OutputPath
    )
}

function Get-HybridCsv {
    param([int]$Processes, [int]$Threads, [int]$N, [uint32]$Seed)
    $launcher = Get-MPILauncher
    $exe = Join-Path $script:ProjectRoot "c_paralelo\build\$Configuration\c_paralelo.exe"
    $previousThreads = $env:OMP_NUM_THREADS
    $previousDynamic = $env:OMP_DYNAMIC
    try {
        $env:OMP_NUM_THREADS = "$Threads"
        $env:OMP_DYNAMIC = 'FALSE'
        $lines = @(& $launcher @('-n', "$Processes", $exe, '--n', "$N", '--seed', "$Seed"))
        if ($LASTEXITCODE -ne 0) {
            throw "c_paralelo termino con codigo $LASTEXITCODE."
        }
        return $lines
    } finally {
        $env:OMP_NUM_THREADS = $previousThreads
        $env:OMP_DYNAMIC = $previousDynamic
    }
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
            try {
                Invoke-Native (Join-Path $build 'tests\pending_test.exe')
                if ($item -eq 'c_paralelo') {
                    Invoke-Native (Join-Path $build 'tests\partition_test.exe')
                }
            }
            finally { Pop-Location }
        }
        if ($item -eq 'c_paralelo') {
            Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\run_hybrid_windows.ps1",'-Configuration',$Configuration,'-SmokeTest')
            $outputs = Join-Path $build 'fixture-results'
            New-Item -ItemType Directory -Force -Path $outputs | Out-Null
            $cases = @(
                @{ Fixture='producto2'; P=2; T=2 },
                @{ Fixture='escalar'; P=2; T=2 },
                @{ Fixture='identidad'; P=2; T=2 },
                @{ Fixture='cero'; P=2; T=2 },
                @{ Fixture='impar3'; P=2; T=2 },
                @{ Fixture='impar3'; P=1; T=2 },
                @{ Fixture='impar3'; P=2; T=1 },
                @{ Fixture='producto2'; P=3; T=1 },
                @{ Fixture='impar3'; P=5; T=1 }
            )
            foreach ($case in $cases) {
                $inputPath = Join-Path $script:ProjectRoot "tests\fixtures\$($case.Fixture).input.txt"
                $expectedPath = Join-Path $script:ProjectRoot "tests\fixtures\$($case.Fixture).expected.txt"
                $outputPath = Join-Path $outputs "$($case.Fixture)-P$($case.P)-T$($case.T).output.txt"
                Invoke-HybridFixture -Processes $case.P -Threads $case.T -InputPath $inputPath -OutputPath $outputPath
                Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\compare_results.ps1",'-Expected',$expectedPath,'-Actual',$outputPath)
            }
            $csvLines = @(Get-HybridCsv -Processes 2 -Threads 2 -N 2 -Seed 42)
            Assert-HybridCSV $csvLines 2 2
            Write-Host "OK: c_paralelo (smoke, cinco fixtures, P=1, P>N, no divisible y CSV validado)."
        } elseif ($item -in @('c_secuencial','go_secuencial')) {
            Invoke-Native $exe @('--smoke-test')
            $csvLines = @(& $exe --n 2 --seed 42)
            if ($LASTEXITCODE -ne 0) { throw "$item debe completar el calculo con codigo 0." }
            Assert-SequentialCSV $csvLines
            $outputs = Join-Path $build 'fixture-results'
            New-Item -ItemType Directory -Force -Path $outputs | Out-Null
            foreach ($fixture in @('producto2','escalar','identidad','cero','impar3')) {
                $inputPath = Join-Path $script:ProjectRoot "tests\fixtures\$fixture.input.txt"
                $expectedPath = Join-Path $script:ProjectRoot "tests\fixtures\$fixture.expected.txt"
                $outputPath = Join-Path $outputs "$fixture.output.txt"
                $csvLines = @(& $exe --input $inputPath --output $outputPath)
                if ($LASTEXITCODE -ne 0) { throw "$item fallo en $fixture." }
                Assert-SequentialCSV $csvLines
                Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\compare_results.ps1",'-Expected',$expectedPath,'-Actual',$outputPath)
            }
            Write-Host "OK: $item (producto real, cinco fixtures y CSV validado)."
        } elseif ($item -eq 'go_paralelo') {
            # Probar CLI completa con --workers
            $csvLines = @(& $exe --n 2 --seed 42 --workers 2)
            if ($LASTEXITCODE -ne 0) { throw "go_paralelo debe completar el calculo con codigo 0." }
            Assert-ParallelCSV $csvLines 2
            $outputs = Join-Path $build 'fixture-results'
            New-Item -ItemType Directory -Force -Path $outputs | Out-Null
            foreach ($fixture in @('producto2','escalar','identidad','cero','impar3')) {
                $inputPath = Join-Path $script:ProjectRoot "tests\fixtures\$fixture.input.txt"
                $expectedPath = Join-Path $script:ProjectRoot "tests\fixtures\$fixture.expected.txt"
                $outputPath = Join-Path $outputs "$fixture.output.txt"
                $csvLines = @(& $exe --input $inputPath --output $outputPath --workers 2)
                if ($LASTEXITCODE -ne 0) { throw "go_paralelo fallo en $fixture." }
                Assert-ParallelCSV $csvLines 2
                Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\compare_results.ps1",'-Expected',$expectedPath,'-Actual',$outputPath)
            }
            # Probar workers > filas
            $csvLines = @(& $exe --n 2 --seed 42 --workers 4)
            if ($LASTEXITCODE -ne 0) { throw "go_paralelo workers>filas debe completar con codigo 0." }
            Assert-ParallelCSV $csvLines 4
            foreach ($repetition in @(0,5)) {
                $csvLines = @(& $exe --n 2 --seed 42 --workers 1 --repetition $repetition)
                if ($LASTEXITCODE -ne 0) { throw "go_paralelo fallo en repeticion $repetition con un worker." }
                Assert-ParallelCSV $csvLines 1 $repetition
            }
            Write-Host "OK: $item (producto real, cinco fixtures, workers>filas y CSV validado)."
        } else {
            Invoke-Native $exe @('--smoke-test')
            & $exe --n 2 --seed 42
            if ($LASTEXITCODE -ne 2) { throw 'El esqueleto debe rechazar el calculo pendiente con codigo 2.' }
            if ($item -eq 'go_paralelo') {
                Write-Host "OK: $item (pruebas Go del nucleo y entorno; CLI de calculo pendiente)."
            } else {
                Write-Host "OK: $item (entorno y rechazo de operaciones pendientes; no valida multiplicacion)."
            }
        }
    } catch {
        $failures += $item
        Write-Warning "$item : $($_.Exception.Message)"
    }
}
if ($failures.Count) { [Console]::Error.WriteLine("Pruebas incompletas: $($failures -join ', ')."); exit 1 }
exit 0
