param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateRange(1,2147483647)][int]$N = 512,
    [uint32]$Seed = 42,
    [ValidateRange(1,1024)][int]$Workers = 2,
    # go_paralelo: lista de workers; vacía = serie del protocolo (1,2,4 y 8 si hay 8+ núcleos)
    [int[]]$GoWorkers = @(),
    [ValidateRange(1,1024)][int]$Processes = 2,
    [ValidateRange(1,1024)][int]$Threads = 2,
    [ValidateRange(1,1000)][int]$Repetitions = 5,
    [ValidateSet('piloto','oficial')][string]$Fase = 'piloto'
)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
foreach ($item in $selected) {
    $status = Get-Content -LiteralPath (Join-Path $script:ProjectRoot "$item\status.json") -Raw | ConvertFrom-Json
    if ($status.algorithm -ne 'implemented' -or $status.validation -ne 'passed') {
        [Console]::Error.WriteLine("$item : algoritmo/validacion pendientes. No se ejecuta ni se generan mediciones.")
        exit 2
    }
}

# ---------------------------------------------------------------------------
#  Expected CSV header (20 columns) — from docs/contrato.md §4
# ---------------------------------------------------------------------------
$script:CsvHeader = @(
    'timestamp','version','commit','hostname','cpu_model','ram_gb',
    'os_version','configuration','n','seed','processes','threads',
    'observed_threads','workers','gomaxprocs','repetition','is_warmup',
    'kernel_s','total_s','validation_status'
)

# ---------------------------------------------------------------------------
#  Validate-CsvRow: parse one CSV data row and enforce protocol constraints
#   Returns a hashtable with column values or $null on error.
# ---------------------------------------------------------------------------
function Validate-CsvRow {
    param(
        [string]$HeaderLine,
        [string]$DataLine,
        [string]$ExpectedVersion,
        [int]$ExpectedN,
        [uint32]$ExpectedSeed,
        [int]$ExpectedRepetition
    )

    # Parse header
    $headers = $HeaderLine -split ','
    if ($headers.Count -ne 20) {
        [Console]::Error.WriteLine("ERROR: cabecera CSV tiene $($headers.Count) campos, se esperaban 20.")
        return $null
    }
    for ($i = 0; $i -lt 20; $i++) {
        $got = $headers[$i].Trim('"').Trim()
        $want = $script:CsvHeader[$i]
        if ($got -ne $want) {
            [Console]::Error.WriteLine("ERROR: campo $i de cabecera es '$got', se esperaba '$want'.")
            return $null
        }
    }

    # Parse data row — handle quoted fields
    $fields = @()
    $current = ''
    $inQuote = $false
    for ($ci = 0; $ci -lt $DataLine.Length; $ci++) {
        $ch = $DataLine[$ci]
        if ($inQuote) {
            if ($ch -eq '"') {
                if ($ci + 1 -lt $DataLine.Length -and $DataLine[$ci + 1] -eq '"') {
                    $current += '"'
                    $ci++
                } else {
                    $inQuote = $false
                }
            } else {
                $current += $ch
            }
        } else {
            if ($ch -eq '"') {
                $inQuote = $true
            } elseif ($ch -eq ',') {
                $fields += $current
                $current = ''
            } else {
                $current += $ch
            }
        }
    }
    $fields += $current

    if ($fields.Count -ne 20) {
        [Console]::Error.WriteLine("ERROR: fila CSV tiene $($fields.Count) campos, se esperaban 20.")
        return $null
    }

    $row = @{}
    for ($i = 0; $i -lt 20; $i++) {
        $row[$script:CsvHeader[$i]] = $fields[$i]
    }

    # Validate version
    if ($row['version'] -ne $ExpectedVersion) {
        [Console]::Error.WriteLine("ERROR: version='$($row['version'])', se esperaba '$ExpectedVersion'.")
        return $null
    }

    # Validate N
    if ([int]$row['n'] -ne $ExpectedN) {
        [Console]::Error.WriteLine("ERROR: n=$($row['n']), se esperaba $ExpectedN.")
        return $null
    }

    # Validate seed
    if ([uint32]$row['seed'] -ne $ExpectedSeed) {
        [Console]::Error.WriteLine("ERROR: seed=$($row['seed']), se esperaba $ExpectedSeed.")
        return $null
    }

    # Validate repetition
    if ([int]$row['repetition'] -ne $ExpectedRepetition) {
        [Console]::Error.WriteLine("ERROR: repetition=$($row['repetition']), se esperaba $ExpectedRepetition.")
        return $null
    }

    # Validate is_warmup consistency with repetition
    $expectedWarmup = if ($ExpectedRepetition -eq 0) { 'true' } else { 'false' }
    if ($row['is_warmup'] -ne $expectedWarmup) {
        [Console]::Error.WriteLine("ERROR: is_warmup='$($row['is_warmup'])', se esperaba '$expectedWarmup' para repetition=$ExpectedRepetition.")
        return $null
    }

    # Validate validation_status
    if ($row['validation_status'] -ne 'OK') {
        [Console]::Error.WriteLine("ERROR: validation_status='$($row['validation_status'])', se requiere 'OK'.")
        return $null
    }

    # Validate kernel_s and total_s (PS 5.1 compatible — no [double]::IsFinite)
    $kernelS = [double]$row['kernel_s']
    $totalS  = [double]$row['total_s']

    if ([double]::IsNaN($kernelS) -or [double]::IsInfinity($kernelS) -or $kernelS -lt 0.0) {
        [Console]::Error.WriteLine("ERROR: kernel_s=$kernelS invalido (no finito o negativo).")
        return $null
    }
    if ([double]::IsNaN($totalS) -or [double]::IsInfinity($totalS) -or $totalS -lt 0.0) {
        [Console]::Error.WriteLine("ERROR: total_s=$totalS invalido (no finito o negativo).")
        return $null
    }
    if ($kernelS -gt $totalS) {
        [Console]::Error.WriteLine("ERROR: kernel_s ($kernelS) > total_s ($totalS) — viola protocolo.")
        return $null
    }

    return $row
}

# ---------------------------------------------------------------------------
#  Run-CSecuencial: executes the c_secuencial binary for one (N, seed, rep)
#   Returns validated row hashtable or $null on error.
# ---------------------------------------------------------------------------
function Run-CSecuencial {
    param(
        [int]$MatrixN,
        [uint32]$MatrixSeed,
        [int]$RepIndex   # 0 = warmup, 1..5 = measured
    )

    $exe = Join-Path $script:ProjectRoot 'c_secuencial\build\Release\c_secuencial.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
        [Console]::Error.WriteLine("ERROR: no se encontro el binario Release: $exe")
        [Console]::Error.WriteLine("       Compile primero con: scripts\build_windows.ps1 -Version c_secuencial -Configuration Release")
        return $null
    }

    $isWarmup = ($RepIndex -eq 0)
    $label = if ($isWarmup) { "warmup" } else { "rep $RepIndex" }
    [Console]::Error.WriteLine("[c_secuencial] N=$MatrixN seed=$MatrixSeed $label — ejecutando...")

    # Run the binary and capture stdout/stderr separately
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $exe
    $psi.Arguments = "--n $MatrixN --seed $MatrixSeed --repetition $RepIndex"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi

    try {
        if (-not $proc.Start()) {
            [Console]::Error.WriteLine("ERROR: no se pudo iniciar el proceso c_secuencial.")
            return $null
        }
    } catch {
        [Console]::Error.WriteLine("ERROR: excepcion al iniciar c_secuencial: $_")
        return $null
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    $proc.Dispose()

    # Report stderr (diagnostic info from the binary)
    if ($stderr) {
        foreach ($errLine in ($stderr -split "`n")) {
            $trimmed = $errLine.TrimEnd("`r")
            if ($trimmed) {
                [Console]::Error.WriteLine("  [c_secuencial stderr] $trimmed")
            }
        }
    }

    # Check exit code
    if ($exitCode -eq 2) {
        [Console]::Error.WriteLine("ERROR: c_secuencial devolvio codigo 2 (operacion pendiente). N=$MatrixN rep=$RepIndex")
        return $null
    }
    if ($exitCode -ne 0) {
        [Console]::Error.WriteLine("ERROR: c_secuencial devolvio codigo $exitCode. N=$MatrixN rep=$RepIndex")
        return $null
    }

    # Parse stdout lines (header + data)
    $lines = @($stdout -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_.Length -gt 0 })
    if ($lines.Count -lt 2) {
        [Console]::Error.WriteLine("ERROR: stdout de c_secuencial tiene $($lines.Count) linea(s), se esperaban al menos 2 (cabecera + datos).")
        return $null
    }

    $row = Validate-CsvRow `
        -HeaderLine $lines[0] `
        -DataLine $lines[1] `
        -ExpectedVersion 'c_secuencial' `
        -ExpectedN $MatrixN `
        -ExpectedSeed $MatrixSeed `
        -ExpectedRepetition $RepIndex

    if (-not $row) {
        [Console]::Error.WriteLine("ERROR: la fila CSV de c_secuencial no paso la validacion. N=$MatrixN rep=$RepIndex")
        return $null
    }

    # Validate c_secuencial-specific fields
    # NOTE: the binary emits PROJECT_CONFIGURATION (build config, e.g. "Release")
    # in the configuration field. Per contrato.md §4.1 the canonical value must be
    # "c_secuencial". We override it here to comply with the 20-field CSV contract
    # without modifying the source code (out of scope for I1).
    if ($row['configuration'] -ne 'c_secuencial') {
        [Console]::Error.WriteLine("  [c_secuencial] AVISO: configuration='$($row['configuration'])' del binario; se reemplaza por 'c_secuencial' segun contrato.")
        $row['configuration'] = 'c_secuencial'
    }
    if ($row['processes'] -ne '1' -or $row['threads'] -ne '1') {
        [Console]::Error.WriteLine("ERROR: c_secuencial debe reportar processes=1, threads=1.")
        return $null
    }

    # Per contrato.md §4, gomaxprocs must be empty in C versions. The binary
    # currently emits "1" as a placeholder; we clear it here.
    if ($row['gomaxprocs'] -ne '') {
        $row['gomaxprocs'] = ''
    }

    [Console]::Error.WriteLine("  [c_secuencial] OK — kernel_s=$($row['kernel_s']) total_s=$($row['total_s'])")
    return $row
}

# ---------------------------------------------------------------------------
#  Invoke-CSecuencialCampaign: full measurement campaign for c_secuencial
#   Respects protocol: warmup (rep 0) + 5 measured repetitions (rep 1..5)
#   per each dimension N, with seed=42.
# ---------------------------------------------------------------------------
function Invoke-CSecuencialCampaign {
    param(
        [int[]]$Dimensions,
        [uint32]$CampaignSeed,
        [int]$MeasuredReps
    )

    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("========== CAMPANA c_secuencial ==========")
    [Console]::Error.WriteLine("  Dimensiones : $($Dimensions -join ', ')")
    [Console]::Error.WriteLine("  Semilla     : $CampaignSeed")
    [Console]::Error.WriteLine("  Repeticiones: 1 warmup + $MeasuredReps medidas")
    [Console]::Error.WriteLine("===========================================")
    [Console]::Error.WriteLine("")

    $allRows = [System.Collections.Generic.List[hashtable]]::new()
    $headerWritten = $false
    $totalRuns = $Dimensions.Count * (1 + $MeasuredReps)
    $runCount = 0

    foreach ($dim in $Dimensions) {
        # Warmup (repetition 0)
        $runCount++
        [Console]::Error.WriteLine("--- [$runCount/$totalRuns] Warmup N=$dim ---")
        $warmupRow = Run-CSecuencial -MatrixN $dim -MatrixSeed $CampaignSeed -RepIndex 0
        if (-not $warmupRow) {
            [Console]::Error.WriteLine("FATAL: warmup fallido para N=$dim. Se detiene la campana c_secuencial.")
            return $null
        }

        # Write header once to stdout
        if (-not $headerWritten) {
            [Console]::Out.WriteLine(($script:CsvHeader -join ','))
            $headerWritten = $true
        }

        # Write warmup row (re-quote fields that contain commas, quotes, or newlines)
        $csvLine = ($script:CsvHeader | ForEach-Object {
            $v = $warmupRow[$_]
            if ($v -match '[,"\r\n]') { '"' + ($v -replace '"','""') + '"' } else { $v }
        }) -join ','
        [Console]::Out.WriteLine($csvLine)
        $allRows.Add($warmupRow)

        # Measured repetitions 1..5
        for ($rep = 1; $rep -le $MeasuredReps; $rep++) {
            $runCount++
            [Console]::Error.WriteLine("--- [$runCount/$totalRuns] Medicion N=$dim rep=$rep ---")
            $measuredRow = Run-CSecuencial -MatrixN $dim -MatrixSeed $CampaignSeed -RepIndex $rep
            if (-not $measuredRow) {
                [Console]::Error.WriteLine("FATAL: medicion fallida para N=$dim rep=$rep. Se detiene la campana c_secuencial.")
                return $null
            }

            $csvLine = ($script:CsvHeader | ForEach-Object {
                $v = $measuredRow[$_]
                if ($v -match '[,"\r\n]') { '"' + ($v -replace '"','""') + '"' } else { $v }
            }) -join ','
            [Console]::Out.WriteLine($csvLine)
            $allRows.Add($measuredRow)
        }
    }

    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("========== c_secuencial COMPLETADO ==========")
    [Console]::Error.WriteLine("  Corridas exitosas: $($allRows.Count) / $totalRuns")
    [Console]::Error.WriteLine("===============================================")

    return $allRows
}

# ===========================================================================
#  I2 — c_paralelo (Sebastian) — TODO Sprint 7
# ===========================================================================
# function Invoke-CParaleloCampaign { ... }

# ===========================================================================
#  I3 — go_secuencial (Giuliano) — TODO Sprint 7
# ===========================================================================
# function Invoke-GoSecuencialCampaign { ... }

# ===========================================================================
#  I4 — go_paralelo (Eva) — Sprint 7
#   Mide el ejecutable Release con varios workers, comprueba que el
#   paralelismo pedido sea el efectivo y evita campañas simultáneas.
# ===========================================================================

# Ejecutables de medición del proyecto; si alguno corre, no se inicia otra campaña.
$script:MeasurementProcessNames = @('c_secuencial', 'c_paralelo', 'go_secuencial', 'go_paralelo', 'mpiexec', 'smpd')

# Get-GoParaleloWorkerSeries: sin lista explícita aplica la serie del protocolo
# (W=1,2,4 y W=8 solo con 8 o más núcleos físicos). Rechaza W mayor que los
# procesadores lógicos: GOMAXPROCS=W no daría paralelismo real.
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
#  Main dispatch
# ===========================================================================

# Al cargar el archivo con dot-source (pruebas) solo se definen las funciones.
if ($MyInvocation.InvocationName -eq '.') { return }

# Determine dimensions based on phase
$dimensions = if ($Fase -eq 'piloto') {
    @(256, 512, 1024)
} else {
    @(512, 1024, 2048)
}

foreach ($item in $selected) {
    switch ($item) {
        'c_secuencial' {
            $result = Invoke-CSecuencialCampaign `
                -Dimensions $dimensions `
                -CampaignSeed $Seed `
                -MeasuredReps $Repetitions
            if (-not $result) {
                [Console]::Error.WriteLine("ERROR: campana c_secuencial fallida.")
                exit 1
            }
        }
        'c_paralelo' {
            [Console]::Error.WriteLine("TODO: c_paralelo pendiente de I2 (Sebastian).")
            exit 2
        }
        'go_secuencial' {
            [Console]::Error.WriteLine("TODO: go_secuencial pendiente de I3 (Giuliano).")
            exit 2
        }
        'go_paralelo' {
            $result = Invoke-GoParaleloCampaign `
                -Dimensions $dimensions `
                -CampaignSeed $Seed `
                -MeasuredReps $Repetitions `
                -WorkerSeries $GoWorkers
            if (-not $result) {
                [Console]::Error.WriteLine("ERROR: campana go_paralelo fallida.")
                exit 1
            }
        }
    }
}

exit 0
