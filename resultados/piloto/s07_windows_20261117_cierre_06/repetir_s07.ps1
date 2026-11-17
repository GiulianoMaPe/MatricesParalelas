param([switch]$InspectOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$frozen = Join-Path $workspace '.cache/s08-candidata-97ccc98'
$candidate = '97ccc981e9068d8ec0753cd8a4b7572a6bece34d'
$ids = @('s07_windows_20261117_reproduccion_06')
$windowStart = [datetimeoffset]::Parse('2026-11-17T13:00:00-05:00')
$deadline = [datetimeoffset]::Parse('2026-11-17T13:55:00-05:00')
$utf8 = [Text.UTF8Encoding]::new($false)
function Save-Json([string]$Path, $Value) { [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 12), $utf8) }
function Busy-Apps { @(Get-Process -Name chrome,msedge,firefox,brave,opera,Zoom -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique) }
function Publish-Attempts {
    foreach ($id in $ids) {
        foreach ($name in @($id,"${id}_plan")) {
            $source=Join-Path $frozen "resultados/piloto/$name"; $destination=Join-Path $workspace "resultados/piloto/$name"
            if ((Test-Path -LiteralPath $source) -and -not (Test-Path -LiteralPath $destination)) { Copy-Item -LiteralPath $source -Destination $destination -Recurse }
        }
    }
}
function Preflight {
    $apps = @(Busy-Apps)
    $loads = @(1..5 | ForEach-Object {
        $load = @(Get-CimInstance Win32_Processor | ForEach-Object { $_.LoadPercentage })
        if (@($load | Where-Object { $null -eq $_ }).Count -gt 0 -or $load.Count -eq 0) { throw 'No se puede verificar carga CPU.' }
        [double](($load | Measure-Object -Average).Average)
        Start-Sleep -Seconds 2
    })
    $head = (& git -C $frozen rev-parse HEAD) -join ''
    if ($LASTEXITCODE -ne 0 -or $head -cne $candidate) { throw 'La copia congelada no coincide con la candidata.' }
    $dirty = @(& git -C $frozen status --porcelain)
    if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) { throw "Copia congelada modificada: $dirty" }
    $reference = Get-Content (Join-Path $workspace 'resultados/piloto/s07_windows_20261117_piloto_02/source-hashes.json') -Raw | ConvertFrom-Json
    foreach ($source in $reference.PSObject.Properties) {
        if ((Get-FileHash -LiteralPath (Join-Path $frozen $source.Name)).Hash -ine $source.Value) { throw "Fuente distinta: $($source.Name)" }
    }
    $binaryHashes = [ordered]@{}
    foreach ($version in @('c_secuencial','c_paralelo','go_secuencial','go_paralelo')) {
        $folder = Join-Path $frozen "$version/build/Release"
        $manifest = Get-Content (Join-Path $folder 'build.json') -Raw | ConvertFrom-Json
        $hash = (Get-FileHash (Join-Path $folder "$version.exe")).Hash
        if ($manifest.commit -cne $candidate -or $manifest.dirty -or $manifest.sha256 -cne $hash) { throw "Build no congelado: $version" }
        $binaryHashes[$version] = $hash
    }
    $nvidia = (Get-Command nvidia-smi.exe -ErrorAction Stop).Source
    $null = Get-Command python.exe -ErrorAction Stop
    $gpu = @(& $nvidia '--query-gpu=name,temperature.gpu' '--format=csv,noheader,nounits')
    if ($LASTEXITCODE -ne 0 -or ($gpu -join '') -notmatch ',\s*\d+\s*$') { throw 'No se puede leer temperatura GPU.' }
    $apps = @(@($apps) + @(Busy-Apps) | Sort-Object -Unique)
    $average = [double](($loads | Measure-Object -Average).Average)
    return [ordered]@{ checked_at_utc=[datetime]::UtcNow.ToString('o'); ready=$true
        busy_apps=$apps; cpu_load_percent_samples=$loads; mean_cpu_load_percent=$average; heuristic_max_idle_mean_percent=10
        workload_mode='USER_AUTHORIZED_CURRENT_ENVIRONMENT'; idle_heuristic_enforced=$false
        gpu_preview=$gpu; gpu_sensor_available=$true; cpu_temperature_available=$false
        cpu_temperature_reason='User chose GPU only; CPU driver not installed.'; commit=$head; binary_sha256=$binaryHashes }
}
function Run-Acceptance([string]$Id) {
    $runLog = Join-Path $PSScriptRoot $Id
    New-Item -ItemType Directory -Path $runLog | Out-Null
    $gpuScript = Join-Path $PSScriptRoot 'registrar_gpu.ps1'
    $gpuArguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $gpuScript + '" -OutputDirectory "' + $runLog + '" -DurationSeconds 3600'
    $gpu = Start-Process -FilePath (Join-Path $env:windir 'System32/WindowsPowerShell/v1.0/powershell.exe') -ArgumentList $gpuArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runLog 'gpu_stdout.txt') -RedirectStandardError (Join-Path $runLog 'gpu_stderr.txt')
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = Join-Path $env:windir 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $info.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $frozen 'scripts/accept_sprint07_windows.ps1') + '" -CampaignId ' + $Id + ' -SkipBuild'
    $info.WorkingDirectory = $frozen
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $info
    $reason = ''; $started = [datetime]::UtcNow.ToString('o')
    try {
        if (-not $process.Start()) { throw 'No se pudo iniciar la aceptacion.' }
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        while (-not $process.WaitForExit(5000)) {
            $busy = @(Busy-Apps)
            $observation = @{utc=[datetime]::UtcNow.ToString('o');busy_apps=$busy}
            [IO.File]::AppendAllText((Join-Path $runLog 'supervision.jsonl'), (($observation | ConvertTo-Json -Compress) + "`n"), $utf8)
            if ([datetimeoffset]::Now -ge $deadline) { $reason='Se alcanzo el fin de la franja autorizada.' }
            elseif ($gpu.HasExited) { $reason='Se interrumpio el monitor GPU.' }
            if ($reason) {
                & taskkill.exe /PID $process.Id /T /F | Out-Null
                $process.WaitForExit()
                break
            }
        }
        [IO.File]::WriteAllText((Join-Path $runLog 'aceptacion_stdout.txt'), $stdout.GetAwaiter().GetResult(), $utf8)
        [IO.File]::WriteAllText((Join-Path $runLog 'aceptacion_stderr.txt'), $stderr.GetAwaiter().GetResult(), $utf8)
        if ($reason) { throw $reason }
        if ($process.ExitCode -ne 0) { throw "Aceptacion $Id fallo: codigo $($process.ExitCode)." }
    } finally {
        [IO.File]::WriteAllText((Join-Path $runLog 'detener_monitor'),'stop',$utf8)
        if (-not $gpu.HasExited -and -not $gpu.WaitForExit(15000)) {
            & taskkill.exe /PID $gpu.Id /T /F | Out-Null
            $gpu.WaitForExit()
        }
        $metadata = [ordered]@{campaign_id=$Id;started_at_utc=$started;ended_at_utc=[datetime]::UtcNow.ToString('o');query='timestamp,name,temperature.gpu,utilization.gpu,utilization.memory'
            timestamp_timezone='America/Lima';interval_seconds=5;scope='Includes acceptance tests and measurement; correlate with proceso.json start_utc/wall_s.'
            workload_mode='User authorized running with applications as found; no applications closed.';idle_heuristic_enforced=$false;supervision_log='supervision.jsonl'
            gpu_sensor_available=$true;cpu_temperature_available=$false;cpu_reason='GPU-only choice; PawnIO not installed.';interruption_reason=$reason}
        Save-Json (Join-Path $runLog 'monitor.json') $metadata
        Copy-Item -LiteralPath $gpuScript -Destination (Join-Path $runLog 'registrar_gpu.ps1')
        Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $runLog 'repetir_s07.ps1')
        $campaign = Join-Path $frozen "resultados/piloto/$Id"
        if (Test-Path -LiteralPath $campaign) {
            Copy-Item -LiteralPath $runLog -Destination (Join-Path $campaign 'monitor_externo') -Recurse
            [IO.File]::AppendAllText((Join-Path $campaign 'bitacora.txt'), "`nEXTERNAL_MONITOR GPU temperature/load sampled every 5s in monitor_externo/gpu.csv; CPU temperature unavailable by user choice. Applications were observed every 5s and left running per user instruction; see supervision.jsonl. CPU load is recorded; no idle heuristic enforced and no causal attribution to applications. Interruption reason: $reason`n", $utf8)
        }
        $gpu.Dispose(); $process.Dispose()
    }
}
if ($InspectOnly) {
    $preflight = Preflight
    Save-Json (Join-Path $PSScriptRoot 'preflight-now.json') $preflight
    $preflight | ConvertTo-Json -Depth 5
    exit 0
}
$statePath = Join-Path $PSScriptRoot 'estado.json'
$jobState = [ordered]@{status='STARTING';started_at_utc=[datetime]::UtcNow.ToString('o');commit=$candidate;campaigns=$ids;cpu_temperature_available=$false;gpu_sensor_available=$true;human_acceptance='not granted'}
$lock = $null
try {
    $lock = [IO.File]::Open((Join-Path $PSScriptRoot 'ejecucion.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    if ([datetimeoffset]::Now -ge $deadline) { throw 'Venció el límite de ejecución autorizado.' }
    foreach ($id in $ids) {
        foreach ($name in @($id,"${id}_plan")) {
            if ((Test-Path (Join-Path $frozen "resultados/piloto/$name")) -or (Test-Path (Join-Path $workspace "resultados/piloto/$name"))) { throw "Ya existe $name; conservarlo y elegir ID nuevo." }
        }
    }
    for ($index=0; $index -lt $ids.Count; $index++) {
        if ($index -gt 0) { Start-Sleep -Seconds 120 }
        $preflight = Preflight
        Save-Json (Join-Path $PSScriptRoot ("preflight-"+$ids[$index]+'.json')) $preflight
        if (-not $preflight.ready) { throw 'La verificación técnica del entorno no pasó.' }
        $jobState.status='RUNNING'; $jobState.current_campaign=$ids[$index]; Save-Json $statePath $jobState
        Run-Acceptance $ids[$index]
    }
    Publish-Attempts
    Push-Location $workspace
    try {
        $previousPreference=$ErrorActionPreference
        try {
            $ErrorActionPreference='Continue'
            & (Get-Command python.exe).Source (Join-Path $PSScriptRoot 'crear_informe.py') *> (Join-Path $PSScriptRoot 'comparacion.log')
            $comparisonExit=$LASTEXITCODE
        } finally { $ErrorActionPreference=$previousPreference }
        if ($comparisonExit -ne 0) { throw 'Fallo de comparacion/telemetria; revisar comparacion.log.' }
    } finally { Pop-Location }
    $jobState.status='COMPLETE_TECHNICAL_REQUIRES_REVIEW'
} catch {
    $jobState.status='FAILED_OR_BLOCKED'; $jobState.reason=$_.Exception.Message
} finally {
    Publish-Attempts
    $jobState.ended_at_utc=[datetime]::UtcNow.ToString('o'); Save-Json $statePath $jobState
    [IO.File]::AppendAllText((Join-Path $workspace 'PENDIENTES_CIERRE_SPRINT_7.md'), ("`n`n## Resultado de la repeticion programada`n`n"+$jobState.ended_at_utc+' UTC: '+$jobState.status+". Ver .cache/s07_1300/estado.json y resultados/piloto/s07_windows_20261117_cierre_03/. Cierre humano no concedido automaticamente.`n"),$utf8)
    if ($null -ne $lock) { $lock.Dispose() }
}
if ($jobState.status -cne 'COMPLETE_TECHNICAL_REQUIRES_REVIEW') { exit 1 }
