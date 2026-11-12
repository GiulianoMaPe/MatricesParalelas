param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateRange(1,2147483647)][int]$N = 512,
    [uint32]$Seed = 42,
    [ValidateRange(1,1024)][int]$Workers = 2,
    [ValidateRange(1,1024)][int]$Processes = 2,
    [ValidateRange(1,1024)][int]$Threads = 2,
    [ValidateRange(1,5)][int]$Repetitions = 5,
    [string[]]$NList = @(),
    [string[]]$Configurations = @(),
    [ValidateRange(0,1)][int]$Warmups = 1,
    [ValidateRange(1,86400)][int]$TimeoutSeconds = 120,
    [ValidateSet('Debug','Release')][string]$Configuration = 'Release',
    [string]$OutputRoot = '',
    [string]$CampaignId = '',
    [switch]$DryRun,
    [switch]$FailFast,
    [switch]$ForceUnlock
)
. "$PSScriptRoot\common_windows.ps1"

# ============================================================================
# Sprint 7 - Integrante 2 (Sebastian)
# Caso c_paralelo del script de campana: combinaciones P x T, captura del CSV
# de 20 campos, validacion de procesos/hilos observados y bitacora por corrida.
#
# Este archivo se puede dot-sourcear para probar las funciones puras:
#   . .\scripts\bench_windows.ps1
# En ese caso no se ejecuta la campana (ver el bloque final).
# ============================================================================

$script:IsDotSourced = $MyInvocation.InvocationName -eq '.'
$script:InvocationLine = $MyInvocation.Line

$script:CsvHeader = @(
    'timestamp','version','commit','hostname','cpu_model','ram_gb',
    'os_version','configuration','n','seed','processes','threads',
    'observed_threads','workers','gomaxprocs','repetition','is_warmup',
    'kernel_s','total_s','validation_status'
)
$script:PlanHeader = @('execution_order','n','configuration','seed','repetition','is_warmup')
$script:ConfigurationRank = @{
    'P1_T1' = 1
    'P1_T2' = 2
    'P2_T1' = 3
    'P1_T4' = 4
    'P2_T2' = 5
    'P4_T1' = 6
    'P1_T8' = 7
    'P2_T4' = 8
    'P4_T2' = 9
    'P8_T1' = 10
}

# ---------------------------------------------------------------------------
# Utilidades de texto, CSV y numeros
# ---------------------------------------------------------------------------

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [switch]$Append
    )
    $encoding = [Text.UTF8Encoding]::new($false)
    if ($Append) {
        [IO.File]::AppendAllText($Path, $Text, $encoding)
    } else {
        [IO.File]::WriteAllText($Path, $Text, $encoding)
    }
}

function Get-UtcTimestamp {
    return [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
}

function Format-InvariantDouble {
    param(
        [Parameter(Mandatory = $true)][double]$Value,
        [string]$Format = '0.000'
    )
    return $Value.ToString($Format, [Globalization.CultureInfo]::InvariantCulture)
}

function ConvertFrom-InvariantDouble {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $value = 0.0
    $ok = [double]::TryParse(
        $Text,
        [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$value
    )
    if (-not $ok) { return $null }
    return $value
}

function ConvertTo-CsvField {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return '' }
    $text = [string]$Value
    if ($text -match '[",\r\n]') {
        return '"' + ($text -replace '"','""') + '"'
    }
    return $text
}

function ConvertTo-CsvLine {
    param([object[]]$Values)
    return (($Values | ForEach-Object { ConvertTo-CsvField $_ }) -join ',')
}

function ConvertFrom-CsvLine {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Line)
    $fields = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inQuotes = $false
    $index = 0
    while ($index -lt $Line.Length) {
        $character = $Line[$index]
        if ($inQuotes) {
            if ($character -eq '"') {
                if ($index + 1 -lt $Line.Length -and $Line[$index + 1] -eq '"') {
                    [void]$current.Append('"')
                    $index++
                } else {
                    $inQuotes = $false
                }
            } else {
                [void]$current.Append($character)
            }
        } else {
            if ($character -eq '"') {
                $inQuotes = $true
            } elseif ($character -eq ',') {
                $fields.Add($current.ToString())
                [void]$current.Clear()
            } else {
                [void]$current.Append($character)
            }
        }
        $index++
    }
    if ($inQuotes) { throw 'CSV con comilla sin cerrar.' }
    $fields.Add($current.ToString())
    return $fields.ToArray()
}

function Test-CsvHeader {
    param([string[]]$Header)
    if ($Header.Count -ne $script:CsvHeader.Count) { return $false }
    for ($index = 0; $index -lt $script:CsvHeader.Count; $index++) {
        if ($Header[$index] -cne $script:CsvHeader[$index]) { return $false }
    }
    return $true
}

function Split-CsvOutput {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return @() }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "\r?\n")) { $lines.Add($line) }
    while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }
    return $lines.ToArray()
}

function Parse-CsvMeasurement {
    param([AllowNull()][string]$Text)
    $lines = @(Split-CsvOutput $Text)
    if ($lines.Count -ne 2) {
        return [pscustomobject]@{
            Ok = $false
            Reason = "Se esperaban 2 lineas CSV (cabecera y fila); se encontraron $($lines.Count)."
            Row = $null
        }
    }
    try {
        $header = @(ConvertFrom-CsvLine $lines[0])
        $values = @(ConvertFrom-CsvLine $lines[1])
    } catch {
        return [pscustomobject]@{ Ok = $false; Reason = $_.Exception.Message; Row = $null }
    }
    if (-not (Test-CsvHeader $header)) {
        return [pscustomobject]@{
            Ok = $false
            Reason = 'La cabecera CSV no coincide con los 20 campos del protocolo.'
            Row = $null
        }
    }
    if ($values.Count -ne $script:CsvHeader.Count) {
        return [pscustomobject]@{
            Ok = $false
            Reason = "La fila CSV tiene $($values.Count) campos; se esperaban $($script:CsvHeader.Count)."
            Row = $null
        }
    }
    $row = [pscustomobject]@{}
    for ($index = 0; $index -lt $script:CsvHeader.Count; $index++) {
        Add-Member -InputObject $row -NotePropertyName $script:CsvHeader[$index] -NotePropertyValue $values[$index]
    }
    return [pscustomobject]@{ Ok = $true; Reason = ''; Row = $row }
}

function Get-RowValues {
    param(
        [Parameter(Mandatory = $true)][object]$Row,
        [string[]]$Header = $script:CsvHeader
    )
    $values = New-Object System.Collections.Generic.List[object]
    foreach ($name in $Header) {
        $property = $Row.PSObject.Properties[$name]
        if ($null -eq $property) { $values.Add('') } else { $values.Add($property.Value) }
    }
    return $values.ToArray()
}

# ---------------------------------------------------------------------------
# Configuraciones P x T y plan experimental
# ---------------------------------------------------------------------------

function Parse-BenchConfiguration {
    param([Parameter(Mandatory = $true)][string]$Text)
    $processes = 0
    $threads = 0
    if ($Text -match '^P(\d+)_T(\d+)$') {
        $processes = [int]$matches[1]
        $threads = [int]$matches[2]
    } elseif ($Text -match '^(\d+)x(\d+)$') {
        $processes = [int]$matches[1]
        $threads = [int]$matches[2]
    } else {
        throw "Configuracion no valida: '$Text'. Use P<procesos>_T<hilos>, por ejemplo P2_T2."
    }
    if ($processes -lt 1 -or $threads -lt 1) {
        throw "Configuracion no valida: '$Text'. P y T deben ser enteros positivos."
    }
    return [pscustomobject]@{
        Name = "P${processes}_T${threads}"
        Processes = $processes
        Threads = $threads
        Budget = $processes * $threads
    }
}

function Get-DefaultCParallelConfigurations {
    param([Parameter(Mandatory = $true)][int]$PhysicalCores)
    $names = New-Object System.Collections.Generic.List[string]
    $names.Add('P1_T1')
    if ($PhysicalCores -ge 2) {
        $names.Add('P1_T2')
        $names.Add('P2_T1')
    }
    if ($PhysicalCores -ge 4) {
        $names.Add('P1_T4')
        $names.Add('P2_T2')
        $names.Add('P4_T1')
    }
    if ($PhysicalCores -ge 8) {
        $names.Add('P1_T8')
        $names.Add('P2_T4')
        $names.Add('P4_T2')
        $names.Add('P8_T1')
    }
    return $names.ToArray()
}

function Get-CParallelConfigurations {
    param(
        [string[]]$Requested = @(),
        [Parameter(Mandatory = $true)][int]$PhysicalCores,
        [int]$Processes = 0,
        [int]$Threads = 0,
        [bool]$ExplicitPair = $false
    )
    $excluded = New-Object System.Collections.Generic.List[string]
    $candidates = New-Object System.Collections.Generic.List[object]
    $requestedTexts = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $Requested) {
        foreach ($part in ([string]$entry -split ',')) {
            $text = $part.Trim()
            if ($text -ne '') { $requestedTexts.Add($text) }
        }
    }

    if ($requestedTexts.Count -gt 0) {
        foreach ($text in $requestedTexts) {
            $config = Parse-BenchConfiguration $text
            if ($config.Budget -gt $PhysicalCores) {
                $excluded.Add("$($config.Name): P*T=$($config.Budget) excede $PhysicalCores nucleos fisicos") | Out-Null
                continue
            }
            $candidates.Add($config)
        }
    } elseif ($ExplicitPair) {
        if ($Processes -lt 1 -or $Threads -lt 1) {
            throw 'Indique -Processes y -Threads juntos, ambos mayores que cero.'
        }
        $config = [pscustomobject]@{
            Name = "P${Processes}_T${Threads}"
            Processes = $Processes
            Threads = $Threads
            Budget = $Processes * $Threads
        }
        if ($config.Budget -gt $PhysicalCores) {
            throw "P$Processes_T$Threads usa $($config.Budget) trabajadores y solo hay $PhysicalCores nucleos fisicos."
        }
        $candidates.Add($config)
    } else {
        foreach ($name in (Get-DefaultCParallelConfigurations -PhysicalCores $PhysicalCores)) {
            $candidates.Add((Parse-BenchConfiguration $name))
        }
    }

    $seen = @{}
    $unique = New-Object System.Collections.Generic.List[object]
    foreach ($config in $candidates) {
        if (-not $seen.ContainsKey($config.Name)) {
            $seen[$config.Name] = $true
            $unique.Add($config)
        }
    }
    if ($unique.Count -eq 0) {
        throw 'No quedo ninguna configuracion C valida tras aplicar los limites de nucleos fisicos.'
    }

    $sorted = @($unique | Sort-Object -Property `
        @{Expression = { if ($script:ConfigurationRank.ContainsKey($_.Name)) { $script:ConfigurationRank[$_.Name] } else { 100 + $_.Budget } }}, `
        @{Expression = { $_.Budget }}, `
        @{Expression = { $_.Processes }}, `
        @{Expression = { $_.Threads }})

    return [pscustomobject]@{
        Configurations = $sorted
        Excluded = $excluded.ToArray()
    }
}

function Get-CParallelCapacityExclusions {
    param(
        [int[]]$Sizes,
        [object[]]$Configurations,
        [Parameter(Mandatory = $true)][uint64]$AvailableRamBytes
    )
    $limit = [uint64][math]::Floor([double]$AvailableRamBytes * 0.5)
    $excluded = New-Object System.Collections.Generic.List[object]
    foreach ($size in $Sizes) {
        foreach ($config in $Configurations) {
            $bytes = [uint64]($config.Processes + 5) * 8 * [uint64]$size * [uint64]$size
            if ($bytes -gt $limit) {
                $excluded.Add([pscustomobject]@{
                    N = $size
                    Configuration = $config.Name
                    Reason = "pico estimado $bytes B supera el 50% de la RAM disponible ($limit B)"
                })
            }
        }
    }
    return $excluded.ToArray()
}

function New-CampaignPlan {
    param(
        [int[]]$Sizes,
        [object[]]$Configurations,
        [Parameter(Mandatory = $true)][uint32]$Seed,
        [ValidateRange(0,1)][int]$Warmups = 1,
        [ValidateRange(1,5)][int]$Repetitions = 5,
        [object[]]$Exclusions = @()
    )
    $excludedKeys = @{}
    foreach ($exclusion in $Exclusions) {
        $excludedKeys["$($exclusion.N)|$($exclusion.Configuration)"] = $true
    }

    $list = New-Object System.Collections.Generic.List[object]
    foreach ($size in ($Sizes | Sort-Object)) {
        foreach ($config in $Configurations) {
            if ($excludedKeys.ContainsKey("$size|$($config.Name)")) { continue }
            $list.Add([pscustomobject]@{
                N = [int]$size
                Configuration = $config.Name
                Processes = $config.Processes
                Threads = $config.Threads
            })
        }
    }
    if ($list.Count -eq 0) {
        throw 'El plan quedo vacio: todas las combinaciones fueron excluidas.'
    }

    $rows = New-Object System.Collections.Generic.List[object]
    $order = 0
    for ($warmup = 0; $warmup -lt $Warmups; $warmup++) {
        foreach ($item in $list) {
            $order++
            $rows.Add([pscustomobject]@{
                execution_order = $order
                n = $item.N
                configuration = $item.Configuration
                seed = $Seed
                repetition = 0
                is_warmup = 'true'
            })
        }
    }
    for ($round = 1; $round -le $Repetitions; $round++) {
        $roundItems = $list.ToArray()
        if ($round % 2 -eq 0) { [array]::Reverse($roundItems) }
        foreach ($item in $roundItems) {
            $order++
            $rows.Add([pscustomobject]@{
                execution_order = $order
                n = $item.N
                configuration = $item.Configuration
                seed = $Seed
                repetition = $round
                is_warmup = 'false'
            })
        }
    }

    return [pscustomobject]@{ List = $list.ToArray(); Rows = $rows.ToArray() }
}

function Write-CampaignPlan {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [object[]]$Rows
    )
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(($script:PlanHeader -join ','))
    foreach ($row in $Rows) {
        $lines.Add((ConvertTo-CsvLine @(
            [string]$row.execution_order,
            [string]$row.n,
            [string]$row.configuration,
            [string]$row.seed,
            [string]$row.repetition,
            [string]$row.is_warmup
        )))
    }
    Write-Utf8NoBom -Path $Path -Text (($lines -join "`n") + "`n")
}

# ---------------------------------------------------------------------------
# Validacion de la fila CSV y filas de fallo
# ---------------------------------------------------------------------------

function Test-MeasurementRow {
    param(
        [Parameter(Mandatory = $true)][object]$Row,
        [Parameter(Mandatory = $true)][object]$Run,
        [Parameter(Mandatory = $true)][object]$Context
    )
    $problems = New-Object System.Collections.Generic.List[string]

    if ($Row.version -cne 'c_paralelo') {
        $problems.Add("version='$($Row.version)' (se esperaba c_paralelo)")
    }
    $expectedConfiguration = "c_paralelo_P$($Run.Processes)_T$($Run.Threads)"
    if ($Row.configuration -cne $expectedConfiguration) {
        $problems.Add("configuration='$($Row.configuration)' (se esperaba $expectedConfiguration)")
    }

    $n = 0
    if (-not [int]::TryParse($Row.n, [ref]$n) -or $n -ne $Run.N) {
        $problems.Add("n='$($Row.n)' (se esperaba $($Run.N))")
    }
    $seed = [uint32]0
    if (-not [uint32]::TryParse($Row.seed, [ref]$seed) -or $seed -ne $Run.Seed) {
        $problems.Add("seed='$($Row.seed)' (se esperaba $($Run.Seed))")
    }
    $processes = 0
    if (-not [int]::TryParse($Row.processes, [ref]$processes) -or $processes -ne $Run.Processes) {
        $problems.Add("processes='$($Row.processes)' (se esperaba $($Run.Processes))")
    }
    $threads = 0
    if (-not [int]::TryParse($Row.threads, [ref]$threads) -or $threads -ne $Run.Threads) {
        $problems.Add("threads='$($Row.threads)' (se esperaba $($Run.Threads))")
    }
    $observed = 0
    if (-not [int]::TryParse($Row.observed_threads, [ref]$observed) -or $observed -ne $Run.Threads) {
        $problems.Add("observed_threads='$($Row.observed_threads)' (se esperaba $($Run.Threads))")
    }
    if ($Row.workers -cne '1') {
        $problems.Add("workers='$($Row.workers)' (se esperaba 1)")
    }
    if ($Row.gomaxprocs -cne '') {
        $problems.Add("gomaxprocs='$($Row.gomaxprocs)' (debe estar vacio en C)")
    }
    $repetition = -1
    if (-not [int]::TryParse($Row.repetition, [ref]$repetition) -or $repetition -ne $Run.Repetition) {
        $problems.Add("repetition='$($Row.repetition)' (se esperaba $($Run.Repetition))")
    }
    $expectedWarmup = if ($Run.Repetition -eq 0) { 'true' } else { 'false' }
    if ($Row.is_warmup -cne $expectedWarmup) {
        $problems.Add("is_warmup='$($Row.is_warmup)' (se esperaba $expectedWarmup)")
    }
    if ($Row.validation_status -cne 'OK') {
        $problems.Add("validation_status='$($Row.validation_status)' (se esperaba OK)")
    }
    if ($Row.timestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') {
        $problems.Add("timestamp='$($Row.timestamp)' no tiene formato ISO 8601 UTC")
    }
    if ($Row.commit -notmatch '^[0-9a-fA-F]{7,40}$') {
        $problems.Add("commit='$($Row.commit)' no es un hash hexadecimal de 7 a 40 caracteres")
    } elseif (-not $Context.Commit.StartsWith($Row.commit, [StringComparison]::OrdinalIgnoreCase)) {
        $problems.Add("commit='$($Row.commit)' no coincide con el commit de la campana")
    }
    if ($Row.hostname -cne $Context.Hostname) {
        $problems.Add("hostname='$($Row.hostname)' no coincide con la campana")
    }
    if ([string]::IsNullOrWhiteSpace($Row.cpu_model)) {
        $problems.Add('cpu_model vacio')
    }
    $ramGb = ConvertFrom-InvariantDouble $Row.ram_gb
    if ($null -eq $ramGb -or $ramGb -le 0) {
        $problems.Add("ram_gb='$($Row.ram_gb)' no es un decimal positivo")
    }
    if ([string]::IsNullOrWhiteSpace($Row.os_version)) {
        $problems.Add('os_version vacio')
    }

    $kernel = ConvertFrom-InvariantDouble $Row.kernel_s
    $total = ConvertFrom-InvariantDouble $Row.total_s
    if ($null -eq $kernel -or [double]::IsNaN($kernel) -or [double]::IsInfinity($kernel) -or $kernel -lt 0) {
        $problems.Add("kernel_s='$($Row.kernel_s)' no es finito y >= 0")
    }
    if ($null -eq $total -or [double]::IsNaN($total) -or [double]::IsInfinity($total) -or $total -lt 0) {
        $problems.Add("total_s='$($Row.total_s)' no es finito y >= 0")
    }
    if ($null -ne $kernel -and $null -ne $total -and $kernel -gt $total) {
        $problems.Add("kernel_s=$($Row.kernel_s) supera total_s=$($Row.total_s)")
    }

    if ($problems.Count -gt 0) {
        return [pscustomobject]@{ Valid = $false; Reason = ($problems -join '; ') }
    }
    return [pscustomobject]@{ Valid = $true; Reason = '' }
}

function New-FailureRow {
    param(
        [Parameter(Mandatory = $true)][object]$Run,
        [Parameter(Mandatory = $true)][object]$Context,
        [Parameter(Mandatory = $true)][string]$Status
    )
    $isWarmup = if ($Run.Repetition -eq 0) { 'true' } else { 'false' }
    $ramGb = Format-InvariantDouble -Value ([double]$Context.RamBytes / 1GB) -Format '0.000'
    return [pscustomobject][ordered]@{
        timestamp = Get-UtcTimestamp
        version = 'c_paralelo'
        commit = $Context.Commit
        hostname = $Context.Hostname
        cpu_model = $Context.CpuModel
        ram_gb = $ramGb
        os_version = $Context.OsVersion
        configuration = "c_paralelo_P$($Run.Processes)_T$($Run.Threads)"
        n = [string]$Run.N
        seed = [string]$Run.Seed
        processes = [string]$Run.Processes
        threads = [string]$Run.Threads
        observed_threads = ''
        workers = '1'
        gomaxprocs = ''
        repetition = [string]$Run.Repetition
        is_warmup = $isWarmup
        kernel_s = ''
        total_s = ''
        validation_status = $Status
    }
}

function Get-FailureStatus {
    param(
        [int]$ExitCode,
        [bool]$TimedOut,
        [AllowNull()][string]$StdErr
    )
    if ($TimedOut) { return 'TIMEOUT' }
    if ($ExitCode -eq 2) { return 'PENDING' }
    if ($ExitCode -eq 1) {
        if ($StdErr -match 'resultado incorrecto') { return 'MISMATCH' }
        if ($StdErr -match 'no se pudo reservar|memoria insuficiente|no se pudieron preparar los recursos') {
            return 'OOM'
        }
    }
    return 'ERROR'
}

function Write-MeasurementRow {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Row
    )
    $values = @(Get-RowValues -Row $Row)
    Write-Utf8NoBom -Path $Path -Text ((ConvertTo-CsvLine $values) + "`n") -Append
}

# ---------------------------------------------------------------------------
# Ejecucion de una corrida C paralela
# ---------------------------------------------------------------------------

function ConvertTo-ProcessArgumentString {
    param([string[]]$Arguments)
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($argument in $Arguments) {
        if ($null -eq $argument) {
            $parts.Add('""')
        } elseif ($argument -match '[\s"]') {
            $parts.Add('"' + ($argument -replace '"','\"') + '"')
        } else {
            $parts.Add($argument)
        }
    }
    return ($parts -join ' ')
}

function Invoke-CParallelRun {
    param(
        [Parameter(Mandatory = $true)][object]$Run,
        [Parameter(Mandatory = $true)][string]$Launcher,
        [Parameter(Mandatory = $true)][string]$ExePath,
        [Parameter(Mandatory = $true)][string]$LogDirectory,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )
    $stdoutPath = Join-Path $LogDirectory ('order-{0:D3}.stdout.txt' -f $Run.ExecutionOrder)
    $stderrPath = Join-Path $LogDirectory ('order-{0:D3}.stderr.txt' -f $Run.ExecutionOrder)
    $previousThreads = [Environment]::GetEnvironmentVariable('OMP_NUM_THREADS', 'Process')
    $previousDynamic = [Environment]::GetEnvironmentVariable('OMP_DYNAMIC', 'Process')
    $process = $null
    $stdout = ''
    $stderr = ''
    $exitCode = -1
    $timedOut = $false
    $startedAt = Get-UtcTimestamp
    $watch = [Diagnostics.Stopwatch]::StartNew()

    try {
        [Environment]::SetEnvironmentVariable('OMP_NUM_THREADS', [string]$Run.Threads, 'Process')
        [Environment]::SetEnvironmentVariable('OMP_DYNAMIC', 'FALSE', 'Process')

        $arguments = @(
            '-n', [string]$Run.Processes,
            $ExePath,
            '--n', [string]$Run.N,
            '--seed', [string]$Run.Seed,
            '--repetition', [string]$Run.Repetition
        )
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $Launcher
        $startInfo.Arguments = ConvertTo-ProcessArgumentString $arguments
        $startInfo.WorkingDirectory = $WorkingDirectory
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true
        $startInfo.StandardOutputEncoding = [Text.Encoding]::UTF8
        $startInfo.StandardErrorEncoding = [Text.Encoding]::UTF8

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        if (-not $process.Start()) { throw 'No se pudo iniciar mpiexec.' }

        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            try { & taskkill.exe /PID $process.Id /T /F 2>$null | Out-Null } catch { }
            if (-not $process.WaitForExit(5000)) {
                try { $process.Kill() } catch { }
            }
        }
        $process.WaitForExit()
        $watch.Stop()

        try { $stdout = $stdoutTask.Result } catch { $stdout = '' }
        try { $stderr = $stderrTask.Result } catch { $stderr = '' }
        $exitCode = $process.ExitCode
    } finally {
        $watch.Stop()
        [Environment]::SetEnvironmentVariable('OMP_NUM_THREADS', $previousThreads, 'Process')
        [Environment]::SetEnvironmentVariable('OMP_DYNAMIC', $previousDynamic, 'Process')
        if ($null -ne $process) { $process.Dispose() }
        Write-Utf8NoBom -Path $stdoutPath -Text $stdout
        Write-Utf8NoBom -Path $stderrPath -Text $stderr
    }

    return [pscustomobject]@{
        StartedAtUtc = $startedAt
        EndedAtUtc = Get-UtcTimestamp
        WallSeconds = $watch.Elapsed.TotalSeconds
        ExitCode = $exitCode
        TimedOut = $timedOut
        StdOut = $stdout
        StdErr = $stderr
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
    }
}

# ---------------------------------------------------------------------------
# Bloqueo de campana y carpetas
# ---------------------------------------------------------------------------

function Enter-CampaignLock {
    param(
        [Parameter(Mandatory = $true)][string]$LockPath,
        [Parameter(Mandatory = $true)][string]$CampaignId,
        [switch]$ForceUnlock
    )
    $directory = Split-Path -Parent $LockPath
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    $attempt = 0
    while ($true) {
        $attempt++
        try {
            $stream = [IO.File]::Open($LockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            $info = [ordered]@{
                pid = $PID
                hostname = [Environment]::MachineName
                campaign_id = $CampaignId
                started_at_utc = Get-UtcTimestamp
            } | ConvertTo-Json -Compress
            $bytes = [Text.Encoding]::UTF8.GetBytes($info)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            return $stream
        } catch [IO.IOException] {
            $existing = ''
            if (Test-Path -LiteralPath $LockPath) {
                try { $existing = Get-Content -LiteralPath $LockPath -Raw } catch { }
            }
            if ($ForceUnlock -and $attempt -eq 1) {
                Write-Warning "Retirando lock existente por -ForceUnlock: $existing"
                Remove-Item -LiteralPath $LockPath -Force -ErrorAction Stop
                continue
            }
            throw "Otra campana esta en curso o quedo un lock huerfano. Lock: $LockPath. Contenido: $existing. Use -ForceUnlock solo tras confirmar que no hay procesos de medicion activos."
        }
    }
}

function Exit-CampaignLock {
    param(
        [AllowNull()][object]$Stream,
        [Parameter(Mandatory = $true)][string]$LockPath,
        [Parameter(Mandatory = $true)][string]$CampaignId
    )
    if ($null -ne $Stream) { $Stream.Dispose() }
    if (Test-Path -LiteralPath $LockPath) {
        try {
            $info = Get-Content -LiteralPath $LockPath -Raw | ConvertFrom-Json
            if ($info.pid -eq $PID -and $info.campaign_id -eq $CampaignId) {
                Remove-Item -LiteralPath $LockPath -Force
            }
        } catch {
            Remove-Item -LiteralPath $LockPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-CampaignDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$CampaignId
    )
    if (-not (Test-Path -LiteralPath $Root)) {
        New-Item -ItemType Directory -Force -Path $Root | Out-Null
    }
    $candidate = Join-Path $Root $CampaignId
    if (Test-Path -LiteralPath $candidate) {
        $attempt = 2
        while (Test-Path -LiteralPath (Join-Path $Root ('{0}_intento{1:D2}' -f $CampaignId, $attempt))) {
            $attempt++
        }
        $candidate = Join-Path $Root ('{0}_intento{1:D2}' -f $CampaignId, $attempt)
    }
    New-Item -ItemType Directory -Force -Path $candidate | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $candidate 'logs') | Out-Null
    return $candidate
}

# ---------------------------------------------------------------------------
# Metadatos de la campana
# ---------------------------------------------------------------------------

function Get-GitInfo {
    param([Parameter(Mandatory = $true)][string]$Root)
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git) { throw 'git.exe no encontrado; no se puede registrar el commit de la campana.' }
    # Git puede escribir avisos (por ejemplo, LF/CRLF) en stderr. Bajo
    # $ErrorActionPreference='Stop' eso se convierte en un error terminante,
    # aunque la orden haya tenido exito. Se silencia solo durante estas llamadas.
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        $commit = (& $git.Source -C $Root rev-parse HEAD 2>$null)
        $commitExit = $LASTEXITCODE
        $statusLines = @(& $git.Source -C $Root status --porcelain 2>$null)
        $diffText = ((& $git.Source -C $Root diff HEAD 2>$null) -join "`n")
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($commitExit -ne 0 -or $commit -notmatch '^[0-9a-fA-F]{40}$') {
        throw 'No se pudo obtener el commit completo de Git. Una campana sin commit no es trazable.'
    }
    return [pscustomobject]@{
        Commit = $commit.ToLowerInvariant()
        Dirty = ($statusLines.Count -gt 0)
        Status = ($statusLines -join "`n")
        Diff = $diffText
        GitPath = $git.Source
    }
}

function Get-HardwareInfo {
    $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
    if ($processors.Count -eq 0) { throw 'No se pudo leer Win32_Processor.' }
    $physical = [int](($processors | Measure-Object -Property NumberOfCores -Sum).Sum)
    $logical = [int](($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
    if ($physical -lt 1) { throw 'No se pudieron determinar los nucleos fisicos; no se habilita la campana.' }
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $battery = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)
    $powerSource = 'AC'
    if ($battery.Count -gt 0) {
        $status = $battery[0].BatteryStatus
        if ($status -eq 1) { $powerSource = 'bateria' } else { $powerSource = 'AC' }
    }
    $powerPlan = 'desconocido'
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        $plan = ((& powercfg.exe /getactivescheme 2>$null) -join ' ')
        if ($plan -match '\(([^)]+)\)') { $powerPlan = $matches[1].Trim() }
    } catch {
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $cpuModel = (($processors | ForEach-Object { ([string]$_.Name).Trim() } | Select-Object -Unique) -join '; ')
    return [pscustomobject]@{
        CpuModel = $cpuModel
        PhysicalCores = $physical
        LogicalProcessors = $logical
        RamBytes = [uint64]$computer.TotalPhysicalMemory
        RamAvailableBytes = [uint64]$os.FreePhysicalMemory * 1KB
        OsEdition = [string]$os.Caption
        OsBuild = [string]$os.BuildNumber
        PowerSource = $powerSource
        PowerPlan = $powerPlan
    }
}

function Get-BuildInfo {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Configuration
    )
    $exe = Join-Path $ProjectRoot "c_paralelo\build\$Configuration\c_paralelo.exe"
    if (-not (Test-Path -LiteralPath $exe)) {
        throw "Falta el ejecutable $exe. Compile con build_windows.ps1 -Version c_paralelo -Configuration Release."
    }
    if ((Get-PEArchitecture $exe) -ne 'x64') { throw 'El ejecutable c_paralelo no es x64.' }
    $sha = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()

    $msvc = 'no disponible'
    $sdk = 'no disponible'
    try {
        $compiler = Initialize-MSVC
        $version = [string](Get-Item -LiteralPath $compiler).VersionInfo.FileVersion
        if ($version) { $msvc = $version }
        if ($env:WindowsSDKVersion) { $sdk = $env:WindowsSDKVersion.TrimEnd('\') }
    } catch { }

    $mpi = Find-MPI
    $mpiRuntime = 'no disponible'
    $mpiSdk = 'no disponible'
    if ($mpi.Launcher -and (Test-Path -LiteralPath $mpi.Launcher)) {
        $version = [string](Get-Item -LiteralPath $mpi.Launcher).VersionInfo.FileVersion
        if ($version) { $mpiRuntime = $version }
    }
    if ($mpi.Library) {
        $library = Join-Path $mpi.Library 'msmpi.lib'
        if (Test-Path -LiteralPath $library) {
            $version = [string](Get-Item -LiteralPath $library).VersionInfo.FileVersion
            if ($version) { $mpiSdk = $version }
        }
    }
    return [pscustomobject]@{
        ExePath = $exe
        Sha256 = $sha
        MsvcVersion = $msvc
        WindowsSdkVersion = $sdk
        MsmPiRuntimeVersion = $mpiRuntime
        MsmPiSdkVersion = $mpiSdk
        EffectiveOptions = '/O2 /MD /std:c11 /W4 /WX /fp:precise /openmp /D_WIN32_WINNT=0x0600 /MACHINE:X64; enlace msmpi.lib'
    }
}

function Get-CampaignContext {
    param(
        [Parameter(Mandatory = $true)][string]$CampaignId,
        [Parameter(Mandatory = $true)][object]$Hardware,
        [Parameter(Mandatory = $true)][object]$Build,
        [Parameter(Mandatory = $true)][object]$Git,
        [Parameter(Mandatory = $true)][string]$Configuration
    )
    $operator = $env:USERNAME
    if ([string]::IsNullOrWhiteSpace($operator)) { $operator = 'desconocido' }
    return [pscustomobject]@{
        CampaignId = $CampaignId
        StartedAtUtc = Get-UtcTimestamp
        Operator = $operator
        Hostname = [Environment]::MachineName
        Commit = $Git.Commit
        Dirty = $Git.Dirty
        GitStatus = $Git.Status
        GitDiff = $Git.Diff
        CpuModel = $Hardware.CpuModel
        PhysicalCores = $Hardware.PhysicalCores
        LogicalProcessors = $Hardware.LogicalProcessors
        RamBytes = $Hardware.RamBytes
        RamAvailableBytes = $Hardware.RamAvailableBytes
        OsEdition = $Hardware.OsEdition
        OsBuild = $Hardware.OsBuild
        OsVersion = "$($Hardware.OsEdition) build $($Hardware.OsBuild)"
        PowerSource = $Hardware.PowerSource
        PowerPlan = $Hardware.PowerPlan
        MsvcVersion = $Build.MsvcVersion
        WindowsSdkVersion = $Build.WindowsSdkVersion
        MsmPiRuntimeVersion = $Build.MsmPiRuntimeVersion
        MsmPiSdkVersion = $Build.MsmPiSdkVersion
        ExePath = $Build.ExePath
        ExeSha256 = $Build.Sha256
        EffectiveOptions = $Build.EffectiveOptions
        Configuration = $Configuration
    }
}

function New-CampaignEnvironment {
    param(
        [Parameter(Mandatory = $true)][object]$Context,
        [Parameter(Mandatory = $true)][object]$Plan,
        [object[]]$Exclusions = @(),
        [int[]]$Sizes,
        [Parameter(Mandatory = $true)][uint32]$Seed,
        [Parameter(Mandatory = $true)][int]$Warmups,
        [Parameter(Mandatory = $true)][int]$Repetitions,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
        [Parameter(Mandatory = $true)][string]$CampaignPath
    )
    $diffFile = $null
    if ($Context.Dirty) {
        Write-Utf8NoBom -Path (Join-Path $CampaignPath 'git_status.txt') -Text ($Context.GitStatus + "`n")
        if (-not [string]::IsNullOrWhiteSpace($Context.GitDiff)) {
            Write-Utf8NoBom -Path (Join-Path $CampaignPath 'diff_codigo.patch') -Text ($Context.GitDiff + "`n")
            $diffFile = 'diff_codigo.patch'
        } else {
            $diffFile = 'git_status.txt'
        }
    }

    $orderedConfigurations = @($Plan.List | ForEach-Object { $_.Configuration } | Select-Object -Unique)
    $budgets = @($Plan.List | ForEach-Object { $_.Processes * $_.Threads } | Sort-Object -Unique)
    $ompMap = [ordered]@{}
    foreach ($item in $Plan.List) { $ompMap[$item.Configuration] = $item.Threads }
    $peak = [uint64]0
    foreach ($item in $Plan.List) {
        $bytes = [uint64]($item.Processes + 5) * 8 * [uint64]$item.N * [uint64]$item.N
        if ($bytes -gt $peak) { $peak = $bytes }
    }
    $exclusionText = New-Object System.Collections.Generic.List[string]
    foreach ($exclusion in $Exclusions) {
        $exclusionText.Add("N=$($exclusion.N) $($exclusion.Configuration): $($exclusion.Reason)")
    }

    $environment = [ordered]@{
        protocol_version = '1.3'
        campaign_id = $Context.CampaignId
        phase = 'piloto'
        started_at_utc = $Context.StartedAtUtc
        operator = $Context.Operator
        hostname = $Context.Hostname
        git = [ordered]@{
            commit_full = $Context.Commit
            dirty = $Context.Dirty
            diff_file = $diffFile
        }
        hardware = [ordered]@{
            cpu_model = $Context.CpuModel
            physical_cores = $Context.PhysicalCores
            logical_processors = $Context.LogicalProcessors
            ram_visible_bytes = $Context.RamBytes
            ram_available_at_start_bytes = $Context.RamAvailableBytes
            os_edition = $Context.OsEdition
            os_build = $Context.OsBuild
            power_source = $Context.PowerSource
            power_plan = $Context.PowerPlan
        }
        build = [ordered]@{
            configuration = $Context.Configuration
            target = 'x64'
            msvc_version = $Context.MsvcVersion
            windows_sdk_version = $Context.WindowsSdkVersion
            msmpi_runtime_version = $Context.MsmPiRuntimeVersion
            msmpi_sdk_version = $Context.MsmPiSdkVersion
            go_version = $null
            goos = 'windows'
            goarch = 'amd64'
            effective_options_by_version = [ordered]@{
                c_secuencial = $null
                c_paralelo = $Context.EffectiveOptions
                go_secuencial = $null
                go_paralelo = $null
            }
            executable_sha256_by_version = [ordered]@{
                c_secuencial = $null
                c_paralelo = $Context.ExeSha256
                go_secuencial = $null
                go_paralelo = $null
            }
        }
        experiment = [ordered]@{
            matrix_sizes = @($Sizes | Sort-Object)
            seed = $Seed
            enabled_budgets = $budgets
            ordered_configurations = $orderedConfigurations
            warmups_per_combination = $Warmups
            measured_repetitions = $Repetitions
            order_policy = 'N ascending, protocol table order; odd rounds forward, even rounds reverse'
            maximum_matrix_fraction_of_available_ram = 0.5
            estimated_matrix_peak_bytes = $peak
            timeout_per_run_seconds = $TimeoutSeconds
            campaign_machine_time_budget_seconds = [int64]$Plan.Rows.Count * $TimeoutSeconds
            omp_dynamic = 'FALSE'
            omp_num_threads_by_configuration = $ompMap
            gomaxprocs_by_configuration = $null
            excluded_combinations_and_reasons = $exclusionText.ToArray()
            plan_file = 'plan.csv'
            observations_file = 'mediciones.csv'
            log_file = 'bitacora.txt'
        }
    }
    $json = $environment | ConvertTo-Json -Depth 10
    Write-Utf8NoBom -Path (Join-Path $CampaignPath 'entorno.json') -Text ($json + "`n")
}

function Write-BitacoraHeader {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Context,
        [Parameter(Mandatory = $true)][object]$Plan,
        [object[]]$Exclusions = @(),
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
        [Parameter(Mandatory = $true)][string]$CommandLine
    )
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("campaign_id=$($Context.CampaignId)")
    $lines.Add("scope=c_paralelo (piloto parcial de validacion; no sustituye al piloto completo de I6)")
    $lines.Add("protocol_version=1.3")
    $lines.Add("started_at_utc=$($Context.StartedAtUtc)")
    $lines.Add("operator=$($Context.Operator)")
    $lines.Add("hostname=$($Context.Hostname)")
    $lines.Add("commit=$($Context.Commit)")
    $lines.Add("dirty=$($Context.Dirty)")
    $lines.Add("configuration=$($Context.Configuration)")
    $lines.Add("command=$CommandLine")
    $lines.Add("physical_cores=$($Context.PhysicalCores) logical_processors=$($Context.LogicalProcessors)")
    $lines.Add("ram_visible_bytes=$($Context.RamBytes) ram_available_at_start_bytes=$($Context.RamAvailableBytes)")
    $lines.Add("timeout_per_run_seconds=$TimeoutSeconds")
    $lines.Add("planned_runs=$($Plan.Rows.Count)")
    $lines.Add("ordered_configurations=$((@($Plan.List | ForEach-Object { $_.Configuration } | Select-Object -Unique)) -join ',')")
    if ($Exclusions.Count -gt 0) {
        foreach ($exclusion in $Exclusions) {
            $lines.Add("excluded=N$($exclusion.N)/$($exclusion.Configuration) reason=$($exclusion.Reason)")
        }
    } else {
        $lines.Add('excluded=none')
    }
    $lines.Add('--- runs ---')
    Write-Utf8NoBom -Path $Path -Text (($lines -join "`n") + "`n")
}

function Write-BitacoraRun {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Run,
        [Parameter(Mandatory = $true)][object]$Result,
        [Parameter(Mandatory = $true)][string]$Status,
        [AllowEmptyString()][string]$Reason = ''
    )
    $wall = $Result.WallSeconds.ToString('0.000000', [Globalization.CultureInfo]::InvariantCulture)
    $line = "order=$($Run.ExecutionOrder) planned=N$($Run.N)/$($Run.Configuration)/rep=$($Run.Repetition) " +
        "start=$($Result.StartedAtUtc) end=$($Result.EndedAtUtc) wall_s=$wall " +
        "exit=$($Result.ExitCode) timeout=$($Result.TimedOut) status=$Status " +
        "processes=$($Run.Processes) threads=$($Run.Threads) " +
        "stdout=$($Result.StdoutPath) stderr=$($Result.StderrPath)"
    if (-not [string]::IsNullOrWhiteSpace($Reason)) { $line += " reason=$Reason" }
    Write-Utf8NoBom -Path $Path -Text ($line + "`n") -Append
}

# ---------------------------------------------------------------------------
# Orquestacion
# ---------------------------------------------------------------------------

function Invoke-BenchMain {
    param(
        [Parameter(Mandatory = $true)][string]$Version,
        [int]$N = 512,
        [Parameter(Mandatory = $true)][uint32]$Seed,
        [int]$Workers = 2,
        [int]$Processes = 2,
        [int]$Threads = 2,
        [int]$Repetitions = 5,
        [string[]]$NList = @(),
        [string[]]$Configurations = @(),
        [int]$Warmups = 1,
        [int]$TimeoutSeconds = 120,
        [string]$Configuration = 'Release',
        [string]$OutputRoot = '',
        [string]$CampaignId = '',
        [switch]$DryRun,
        [switch]$FailFast,
        [switch]$ForceUnlock,
        [bool]$ExplicitN = $false,
        [bool]$ExplicitPair = $false
    )
    Assert-Windows

    if ($Version -eq 'all') {
        throw 'Esta rama de S7 implementa solo el caso c_paralelo. Use -Version c_paralelo; la integracion de los cuatro casos corresponde a I5.'
    }
    if ($Version -ne 'c_paralelo') {
        throw "El caso $Version todavia no esta implementado en esta rama de S7 (I2)."
    }
    if ($Configuration -ne 'Release') {
        throw 'La campana exige -Configuration Release segun docs/protocolo_medicion.md.'
    }
    if ($Configurations.Count -gt 0 -and $ExplicitPair) {
        throw 'Use -Configurations o -Processes/-Threads, no ambos.'
    }
    if ($Repetitions -ne 5) {
        Write-Warning "Se usaran $Repetitions repeticiones; el protocolo del piloto fija 5."
    }

    $statusPath = Join-Path $script:ProjectRoot "$Version\status.json"
    if (-not (Test-Path -LiteralPath $statusPath)) { throw "Falta $statusPath." }
    $status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
    if ($status.algorithm -ne 'implemented' -or $status.validation -ne 'passed') {
        throw "$Version : algoritmo o validacion pendientes. No se ejecuta ni se generan mediciones."
    }

    $sizeValues = New-Object System.Collections.Generic.List[int]
    foreach ($entry in $NList) {
        foreach ($part in ([string]$entry -split ',')) {
            $text = $part.Trim()
            if ($text -eq '') { continue }
            $value = 0
            if (-not [int]::TryParse($text, [ref]$value) -or $value -lt 1) {
                throw "N no valido: '$text'."
            }
            $sizeValues.Add($value)
        }
    }
    if ($sizeValues.Count -gt 0) {
        $sizes = @($sizeValues | Sort-Object -Unique)
    } elseif ($ExplicitN) {
        $sizes = @($N)
    } else {
        $sizes = @(256, 512, 1024)
    }

    $hardware = Get-HardwareInfo
    $resolved = Get-CParallelConfigurations `
        -Requested $Configurations `
        -PhysicalCores $hardware.PhysicalCores `
        -Processes $Processes `
        -Threads $Threads `
        -ExplicitPair $ExplicitPair
    $capacityExclusions = @(Get-CParallelCapacityExclusions `
        -Sizes $sizes `
        -Configurations $resolved.Configurations `
        -AvailableRamBytes $hardware.RamAvailableBytes)
    $exclusions = @($resolved.Excluded) + @($capacityExclusions)
    $plan = New-CampaignPlan `
        -Sizes $sizes `
        -Configurations $resolved.Configurations `
        -Seed $Seed `
        -Warmups $Warmups `
        -Repetitions $Repetitions `
        -Exclusions $exclusions

    $git = Get-GitInfo -Root $script:ProjectRoot
    if ([string]::IsNullOrWhiteSpace($CampaignId)) {
        $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ', [Globalization.CultureInfo]::InvariantCulture)
        $hostPart = [Environment]::MachineName -replace '[^A-Za-z0-9._-]', '-'
        $CampaignId = "${stamp}_${hostPart}_$($git.Commit.Substring(0, 7))_i02"
    }
    if ($CampaignId -notmatch '^[A-Za-z0-9._-]+$') {
        throw "CampaignId no valido: '$CampaignId'. Use letras, digitos, punto, guion o guion bajo."
    }
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
        $OutputRoot = Join-Path $script:ProjectRoot 'resultados\piloto'
    } elseif (-not [IO.Path]::IsPathRooted($OutputRoot)) {
        $OutputRoot = Join-Path $script:ProjectRoot $OutputRoot
    }

    if ($DryRun) {
        Write-Host "DryRun c_paralelo: campaign_id=$CampaignId"
        Write-Host "Commit=$($git.Commit) dirty=$($git.Dirty)"
        Write-Host "N=$($sizes -join ',') configuraciones=$((@($resolved.Configurations | ForEach-Object { $_.Name })) -join ',')"
        Write-Host "Corridas planificadas=$($plan.Rows.Count) (warmups=$Warmups, repeticiones=$Repetitions)"
        if ($exclusions.Count -gt 0) {
            Write-Host 'Exclusiones:'
            foreach ($exclusion in $exclusions) {
                Write-Host "  N=$($exclusion.N) $($exclusion.Configuration): $($exclusion.Reason)"
            }
        }
        $plan.Rows | Format-Table -AutoSize | Out-String | Write-Host
        Write-Host "Destino previsto: $(Join-Path $OutputRoot $CampaignId)"
        return 0
    }

    $build = Get-BuildInfo -ProjectRoot $script:ProjectRoot -Configuration $Configuration
    $launcher = Get-MPILauncher
    $context = Get-CampaignContext `
        -CampaignId $CampaignId `
        -Hardware $hardware `
        -Build $build `
        -Git $git `
        -Configuration $Configuration

    $lockPath = Join-Path $script:ProjectRoot '.cache\bench.lock'
    $lock = $null
    $campaignPath = $null
    $executed = 0
    $failures = 0
    try {
        $lock = Enter-CampaignLock -LockPath $lockPath -CampaignId $CampaignId -ForceUnlock:$ForceUnlock
        $campaignPath = New-CampaignDirectory -Root $OutputRoot -CampaignId $CampaignId
        Write-CampaignPlan -Path (Join-Path $campaignPath 'plan.csv') -Rows $plan.Rows
        New-CampaignEnvironment `
            -Context $context `
            -Plan $plan `
            -Exclusions $exclusions `
            -Sizes $sizes `
            -Seed $Seed `
            -Warmups $Warmups `
            -Repetitions $Repetitions `
            -TimeoutSeconds $TimeoutSeconds `
            -CampaignPath $campaignPath
        Write-Utf8NoBom -Path (Join-Path $campaignPath 'mediciones.csv') -Text (($script:CsvHeader -join ',') + "`n")
        $commandLine = $script:InvocationLine
        if ([string]::IsNullOrWhiteSpace($commandLine)) {
            $commandLine = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath"
        }
        Write-BitacoraHeader `
            -Path (Join-Path $campaignPath 'bitacora.txt') `
            -Context $context `
            -Plan $plan `
            -Exclusions $exclusions `
            -TimeoutSeconds $TimeoutSeconds `
            -CommandLine $commandLine

        $configByName = @{}
        foreach ($config in $resolved.Configurations) { $configByName[$config.Name] = $config }

        foreach ($planRow in $plan.Rows) {
            $config = $configByName[$planRow.configuration]
            $run = [pscustomobject]@{
                ExecutionOrder = [int]$planRow.execution_order
                N = [int]$planRow.n
                Configuration = [string]$planRow.configuration
                Processes = [int]$config.Processes
                Threads = [int]$config.Threads
                Seed = [uint32]$planRow.seed
                Repetition = [int]$planRow.repetition
                IsWarmup = [bool]($planRow.repetition -eq 0)
            }
            $result = Invoke-CParallelRun `
                -Run $run `
                -Launcher $launcher `
                -ExePath $build.ExePath `
                -LogDirectory (Join-Path $campaignPath 'logs') `
                -TimeoutSeconds $TimeoutSeconds `
                -WorkingDirectory $script:ProjectRoot
            $executed++

            $parsed = Parse-CsvMeasurement $result.StdOut
            $status = 'OK'
            $reason = ''
            $row = $null
            if ($result.TimedOut) {
                $status = 'TIMEOUT'
                $reason = "timeout de $TimeoutSeconds s"
            } elseif (-not $parsed.Ok) {
                $status = Get-FailureStatus -ExitCode $result.ExitCode -TimedOut $false -StdErr $result.StdErr
                $reason = $parsed.Reason
            } elseif ($result.ExitCode -ne 0) {
                $status = Get-FailureStatus -ExitCode $result.ExitCode -TimedOut $false -StdErr $result.StdErr
                $reason = "codigo de salida $($result.ExitCode)"
            } else {
                $check = Test-MeasurementRow -Row $parsed.Row -Run $run -Context $context
                if (-not $check.Valid) {
                    $status = 'ERROR'
                    $reason = $check.Reason
                } else {
                    $row = $parsed.Row
                }
            }

            if ($status -eq 'OK') {
                Write-MeasurementRow -Path (Join-Path $campaignPath 'mediciones.csv') -Row $row
            } else {
                $failures++
                $failureRow = New-FailureRow -Run $run -Context $context -Status $status
                Write-MeasurementRow -Path (Join-Path $campaignPath 'mediciones.csv') -Row $failureRow
            }

            Write-BitacoraRun `
                -Path (Join-Path $campaignPath 'bitacora.txt') `
                -Run $run `
                -Result $result `
                -Status $status `
                -Reason $reason

            if ($FailFast -and $status -ne 'OK') { break }
        }
    } finally {
        if ($null -ne $lock) {
            Exit-CampaignLock -Stream $lock -LockPath $lockPath -CampaignId $CampaignId
        }
    }

    $ok = $executed - $failures
    Write-Host "Campana ${CampaignId}: $ok OK, $failures fallos, $executed/$($plan.Rows.Count) corridas ejecutadas."
    if ($null -ne $campaignPath) { Write-Host "Datos en $campaignPath" }
    if ($failures -gt 0 -or $executed -lt $plan.Rows.Count) { return 1 }
    return 0
}

# ---------------------------------------------------------------------------
# Punto de entrada (no se ejecuta al dot-sourcear)
# ---------------------------------------------------------------------------

if (-not $script:IsDotSourced) {
    try {
        $explicitN = $PSBoundParameters.ContainsKey('N')
        $explicitProcesses = $PSBoundParameters.ContainsKey('Processes')
        $explicitThreads = $PSBoundParameters.ContainsKey('Threads')
        if ($explicitProcesses -xor $explicitThreads) {
            throw 'Indique -Processes y -Threads juntos, o use -Configurations.'
        }
        $code = Invoke-BenchMain `
            -Version $Version `
            -N $N `
            -Seed $Seed `
            -Workers $Workers `
            -Processes $Processes `
            -Threads $Threads `
            -Repetitions $Repetitions `
            -NList $NList `
            -Configurations $Configurations `
            -Warmups $Warmups `
            -TimeoutSeconds $TimeoutSeconds `
            -Configuration $Configuration `
            -OutputRoot $OutputRoot `
            -CampaignId $CampaignId `
            -DryRun:$DryRun `
            -FailFast:$FailFast `
            -ForceUnlock:$ForceUnlock `
            -ExplicitN $explicitN `
            -ExplicitPair ($explicitProcesses -or $explicitThreads)
        exit $code
    } catch {
        [Console]::Error.WriteLine($_.Exception.Message)
        exit 1
    }
}
