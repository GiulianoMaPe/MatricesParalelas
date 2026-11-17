param([string]$CampaignId,[switch]$SkipBuild)
Set-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) "child-$CampaignId.pid") -Value $PID
Write-Output 'CONTROLLED_ACCEPTANCE_NOT_EXPERIMENTAL'
if ($CampaignId -eq 'success') { Start-Sleep -Seconds 6 } else { Start-Sleep -Seconds 30 }
exit 0