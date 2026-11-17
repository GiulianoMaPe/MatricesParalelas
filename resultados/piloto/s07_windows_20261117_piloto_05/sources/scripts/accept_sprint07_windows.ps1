param(
    [string]$CampaignId = '',
    [ValidateRange(1,86400)][int]$TimeoutSeconds = 300,
    [switch]$SkipBuild
)
. "$PSScriptRoot/common_windows.ps1"
Assert-Windows
if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
    throw 'Ejecute con Windows PowerShell 5.1 (powershell.exe).'
}
if (-not $CampaignId) { $CampaignId='s07_' + [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8) }
if ($CampaignId -notmatch '^[A-Za-z0-9_-]+$') { throw 'CampaignId invalido.' }
$folder = Join-Path $script:ProjectRoot "resultados/piloto/$CampaignId"
if (Test-Path -LiteralPath $folder) { throw 'CampaignId ya existe; use otro para conservar intentos.' }
$logs = Join-Path $script:ProjectRoot ".cache/s07-acceptance/$CampaignId"
New-Item -ItemType Directory -Path $logs -Force | Out-Null
function Run-Check {
    param([string]$Label, [string]$File, [string[]]$Arguments=@())
    $log = Join-Path $logs "$Label.txt"
    Write-Host "$Label -> $log"
    # Windows PowerShell treats native stderr as an error record even when it
    # is redirected. Preserve the complete log and inspect the real exit code.
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:ProjectRoot $File) @Arguments *> $log
        $checkExitCode = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
    if ($checkExitCode -ne 0) { throw "$Label fallo (codigo $checkExitCode). Revise $log" }
}
function Read-AcceptanceBuilds {
    param([string]$Commit)
    # Keep bench_windows.ps1's entry-point parameters in a local scope.
    . "$PSScriptRoot/bench_windows.ps1"
    Read-IntegratedBuilds -Commit $Commit
}
if (-not $SkipBuild) { Run-Check 'build-release' 'scripts/build_windows.ps1' @('-Version','all','-Configuration','Release','-Tests') }
$candidate = & git -C $script:ProjectRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $candidate -notmatch '^[0-9a-f]{40}$') { throw 'No se pudo identificar la candidata.' }
$acceptedBuilds = Read-AcceptanceBuilds -Commit $candidate
Run-Check 'regresion-release' 'scripts/test_windows.ps1' @('-Version','all','-Configuration','Release','-SkipBuild')
Run-Check 'csv' 'tests/bench_csv_validation_test.ps1'
Run-Check 'c-paralelo' 'tests/bench_c_paralelo_test.ps1'
Run-Check 'go-secuencial' 'tests/bench_go_secuencial_test.ps1' @('-WithExecutable')
Run-Check 'go-paralelo' 'tests/bench_go_paralelo_test.ps1' @('-WithExecutable')
Run-Check 'resumen' 'tests/summarize_results_test.ps1'
Run-Check 'manifiestos' 'tests/bench_build_manifest_test.ps1'
Run-Check 'integridad-resumen' 'tests/summarize_integrity_test.ps1'
Run-Check 'campana-controlada' 'tests/bench_campaign_test.ps1'
Run-Check 'aceptacion-controlada' 'tests/accept_sprint07_windows_test.ps1'
$checkedBuilds = Read-AcceptanceBuilds -Commit $candidate
foreach ($version in $script:Versions) {
    if ($acceptedBuilds[$version].sha256 -cne $checkedBuilds[$version].sha256) { throw "Las pruebas modificaron el binario $version." }
}
Run-Check 'plan-piloto' 'scripts/bench_windows.ps1' @('-Version','all','-Fase','piloto','-CampaignId',"${CampaignId}_plan",'-DryRun')
Run-Check 'piloto-real' 'scripts/bench_windows.ps1' @('-Version','all','-Fase','piloto','-CampaignId',$CampaignId,'-TimeoutSeconds',[string]$TimeoutSeconds)
Run-Check 'verificacion' 'scripts/verify_campaign.ps1' @('-CampaignDirectory',$folder)
Copy-Item -LiteralPath $logs -Destination (Join-Path $folder 'aceptacion') -Recurse
$state = Get-Content (Join-Path $folder 'estado.json') -Raw | ConvertFrom-Json
$estimate = [ordered]@{
    pilot_wall_seconds=$state.wall_s
    official_machine_seconds_estimate=(8.0 * $state.wall_s)
    suggested_reservation_seconds=(12.0 * $state.wall_s)
    assumption='Escalado cubico al duplicar N, misma tabla. Estimacion inicial, no medicion S8 ni reserva de calendario.'
    pending='Revisar memoria/carga/temperatura, confirmar duracion y disponibilidad; reproducir mismo commit/binarios.'
}
[IO.File]::WriteAllText((Join-Path $folder 'estimacion.json'),($estimate | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
Write-Host "Piloto verificado: $folder. Falta revisar entorno y reproducir antes de cerrar S7."
