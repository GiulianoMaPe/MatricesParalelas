# Pruebas de Sprint 8 - Integrante 2
# Extractor/verificador del lote c_paralelo. No requieren MSVC ni MS-MPI:
# construyen una campana integrada sintetica con el mismo escritor del proyecto.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\scripts\bench_windows.ps1')
$script:Extractor = Join-Path $PSScriptRoot '..\scripts\extract_s08_c_paralelo.ps1'

$script:TestFailures = 0
$script:TestCount = 0

function Invoke-Test {
    param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][scriptblock]$Block)
    $script:TestCount++
    try {
        & $Block
        Write-Host "PASS $Name"
    } catch {
        $script:TestFailures++
        Write-Host "FAIL $Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) { throw "$Message. Esperado: '$Expected'. Obtenido: '$Actual'." }
}

function Assert-Throws {
    param([scriptblock]$Block, [string]$Message)
    $thrown = $false
    try { & $Block | Out-Null } catch { $thrown = $true }
    if (-not $thrown) { throw "$Message. No se lanzo ninguna excepcion." }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('s08-i02-extract-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
$script:Commit = 'a' * 40
$script:Hostname = 'PC-TEST'
$script:Size = 512
$script:Seed = 42
$script:Configs = @(Get-IntegratedConfigurations -PhysicalCores 6)
$script:Plan = New-IntegratedPlan -Sizes @($script:Size) -Configs $script:Configs -Seed $script:Seed -AvailableBytes 8GB
$script:ConfigByName = @{}
foreach ($config in $script:Configs) { $script:ConfigByName[$config.Name] = $config }

function Write-JsonFile {
    param([string]$Path, $Object)
    Write-Utf8NoBom -Path $Path -Text ($Object | ConvertTo-Json -Depth 12)
}

function New-SyntheticCampaign {
    param([Parameter(Mandatory = $true)][string]$Directory)
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    $environment = [ordered]@{
        protocol_version = '1.3'
        campaign_id = 's08_i02_synthetic'
        phase = 'piloto'
        dry_run = $false
        started_at_utc = '2026-11-18T09:00:00Z'
        operator = 'TEST'
        hostname = $script:Hostname
        git = [ordered]@{ commit_full = $script:Commit; dirty = $false; diff_file = $null }
        hardware = [ordered]@{
            cpu_model = 'TEST CPU'
            physical_cores = 6
            logical_processors = 12
            ram_visible_bytes = [uint64]17179869184
            ram_available_at_start_bytes = [uint64]8589934592
            os_edition = 'Microsoft Windows 11 Pro'
            os_build = '26300'
            power_source = 'AC'
            power_plan = 'Equilibrado'
            temperature_monitoring = 'unavailable'
        }
        build = [ordered]@{ configuration = 'Release'; target = 'x64'; executable_sha256_by_version = [ordered]@{ c_paralelo = ('C' * 64) } }
        experiment = [ordered]@{
            matrix_sizes = @($script:Size)
            seed = $script:Seed
            enabled_budgets = @(1, 2, 4)
            ordered_configurations = @($script:Configs.Name)
            warmups_per_combination = 1
            measured_repetitions = 5
        }
    }
    Write-JsonFile (Join-Path $Directory 'entorno.json') $environment
    Write-CampaignPlan -Path (Join-Path $Directory 'plan.csv') -Rows $script:Plan.Rows
    Write-Utf8NoBom -Path (Join-Path $Directory 'mediciones.csv') -Text (($script:CsvHeader -join ',') + "`n")
    Write-JsonFile (Join-Path $Directory 'estado.json') ([ordered]@{ status = 'COMPLETE'; planned = $script:Plan.Rows.Count; accepted = $script:Plan.Rows.Count; wall_s = 120.5; ended_at_utc = '2026-11-18T09:02:00Z' })
    $bitacora = New-Object System.Collections.Generic.List[string]
    $start = [DateTime]::UtcNow

    for ($index = 0; $index -lt $script:Plan.Rows.Count; $index++) {
        $planRow = $script:Plan.Rows[$index]
        $order = [int]$planRow.execution_order
        $config = $script:ConfigByName[[string]$planRow.configuration]
        $isC = $config.Version -eq 'c_paralelo'
        $kernel = 0.050 + ($index * 0.001)
        $total = $kernel + 0.005
        $isWarmup = ([string]$planRow.is_warmup -eq 'true')
        $row = [ordered]@{}
        foreach ($field in $script:CsvHeader) { $row[$field] = '' }
        $row.timestamp = $start.AddSeconds($index).ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        $row.version = $config.Version
        $row.commit = $script:Commit
        $row.hostname = $script:Hostname
        $row.cpu_model = 'TEST CPU'
        $row.ram_gb = '16.000'
        $row.os_version = 'Microsoft Windows 11 Pro build 26300'
        $row.configuration = $config.Name
        $row.n = [string]$planRow.n
        $row.seed = [string]$planRow.seed
        $row.processes = [string]$config.Processes
        $row.threads = [string]$config.Threads
        $row.observed_threads = if ($isC) { [string]$config.Threads } else { '1' }
        $row.workers = [string]$config.Workers
        $row.gomaxprocs = if ($config.Version -like 'go_*') { [string]$config.Workers } else { '' }
        $row.repetition = [string]$planRow.repetition
        $row.is_warmup = [string]$planRow.is_warmup
        $row.kernel_s = Format-InvariantDouble $kernel '0.000000000'
        $row.total_s = Format-InvariantDouble $total '0.000000000'
        $row.validation_status = 'OK'
        Write-MeasurementRow -Path (Join-Path $Directory 'mediciones.csv') -Row ([pscustomobject]$row)

        $logDirectory = Join-Path $Directory ('logs/{0:D4}' -f $order)
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        $bitacora.Add("order=$order cpu_load_percent=10 free_memory_kib=8000000 temperature=unavailable")
        $bitacora.Add("order=$order N=$($planRow.n) $($config.Name) rep=$($planRow.repetition) status=OK")

        if (-not $isC) {
            Write-Utf8NoBom -Path (Join-Path $logDirectory 'stdout.txt') -Text ''
            Write-Utf8NoBom -Path (Join-Path $logDirectory 'stderr.txt') -Text ''
            continue
        }

        $arguments = @('-n', [string]$config.Processes, 'C:\fake\c_paralelo.exe', '--n', [string]$planRow.n,
            '--seed', [string]$planRow.seed, '--repetition', [string]$planRow.repetition)
        $process = [ordered]@{
            executable = 'C:\fake\mpiexec.exe'
            arguments = $arguments
            start_utc = '2026-11-18T09:00:00Z'
            wall_s = $total + 0.1
            pid = 1000 + $order
            exit_code = 0
            status = 'OK'
            detail = ''
            child_environment = [ordered]@{ OMP_NUM_THREADS = [string]$config.Threads; OMP_DYNAMIC = 'FALSE'; GOMAXPROCS = $null; S06_DIAGNOSTICS = $logDirectory }
        }
        Write-JsonFile (Join-Path $logDirectory 'proceso.json') $process
        $line = ConvertTo-CsvLine @(Get-RowValues -Row ([pscustomobject]$row))
        Write-Utf8NoBom -Path (Join-Path $logDirectory 'stdout.txt') -Text (($script:CsvHeader -join ',') + "`n" + $line + "`n")
        Write-Utf8NoBom -Path (Join-Path $logDirectory 'stderr.txt') -Text ''

        $processes = [int]$config.Processes
        $q = [int][Math]::Floor([int]$planRow.n / [double]$processes)
        $r = [int]$planRow.n % $processes
        for ($rank = 0; $rank -lt $processes; $rank++) {
            $rows = $q
            if ($rank -lt $r) { $rows++ }
            $first = $rank * $q + [Math]::Min($rank, $r)
            $rankData = [ordered]@{
                rank = $rank
                pid = 2000 + $order * 10 + $rank
                rows = $rows
                first_row = $first
                requested_threads = [int]$config.Threads
                timed_observed_threads = if ($rows -gt 0) { [int]$config.Threads } else { 0 }
                kernel_s = $kernel - 0.001
                total_s = $total - 0.002
            }
            Write-JsonFile (Join-Path $logDirectory "rank-$rank.json") $rankData
        }
    }
    Write-Utf8NoBom -Path (Join-Path $Directory 'bitacora.txt') -Text (($bitacora -join "`n") + "`n")
}

function Copy-Campaign {
    param([Parameter(Mandatory = $true)][string]$Name)
    $destination = Join-Path $temp $Name
    Copy-Item -LiteralPath $script:BaseCampaign -Destination $destination -Recurse
    return $destination
}

function Invoke-Extractor {
    param([string]$Campaign, [string]$Output, [switch]$AllowIncomplete)
    & $script:Extractor -CampaignDirectory $Campaign -Phase piloto -OutputPath $Output -ManifestPath "$Output.manifest.json" -ExpectedSizes ([string]$script:Size) -PassThru -AllowIncomplete:$AllowIncomplete
}

$script:BaseCampaign = Join-Path $temp 'base'
New-SyntheticCampaign -Directory $script:BaseCampaign
$expectedC = @($script:Plan.Rows | Where-Object { $_.configuration -like 'c_paralelo_*' })
$expectedNonC = $script:Plan.Rows.Count - $expectedC.Count

Invoke-Test 'Extrae solo c_paralelo y conserva las lineas originales' {
    $campaign = Copy-Campaign 'valid'
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    $result = Invoke-Extractor -Campaign $campaign -Output $output
    Assert-Equal 'VERIFIED_PILOT' $result.Status 'Estado del lote'
    Assert-Equal $expectedC.Count $result.Rows 'Filas extraidas'
    $lines = @(Get-Content -LiteralPath $output)
    Assert-Equal ($expectedC.Count + 1) $lines.Count 'Cabecera y filas'
    Assert-Equal ($script:CsvHeader -join ',') $lines[0] 'Cabecera canonica'
    foreach ($line in $lines[1..($lines.Count - 1)]) {
        Assert-True ($line -match ',c_paralelo,') 'Solo filas c_paralelo'
    }
    $manifest = Get-Content -LiteralPath "$output.manifest.json" -Raw | ConvertFrom-Json
    Assert-Equal $expectedC.Count $manifest.selection.rows 'Filas en manifiesto'
    Assert-Equal $expectedNonC $manifest.selection.ignored_non_c_rows 'Filas no C ignoradas'
    Assert-Equal 6 $manifest.groups.Count 'Grupos N/configuracion'
    Assert-Equal 0 $manifest.verification.critical_anomalies 'Sin anomalias criticas'
}

Invoke-Test 'La vista conserva exactamente las lineas del CSV fuente' {
    $campaign = Copy-Campaign 'bytes'
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    $null = Invoke-Extractor -Campaign $campaign -Output $output
    $source = @(Get-Content -LiteralPath (Join-Path $campaign 'mediciones.csv') | Select-Object -Skip 1 | Where-Object { $_ -match ',c_paralelo,' })
    $produced = @(Get-Content -LiteralPath $output | Select-Object -Skip 1)
    Assert-Equal $source.Count $produced.Count 'Conteo de lineas'
    for ($index = 0; $index -lt $source.Count; $index++) {
        Assert-Equal $source[$index] $produced[$index] "Linea $($index + 1)"
    }
}

Invoke-Test 'Rechaza observed_threads distinto de T' {
    $campaign = Copy-Campaign 'threads'
    $dataPath = Join-Path $campaign 'mediciones.csv'
    $text = [IO.File]::ReadAllText($dataPath)
    $regex = [regex]::new('(,c_paralelo_P2_T2,512,42,2,2,)2(,1,,)')
    $text = $regex.Replace($text, '${1}1${2}', 1)
    Write-Utf8NoBom -Path $dataPath -Text $text
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output } 'observed_threads incorrecto debe rechazarse'
    Assert-True (-not (Test-Path -LiteralPath $output)) 'No debe escribir vista oficial invalida'
}

Invoke-Test 'Rechaza reparto de ranks incompleto' {
    $campaign = Copy-Campaign 'ranks'
    $target = @($script:Plan.Rows | Where-Object { $_.configuration -eq 'c_paralelo_P2_T1' })[0]
    $rankPath = Join-Path $campaign ('logs/{0:D4}/rank-1.json' -f [int]$target.execution_order)
    Remove-Item -LiteralPath $rankPath
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output } 'Falta rank debe rechazarse'
}

Invoke-Test 'Rechaza una repeticion fallida con tiempos vacios' {
    $campaign = Copy-Campaign 'failed'
    $dataPath = Join-Path $campaign 'mediciones.csv'
    $text = [IO.File]::ReadAllText($dataPath)
    $regex = [regex]::new('(?m)^([^\r\n]*,c_paralelo,[^\r\n]*,)0\.\d+(,0\.\d+,)OK\r?$')
    $text = $regex.Replace($text, '${1},,TIMEOUT', 1)
    Write-Utf8NoBom -Path $dataPath -Text $text
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output } 'Fila fallida debe rechazarse'
}

Invoke-Test 'AllowIncomplete conserva la vista marcada INCOMPLETE' {
    $campaign = Copy-Campaign 'incomplete'
    $dataPath = Join-Path $campaign 'mediciones.csv'
    $text = [IO.File]::ReadAllText($dataPath)
    $regex = [regex]::new('(?m)^([^\r\n]*,c_paralelo,[^\r\n]*,)0\.\d+(,0\.\d+,)OK\r?$')
    $text = $regex.Replace($text, '${1},,TIMEOUT', 1)
    Write-Utf8NoBom -Path $dataPath -Text $text
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output -AllowIncomplete } 'Debe terminar con error'
    Assert-True (Test-Path -LiteralPath $output) 'La vista de diagnostico debe existir'
    $manifest = Get-Content -LiteralPath "$output.manifest.json" -Raw | ConvertFrom-Json
    Assert-Equal 'INCOMPLETE' $manifest.status 'Estado del manifiesto'
    Assert-True ($manifest.verification.critical_anomalies -ge 1) 'Debe registrar anomalias criticas'
}

Invoke-Test 'Rechaza stdout distinto de mediciones.csv' {
    $campaign = Copy-Campaign 'stdout'
    $target = @($script:Plan.Rows | Where-Object { $_.configuration -eq 'c_paralelo_P1_T1' })[0]
    $stdoutPath = Join-Path $campaign ('logs/{0:D4}/stdout.txt' -f [int]$target.execution_order)
    $text = [IO.File]::ReadAllText($stdoutPath)
    $text = $text -replace ',0\.0', ',9.9'
    Write-Utf8NoBom -Path $stdoutPath -Text $text
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output } 'stdout alterado debe rechazarse'
}

Invoke-Test 'Rechaza commit distinto del esperado' {
    $campaign = Copy-Campaign 'commit'
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { & $script:Extractor -CampaignDirectory $campaign -Phase piloto -OutputPath $output -ExpectedCommit ('b' * 40) } 'Commit distinto debe rechazarse'
}

Invoke-Test 'Rechaza BOM en el CSV fuente' {
    $campaign = Copy-Campaign 'bom'
    $dataPath = Join-Path $campaign 'mediciones.csv'
    $bytes = [IO.File]::ReadAllBytes($dataPath)
    [IO.File]::WriteAllBytes($dataPath, ([byte[]](239, 187, 191) + $bytes))
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output } 'BOM debe rechazarse'
}

Invoke-Test 'Rechaza plan fuera del orden alternado' {
    $campaign = Copy-Campaign 'plan'
    $planPath = Join-Path $campaign 'plan.csv'
    $text = [IO.File]::ReadAllText($planPath)
    $regex = [regex]::new('(?m)^2,512,')
    $text = $regex.Replace($text, '2,1024,', 1)
    Write-Utf8NoBom -Path $planPath -Text $text
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { Invoke-Extractor -Campaign $campaign -Output $output } 'Plan alterado debe rechazarse'
}

Invoke-Test 'La fase oficial exige arbol limpio' {
    $campaign = Copy-Campaign 'dirty'
    $environmentPath = Join-Path $campaign 'entorno.json'
    $environment = Get-Content -LiteralPath $environmentPath -Raw | ConvertFrom-Json
    $environment.phase = 'oficial'
    $environment.git.dirty = $true
    Write-JsonFile $environmentPath $environment
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { & $script:Extractor -CampaignDirectory $campaign -Phase oficial -OutputPath $output } 'Arbol sucio debe rechazarse'
}

Invoke-Test 'La fase oficial exige campana oficial' {
    $campaign = Copy-Campaign 'phase'
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { & $script:Extractor -CampaignDirectory $campaign -Phase oficial -OutputPath $output } 'Fase piloto no acredita lote oficial'
}

Invoke-Test 'La fase oficial exige N=512,1024,2048' {
    $campaign = Copy-Campaign 'sizes'
    $environmentPath = Join-Path $campaign 'entorno.json'
    $environment = Get-Content -LiteralPath $environmentPath -Raw | ConvertFrom-Json
    $environment.phase = 'oficial'
    Write-JsonFile $environmentPath $environment
    $output = Join-Path $campaign 'export/c_paralelo.csv'
    Assert-Throws { & $script:Extractor -CampaignDirectory $campaign -Phase oficial -OutputPath $output } 'Dimensiones de piloto no acreditan lote oficial'
}

if ($env:S08_I02_KEEP_TEMP) {
    Write-Host "Temporal conservado: $temp"
} else {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ""
Write-Host "Pruebas I2 S8: $($script:TestCount - $script:TestFailures)/$($script:TestCount) correctas."
if ($script:TestFailures -gt 0) { exit 1 }
exit 0
