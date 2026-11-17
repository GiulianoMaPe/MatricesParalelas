Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$frozen=Join-Path $PSScriptRoot 'frozen'
function Save-Json([string]$Path,$Value) { [IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 10),$utf8) }
function Busy-Apps { @($script:busy) }
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
            elseif ($busy.Count -gt 0) { $reason='Se abrio Zoom/navegador durante la repeticion: ' + ($busy -join ', ') }
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
            gpu_sensor_available=$true;cpu_temperature_available=$false;cpu_reason='GPU-only choice; PawnIO not installed.';interruption_reason=$reason}
        Save-Json (Join-Path $runLog 'monitor.json') $metadata
        Copy-Item -LiteralPath $gpuScript -Destination (Join-Path $runLog 'registrar_gpu.ps1')
        Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $runLog 'repetir_s07.ps1')
        $campaign = Join-Path $frozen "resultados/piloto/$Id"
        if (Test-Path -LiteralPath $campaign) {
            Copy-Item -LiteralPath $runLog -Destination (Join-Path $campaign 'monitor_externo') -Recurse
            [IO.File]::AppendAllText((Join-Path $campaign 'bitacora.txt'), "`nEXTERNAL_MONITOR GPU temperature/load sampled every 5s in monitor_externo/gpu.csv; CPU temperature unavailable by user choice. Background apps checked every 5s; interruption reason: $reason`n", $utf8)
        }
        $gpu.Dispose(); $process.Dispose()
    }
}
foreach ($id in @('busy','deadline','success')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $frozen "resultados/piloto/$id") | Out-Null
    $script:busy=if ($id -eq 'busy') { @('CONTROLLED_BUSY_APP') } else { @() }
    $deadline=if ($id -eq 'deadline') { [datetimeoffset]::Now.AddSeconds(-1) } else { [datetimeoffset]::Now.AddMinutes(2) }
    $failed=$false; $message=''
    try { Run-Acceptance $id } catch { $failed=$true; $message=$_.Exception.Message }
    if ($id -eq 'success' -and $failed) { throw $message }
    if ($id -ne 'success' -and -not $failed) { throw "No se bloqueo $id" }
    if ($id -eq 'busy' -and $message -notlike '*CONTROLLED_BUSY_APP*') { throw $message }
    if ($id -eq 'deadline' -and $message -notlike '*franja*') { throw $message }
    $childId=[int](Get-Content (Join-Path $frozen "child-$id.pid"))
    if (Get-Process -Id $childId -ErrorAction SilentlyContinue) { throw 'El hijo controlado sigue activo.' }
    $csv=Join-Path $PSScriptRoot "$id/gpu.csv"
    if (-not (Test-Path $csv)) { throw 'No se conservo el registro GPU.' }
    Write-Output "PASS: $id (controlled acceptance, real GPU samples; no matrix measurements)"
}