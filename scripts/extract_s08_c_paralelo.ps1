<#
.SYNOPSIS
    Extrae y verifica el lote c_paralelo de una campana integrada de medicion.

.DESCRIPTION
    Entrega del Sprint 8, Integrante 2. No ejecuta matrices ni reconstruye
    tiempos: audita una campana ya ejecutada, comprueba la participacion real de
    procesos e hilos y escribe una vista derivada con solo las filas
    version=c_paralelo. El CSV fuente nunca se modifica.

    La vista conserva la cabecera canonica de 20 campos y las lineas originales
    en el orden del plan. El manifiesto JSON registra hashes, grupos, anomalias y
    los controles aplicados.

.PARAMETER CampaignDirectory
    Carpeta de la campana integrada con entorno.json, plan.csv, mediciones.csv,
    bitacora.txt, estado.json y logs/<orden>/.

.PARAMETER OutputPath
    Ruta de la vista derivada. Por defecto, resultados/raw/c_paralelo.csv en
    fase oficial. En fases no oficiales se exige una ruta explicita.

.PARAMETER ManifestPath
    Ruta del manifiesto JSON. Por defecto, junto a OutputPath.

.PARAMETER Phase
    oficial: exige campana oficial, arbol limpio, N=512/1024/2048 y lote
              completo de configuraciones.
    piloto:  extrae un piloto completo; conserva el estado de fase.
    diagnostico: permite lotes incompletos y esta pensado para evidencia.

.PARAMETER ExpectedSizes
    Dimensiones que debe contener la campana. Si se omite, en fase oficial se
    exige 512,1024,2048 y en las demas se toman de entorno.json.

.PARAMETER ExpectedCommit
    Commit completo que debe coincidir con entorno.json y las filas.

.PARAMETER AllowIncomplete
    Escribe la vista aunque existan anomalias criticas, marcandola INCOMPLETE.
    El proceso termina con error para no acreditar el lote como oficial.
#>
param(
    [Parameter(Mandatory = $true)][string]$CampaignDirectory,
    [string]$OutputPath = '',
    [string]$ManifestPath = '',
    [ValidateSet('oficial', 'piloto', 'diagnostico')][string]$Phase = 'oficial',
    [string[]]$ExpectedSizes = @(),
    [string]$ExpectedCommit = '',
    [switch]$AllowIncomplete,
    [switch]$PassThru
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bench_windows.ps1"

$script:Anomalies = New-Object System.Collections.Generic.List[object]
$script:CriticalCount = 0
$script:ToolPath = $PSCommandPath

function Add-Anomaly {
    param(
        [ValidateSet('critical', 'warning', 'info')][string]$Severity,
        [Parameter(Mandatory = $true)][string]$Code,
        [Parameter(Mandatory = $true)][string]$Detail
    )
    foreach ($existing in $script:Anomalies) {
        if ($existing.code -ceq $Code -and $existing.detail -ceq $Detail) { return }
    }
    if ($Severity -eq 'critical') { $script:CriticalCount++ }
    $script:Anomalies.Add([pscustomobject][ordered]@{
        severity = $Severity
        code = $Code
        detail = $Detail
    })
}

function Stop-Extraction {
    param([Parameter(Mandatory = $true)][string]$Message)
    throw "I2 S8: $Message"
}

function Get-OptionalProperty {
    param($Object, [Parameter(Mandatory = $true)][string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-ArgValue {
    param([object[]]$Arguments, [Parameter(Mandatory = $true)][string]$Name)
    for ($index = 0; $index -lt $Arguments.Count - 1; $index++) {
        if ([string]$Arguments[$index] -ceq $Name) { return [string]$Arguments[$index + 1] }
    }
    return $null
}

function ConvertTo-PlanRowObject {
    param([Parameter(Mandatory = $true)][object]$Row)
    return [pscustomobject][ordered]@{
        execution_order = [string]$Row.execution_order
        n = [string]$Row.n
        configuration = [string]$Row.configuration
        seed = [string]$Row.seed
        repetition = [string]$Row.repetition
        is_warmup = [string]$Row.is_warmup
    }
}

function Get-RowObject {
    param([string[]]$Header, [string[]]$Fields)
    $ordered = [ordered]@{}
    for ($index = 0; $index -lt $Header.Count; $index++) {
        $ordered[$Header[$index]] = $Fields[$index]
    }
    return [pscustomobject]$ordered
}

function Get-Median {
    param([double[]]$Values)
    if ($Values.Count -eq 0) { return $null }
    $sorted = @($Values | Sort-Object)
    $middle = [int][Math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2 -eq 1) { return [double]$sorted[$middle] }
    return ([double]$sorted[$middle - 1] + [double]$sorted[$middle]) / 2.0
}

$CampaignDirectory = (Resolve-Path -LiteralPath $CampaignDirectory).Path
foreach ($name in @('entorno.json', 'plan.csv', 'mediciones.csv', 'bitacora.txt')) {
    $required = Join-Path $CampaignDirectory $name
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        Stop-Extraction "Falta $name en $CampaignDirectory."
    }
}

$environmentPath = Join-Path $CampaignDirectory 'entorno.json'
$planPath = Join-Path $CampaignDirectory 'plan.csv'
$dataPath = Join-Path $CampaignDirectory 'mediciones.csv'
$logPath = Join-Path $CampaignDirectory 'bitacora.txt'
$statePath = Join-Path $CampaignDirectory 'estado.json'

$bytes = [IO.File]::ReadAllBytes($dataPath)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    Stop-Extraction 'mediciones.csv contiene BOM; no se puede preservar la salida original.'
}
$environment = Get-Content -LiteralPath $environmentPath -Raw | ConvertFrom-Json
$campaignPhase = [string](Get-OptionalProperty $environment 'phase')
$hostname = [string](Get-OptionalProperty $environment 'hostname')
$commit = [string](Get-OptionalProperty (Get-OptionalProperty $environment 'git') 'commit_full')
if (-not $commit) { Stop-Extraction 'entorno.json no registra git.commit_full.' }
if ($ExpectedCommit) {
    if (-not $commit.Equals($ExpectedCommit, [StringComparison]::OrdinalIgnoreCase)) {
        Stop-Extraction "Commit de la campana $commit no coincide con $ExpectedCommit."
    }
}
if ($Phase -eq 'oficial') {
    if ($campaignPhase -cne 'oficial') {
        Stop-Extraction "La fase solicitada es oficial pero la campana declara '$campaignPhase'."
    }
    $dirty = Get-OptionalProperty (Get-OptionalProperty $environment 'git') 'dirty'
    if ($dirty -ne $false) { Stop-Extraction 'Una campana oficial exige arbol limpio (git.dirty=false).' }
}

$hardware = Get-OptionalProperty $environment 'hardware'
if ($null -eq $hardware) { Stop-Extraction 'entorno.json no contiene hardware.' }
$physicalCores = [int]$hardware.physical_cores
$availableBytes = [uint64]$hardware.ram_available_at_start_bytes
$experiment = Get-OptionalProperty $environment 'experiment'
if ($null -eq $experiment) { Stop-Extraction 'entorno.json no contiene experiment.' }
$sizes = @($experiment.matrix_sizes | ForEach-Object { [int]$_ } | Sort-Object -Unique)
$seed = [uint32]$experiment.seed
$expectedSizeValues = @()
foreach ($entry in $ExpectedSizes) {
    foreach ($part in ([string]$entry -split ',')) {
        $text = $part.Trim()
        if ($text -eq '') { continue }
        $value = 0
        if (-not [int]::TryParse($text, [ref]$value) -or $value -lt 1) {
            Stop-Extraction "Tamano esperado no valido: '$text'."
        }
        $expectedSizeValues += $value
    }
}
$expectedSizeValues = @($expectedSizeValues | Sort-Object -Unique)
if ($expectedSizeValues.Count -gt 0) {
    $expectedSizeText = ($expectedSizeValues -join ',')
    $actualSizeText = ($sizes -join ',')
    if ($expectedSizeText -cne $actualSizeText) {
        Stop-Extraction "Dimensiones $actualSizeText no coinciden con las exigidas $expectedSizeText."
    }
} elseif ($Phase -eq 'oficial') {
    if (($sizes -join ',') -cne '512,1024,2048') {
        Stop-Extraction "La campana oficial debe medir N=512,1024,2048; declara $($sizes -join ',')."
    }
}

$state = $null
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
} elseif ($Phase -ne 'diagnostico') {
    Stop-Extraction 'Falta estado.json; no se puede acreditar el cierre de la campana.'
}

$planLines = @(Split-CsvOutput ([IO.File]::ReadAllText($planPath)))
if ($planLines.Count -lt 1) { Stop-Extraction 'plan.csv esta vacio.' }
$planHeader = @(ConvertFrom-CsvLine $planLines[0])
if (($planHeader -join ',') -cne ($script:PlanHeader -join ',')) {
    Stop-Extraction 'Cabecera de plan.csv no canonica.'
}
$plan = New-Object System.Collections.Generic.List[object]
for ($index = 1; $index -lt $planLines.Count; $index++) {
    if ([string]::IsNullOrWhiteSpace($planLines[$index])) { continue }
    $fields = @(ConvertFrom-CsvLine $planLines[$index])
    if ($fields.Count -ne $script:PlanHeader.Count) {
        Stop-Extraction "plan.csv fila $index tiene $($fields.Count) campos."
    }
    $plan.Add((Get-RowObject -Header $script:PlanHeader -Fields $fields))
}
if ($plan.Count -eq 0) { Stop-Extraction 'plan.csv no contiene corridas.' }
for ($index = 0; $index -lt $plan.Count; $index++) {
    if ([int]$plan[$index].execution_order -ne $index + 1) {
        Stop-Extraction "plan.csv no tiene execution_order consecutivo en la fila $($index + 1)."
    }
}

$orderedConfigurations = @(Get-OptionalProperty $experiment 'ordered_configurations')
$requestedC = @()
$requestedGo = @()
if ($orderedConfigurations.Count -gt 0) {
    $requestedC = @($orderedConfigurations | Where-Object { $_ -like 'c_paralelo_*' } | ForEach-Object { $_.Substring(11) })
    $requestedGo = @($orderedConfigurations | Where-Object { $_ -like 'go_paralelo_W*' } | ForEach-Object { [int]$_.Substring(13) })
}
$expectedConfigs = @(Get-IntegratedConfigurations -PhysicalCores $physicalCores -RequestedC $requestedC -RequestedGo $requestedGo)
$expectedPlan = New-IntegratedPlan -Sizes $sizes -Configs $expectedConfigs -Seed $seed -AvailableBytes $availableBytes
if ($expectedPlan.Rows.Count -ne $plan.Count) {
    Stop-Extraction "plan.csv declara $($plan.Count) corridas y el protocolo/capacidad exige $($expectedPlan.Rows.Count)."
}
for ($index = 0; $index -lt $plan.Count; $index++) {
    foreach ($field in $script:PlanHeader) {
        if ([string]$plan[$index].$field -cne [string]$expectedPlan.Rows[$index].$field) {
            Stop-Extraction "plan.csv se desvia del orden alternado en la fila $($index + 1), campo $field."
        }
    }
}

$dataLines = @(Split-CsvOutput ([IO.File]::ReadAllText($dataPath)))
if ($dataLines.Count -lt 1) { Stop-Extraction 'mediciones.csv esta vacio.' }
$dataHeader = @(ConvertFrom-CsvLine $dataLines[0])
if (-not (Test-CsvHeader $dataHeader)) { Stop-Extraction 'Cabecera de mediciones.csv no canonica.' }
$dataRows = New-Object System.Collections.Generic.List[object]
for ($index = 1; $index -lt $dataLines.Count; $index++) {
    if ([string]::IsNullOrWhiteSpace($dataLines[$index])) { continue }
    $fields = @(ConvertFrom-CsvLine $dataLines[$index])
    if ($fields.Count -ne $script:CsvHeader.Count) {
        Stop-Extraction "mediciones.csv fila $index tiene $($fields.Count) campos."
    }
    $dataRows.Add([pscustomobject]@{ Raw = $dataLines[$index]; Row = (Get-RowObject -Header $script:CsvHeader -Fields $fields) })
}
if ($dataRows.Count -ne $plan.Count) {
    Stop-Extraction "mediciones.csv tiene $($dataRows.Count) filas y plan.csv $($plan.Count)."
}
if ($null -ne $state) {
    $stateStatus = [string](Get-OptionalProperty $state 'status')
    if ($Phase -ne 'diagnostico' -and $stateStatus -cne 'COMPLETE') {
        Stop-Extraction "estado.json declara '$stateStatus'; se exige COMPLETE."
    }
    $accepted = Get-OptionalProperty $state 'accepted'
    $planned = Get-OptionalProperty $state 'planned'
    if ($null -ne $planned -and [int]$planned -ne $plan.Count) {
        Stop-Extraction 'estado.json planned no coincide con plan.csv.'
    }
    if ($null -ne $accepted -and [int]$accepted -ne $dataRows.Count) {
        Stop-Extraction 'estado.json accepted no coincide con mediciones.csv.'
    }
}

$configByName = @{}
foreach ($config in $expectedConfigs) { $configByName[$config.Name] = $config }
$context = [pscustomobject]@{
    CampaignId = [string](Get-OptionalProperty $environment 'campaign_id')
    Commit = $commit
    Hostname = $hostname
    CpuModel = [string]$hardware.cpu_model
    RamBytes = [uint64]$hardware.ram_visible_bytes
    OsVersion = "$($hardware.os_edition) build $($hardware.os_build)"
}

$csvLines = New-Object System.Collections.Generic.List[string]
$groups = @{}
$checkedOrders = New-Object System.Collections.Generic.List[int]
$rankChecked = 0
$nonCRows = 0
$maxLoad = $null
$minFree = $null
$bitacoraText = [IO.File]::ReadAllText($logPath)

for ($index = 0; $index -lt $plan.Count; $index++) {
    $planRow = $plan[$index]
    $data = $dataRows[$index].Row
    foreach ($field in @('n', 'configuration', 'seed', 'repetition', 'is_warmup')) {
        if ([string]$data.$field -cne [string]$planRow.$field) {
            Stop-Extraction "La fila $($index + 1) se desvia del plan en $field."
        }
    }

    $configName = [string]$planRow.configuration
    if ($configName -notlike 'c_paralelo_*') {
        $nonCRows++
        continue
    }
    if (-not $configByName.ContainsKey($configName)) {
        Stop-Extraction "Configuracion $configName fuera del protocolo o de la capacidad de la PC."
    }
    $config = $configByName[$configName]
    $pair = Parse-BenchConfiguration $configName.Substring(11)
    if ($pair.Name -cne $config.Name.Substring(11)) {
        Stop-Extraction "Configuracion $configName incoherente."
    }
    $run = [pscustomobject]@{
        ExecutionOrder = [int]$planRow.execution_order
        N = [int]$planRow.n
        Configuration = $pair.Name
        Processes = [int]$config.Processes
        Threads = [int]$config.Threads
        Seed = [uint32]$planRow.seed
        Repetition = [int]$planRow.repetition
        IsWarmup = ([string]$planRow.is_warmup -eq 'true')
    }

    $check = Test-MeasurementRow -Row $data -Run $run -Context $context
    if (-not $check.Valid) {
        Add-Anomaly -Severity critical -Code 'fila_invalida' -Detail "order=$($run.ExecutionOrder): $($check.Reason)"
        continue
    }

    $logDirectory = Join-Path $CampaignDirectory ('logs/{0:D4}' -f $run.ExecutionOrder)
    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        Add-Anomaly -Severity critical -Code 'log_ausente' -Detail "order=$($run.ExecutionOrder): falta $logDirectory"
        continue
    }

    $processPath = Join-Path $logDirectory 'proceso.json'
    if (-not (Test-Path -LiteralPath $processPath -PathType Leaf)) {
        Add-Anomaly -Severity critical -Code 'proceso_ausente' -Detail "order=$($run.ExecutionOrder): falta proceso.json"
    } else {
        $process = Get-Content -LiteralPath $processPath -Raw | ConvertFrom-Json
        $arguments = @(Get-OptionalProperty $process 'arguments')
        $childEnvironment = Get-OptionalProperty $process 'child_environment'
        if ([string](Get-OptionalProperty $process 'status') -cne 'OK' -or [int](Get-OptionalProperty $process 'exit_code') -ne 0) {
            Add-Anomaly -Severity critical -Code 'proceso_fallido' -Detail "order=$($run.ExecutionOrder): estado/codigo de salida distinto de OK/0."
        }
        $executable = [string](Get-OptionalProperty $process 'executable')
        if ([IO.Path]::GetFileName($executable) -cne 'mpiexec.exe') {
            Add-Anomaly -Severity critical -Code 'lanzador_incorrecto' -Detail "order=$($run.ExecutionOrder): ejecutable '$executable'."
        }
        if ((Get-ArgValue $arguments '-n') -ne [string]$run.Processes -or
            (Get-ArgValue $arguments '--n') -ne [string]$run.N -or
            (Get-ArgValue $arguments '--seed') -ne [string]$run.Seed -or
            (Get-ArgValue $arguments '--repetition') -ne [string]$run.Repetition) {
            Add-Anomaly -Severity critical -Code 'argumentos_incorrectos' -Detail "order=$($run.ExecutionOrder): argumentos no coinciden con P/N/seed/repetition."
        }
        if ([string](Get-OptionalProperty $childEnvironment 'OMP_NUM_THREADS') -ne [string]$run.Threads) {
            Add-Anomaly -Severity critical -Code 'omp_hilos_incorrectos' -Detail "order=$($run.ExecutionOrder): OMP_NUM_THREADS no coincide con T=$($run.Threads)."
        }
        if ([string](Get-OptionalProperty $childEnvironment 'OMP_DYNAMIC') -cne 'FALSE') {
            Add-Anomaly -Severity critical -Code 'omp_dynamic' -Detail "order=$($run.ExecutionOrder): OMP_DYNAMIC distinto de FALSE."
        }
        $wall = ConvertFrom-InvariantDouble ([string](Get-OptionalProperty $process 'wall_s'))
        if ($null -eq $wall -or $wall -le 0) {
            Add-Anomaly -Severity critical -Code 'pared_invalida' -Detail "order=$($run.ExecutionOrder): wall_s no es positivo."
        }
    }

    try {
        Assert-IntegratedRanks -Run $run -Config $config -Directory $logDirectory
    } catch {
        Add-Anomaly -Severity critical -Code 'ranks' -Detail "order=$($run.ExecutionOrder): $($_.Exception.Message)"
        continue
    }
    $rankFiles = @(Get-ChildItem -LiteralPath $logDirectory -Filter 'rank-*.json')
    $maxRankKernel = 0.0
    $maxRankTotal = 0.0
    foreach ($rankFile in $rankFiles) {
        $rank = Get-Content -LiteralPath $rankFile.FullName -Raw | ConvertFrom-Json
        $rankKernelProperty = $rank.PSObject.Properties['kernel_s']
        $rankTotalProperty = $rank.PSObject.Properties['total_s']
        if ($null -ne $rankKernelProperty -and $null -ne $rankTotalProperty) {
            $rankKernel = ConvertFrom-InvariantDouble ([string]$rankKernelProperty.Value)
            $rankTotal = ConvertFrom-InvariantDouble ([string]$rankTotalProperty.Value)
            if ($null -eq $rankKernel -or $null -eq $rankTotal -or $rankKernel -lt 0 -or $rankTotal -lt $rankKernel) {
                Add-Anomaly -Severity critical -Code 'rank_tiempos' -Detail "order=$($run.ExecutionOrder): tiempos de rank invalidos en $($rankFile.Name)."
            } else {
                $maxRankKernel = [Math]::Max($maxRankKernel, $rankKernel)
                $maxRankTotal = [Math]::Max($maxRankTotal, $rankTotal)
            }
        } else {
            Add-Anomaly -Severity warning -Code 'rank_sin_tiempos' -Detail "order=$($run.ExecutionOrder): $($rankFile.Name) no conserva kernel_s/total_s."
        }
    }
    $rowKernel = ConvertFrom-InvariantDouble ([string]$data.kernel_s)
    $rowTotal = ConvertFrom-InvariantDouble ([string]$data.total_s)
    if ($null -ne $rowKernel -and $rowKernel -lt ($maxRankKernel - 0.000001)) {
        Add-Anomaly -Severity critical -Code 'kernel_menor_rank' -Detail "order=$($run.ExecutionOrder): kernel_s de la fila es menor que el mayor kernel de rank."
    }
    if ($null -ne $rowTotal -and $rowTotal -lt ($maxRankTotal - 0.001)) {
        Add-Anomaly -Severity critical -Code 'total_menor_rank' -Detail "order=$($run.ExecutionOrder): total_s de la fila es menor que el mayor total de rank."
    }
    $rankChecked += $rankFiles.Count

    $stdoutPath = Join-Path $logDirectory 'stdout.txt'
    if (-not (Test-Path -LiteralPath $stdoutPath -PathType Leaf)) {
        Add-Anomaly -Severity critical -Code 'stdout_ausente' -Detail "order=$($run.ExecutionOrder): falta stdout.txt."
    } else {
        $stdoutLines = @(Split-CsvOutput ([IO.File]::ReadAllText($stdoutPath)))
        if ($stdoutLines.Count -ne 2) {
            Add-Anomaly -Severity critical -Code 'stdout_forma' -Detail "order=$($run.ExecutionOrder): stdout no contiene cabecera y una sola fila."
        } else {
            $stdoutHeader = @(ConvertFrom-CsvLine $stdoutLines[0])
            $stdoutFields = @(ConvertFrom-CsvLine $stdoutLines[1])
            if (-not (Test-CsvHeader $stdoutHeader) -or $stdoutFields.Count -ne $script:CsvHeader.Count) {
                Add-Anomaly -Severity critical -Code 'stdout_esquema' -Detail "order=$($run.ExecutionOrder): esquema de stdout invalido."
            } else {
                $stdoutRow = Get-RowObject -Header $script:CsvHeader -Fields $stdoutFields
                foreach ($field in $script:CsvHeader) {
                    if ([string]$stdoutRow.$field -cne [string]$data.$field) {
                        Add-Anomaly -Severity critical -Code 'stdout_desvio' -Detail "order=$($run.ExecutionOrder): stdout difiere de mediciones.csv en $field."
                        break
                    }
                }
            }
        }
    }

    $stderrPath = Join-Path $logDirectory 'stderr.txt'
    if (Test-Path -LiteralPath $stderrPath -PathType Leaf) {
        $stderrText = [IO.File]::ReadAllText($stderrPath)
        if (-not [string]::IsNullOrWhiteSpace($stderrText)) {
            $severity = if ($Phase -eq 'oficial') { 'critical' } else { 'warning' }
            Add-Anomaly -Severity $severity -Code 'stderr' -Detail "order=$($run.ExecutionOrder): stderr no vacio; revisar log."
        }
    } else {
        Add-Anomaly -Severity critical -Code 'stderr_ausente' -Detail "order=$($run.ExecutionOrder): falta stderr.txt."
    }

    $statusPattern = '^order=' + $run.ExecutionOrder + '\s.*\bstatus=OK\b'
    if (-not [regex]::IsMatch($bitacoraText, $statusPattern, [Text.RegularExpressions.RegexOptions]::Multiline)) {
        Add-Anomaly -Severity critical -Code 'bitacora' -Detail "order=$($run.ExecutionOrder): la bitacora no registra status=OK."
    }
    $loadPattern = '^order=' + $run.ExecutionOrder + ' cpu_load_percent=([0-9,]+).*free_memory_kib=(\d+)'
    $loadMatch = [regex]::Match($bitacoraText, $loadPattern, [Text.RegularExpressions.RegexOptions]::Multiline)
    if ($loadMatch.Success) {
        foreach ($loadText in ($loadMatch.Groups[1].Value -split ',')) {
            $loadValue = ConvertFrom-InvariantDouble $loadText
            if ($null -ne $loadValue) { $maxLoad = if ($null -eq $maxLoad) { $loadValue } else { [Math]::Max($maxLoad, $loadValue) } }
        }
        $freeValue = [double]$loadMatch.Groups[2].Value
        $minFree = if ($null -eq $minFree) { $freeValue } else { [Math]::Min($minFree, $freeValue) }
    }

    $osLabelMismatch = -not ([string]$data.os_version).StartsWith([string]$context.OsVersion, [StringComparison]::OrdinalIgnoreCase)
    if ($osLabelMismatch) {
        Add-Anomaly -Severity warning -Code 'os_heredado' -Detail "La etiqueta de sistema de la fila es '$($data.os_version)' y entorno declara '$($context.OsVersion)'; se conserva el valor original."
    }

    $key = "$($run.N)|$configName"
    if (-not $groups.ContainsKey($key)) {
        $groups[$key] = [pscustomobject]@{
            n = $run.N
            configuration = $configName
            processes = $run.Processes
            threads = $run.Threads
            warmups = 0
            measurements = 0
            kernels = New-Object System.Collections.Generic.List[double]
            totals = New-Object System.Collections.Generic.List[double]
            repetitions = New-Object System.Collections.Generic.List[int]
        }
    }
    if ($run.Repetition -eq 0) { $groups[$key].warmups++ } else { $groups[$key].measurements++ }
    $groups[$key].repetitions.Add($run.Repetition)
    $groups[$key].kernels.Add([double]$rowKernel)
    $groups[$key].totals.Add([double]$rowTotal)
    $checkedOrders.Add($run.ExecutionOrder)
    $csvLines.Add($dataRows[$index].Raw)
}

$expectedCGroups = @($expectedPlan.Rows | Where-Object { $_.configuration -like 'c_paralelo_*' } |
    ForEach-Object { "$($_.n)|$($_.configuration)" } | Sort-Object -Unique)
$actualCGroups = @($groups.Keys | Sort-Object)
foreach ($key in $expectedCGroups) {
    if ($actualCGroups -notcontains $key) {
        Add-Anomaly -Severity critical -Code 'grupo_ausente' -Detail "Falta el grupo $key."
    }
}
foreach ($group in $groups.Values) {
    $repetitionText = (@($group.repetitions | Sort-Object) -join ',')
    if ($repetitionText -cne '0,1,2,3,4,5') {
        Add-Anomaly -Severity critical -Code 'repeticiones' -Detail "Grupo N=$($group.n) $($group.configuration): repeticiones '$repetitionText'."
    }
    if ($group.measurements -ne 5 -or $group.warmups -ne 1) {
        Add-Anomaly -Severity critical -Code 'grupo_incompleto' -Detail "Grupo N=$($group.n) $($group.configuration): $($group.warmups) calentamientos y $($group.measurements) medidas."
    }
}
$expectedConfigNames = @($expectedConfigs | Where-Object { $_.Version -eq 'c_paralelo' } | ForEach-Object { $_.Name } | Sort-Object)
$actualConfigNames = @($groups.Values | ForEach-Object { $_.configuration } | Sort-Object -Unique)
if (($expectedConfigNames -join ',') -cne ($actualConfigNames -join ',')) {
    Add-Anomaly -Severity critical -Code 'configuraciones' -Detail "Configuraciones extraidas '$($actualConfigNames -join ',')' frente a las previstas '$($expectedConfigNames -join ',')'."
}

$official = $Phase -eq 'oficial'
$complete = $script:CriticalCount -eq 0
$status = if ($complete) { if ($official) { 'VERIFIED' } elseif ($Phase -eq 'piloto') { 'VERIFIED_PILOT' } else { 'DIAGNOSTIC' } } else { 'INCOMPLETE' }

if (-not $OutputPath) {
    if ($official) {
        $OutputPath = Join-Path $script:ProjectRoot 'resultados/raw/c_paralelo.csv'
    } else {
        Stop-Extraction 'En fases piloto/diagnostico indique -OutputPath para no confundir la vista con el CSV oficial.'
    }
}
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
if (-not $ManifestPath) { $ManifestPath = Join-Path (Split-Path -Parent $OutputPath) 'c_paralelo_revision.json' }
$ManifestPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ManifestPath)
$outputDirectory = Split-Path -Parent $OutputPath
$manifestDirectory = Split-Path -Parent $ManifestPath
foreach ($directory in @($outputDirectory, $manifestDirectory)) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

if (-not $complete -and -not $AllowIncomplete) {
    Stop-Extraction "Se encontraron $($script:CriticalCount) anomalias criticas; no se escribe la vista. Use -AllowIncomplete solo para diagnostico."
}

$csvText = (($script:CsvHeader -join ',') + "`n")
if ($csvLines.Count -gt 0) { $csvText += (($csvLines -join "`n") + "`n") }
Write-Utf8NoBom -Path $OutputPath -Text $csvText

$groupSummaries = New-Object System.Collections.Generic.List[object]
foreach ($group in @($groups.Values | Sort-Object n, configuration)) {
    $measuredTotals = New-Object System.Collections.Generic.List[double]
    $measuredKernels = New-Object System.Collections.Generic.List[double]
    for ($rep = 1; $rep -le 5; $rep++) {
        $position = $group.repetitions.IndexOf($rep)
        if ($position -ge 0) {
            $measuredTotals.Add($group.totals[$position])
            $measuredKernels.Add($group.kernels[$position])
        }
    }
    $medianKernel = Get-Median $measuredKernels.ToArray()
    $medianTotal = Get-Median $measuredTotals.ToArray()
    $groupSummaries.Add([pscustomobject][ordered]@{
        n = $group.n
        configuration = $group.configuration
        processes = $group.processes
        threads = $group.threads
        warmups = $group.warmups
        measurements = $group.measurements
        median_kernel_s = if ($null -eq $medianKernel) { $null } else { Format-InvariantDouble $medianKernel '0.000000000' }
        median_total_s = if ($null -eq $medianTotal) { $null } else { Format-InvariantDouble $medianTotal '0.000000000' }
        min_total_s = if ($measuredTotals.Count -eq 0) { $null } else { Format-InvariantDouble ($measuredTotals | Measure-Object -Minimum).Minimum '0.000000000' }
        max_total_s = if ($measuredTotals.Count -eq 0) { $null } else { Format-InvariantDouble ($measuredTotals | Measure-Object -Maximum).Maximum '0.000000000' }
    })
}

$sourceHashes = @{}
foreach ($pair in @(
        @('entorno.json', $environmentPath),
        @('plan.csv', $planPath),
        @('mediciones.csv', $dataPath),
        @('bitacora.txt', $logPath),
        @('estado.json', $statePath))) {
    if (Test-Path -LiteralPath $pair[1] -PathType Leaf) {
        $sourceHashes[$pair[0]] = (Get-FileHash -LiteralPath $pair[1] -Algorithm SHA256).Hash
    }
}
$manifest = [ordered]@{
    status = $status
    phase = $Phase
    campaign_phase = $campaignPhase
    generated_at_utc = Get-UtcTimestamp
    tool = [ordered]@{
        name = 'scripts/extract_s08_c_paralelo.ps1'
        sha256 = (Get-FileHash -LiteralPath $script:ToolPath -Algorithm SHA256).Hash
        protocol_version = Get-OptionalProperty $environment 'protocol_version'
    }
    campaign = [ordered]@{
        campaign_id = Get-OptionalProperty $environment 'campaign_id'
        directory = $CampaignDirectory
        hostname = $hostname
        operator = Get-OptionalProperty $environment 'operator'
        started_at_utc = Get-OptionalProperty $environment 'started_at_utc'
        commit = $commit
        dirty = Get-OptionalProperty (Get-OptionalProperty $environment 'git') 'dirty'
        executable_sha256 = Get-OptionalProperty (Get-OptionalProperty $environment 'build') 'executable_sha256_by_version'
    }
    selection = [ordered]@{
        version = 'c_paralelo'
        sizes = $sizes
        seed = $seed
        configurations = $actualConfigNames
        warmups_per_group = 1
        measurements_per_group = 5
        rows = $csvLines.Count
        ignored_non_c_rows = $nonCRows
    }
    verification = [ordered]@{
        schema_20_fields = $true
        plan_order_and_rounds = $true
        plan_matches_protocol_and_capacity = $true
        source_and_state_complete = ($null -eq $state -or [string](Get-OptionalProperty $state 'status') -eq 'COMPLETE')
        csv_matches_stdout = $true
        processes_observed = $checkedOrders.Count
        ranks_observed = $rankChecked
        omp_threads_requested_and_observed = $true
        omp_dynamic_false = $true
        bitacora_status_ok = $true
        critical_anomalies = $script:CriticalCount
        anomalies_total = $script:Anomalies.Count
    }
    resources = [ordered]@{
        cpu_max_load_percent = $maxLoad
        free_memory_min_kib = $minFree
        temperature = 'unavailable: no se inventan lecturas'
    }
    groups = $groupSummaries.ToArray()
    anomalies = $script:Anomalies.ToArray()
    hashes = [ordered]@{
        source = $sourceHashes
        output = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
    }
}
Write-Utf8NoBom -Path $ManifestPath -Text ($manifest | ConvertTo-Json -Depth 12)

Write-Host "I2 S8: $status; $($csvLines.Count) filas c_paralelo, $($groupSummaries.Count) grupos; $($script:CriticalCount) anomalias criticas."
Write-Host "Vista: $OutputPath"
Write-Host "Manifiesto: $ManifestPath"
foreach ($anomaly in @($script:Anomalies | Where-Object { $_.severity -eq 'critical' })) {
    Write-Host "CRITICO [$($anomaly.code)] $($anomaly.detail)" -ForegroundColor Red
}
foreach ($anomaly in @($script:Anomalies | Where-Object { $_.severity -eq 'warning' } | Select-Object -First 5)) {
    Write-Host "AVISO [$($anomaly.code)] $($anomaly.detail)" -ForegroundColor Yellow
}

if (-not $complete) {
    Stop-Extraction "Lote INCOMPLETE: $($script:CriticalCount) anomalias criticas. La vista se conserva solo como diagnostico."
}
if ($PassThru) {
    return [pscustomobject]@{
        Status = $status
        OutputPath = $OutputPath
        ManifestPath = $ManifestPath
        Rows = $csvLines.Count
        Groups = $groupSummaries.Count
        CriticalAnomalies = $script:CriticalCount
    }
}
