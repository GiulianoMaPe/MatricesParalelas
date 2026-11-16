param([switch]$WithExecutable)

# Pruebas del caso go_paralelo de scripts/bench_windows.ps1 (S7, I4).
# Los casos controlados usan ejecutables falsos (.cmd) y no producen
# observaciones experimentales. -WithExecutable añade corridas reales con el
# ejecutable Release de go_paralelo (N=64), sin guardar sus tiempos.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\scripts\bench_windows.ps1"

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('bench-go-paralelo-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()
$header = $script:CsvHeader -join ','
$sample = [ordered]@{
    timestamp = '2026-11-12T00:00:00Z'; version = 'go_paralelo'
    commit = '0123456789abcdef0123456789abcdef01234567'; hostname = 'PC-PRUEBA'
    cpu_model = 'CPU de prueba'; ram_gb = '15.900'; os_version = 'Windows de prueba'
    configuration = 'go_paralelo_W2'; n = '3'; seed = '42'; processes = '1'; threads = '1'
    observed_threads = '1'; workers = '2'; gomaxprocs = '2'; repetition = '1'; is_warmup = 'false'
    kernel_s = '0.100000000'; total_s = '0.200000000'; validation_status = 'OK'
}

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

# Test-Case ejecuta la acción con stderr capturado y lo pasa como $log.
function Test-Case {
    param([string]$Name, [scriptblock]$Action)
    $errorWriter = [IO.StringWriter]::new()
    $originalError = [Console]::Error
    [Console]::SetError($errorWriter)
    try {
        & $Action $errorWriter | Out-Null
    } catch {
        [Console]::SetError($originalError)
        throw "FAIL: $Name : $_`n$($errorWriter.ToString())"
    } finally {
        [Console]::SetError($originalError)
    }
    $results.Add([pscustomobject]@{ case = $Name; status = 'OK' })
}

# New-FakeExecutable crea un .cmd que imprime cabecera y filas, o un fallo.
function New-FakeExecutable {
    param([string]$Name, [hashtable]$Changes = @{}, [int]$ExitCode = 0, [int]$ExtraRows = 0, [int]$SleepSeconds = 0)
    $data = [ordered]@{}
    foreach ($key in $sample.Keys) { $data[$key] = $sample[$key] }
    foreach ($key in $Changes.Keys) { $data[$key] = $Changes[$key] }
    $row = ($script:CsvHeader | ForEach-Object { $data[$_] }) -join ','
    $lines = @('@echo off')
    if ($SleepSeconds -gt 0) { $lines += "ping -n $($SleepSeconds + 1) 127.0.0.1 >nul" }
    $lines += "echo $header"
    for ($i = 0; $i -le $ExtraRows; $i++) { $lines += "echo $row" }
    $lines += "exit /b $ExitCode"
    $path = Join-Path $testRoot "$Name.cmd"
    [IO.File]::WriteAllLines($path, $lines, [Text.Encoding]::ASCII)
    return $path
}

function Invoke-FakeRun {
    param([string]$Executable, [int]$Workers = 2, [int]$Repetition = 1, [int]$TimeoutSeconds = 30)
    Invoke-GoParaleloRun -Executable $Executable -MatrixN 3 -MatrixSeed 42 -WorkerCount $Workers `
        -RepIndex $Repetition -TimeoutSeconds $TimeoutSeconds
}

function Assert-Rejected {
    param([object]$Row, [System.IO.StringWriter]$Log, [string]$Pattern)
    Assert-That ($null -eq $Row) 'La corrida debia rechazarse.'
    Assert-That ($Log.ToString() -match $Pattern) "Falta el motivo '$Pattern' en: $($Log.ToString())"
}

try {
    # --- Validación de la fila y del paralelismo efectivo ---------------------
    Test-Case 'fila-valida-W2' {
        $row = Invoke-FakeRun (New-FakeExecutable 'valida')
        Assert-That ($null -ne $row) 'La fila valida fue rechazada.'
        Assert-That ($row['gomaxprocs'] -eq '2' -and $row['configuration'] -eq 'go_paralelo_W2') 'Campos alterados.'
        Assert-That ($row.ContainsKey('_cpu_wall')) 'Falta el diagnostico cpu/pared.'
        Assert-That ((ConvertTo-GoParaleloCsvLine -Row $row).Split(',').Count -eq 20) 'La salida no tiene 20 campos.'
    }
    Test-Case 'warmup-rep0' {
        $row = Invoke-FakeRun (New-FakeExecutable 'warmup' @{ repetition = '0'; is_warmup = 'true' }) -Repetition 0
        Assert-That ($null -ne $row) 'El warmup valido fue rechazado.'
    }
    $parallelism = [ordered]@{
        'gomaxprocs-distinto' = @{ gomaxprocs = '1' }
        'workers-distinto'    = @{ workers = '1' }
        'configuracion-distinta' = @{ configuration = 'go_paralelo_W1' }
        'procesos-distintos'  = @{ processes = '2' }
        'hilos-observados-distintos' = @{ observed_threads = '2' }
    }
    foreach ($name in $parallelism.Keys) {
        $fake = New-FakeExecutable $name $parallelism[$name]
        Test-Case $name { param($log) Assert-Rejected (Invoke-FakeRun $fake) $log 'paralelismo solicitado no es el efectivo' }
    }
    Test-Case 'version-distinta' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'version' @{ version = 'go_secuencial' })) $log "version='go_secuencial'" }
    Test-Case 'kernel-mayor-que-total' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'kernel' @{ kernel_s = '0.3' })) $log 'viola protocolo' }
    Test-Case 'validacion-no-ok' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'estado' @{ validation_status = 'ERROR' })) $log 'validation_status' }
    Test-Case 'repeticion-distinta' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'rep' @{ repetition = '2' })) $log 'repetition=2' }
    Test-Case 'dos-filas' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'dosfilas' -ExtraRows 1)) $log '3 linea' }
    Test-Case 'codigo-2-pendiente' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'pendiente' -ExitCode 2)) $log 'codigo 2' }
    Test-Case 'codigo-1-error' { param($log) Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'error' -ExitCode 1)) $log 'codigo 1' }
    Test-Case 'ejecutable-ausente' { param($log) Assert-Rejected (Invoke-FakeRun (Join-Path $testRoot 'ausente.exe')) $log 'excepcion al iniciar' }
    Test-Case 'plazo-excedido' {
        param($log)
        $watch = [Diagnostics.Stopwatch]::StartNew()
        Assert-Rejected (Invoke-FakeRun (New-FakeExecutable 'lento' -SleepSeconds 20) -TimeoutSeconds 1) $log 'supero el plazo'
        Assert-That ($watch.Elapsed.TotalSeconds -lt 10) "El plazo no detuvo la corrida a tiempo ($($watch.Elapsed.TotalSeconds) s)."
    }

    # --- Serie de workers ------------------------------------------------------
    $physical = [int](@(Get-CimInstance Win32_Processor) | Measure-Object -Property NumberOfCores -Sum).Sum
    $logical = [Environment]::ProcessorCount
    Test-Case 'serie-del-protocolo' {
        $expected = @(1, 2, 4)
        if ($physical -ge 8) { $expected += 8 }
        $plan = Get-GoParaleloWorkerSeries
        Assert-That (($plan.Workers -join ',') -eq ($expected -join ',')) "Serie $($plan.Workers -join ',') distinta de $($expected -join ',')."
    }
    Test-Case 'serie-explicita-ordenada-sin-duplicados' {
        $plan = Get-GoParaleloWorkerSeries -Requested @(4, 1, 4)
        Assert-That (($plan.Workers -join ',') -eq '1,4') "Serie $($plan.Workers -join ',')."
    }
    foreach ($invalid in @(0, ($logical + 1), 1025)) {
        Test-Case "serie-rechaza-W$invalid" {
            $caught = $null
            try { Get-GoParaleloWorkerSeries -Requested @($invalid) | Out-Null } catch { $caught = $_ }
            Assert-That ($null -ne $caught) "W=$invalid fue aceptado."
        }
    }

    # --- Lock y campañas simultáneas ------------------------------------------
    $lockPath = Join-Path $testRoot 'lock\bench.lock'
    Test-Case 'lock-exclusivo-y-liberado' {
        $first = Enter-GoParaleloLock -LockPath $lockPath -CampaignId 'prueba-1'
        $caught = $null
        try { Enter-GoParaleloLock -LockPath $lockPath -CampaignId 'prueba-2' | Out-Null } catch { $caught = $_ }
        Exit-GoParaleloLock -Stream $first -LockPath $lockPath
        Assert-That ($null -ne $caught) 'Se tomo el lock dos veces.'
        Assert-That (-not (Test-Path -LiteralPath $lockPath)) 'El lock no se libero.'
        $again = Enter-GoParaleloLock -LockPath $lockPath -CampaignId 'prueba-3'
        $readWhileHeld = $null
        try { [IO.File]::ReadAllText($lockPath) | Out-Null } catch { $readWhileHeld = $_ }
        Assert-That ($null -ne $readWhileHeld) 'El lock tomado no es exclusivo.'
        $again.Dispose()
        $content = [IO.File]::ReadAllText($lockPath) | ConvertFrom-Json
        Exit-GoParaleloLock -Stream $null -LockPath $lockPath
        Assert-That ($content.pid -eq $PID -and $content.campaign_id -eq 'prueba-3') 'Contenido del lock incorrecto.'
    }
    Test-Case 'lock-huerfano-rechazado' {
        [IO.File]::WriteAllText($lockPath, '{"pid":1,"campaign_id":"c_paralelo-anterior"}')
        $caught = $null
        try { Enter-GoParaleloLock -LockPath $lockPath -CampaignId 'prueba' | Out-Null } catch { $caught = $_ }
        Assert-That ($null -ne $caught -and "$caught" -match 'c_paralelo-anterior') 'No se informo el lock existente.'
        Assert-That (Test-Path -LiteralPath $lockPath) 'Se borro un lock ajeno.'
        Remove-Item -LiteralPath $lockPath -Force
    }
    Test-Case 'medicion-en-curso-rechazada' {
        $fakeProcess = Join-Path $testRoot 'go_paralelo.exe'
        Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\PING.EXE') -Destination $fakeProcess
        $running = Start-Process -FilePath $fakeProcess -ArgumentList '-n', '30', '127.0.0.1' -WindowStyle Hidden -PassThru
        try {
            $caught = $null
            try { Assert-NoConcurrentMeasurement } catch { $caught = $_ }
            Assert-That ($null -ne $caught -and "$caught" -match "go_paralelo\[$($running.Id)\]") 'No se detecto la medicion en curso.'
        } finally {
            Stop-Process -Id $running.Id -Force -ErrorAction SilentlyContinue
            $running.WaitForExit()
        }
        Assert-NoConcurrentMeasurement
    }
    Test-Case 'campana-respeta-lock-ajeno' {
        param($log)
        $projectLock = Join-Path $script:ProjectRoot '.cache\bench.lock'
        Assert-That (-not (Test-Path -LiteralPath $projectLock)) "Ya existe $projectLock; no se ejecuta la prueba."
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $projectLock) | Out-Null
        $held = [IO.File]::Open($projectLock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $result = Invoke-GoParaleloCampaign -Dimensions @(3) -CampaignSeed 42 -MeasuredReps 1 -WorkerSeries @(1)
            Assert-That ($null -eq $result) 'La campana corrio con el lock tomado.'
            Assert-That (Test-Path -LiteralPath $projectLock) 'La campana borro un lock ajeno.'
        } finally {
            $held.Dispose()
            Remove-Item -LiteralPath $projectLock -Force -ErrorAction SilentlyContinue
        }
    }
    Test-Case 'campana-rechaza-mas-de-5-repeticiones' {
        param($log)
        $result = Invoke-GoParaleloCampaign -Dimensions @(3) -CampaignSeed 42 -MeasuredReps 6 -WorkerSeries @(1)
        Assert-That ($null -eq $result) 'Se aceptaron 6 repeticiones medidas.'
    }

    # --- Ejecutable real (opcional) -------------------------------------------
    if ($WithExecutable) {
        Test-Case 'ejecutable-real-campana-corta' {
            $output = [IO.StringWriter]::new()
            $originalOut = [Console]::Out
            [Console]::SetOut($output)
            try {
                $rows = @(Invoke-GoParaleloCampaign -Dimensions @(64) -CampaignSeed 42 -MeasuredReps 2 -WorkerSeries @(1, 2, $logical))
            } finally {
                [Console]::SetOut($originalOut)
            }
            $series = @(@(1, 2, $logical) | Sort-Object -Unique)
            Assert-That ($rows.Count -eq 3 * $series.Count) "Se esperaban $(3 * $series.Count) filas; hubo $($rows.Count)."
            $lines = @($output.ToString() -split "`r?`n" | Where-Object { $_ })
            Assert-That ($lines[0] -eq $header -and $lines.Count -eq $rows.Count + 1) 'CSV de salida incorrecto.'
            foreach ($row in $rows) {
                Assert-That ($row['gomaxprocs'] -eq $row['workers']) "gomaxprocs=$($row['gomaxprocs']) con workers=$($row['workers'])."
            }
            Assert-That (-not (Test-Path -LiteralPath (Join-Path $script:ProjectRoot '.cache\bench.lock'))) 'La campana no libero el lock.'
        }
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$results | Format-Table -AutoSize | Out-String | Write-Output
Write-Output "OK: bench go_paralelo ($($results.Count) casos)."
exit 0
