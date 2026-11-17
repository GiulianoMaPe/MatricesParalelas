param(
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateRange(1,3600)][int]$DurationSeconds=3600
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$nvidia=(Get-Command nvidia-smi.exe -ErrorAction Stop).Source
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$raw=Join-Path $OutputDirectory 'gpu_raw.csv'
$csv=Join-Path $OutputDirectory 'gpu.csv'
if ((Test-Path -LiteralPath $raw) -or (Test-Path -LiteralPath $csv)) { throw 'No sobrescribir un registro GPU existente.' }
[IO.File]::WriteAllText($raw,'',$utf8)
[IO.File]::WriteAllText($csv,"sample_utc,timestamp_local,gpu_name,gpu_temperature_c,gpu_utilization_percent,gpu_memory_utilization_percent`n",$utf8)
$samples=0
$watch=[Diagnostics.Stopwatch]::StartNew()
$started=[datetime]::UtcNow.ToString('o')
try {
    while ($watch.Elapsed.TotalSeconds -lt $DurationSeconds -and -not (Test-Path -LiteralPath (Join-Path $OutputDirectory 'detener_monitor'))) {
        $next=$watch.Elapsed.TotalMilliseconds+5000
        $sampleUtc=[datetime]::UtcNow.ToString('o')
        $lines=@(& $nvidia '--query-gpu=timestamp,name,temperature.gpu,utilization.gpu,utilization.memory' '--format=csv,noheader,nounits')
        if ($LASTEXITCODE -ne 0 -or $lines.Count -ne 1) { throw 'Fallo de consulta GPU: se espera exactamente la GTX 1070 de esta PC.' }
        $row=@($lines | ConvertFrom-Csv -Header timestamp_local,gpu_name,gpu_temperature_c,gpu_utilization_percent,gpu_memory_utilization_percent)[0]
        $temperature=0.0
        if (-not [double]::TryParse($row.gpu_temperature_c.Trim(),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$temperature) -or [double]::IsNaN($temperature) -or [double]::IsInfinity($temperature)) { throw 'Temperatura GPU no numerica.' }
        [IO.File]::AppendAllText($raw,($lines[0]+"`n"),$utf8)
        [IO.File]::AppendAllText($csv,($sampleUtc+','+$lines[0]+"`n"),$utf8)
        $samples++
        $remaining=[Math]::Max(0,1000*$DurationSeconds-$watch.Elapsed.TotalMilliseconds)
        $delay=[Math]::Min($remaining,[Math]::Min(5000,[Math]::Max(0,$next-$watch.Elapsed.TotalMilliseconds)))
        if ($delay -gt 0) { Start-Sleep -Milliseconds ([int]$delay) }
    }
} finally {
    $watch.Stop()
    $metadata=[ordered]@{started_at_utc=$started;ended_at_utc=[datetime]::UtcNow.ToString('o');samples=$samples;interval_seconds=5
        method='One finite nvidia-smi query per interval; raw and timestamped rows appended and flushed.'
        sensor='GPU';cpu_temperature_available=$false;cpu_reason='User chose GPU only; no CPU driver installed.'
        nvidia_smi_path=$nvidia;nvidia_smi_sha256=(Get-FileHash -LiteralPath $nvidia).Hash;script_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash}
    [IO.File]::WriteAllText((Join-Path $OutputDirectory 'sampler.json'),($metadata|ConvertTo-Json -Depth 5),$utf8)
}
