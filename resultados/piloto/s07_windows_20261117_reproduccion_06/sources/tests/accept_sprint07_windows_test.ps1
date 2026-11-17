# Acceptance orchestration regression: controlled scripts, no experimental data.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) { throw 'Use Windows PowerShell 5.1.' }
$root = Join-Path ([IO.Path]::GetTempPath()) ('s07-acceptance-test-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)
function Put([string]$Path, [string]$Content) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Content, $utf8)
}
$checks = 0
function Check([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}
New-Item -ItemType Directory -Force -Path (Join-Path $root 'scripts') | Out-Null
Copy-Item -LiteralPath "$PSScriptRoot/../scripts/accept_sprint07_windows.ps1" -Destination (Join-Path $root 'scripts/accept_sprint07_windows.ps1')
Put (Join-Path $root 'scripts/common_windows.ps1') @'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:Versions = @('c_secuencial','c_paralelo','go_secuencial','go_paralelo')
function Assert-Windows {}
function git { $global:LASTEXITCODE = 0; return ('a' * 40) }
'@
Put (Join-Path $root 'scripts/build_windows.ps1') @'
Add-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'build-calls.txt') 'BUILD'
'@
Put (Join-Path $root 'scripts/test_windows.ps1') @'
param($Version, $Configuration, [switch]$SkipBuild)
if (-not $SkipBuild) { throw 'Regression would rebuild binaries.' }
Write-Output 'REGRESSION_WITHOUT_BUILD'
'@
Put (Join-Path $root 'scripts/bench_windows.ps1') @'
param($Version, $Fase, $CampaignId = '', $TimeoutSeconds, [switch]$DryRun)
function Read-IntegratedBuilds {
    param($Commit)
    if ($Commit -cne ('a' * 40)) { throw 'Wrong candidate.' }
    $result = @{}
    foreach ($version in $script:Versions) {
        $result[$version] = @{ sha256 = (Get-FileHash (Join-Path $script:ProjectRoot "$version.bin")).Hash }
    }
    return $result
}
if ($MyInvocation.InvocationName -eq '.') { return }
if (-not $CampaignId) { throw 'CampaignId was overwritten while loading helpers.' }
$folder = Join-Path (Split-Path -Parent $PSScriptRoot) "resultados/piloto/$CampaignId"
New-Item -ItemType Directory -Path $folder -Force | Out-Null
if (-not $DryRun) { '{"status":"COMPLETE","wall_s":2}' | Set-Content (Join-Path $folder 'estado.json') }
'@
Put (Join-Path $root 'scripts/verify_campaign.ps1') 'Write-Output "CONTROLLED_VERIFY"'
foreach ($name in @('bench_csv_validation_test','bench_c_paralelo_test','bench_go_secuencial_test','bench_go_paralelo_test','summarize_results_test','bench_build_manifest_test','summarize_integrity_test','bench_campaign_test','accept_sprint07_windows_test')) {
    Put (Join-Path $root "tests/$name.ps1") 'Write-Output "CONTROLLED_CHECK"'
}
foreach ($version in @('c_secuencial','c_paralelo','go_secuencial','go_paralelo')) { Put (Join-Path $root "$version.bin") 'CONTROLLED_BINARY' }
function Attempt([string]$Id, [switch]$SkipBuild) {
    $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'scripts/accept_sprint07_windows.ps1'),'-CampaignId',$Id)
    if ($SkipBuild) { $arguments += '-SkipBuild' }
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & powershell.exe @arguments *> (Join-Path $root "$Id.log")
        return $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
}
Check ((Attempt 'pilot') -eq 0) 'Controlled pilot must complete.'
Check (@(Get-Content (Join-Path $root 'build-calls.txt')).Count -eq 1) 'Pilot builds once.'
Check (Test-Path (Join-Path $root 'resultados/piloto/pilot/aceptacion/regresion-release.txt')) 'CampaignId and logs preserved.'
$estimate = Get-Content (Join-Path $root 'resultados/piloto/pilot/estimacion.json') -Raw | ConvertFrom-Json
Check ($estimate.official_machine_seconds_estimate -eq 16) 'Estimate uses the actual completed state.'
Check ((Attempt 'reproduction' -SkipBuild) -eq 0) 'Reproduction must complete without a build.'
Check (@(Get-Content (Join-Path $root 'build-calls.txt')).Count -eq 1) 'SkipBuild must not call the builder.'
Put (Join-Path $root 'tests/bench_campaign_test.ps1') @'
Set-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'c_secuencial.bin') 'MUTATED_BINARY'
'@
Check ((Attempt 'mutated' -SkipBuild) -ne 0) 'A binary changed by tests must reject the attempt.'
Check (-not (Test-Path (Join-Path $root 'resultados/piloto/mutated'))) 'Mutation must stop before measurement.'
Put (Join-Path $root 'tests/bench_csv_validation_test.ps1') @'
Write-Output 'BEFORE_FAILURE'
[Console]::Error.WriteLine('CONTROLLED_STDERR')
Write-Output 'AFTER_STDERR'
exit 7
'@
Check ((Attempt 'failure' -SkipBuild) -ne 0) 'A failed child must reject acceptance.'
$log = Get-Content (Join-Path $root '.cache/s07-acceptance/failure/csv.txt') -Raw
Check ($log.Contains('BEFORE_FAILURE') -and $log.Contains('CONTROLLED_STDERR') -and $log.Contains('AFTER_STDERR')) 'Complete stdout/stderr must survive a failed check.'
$failure = Get-Content (Join-Path $root 'failure.log') -Raw
Check ($failure.Contains('csv fallo (codigo 7)')) 'Failure must identify the check and real exit code.'
Check (-not (Test-Path (Join-Path $root 'resultados/piloto/failure'))) 'Failure must stop before measurement.'
Write-Host "OK: aceptacion S7; $checks comprobaciones; evidencia controlada: $root"
