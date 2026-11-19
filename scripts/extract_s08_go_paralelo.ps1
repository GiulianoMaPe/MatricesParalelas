<#
.SYNOPSIS
    Extrae y verifica el lote go_paralelo de una campana integrada de medicion.

.DESCRIPTION
    Entrega del Sprint 8, Integrante 4. No ejecuta matrices ni reconstruye
    tiempos: audita una campana ya ejecutada, comprueba que los workers pedidos
    fueron los efectivos y analiza la estabilidad de las repeticiones. Escribe una
    vista derivada con solo las filas version=go_paralelo; el CSV fuente nunca se
    modifica.

    La vista conserva la cabecera canonica de 20 campos y las lineas originales,
    byte a byte, en el orden del plan. El manifiesto JSON registra hashes, grupos,
    estadisticas, anomalias y los controles aplicados. Las anomalias de estabilidad
    son avisos: ninguna observacion se elimina ni se reordena.

.PARAMETER CampaignDirectory
    Carpeta de la campana integrada con entorno.json, plan.csv, mediciones.csv,
    bitacora.txt, estado.json y logs/<orden>/.

.PARAMETER OutputPath
    Ruta de la vista derivada. Por defecto, resultados/raw/go_paralelo.csv en
    fase oficial. En fases no oficiales se exige una ruta explicita.

.PARAMETER ManifestPath
    Ruta del manifiesto JSON. Por defecto, junto a OutputPath.

.PARAMETER Phase
    oficial:     exige campana oficial COMPLETE, arbol limpio, N=512/1024/2048,
                 el commit candidato y stderr vacio.
    piloto:      extrae un piloto completo.
    diagnostico: permite lotes incompletos; pensado para evidencia.

.PARAMETER ExpectedCommit
    Commit completo que deben declarar entorno.json y cada fila. Por defecto, la
    candidata congelada de docs/campana.md.

.PARAMETER DispersionThreshold
    Umbral de IQR/mediana de total_s a partir del cual un grupo se marca con
    dispersion alta (aviso).

.PARAMETER ShortTimeThresholdSeconds
    Mediana de total_s por debajo de la cual un grupo se marca como tiempo corto,
    segun la politica de reloj del cierre de S6 (aviso informativo).

.PARAMETER AllowIncomplete
    Escribe la vista aunque existan anomalias criticas, marcandola INCOMPLETE.
    El proceso termina con error para no acreditar el lote.
#>
param(
    [Parameter(Mandatory = $true)][string]$CampaignDirectory,
    [string]$OutputPath = '',
    [string]$ManifestPath = '',
    [ValidateSet('oficial', 'piloto', 'diagnostico')][string]$Phase = 'oficial',
    [string]$ExpectedCommit = '97ccc981e9068d8ec0753cd8a4b7572a6bece34d',
    [double]$DispersionThreshold = 0.10,
    [double]$ShortTimeThresholdSeconds = 0.100,
    [switch]$AllowIncomplete
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\bench_windows.ps1"

$script:Anomalies = New-Object System.Collections.Generic.List[object]
$script:CriticalCount = 0
$culture = [Globalization.CultureInfo]::InvariantCulture

function Add-Anomaly {
    param([ValidateSet('critical', 'warning', 'info')][string]$Severity, [string]$Code, [string]$Detail)
    if ($Severity -eq 'critical') { $script:CriticalCount++ }
    $script:Anomalies.Add([pscustomobject][ordered]@{ severity = $Severity; code = $Code; detail = $Detail })
}

function Get-OptionalProperty {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function ConvertTo-RepoPath {
    param([string]$Path)
    $prefix = $script:ProjectRoot.TrimEnd('\') + '\'
    if ($Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $Path.Substring($prefix.Length).Replace('\', '/') }
    return $Path
}

# Get-Quartiles usa la misma definicion que summarize_results.ps1 (I7):
# con cinco observaciones ordenadas, Q1=x2, mediana=x3 y Q3=x4.
function Get-Quartiles {
    param([double[]]$Values)
    $sorted = @($Values | Sort-Object)
    $count = $sorted.Count
    $middle = [int][math]::Floor($count / 2)
    $median = if ($count % 2) { $sorted[$middle] } else { ($sorted[$middle - 1] + $sorted[$middle]) / 2 }
    $q1 = $sorted[[int][math]::Floor(($count - 1) / 4)]
    $q3 = $sorted[[int][math]::Ceiling(3 * ($count - 1) / 4)]
    return [pscustomobject]@{ Min = $sorted[0]; Q1 = $q1; Median = $median; Q3 = $q3; Max = $sorted[$count - 1] }
}

function Format-Number {
    param([double]$Value, [string]$Format = '0.000000000')
    return $Value.ToString($Format, $culture)
}

# --- Archivos de la campana ---------------------------------------------------
$CampaignDirectory = (Resolve-Path -LiteralPath $CampaignDirectory).Path
foreach ($name in @('entorno.json', 'plan.csv', 'mediciones.csv', 'bitacora.txt', 'estado.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $CampaignDirectory $name))) {
        throw "Falta $name en $CampaignDirectory."
    }
}
$environment = Get-Content -LiteralPath (Join-Path $CampaignDirectory 'entorno.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$state = Get-Content -LiteralPath (Join-Path $CampaignDirectory 'estado.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = @(Import-Csv -LiteralPath (Join-Path $CampaignDirectory 'plan.csv'))
$bitacora = Get-Content -LiteralPath (Join-Path $CampaignDirectory 'bitacora.txt') -Encoding UTF8
$dataPath = Join-Path $CampaignDirectory 'mediciones.csv'
$dataBytes = [IO.File]::ReadAllBytes($dataPath)
if ($dataBytes.Length -ge 3 -and $dataBytes[0] -eq 239 -and $dataBytes[1] -eq 187 -and $dataBytes[2] -eq 191) {
    Add-Anomaly critical 'csv_bom' 'mediciones.csv contiene BOM.'
}
$dataText = [Text.UTF8Encoding]::new($false).GetString($dataBytes)
$newline = if ($dataText.Contains("`r`n")) { "`r`n" } else { "`n" }
$dataLines = @($dataText -split "\r?\n")
if ($dataLines.Count -gt 0 -and $dataLines[$dataLines.Count - 1] -eq '') { $dataLines = @($dataLines[0..($dataLines.Count - 2)]) }

# --- Contexto ----------------------------------------------------------------
$campaignId = [string](Get-OptionalProperty $environment 'campaign_id')
$campaignPhase = [string](Get-OptionalProperty $environment 'phase')
$hardware = Get-OptionalProperty $environment 'hardware'
$experiment = Get-OptionalProperty $environment 'experiment'
$gitInfo = Get-OptionalProperty $environment 'git'
$hostname = [string](Get-OptionalProperty $environment 'hostname')
$physicalCores = [int](Get-OptionalProperty $hardware 'physical_cores')
$logicalProcessors = [int](Get-OptionalProperty $hardware 'logical_processors')
$environmentCommit = [string](Get-OptionalProperty $gitInfo 'commit_full')
$sizes = @(Get-OptionalProperty $experiment 'matrix_sizes' | ForEach-Object { [int]$_ })
$campaignSeed = [string](Get-OptionalProperty $experiment 'seed')
$gomaxprocsByConfiguration = Get-OptionalProperty $experiment 'gomaxprocs_by_configuration'
$stateStatus = [string](Get-OptionalProperty $state 'status')

$incompleteSeverity = if ($Phase -eq 'diagnostico') { 'warning' } else { 'critical' }
if (Get-OptionalProperty $environment 'dry_run') { Add-Anomaly critical 'dry_run' 'La campana es un dry-run.' }
if ($stateStatus -cne 'COMPLETE') { Add-Anomaly $incompleteSeverity 'estado' "estado.json declara '$stateStatus'." }
if ($ExpectedCommit -and $environmentCommit -cne $ExpectedCommit) {
    Add-Anomaly critical 'commit_entorno' "entorno.json declara $environmentCommit; se esperaba $ExpectedCommit."
}
if ($Phase -eq 'oficial') {
    if ($campaignPhase -cne 'oficial') { Add-Anomaly critical 'fase' "La campana es de fase '$campaignPhase'." }
    if (Get-OptionalProperty $gitInfo 'dirty') { Add-Anomaly critical 'arbol_sucio' 'La campana oficial exige arbol limpio.' }
    if (($sizes -join ',') -ne '512,1024,2048') { Add-Anomaly critical 'tamanos' "Tamanos $($sizes -join ',') distintos de 512,1024,2048." }
}
if ($physicalCores -lt 1) { Add-Anomaly critical 'hardware' 'entorno.json no registra nucleos fisicos.' }

# Serie de workers: la del plan, acotada por la capacidad fisica registrada
# (W=1/2/4 y W=8 solo con 8 o mas nucleos fisicos, segun el protocolo).
$planGo = @($plan | Where-Object { $_.configuration -like 'go_paralelo_W*' })
$workerSeries = @($planGo | ForEach-Object { [int]$_.configuration.Substring(13) } | Sort-Object -Unique)
$allowedWorkers = @(1, 2, 4, 8 | Where-Object { $_ -le $physicalCores })
if ($workerSeries.Count -eq 0) { Add-Anomaly critical 'sin_go_paralelo' 'El plan no contiene configuraciones go_paralelo.' }
if ($Phase -ne 'diagnostico' -and $workerSeries.Count -gt 0 -and ($workerSeries -join ',') -ne ($allowedWorkers -join ',')) {
    Add-Anomaly critical 'serie_incompleta' "El plan mide W=$($workerSeries -join ','); un lote completo con $physicalCores nucleos fisicos exige W=$($allowedWorkers -join ',')."
}
foreach ($w in $workerSeries) {
    if ($w -notin $allowedWorkers) {
        Add-Anomaly critical 'workers_fuera_de_capacidad' "W=$w no corresponde a $physicalCores nucleos fisicos (permitidos: $($allowedWorkers -join ','))."
    }
    $declared = Get-OptionalProperty $gomaxprocsByConfiguration "go_paralelo_W$w"
    if ("$declared" -ne "$w") {
        Add-Anomaly critical 'gomaxprocs_planificado' "entorno.json declara GOMAXPROCS=$declared para go_paralelo_W$w."
    }
}

# --- Cabecera y alineacion ----------------------------------------------------
if ($dataLines.Count -lt 1 -or -not (Test-CsvHeader -Header @(ConvertFrom-CsvLine $dataLines[0]))) {
    Add-Anomaly critical 'cabecera' 'mediciones.csv no tiene la cabecera canonica de 20 campos.'
}
if ($dataLines.Count - 1 -ne $plan.Count) {
    Add-Anomaly $incompleteSeverity 'filas_plan' "mediciones.csv tiene $($dataLines.Count - 1) filas y el plan $($plan.Count)."
}

# --- Corridas go_paralelo ----------------------------------------------------
$selected = New-Object System.Collections.Generic.List[object]
foreach ($planRow in $planGo) {
    $order = [int]$planRow.execution_order
    $w = [int]$planRow.configuration.Substring(13)
    $tag = "order=$order N=$($planRow.n) W=$w rep=$($planRow.repetition)"
    if ($order -ge $dataLines.Count) {
        Add-Anomaly $incompleteSeverity 'fila_ausente' "${tag}: no hay fila en mediciones.csv."
        continue
    }
    $line = $dataLines[$order]
    $fields = @(ConvertFrom-CsvLine $line)
    if ($fields.Count -ne $script:CsvHeader.Count) {
        Add-Anomaly critical 'fila_forma' "${tag}: la fila tiene $($fields.Count) campos."
        continue
    }
    $row = @{}
    for ($i = 0; $i -lt $fields.Count; $i++) { $row[$script:CsvHeader[$i]] = $fields[$i] }

    $expectedFields = [ordered]@{
        version = 'go_paralelo'; configuration = $planRow.configuration; n = $planRow.n; seed = $planRow.seed
        repetition = $planRow.repetition; is_warmup = $planRow.is_warmup; validation_status = 'OK'
        processes = '1'; threads = '1'; observed_threads = '1'; workers = "$w"; gomaxprocs = "$w"
    }
    $mismatch = @($expectedFields.Keys | Where-Object { $row[$_] -cne $expectedFields[$_] })
    $parallelism = @($mismatch | Where-Object { $_ -in @('workers', 'gomaxprocs', 'processes', 'threads', 'observed_threads') })
    if ($parallelism.Count) {
        Add-Anomaly critical 'workers_efectivos' "${tag}: $(($parallelism | ForEach-Object { "$_='$($row[$_])'" }) -join ', '); se esperaba workers=gomaxprocs=$w y un proceso/hilo."
    }
    $other = @($mismatch | Where-Object { $_ -notin $parallelism })
    if ($other.Count) {
        Add-Anomaly critical 'fila_plan' "${tag}: $(($other | ForEach-Object { "$_='$($row[$_])'" }) -join ', ') no coincide con el plan."
    }
    if ($ExpectedCommit -and $row['commit'] -cne $ExpectedCommit) { Add-Anomaly critical 'commit_fila' "${tag}: commit $($row['commit'])." }
    if ($hostname -and $row['hostname'] -cne $hostname) { Add-Anomaly critical 'hostname' "${tag}: hostname '$($row['hostname'])' distinto de '$hostname'." }

    $kernel = ConvertFrom-InvariantDouble $row['kernel_s']
    $total = ConvertFrom-InvariantDouble $row['total_s']
    $timesValid = $null -ne $kernel -and $null -ne $total -and -not [double]::IsNaN($kernel) -and -not [double]::IsNaN($total) -and
        -not [double]::IsInfinity($kernel) -and -not [double]::IsInfinity($total) -and $kernel -ge 0 -and $kernel -le $total
    if (-not $timesValid) { Add-Anomaly critical 'tiempos' "${tag}: kernel_s='$($row['kernel_s'])' total_s='$($row['total_s'])'." }

    # Registro del proceso: argumentos, GOMAXPROCS del entorno hijo y salida.
    $logDirectory = Join-Path $CampaignDirectory ('logs\{0:D4}' -f $order)
    $processPath = Join-Path $logDirectory 'proceso.json'
    $wall = $null
    if (-not (Test-Path -LiteralPath $processPath)) {
        Add-Anomaly critical 'proceso_ausente' "${tag}: falta $processPath."
    } else {
        $process = Get-Content -LiteralPath $processPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string](Get-OptionalProperty $process 'status') -cne 'OK' -or [int](Get-OptionalProperty $process 'exit_code') -ne 0) {
            Add-Anomaly critical 'proceso_fallido' "${tag}: estado '$(Get-OptionalProperty $process 'status')', codigo $(Get-OptionalProperty $process 'exit_code')."
        }
        $executable = [string](Get-OptionalProperty $process 'executable')
        if ($executable -notmatch '[\\/]go_paralelo[\\/]build[\\/]Release[\\/]go_paralelo\.exe$') {
            Add-Anomaly critical 'ejecutable' "${tag}: ejecutable '$executable'."
        }
        $arguments = @(Get-OptionalProperty $process 'arguments')
        $pairs = @{}
        for ($i = 0; $i + 1 -lt $arguments.Count; $i += 2) { $pairs[[string]$arguments[$i]] = [string]$arguments[$i + 1] }
        if ($pairs['--n'] -ne $planRow.n -or $pairs['--seed'] -ne $planRow.seed -or $pairs['--repetition'] -ne $planRow.repetition -or $pairs['--workers'] -ne "$w") {
            Add-Anomaly critical 'argumentos' "${tag}: argumentos '$($arguments -join ' ')'."
        }
        $childGomaxprocs = Get-OptionalProperty (Get-OptionalProperty $process 'child_environment') 'GOMAXPROCS'
        if ("$childGomaxprocs" -ne "$w" -or [string](Get-OptionalProperty $process 'gomaxprocs') -ne "$w") {
            Add-Anomaly critical 'gomaxprocs_entorno' "${tag}: GOMAXPROCS del entorno hijo '$childGomaxprocs'; se esperaba $w."
        }
        $inherited = Get-OptionalProperty $process 'inherited_runtime_environment'
        foreach ($name in @('GOGC', 'GOMEMLIMIT', 'GODEBUG')) {
            $value = Get-OptionalProperty $inherited $name
            if ($null -ne $value -and "$value" -ne '') { Add-Anomaly warning 'entorno_runtime' "${tag}: $name='$value' heredado." }
        }
        $wall = ConvertFrom-InvariantDouble ([string](Get-OptionalProperty $process 'wall_s'))
        if ($null -eq $wall -or $wall -le 0 -or ($timesValid -and $wall -lt $total)) {
            Add-Anomaly critical 'pared' "${tag}: wall_s='$(Get-OptionalProperty $process 'wall_s')' no cubre total_s."
        }
    }
    $stdoutPath = Join-Path $logDirectory 'stdout.txt'
    if (-not (Test-Path -LiteralPath $stdoutPath)) {
        Add-Anomaly critical 'stdout_ausente' "${tag}: falta stdout.txt."
    } else {
        $stdoutLines = @([IO.File]::ReadAllLines($stdoutPath) | Where-Object { $_ -ne '' })
        if ($stdoutLines.Count -ne 2 -or $stdoutLines[0] -cne $dataLines[0] -or $stdoutLines[1] -cne $line) {
            Add-Anomaly critical 'stdout_desvio' "${tag}: stdout no es la cabecera y la misma fila de mediciones.csv."
        }
    }
    $stderrPath = Join-Path $logDirectory 'stderr.txt'
    if (-not (Test-Path -LiteralPath $stderrPath)) {
        Add-Anomaly critical 'stderr_ausente' "${tag}: falta stderr.txt."
    } elseif ((Get-Item -LiteralPath $stderrPath).Length -gt 0) {
        $severity = if ($Phase -eq 'oficial') { 'critical' } else { 'warning' }
        Add-Anomaly $severity 'stderr' "${tag}: stderr no vacio."
    }
    $expectedLog = "order=$order N=$($planRow.n) $($planRow.configuration) rep=$($planRow.repetition) status=OK"
    if (-not ($bitacora | Where-Object { $_.TrimEnd() -ceq $expectedLog })) {
        Add-Anomaly critical 'bitacora' "${tag}: la bitacora no registra '$expectedLog'."
    }

    $selected.Add([pscustomobject]@{
        Order = $order; N = [int]$planRow.n; Workers = $w; Repetition = [int]$planRow.repetition
        IsWarmup = $planRow.is_warmup -eq 'true'; Line = $line; Kernel = $kernel; Total = $total; Wall = $wall
        Valid = $timesValid -and $row['validation_status'] -ceq 'OK'
    })
}

# --- Grupos y estabilidad -----------------------------------------------------
$groupSizes = if ($Phase -eq 'oficial') { @(512, 1024, 2048) } else { $sizes }
$groups = New-Object System.Collections.Generic.List[object]
$medianByGroup = @{}
foreach ($size in $groupSizes) {
    foreach ($w in $workerSeries) {
        $runs = @($selected | Where-Object { $_.N -eq $size -and $_.Workers -eq $w })
        $warmupRuns = @($runs | Where-Object { $_.IsWarmup -and $_.Repetition -eq 0 -and $_.Valid })
        $measured = @($runs | Where-Object { -not $_.IsWarmup -and $_.Valid })
        $measuredReps = @($measured | ForEach-Object { $_.Repetition } | Sort-Object)
        $complete = $warmupRuns.Count -eq 1 -and ($measuredReps -join ',') -eq '1,2,3,4,5'
        if (-not $complete) {
            Add-Anomaly $incompleteSeverity 'grupo_incompleto' "N=$size W=${w}: $($warmupRuns.Count) calentamiento(s) y repeticiones '$($measuredReps -join ',')'."
        }
        $group = [ordered]@{ n = $size; workers = $w; complete = $complete; warmups = $warmupRuns.Count; measured = $measured.Count; flags = @() }
        if ($measured.Count -gt 0) {
            $total = Get-Quartiles -Values @($measured | ForEach-Object { $_.Total })
            $kernel = Get-Quartiles -Values @($measured | ForEach-Object { $_.Kernel })
            $iqrRatio = if ($total.Median -gt 0) { ($total.Q3 - $total.Q1) / $total.Median } else { 0.0 }
            $spread = if ($total.Min -gt 0) { $total.Max / $total.Min } else { 0.0 }
            $flags = @()
            if ($iqrRatio -gt $DispersionThreshold) {
                $flags += 'dispersion_alta'
                Add-Anomaly warning 'dispersion_alta' ("N=$size W=${w}: IQR/mediana de total_s = {0:P1} (umbral {1:P0}); se conservan las cinco medidas." -f $iqrRatio, $DispersionThreshold)
            }
            if ($total.Median -lt $ShortTimeThresholdSeconds) {
                $flags += 'tiempo_corto'
                Add-Anomaly info 'tiempo_corto' ("N=$size W=${w}: mediana de total_s {0} s < {1} s; diagnostico de tiempos cortos (politica de reloj S6)." -f (Format-Number $total.Median), (Format-Number $ShortTimeThresholdSeconds '0.000'))
            }
            $ordered = @($measured | Sort-Object Repetition | ForEach-Object { $_.Total })
            $increasing = $true
            for ($i = 1; $i -lt $ordered.Count; $i++) { if ($ordered[$i] -le $ordered[$i - 1]) { $increasing = $false } }
            if ($ordered.Count -ge 5 -and $increasing) {
                $flags += 'tendencia_creciente'
                Add-Anomaly warning 'tendencia_creciente' "N=$size W=${w}: total_s crece en cada repeticion; revisar carga o temperatura en la bitacora."
            }
            $group['median_total_s'] = Format-Number $total.Median
            $group['q1_total_s'] = Format-Number $total.Q1
            $group['q3_total_s'] = Format-Number $total.Q3
            $group['min_total_s'] = Format-Number $total.Min
            $group['max_total_s'] = Format-Number $total.Max
            $group['iqr_over_median'] = Format-Number $iqrRatio '0.0000'
            $group['max_over_min'] = Format-Number $spread '0.0000'
            $group['median_kernel_s'] = Format-Number $kernel.Median
            $group['flags'] = $flags
            $medianByGroup["$size/$w"] = $total.Median
        }
        $groups.Add([pscustomobject]$group)
    }
}

# Workers efectivos en tiempo: speedup interno de go_paralelo respecto de W=1
# en la misma campana y N. Solo informa; la comparacion oficial es de I7.
$speedups = New-Object System.Collections.Generic.List[object]
foreach ($size in $groupSizes) {
    $base = $medianByGroup["$size/1"]
    foreach ($w in ($workerSeries | Where-Object { $_ -gt 1 })) {
        $median = $medianByGroup["$size/$w"]
        if ($null -eq $base -or $null -eq $median -or $median -le 0) { continue }
        $speedup = $base / $median
        $speedups.Add([pscustomobject][ordered]@{
            n = $size; workers = $w; speedup_vs_w1 = Format-Number $speedup '0.000'; efficiency = Format-Number ($speedup / $w) '0.000'
        })
        if ($size -ge 1024 -and $speedup -lt 1.0) {
            Add-Anomaly warning 'sin_aceleracion' ("N=$size W=${w}: speedup frente a W=1 = {0}; revisar workers efectivos." -f (Format-Number $speedup '0.000'))
        }
    }
}

# --- Salida -------------------------------------------------------------------
if (-not $OutputPath) {
    if ($Phase -ne 'oficial') { throw 'En fases no oficiales se exige -OutputPath explicito.' }
    $OutputPath = Join-Path $script:ProjectRoot 'resultados\raw\go_paralelo.csv'
}
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
if (-not $ManifestPath) { $ManifestPath = [IO.Path]::ChangeExtension($OutputPath, '.manifest.json') }
$ManifestPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ManifestPath)
$status = if ($script:CriticalCount -gt 0) { 'INCOMPLETE' } elseif ($Phase -eq 'oficial') { 'VERIFIED' } elseif ($Phase -eq 'piloto') { 'VERIFIED_PILOT' } else { 'DIAGNOSTIC' }
$writeView = $script:CriticalCount -eq 0 -or $AllowIncomplete
foreach ($path in @($OutputPath, $ManifestPath)) {
    $directory = Split-Path -Parent $path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Force -Path $directory | Out-Null }
}
if ($writeView) {
    $viewLines = @($dataLines[0]) + @($selected | Sort-Object Order | ForEach-Object { $_.Line })
    Write-Utf8NoBom -Path $OutputPath -Text (($viewLines -join $newline) + $newline)
}

$manifest = [ordered]@{
    tool = 'scripts/extract_s08_go_paralelo.ps1'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    status = $status
    requested_phase = $Phase
    campaign = [ordered]@{
        id = $campaignId; phase = $campaignPhase; directory = (ConvertTo-RepoPath $CampaignDirectory); state = $stateStatus
        commit = $environmentCommit; expected_commit = $ExpectedCommit; hostname = $hostname
        cpu_model = [string](Get-OptionalProperty $hardware 'cpu_model'); physical_cores = $physicalCores
        logical_processors = $logicalProcessors; seed = $campaignSeed; matrix_sizes = $sizes
    }
    sources = [ordered]@{
        'mediciones.csv' = Get-FileSha256 $dataPath
        'plan.csv' = Get-FileSha256 (Join-Path $CampaignDirectory 'plan.csv')
        'entorno.json' = Get-FileSha256 (Join-Path $CampaignDirectory 'entorno.json')
        'estado.json' = Get-FileSha256 (Join-Path $CampaignDirectory 'estado.json')
    }
    output = [ordered]@{
        path = (ConvertTo-RepoPath $OutputPath); written = $writeView
        sha256 = if ($writeView) { Get-FileSha256 $OutputPath } else { $null }
        rows = $selected.Count; warmups = @($selected | Where-Object { $_.IsWarmup }).Count
        measured = @($selected | Where-Object { -not $_.IsWarmup }).Count
    }
    controls = [ordered]@{
        worker_series = $workerSeries; allowed_workers = $allowedWorkers
        dispersion_threshold_iqr_over_median = $DispersionThreshold
        short_time_threshold_s = $ShortTimeThresholdSeconds
        quartiles = 'Q1=x2, mediana=x3, Q3=x4 con cinco medidas (summarize_results.ps1)'
    }
    groups = $groups
    speedup_vs_w1 = $speedups
    anomalies = $script:Anomalies
    critical = $script:CriticalCount
}
Write-Utf8NoBom -Path $ManifestPath -Text ($manifest | ConvertTo-Json -Depth 6)

# --- Resumen en consola -------------------------------------------------------
Write-Output "Estado: $status ($($selected.Count) filas go_paralelo, $script:CriticalCount anomalias criticas)"
foreach ($group in $groups) {
    $median = Get-OptionalProperty $group 'median_total_s'
    $ratio = Get-OptionalProperty $group 'iqr_over_median'
    Write-Output ("  N={0,-4} W={1,-2} completo={2,-5} mediana_total={3} s IQR/mediana={4} {5}" -f $group.n, $group.workers, $group.complete, $median, $ratio, (($group.flags) -join ','))
}
foreach ($item in $script:Anomalies | Where-Object { $_.severity -eq 'critical' }) { Write-Output "  CRITICA $($item.code): $($item.detail)" }
if ($writeView) { Write-Output "Vista: $OutputPath" }
Write-Output "Manifiesto: $ManifestPath"
if ($script:CriticalCount -gt 0) { exit 1 }
exit 0
