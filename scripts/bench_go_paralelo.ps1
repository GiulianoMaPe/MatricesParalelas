$script:MeasurementProcessNames = @('c_secuencial','c_paralelo','go_secuencial','go_paralelo','mpiexec','smpd')
function Get-GoParaleloWorkerSeries {
    param([int[]]$Requested = @())

    $physical = [int](@(Get-CimInstance Win32_Processor) | Measure-Object -Property NumberOfCores -Sum).Sum
    $logical = [Environment]::ProcessorCount
    if ($Requested.Count -eq 0) {
        $series = @(1, 2, 4)
        if ($physical -ge 8) { $series += 8 }
    } else {
        $series = @($Requested | Sort-Object -Unique)
    }
    foreach ($w in $series) {
        if ($w -lt 1 -or $w -gt 1024) {
            throw "workers=$w fuera del rango [1,1024] del ejecutable."
        }
        if ($w -gt $logical) {
            throw "workers=$w supera los $logical procesadores logicos; GOMAXPROCS=$w no daria paralelismo real."
        }
    }
    return [pscustomobject]@{ Workers = $series; Physical = $physical; Logical = $logical }
}

# Assert-NoConcurrentMeasurement: falla si otro ejecutable de medición del
# proyecto está en marcha, sea otra campaña o una corrida manual.
function Assert-NoConcurrentMeasurement {
    $running = @(Get-Process -Name $script:MeasurementProcessNames -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $list = ($running | ForEach-Object { "$($_.ProcessName)[$($_.Id)]" }) -join ', '
        throw "Hay mediciones en curso: $list. No se ejecutan campanas simultaneas; espere a que terminen."
    }
}

# Enter-GoParaleloLock / Exit-GoParaleloLock: usan el mismo archivo
# (.cache\bench.lock), el mismo modo exclusivo y el mismo contenido JSON que el
# lock del caso c_paralelo (I2), de modo que ambas campañas se excluyen.
function Enter-GoParaleloLock {
    param([string]$LockPath, [string]$CampaignId)

    $directory = Split-Path -Parent $LockPath
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    try {
        $stream = [IO.File]::Open($LockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    } catch [IO.IOException] {
        $existing = ''
        try { $existing = Get-Content -LiteralPath $LockPath -Raw -ErrorAction Stop } catch { }
        throw "Otra campana esta en curso o quedo un lock huerfano. Lock: $LockPath. Contenido: $existing. Borrelo solo tras confirmar que no hay mediciones activas."
    }
    $info = [ordered]@{
        pid            = $PID
        hostname       = [Environment]::MachineName
        campaign_id    = $CampaignId
        started_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    } | ConvertTo-Json -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($info)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
    return $stream
}

function Exit-GoParaleloLock {
    param([object]$Stream, [string]$LockPath)
    if ($null -ne $Stream) { $Stream.Dispose() }
    Remove-Item -LiteralPath $LockPath -Force -ErrorAction SilentlyContinue
}

function ConvertTo-GoParaleloCsvLine {
    param([hashtable]$Row)
    return ($script:CsvHeader | ForEach-Object {
        $v = $Row[$_]
        if ($v -match '[,"\r\n]') { '"' + ($v -replace '"', '""') + '"' } else { $v }
    }) -join ','
}

# Invoke-GoParaleloRun: ejecuta go_paralelo para un (N, seed, W, rep), con plazo.
#   Además del contrato CSV, exige workers=W, gomaxprocs=W (paralelismo
#   efectivo informado por el runtime) y configuration=go_paralelo_W{W}.
#   Devuelve la fila validada, con el diagnóstico _cpu_wall, o $null.
function Invoke-GoParaleloRun {
    param(
        [string]$Executable,
        [int]$MatrixN,
        [uint32]$MatrixSeed,
        [int]$WorkerCount,
        [int]$RepIndex,    # 0 = warmup, 1..5 = medidas
        [int]$TimeoutSeconds = 1800
    )

    $label = if ($RepIndex -eq 0) { 'warmup' } else { "rep $RepIndex" }
    $tag = "[go_paralelo] N=$MatrixN W=$WorkerCount seed=$MatrixSeed $label"
    [Console]::Error.WriteLine("$tag - ejecutando...")

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Executable
    $psi.Arguments = "--n $MatrixN --seed $MatrixSeed --workers $WorkerCount --repetition $RepIndex"
    $psi.WorkingDirectory = $script:ProjectRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    # El ejecutable fija GOMAXPROCS=W; una variable heredada no debe intervenir.
    [void]$psi.EnvironmentVariables.Remove('GOMAXPROCS')

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    try {
        if (-not $proc.Start()) {
            [Console]::Error.WriteLine("ERROR: no se pudo iniciar go_paralelo. $tag")
            return $null
        }
    } catch {
        [Console]::Error.WriteLine("ERROR: excepcion al iniciar go_paralelo: $_")
        return $null
    }
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        & taskkill.exe /PID $proc.Id /T /F 2>&1 | Out-Null
        $proc.Dispose()
        [Console]::Error.WriteLine("ERROR: go_paralelo supero el plazo de $TimeoutSeconds s y se detuvo. $tag")
        return $null
    }
    $proc.WaitForExit()
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    $exitCode = $proc.ExitCode
    $wallSeconds = ($proc.ExitTime - $proc.StartTime).TotalSeconds
    $cpuSeconds = $proc.TotalProcessorTime.TotalSeconds
    $proc.Dispose()

    foreach ($errLine in ($stderr -split "`n")) {
        $trimmed = $errLine.TrimEnd("`r")
        if ($trimmed) { [Console]::Error.WriteLine("  [go_paralelo stderr] $trimmed") }
    }
    if ($exitCode -eq 2) {
        [Console]::Error.WriteLine("ERROR: go_paralelo devolvio codigo 2 (operacion pendiente). $tag")
        return $null
    }
    if ($exitCode -ne 0) {
        [Console]::Error.WriteLine("ERROR: go_paralelo devolvio codigo $exitCode. $tag")
        return $null
    }

    $lines = @($stdout -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_.Length -gt 0 })
    if ($lines.Count -ne 2) {
        [Console]::Error.WriteLine("ERROR: go_paralelo emitio $($lines.Count) linea(s); se esperaban cabecera y una fila. $tag")
        return $null
    }
    $row = Validate-CsvRow `
        -HeaderLine $lines[0] `
        -DataLine $lines[1] `
        -ExpectedVersion 'go_paralelo' `
        -ExpectedN $MatrixN `
        -ExpectedSeed $MatrixSeed `
        -ExpectedRepetition $RepIndex
    if (-not $row) {
        [Console]::Error.WriteLine("ERROR: la fila CSV de go_paralelo no paso la validacion. $tag")
        return $null
    }

    $expected = [ordered]@{
        workers          = "$WorkerCount"
        gomaxprocs       = "$WorkerCount"
        configuration    = "go_paralelo_W$WorkerCount"
        processes        = '1'
        threads          = '1'
        observed_threads = '1'
    }
    foreach ($field in $expected.Keys) {
        if ($row[$field] -ne $expected[$field]) {
            [Console]::Error.WriteLine("ERROR: $field='$($row[$field])', se esperaba '$($expected[$field])'; el paralelismo solicitado no es el efectivo. $tag")
            return $null
        }
    }

    # Diagnóstico de paralelismo: tiempo de CPU del proceso entre tiempo de pared.
    # Incluye generación y referencia secuencial, así que con W>1 es mayor que 1
    # pero menor que W; no forma parte del CSV de 20 columnas.
    $cpuWall = if ($wallSeconds -gt 0) { $cpuSeconds / $wallSeconds } else { 0.0 }
    $row['_cpu_wall'] = $cpuWall
    $ratioText = $cpuWall.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture)
    [Console]::Error.WriteLine("  [go_paralelo] OK - kernel_s=$($row['kernel_s']) total_s=$($row['total_s']) gomaxprocs=$($row['gomaxprocs']) cpu/pared=$ratioText")
    return $row
}

# Invoke-GoParaleloCampaign: por cada N y W, 1 warmup (rep 0) y MeasuredReps
#   medidas, con la misma semilla. Toma el lock antes de la primera corrida,
#   lo libera al terminar o fallar y se detiene ante el primer error.
function Invoke-GoParaleloCampaign {
    param(
        [int[]]$Dimensions,
        [uint32]$CampaignSeed,
        [int]$MeasuredReps,
        [int[]]$WorkerSeries = @(),
        [int]$TimeoutSeconds = 1800
    )

    $exe = Join-Path $script:ProjectRoot 'go_paralelo\build\Release\go_paralelo.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
        [Console]::Error.WriteLine("ERROR: no se encontro el binario Release: $exe")
        [Console]::Error.WriteLine("       Compile primero con: scripts\build_windows.ps1 -Version go_paralelo -Configuration Release")
        return $null
    }
    if ($MeasuredReps -gt 5) {
        [Console]::Error.WriteLine("ERROR: go_paralelo acepta --repetition 0..5; se pidieron $MeasuredReps repeticiones medidas.")
        return $null
    }
    try {
        $plan = Get-GoParaleloWorkerSeries -Requested $WorkerSeries
        Assert-NoConcurrentMeasurement
    } catch {
        [Console]::Error.WriteLine("ERROR: $_")
        return $null
    }

    $lockPath = Join-Path $script:ProjectRoot '.cache\bench.lock'
    $campaignId = 'go_paralelo-' + (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    try {
        $lock = Enter-GoParaleloLock -LockPath $lockPath -CampaignId $campaignId
    } catch {
        [Console]::Error.WriteLine("ERROR: $_")
        return $null
    }

    try {
        $hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
        [Console]::Error.WriteLine("")
        [Console]::Error.WriteLine("========== CAMPANA go_paralelo ==========")
        [Console]::Error.WriteLine("  Campana     : $campaignId")
        [Console]::Error.WriteLine("  Ejecutable  : $exe (SHA-256 $hash)")
        [Console]::Error.WriteLine("  Dimensiones : $($Dimensions -join ', ')")
        [Console]::Error.WriteLine("  Workers     : $($plan.Workers -join ', ') (nucleos fisicos $($plan.Physical), logicos $($plan.Logical))")
        [Console]::Error.WriteLine("  Semilla     : $CampaignSeed")
        [Console]::Error.WriteLine("  Repeticiones: 1 warmup + $MeasuredReps medidas")
        [Console]::Error.WriteLine("==========================================")

        $allRows = [System.Collections.Generic.List[hashtable]]::new()
        $totalRuns = $Dimensions.Count * $plan.Workers.Count * (1 + $MeasuredReps)
        $runCount = 0
        [Console]::Out.WriteLine(($script:CsvHeader -join ','))
        foreach ($dim in $Dimensions) {
            foreach ($w in $plan.Workers) {
                for ($rep = 0; $rep -le $MeasuredReps; $rep++) {
                    $runCount++
                    [Console]::Error.WriteLine("--- [$runCount/$totalRuns] N=$dim W=$w rep=$rep ---")
                    $row = Invoke-GoParaleloRun -Executable $exe -MatrixN $dim -MatrixSeed $CampaignSeed `
                        -WorkerCount $w -RepIndex $rep -TimeoutSeconds $TimeoutSeconds
                    if (-not $row) {
                        [Console]::Error.WriteLine("FATAL: corrida fallida N=$dim W=$w rep=$rep. Se detiene la campana go_paralelo.")
                        return $null
                    }
                    [Console]::Out.WriteLine((ConvertTo-GoParaleloCsvLine -Row $row))
                    $allRows.Add($row)
                }
            }
        }

        [Console]::Error.WriteLine("")
        [Console]::Error.WriteLine("========== go_paralelo COMPLETADO ==========")
        [Console]::Error.WriteLine("  Corridas exitosas: $($allRows.Count) / $totalRuns")
        [Console]::Error.WriteLine("=============================================")
        return $allRows
    } finally {
        Exit-GoParaleloLock -Stream $lock -LockPath $lockPath
    }
}

# ===========================================================================
