param([string]$Mode, [string]$Value)
if ($Mode -eq 'timeout') { Start-Sleep -Seconds 30; exit 0 }
if ($Mode -eq 'stderr') { [Console]::Error.Write(('e' * 200000)); exit 0 }
if ($Mode -eq 'failure') { [Console]::Error.Write('fallo controlado'); exit 7 }
[Console]::Out.Write("GOMAXPROCS=$env:GOMAXPROCS; valor=$Value")
exit 0