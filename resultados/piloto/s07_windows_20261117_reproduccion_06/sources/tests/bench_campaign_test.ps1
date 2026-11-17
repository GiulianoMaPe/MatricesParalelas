Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../scripts/bench_windows.ps1"
$checks = 0
function Check([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Reject([scriptblock]$Action, [string]$Message) {
    $thrown = $false
    try { & $Action | Out-Null } catch { $thrown = $true }
    Check $thrown $Message
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('s07-campaign-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    foreach ($case in @(@(1,4,72),@(2,7,126),@(4,11,198),@(6,11,198),@(8,16,288))) {
        $configs = @(Get-IntegratedConfigurations $case[0])
        Check ($configs.Count -eq $case[1]) "Configuraciones CPU=$($case[0])"
        $plan = New-IntegratedPlan -Sizes @(1024,256,512,256) -Configs $configs -Seed 42 -AvailableBytes 8GB
        Check ($plan.Rows.Count -eq $case[2]) "Conteo CPU=$($case[0])"
        $length = $plan.List.Count
        $forward = @($plan.Rows[0..($length-1)].configuration) -join ','
        Check ((@($plan.Rows[$length..(2*$length-1)].configuration) -join ',') -ceq $forward) 'Ronda 1 directa'
        $backward = @($plan.Rows[(2*$length)..(3*$length-1)].configuration)
        [array]::Reverse($backward)
        Check (($backward -join ',') -ceq $forward) 'Ronda 2 inversa'
        Check ((@($plan.Rows.execution_order) -join ',') -ceq (@(1..$plan.Rows.Count) -join ',')) 'Orden consecutivo'
    }
    Reject { Get-IntegratedConfigurations 6 @('P1_T8') } 'Sobreasignacion CPU rechazada'
    Reject { Get-IntegratedConfigurations 8 @() @(3) } 'W fuera del protocolo rechazado'
    $configs = @(Get-IntegratedConfigurations 1)
    $plan = New-IntegratedPlan @(1,1024) $configs 0 10MB
    Check ($plan.Rows.Count -eq 24 -and $plan.Exclusions.Count -eq 4) 'Exclusion memoria conserva baselines'
    Reject { New-IntegratedPlan @(4097) $configs 42 8GB } 'Dimension no soportada por C'
    $path = Join-Path $temp 'bench.lock'
    $stream = Enter-GoParaleloLock $path 'owner'
    try { Reject { Enter-GoParaleloLock $path 'other' } 'Lock exclusivo' }
    finally { Exit-GoParaleloLock $stream $path }
    Check (-not (Test-Path $path)) 'Lock liberado'

    # Launch controlled child PowerShell processes through the real recorder.
    # Only the four native programs/MPI launcher are substituted, never timings
    # represented as experimental data. Exercise the complete serial executor.
    $fixture = Join-Path $PSScriptRoot 'fixtures/control_mediciones.csv'
    $child = Join-Path $temp 'child.ps1'
    @'
param($Fixture,$Version,$N,$Seed,$Rep,$P,$T,$W,$Commit)
$row = Import-Csv $Fixture | Where-Object { $_.version -eq $Version } | Select-Object -First 1
$row.n="$N"; $row.seed="$Seed"; $row.repetition="$Rep"; $row.is_warmup=($Rep -eq 0).ToString().ToLowerInvariant()
$row.hostname=[Environment]::MachineName; $row.commit=$Commit
$row.processes="$P"; $row.threads="$T"; $row.observed_threads="$T"; $row.workers="$W"
$row.gomaxprocs=if ($Version -like 'go_*') { [Environment]::GetEnvironmentVariable('GOMAXPROCS') } else { '' }
$row.configuration=switch ($Version) { 'c_paralelo' { "c_paralelo_P${P}_T${T}" }; 'go_paralelo' { "go_paralelo_W$W" }; default { $Version } }
if ($Version -eq 'c_paralelo') {
    for ($rank=0; $rank -lt [int]$P; $rank++) {
        $q=[int][Math]::Floor([double]$N/[int]$P); $r=[int]$N % [int]$P
        $rows=$q; if ($rank -lt $r) { $rows++ }
        $observed=if ($rows -gt 0) { [int]$T } else { 0 }
        @{ rank=$rank; pid=$PID; rows=$rows; first_row=($rank*$q+[Math]::Min($rank,$r)); requested_threads=[int]$T; timed_observed_threads=$observed } |
            ConvertTo-Json | Set-Content (Join-Path $env:S06_DIAGNOSTICS "rank-$rank.json")
    }
}
$row | ConvertTo-Csv -NoTypeInformation
'@ | Set-Content -LiteralPath $child -Encoding UTF8
    $script:realProcess = ${function:Invoke-GoSequentialProcess}
    $script:pwsh = (Get-Process -Id $PID).Path
    $script:testCommit = '0123456789012345678901234567890123456789'
    $script:injectFailure = $false
    function Invoke-GoSequentialProcess {
        param($Executable,$Arguments,$RunDirectory,$TimeoutSeconds,$ChildEnvironment,[switch]$TerminateTree)
        $version = 'c_secuencial'; $p=1; $t=1; $w=1; $offset=0
        if ($Arguments[0] -eq '-n') { $version='c_paralelo'; $p=[int]$Arguments[1]; $t=[int]$ChildEnvironment.OMP_NUM_THREADS; $offset=3 }
        elseif ($Arguments -contains '--workers') { $version='go_paralelo'; $w=[int]$Arguments[-1] }
        elseif ($ChildEnvironment.GOMAXPROCS -eq '1') { $version='go_secuencial' }
        $argsForChild = @('-NoProfile','-File',$child,'-Fixture',$fixture,'-Version',$version,
            '-N',$Arguments[$offset+1],'-Seed',$Arguments[$offset+3],'-Rep',$Arguments[$offset+5],
            '-P',"$p",'-T',"$t",'-W',"$w",'-Commit',$script:testCommit)
        if ($script:injectFailure -and $version -eq 'go_paralelo') { $argsForChild = @('-NoProfile','-Command','exit 2') }
        & $script:realProcess -Executable $script:pwsh -Arguments $argsForChild -RunDirectory $RunDirectory -TimeoutSeconds $TimeoutSeconds -ChildEnvironment $ChildEnvironment
    }
    $builds = @{}
    foreach ($version in $script:Versions) { $builds[$version]=@{ executable=$pwsh; sha256=(Get-FileHash $pwsh).Hash } }
    $hardware = @{ CpuModel='TEST'; RamBytes=16GB; OsEdition='TEST'; OsBuild='0' }
    $plan = New-IntegratedPlan @(1) $configs 4294967295 8GB
    $directory = Join-Path $temp 'complete'
    New-Item -ItemType Directory -Path $directory | Out-Null
    $ok = Invoke-IntegratedRuns $plan $configs $builds $hardware $testCommit $directory 'fake-mpiexec' 20
    if (-not $ok) { Get-Content (Join-Path $directory 'bitacora.txt') | Write-Host; Get-ChildItem $directory -Filter stderr.txt -Recurse | ForEach-Object { Get-Content $_.FullName | Write-Host } }
    Check $ok 'Ejecutor integrado completo'
    $rows = @(Import-Csv (Join-Path $directory 'mediciones.csv'))
    Check ($rows.Count -eq 24) '24 observaciones sintenticas persistidas'
    Check (@($rows | Where-Object { $_.validation_status -ne 'OK' }).Count -eq 0) 'Validacion cuatro versiones'
    $rankFile = Join-Path $directory 'logs/0003/rank-0.json'
    $rankOriginal = [IO.File]::ReadAllText($rankFile)
    $rankData = $rankOriginal | ConvertFrom-Json
    $rankData.timed_observed_threads = 2
    $rankData | ConvertTo-Json | Set-Content $rankFile
    Reject { Assert-IntegratedRanks $plan.Rows[2] $configs[2] (Split-Path -Parent $rankFile) } 'Rank con hilos incorrectos rechazado'
    $rankData.timed_observed_threads=1; $rankData.rows=0
    $rankData | ConvertTo-Json | Set-Content $rankFile
    Reject { Assert-IntegratedRanks $plan.Rows[2] $configs[2] (Split-Path -Parent $rankFile) } 'Rank con filas incorrectas rechazado'
    Remove-Item $rankFile
    Reject { Assert-IntegratedRanks $plan.Rows[2] $configs[2] (Split-Path -Parent $rankFile) } 'Diagnostico rank ausente rechazado'
    [IO.File]::WriteAllText($rankFile,$rankOriginal)
    $summary = @(& "$PSScriptRoot/../scripts/summarize_results.ps1" -InputPath (Join-Path $directory 'mediciones.csv') -PassThru)
    Check ($summary.Count -eq 4 -and @($summary | Where-Object { $_.status -ne 'COMPLETE' }).Count -eq 0) 'Resumen de cuatro grupos completos'
    $script:injectFailure = $true
    $directory = Join-Path $temp 'failed'
    New-Item -ItemType Directory -Path $directory | Out-Null
    $ok = Invoke-IntegratedRuns $plan $configs $builds $hardware $testCommit $directory 'fake-mpiexec' 20
    Check (-not $ok) 'Fallo aborta campana'
    $rows = @(Import-Csv (Join-Path $directory 'mediciones.csv'))
    Check ($rows.Count -eq 4 -and $rows[-1].validation_status -eq 'PENDING') 'Salida 2 conserva diagnostico y parciales'
    Check ($rows[-1].kernel_s -eq '' -and $rows[-1].total_s -eq '') 'Fallo sin tiempos inventados'
    Check ((Get-Content (Join-Path $directory 'estado.json') -Raw | ConvertFrom-Json).status -eq 'INCOMPLETE') 'Estado incompleto persistente'
    # Test the outer preparation/lock/dry-run without pretending this is Windows.
    function Assert-Windows { }
    function Get-HardwareInfo { return [pscustomobject]@{ CpuModel='TEST'; PhysicalCores=6; LogicalProcessors=12; RamBytes=16GB; RamAvailableBytes=8GB; OsEdition='TEST'; OsBuild='0'; PowerSource='TEST'; PowerPlan='TEST' } }
    function Get-GitInfo { return [pscustomobject]@{ Commit=$script:testCommit; Dirty=$false; Diff=''; Status=''; GitPath=(Get-Command git).Source } }
    function Assert-NoConcurrentMeasurement { }
    Invoke-IntegratedCampaign -Sizes @(256,512,1024) -Seed 42 -Phase piloto -OutputRoot $temp -CampaignId 'dry' -TimeoutSeconds 120 -DryRun
    Check ((Get-Content (Join-Path $temp 'dry/estado.json') -Raw | ConvertFrom-Json).status -eq 'DRY_RUN') 'DryRun identificado'
    Check (-not (Test-Path (Join-Path $temp 'dry/mediciones.csv'))) 'DryRun no fabrica mediciones'
    Check (@(Import-Csv (Join-Path $temp 'dry/plan.csv')).Count -eq 198) 'Preparacion integrada de 198 corridas'
    Check (-not (Test-Path (Join-Path $script:ProjectRoot '.cache/bench.lock'))) 'Preparacion libera lock'
    $script:injectFailure = $false
    function Read-IntegratedBuilds {
        $result=@{}
        foreach ($version in $script:Versions) {
            $hash=(Get-FileHash $script:pwsh).Hash
            $result[$version]=[pscustomobject]@{ executable=$script:pwsh; sha256=$hash; commit=$script:testCommit
                manifest=@{ version=$version; commit=$script:testCommit; configuration='Release'; target='x64'; sha256=$hash
                    arguments=@('CONTROLLED TEST'); tools=@{ msvc='TEST'; windows_sdk='TEST'; msmpi_runtime='TEST'; msmpi_sdk='TEST'; go='TEST' } } }
        }
        return $result
    }
    function Get-MPILauncher { return 'CONTROLLED TEST' }
    Invoke-IntegratedCampaign -Sizes @(1) -Seed 42 -RequestedC @('P1_T1') -RequestedGo @(1) -Phase piloto -OutputRoot $temp -CampaignId 'evidence' -TimeoutSeconds 20
    $verified = & "$PSScriptRoot/../scripts/verify_campaign.ps1" -CampaignDirectory (Join-Path $temp 'evidence') -PassThru
    Check ($verified.status -eq 'VERIFIED' -and $verified.observations -eq 24) 'Verificador acepta evidencia controlada completa'
    $planFile=Join-Path $temp 'evidence/plan.csv'
    $tampered=@(Import-Csv $planFile)
    $tampered[1].configuration='go_paralelo_W1'
    $tampered | Export-Csv $planFile -NoTypeInformation
    Reject { & "$PSScriptRoot/../scripts/verify_campaign.ps1" -CampaignDirectory (Join-Path $temp 'evidence') } 'Verificador rechaza plan alterado'
    Write-Output "Integrated campaign: $checks checks PASS (controlled processes, no experimental observations)."
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
