param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateRange(1,2147483647)][int]$N = 512,
    [uint32]$Seed = 42,
    [ValidateRange(1,1024)][int]$Workers = 2,
    [ValidateRange(1,1024)][int]$Processes = 2,
    [ValidateRange(1,1024)][int]$Threads = 2,
    [ValidateRange(1,1000)][int]$Repetitions = 5,
    [string[]]$NList = @(),
    [string[]]$Configurations = @(),
    [ValidateRange(0,1)][int]$Warmups = 1,
    [ValidateRange(1,86400)][int]$TimeoutSeconds = 120,
    [ValidateSet('Debug','Release')][string]$Configuration = 'Release',
    [string]$OutputRoot = '',
    [string]$OutputDirectory,
    [int[]]$GoWorkers = @(),
    [string]$CampaignId = '',
    [switch]$DryRun,
    [switch]$FailFast,
    [switch]$ForceUnlock,
    [ValidateSet('piloto','oficial')][string]$Fase = 'piloto'
)
$script:BenchInvocationLine = $MyInvocation.Line
. "$PSScriptRoot\common_windows.ps1"
. "$PSScriptRoot\bench_c_paralelo.ps1"
. "$PSScriptRoot\bench_c_secuencial.ps1"
. "$PSScriptRoot\bench_go_paralelo.ps1"
. "$PSScriptRoot\bench_go_secuencial.ps1"

if ($MyInvocation.InvocationName -eq '.') { return }
try {
    Assert-Windows
    $selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
    foreach ($item in $selected) {
        $status = Get-Content -LiteralPath (Join-Path $script:ProjectRoot "$item\status.json") -Raw | ConvertFrom-Json
        if ($status.algorithm -ne 'implemented' -or $status.validation -ne 'passed') {
            [Console]::Error.WriteLine("$item : algoritmo/validacion pendientes.")
            exit 2
        }
    }
    if ($Version -eq 'all') {
        [Console]::Error.WriteLine('Los cuatro casos estan disponibles por separado. La campana intercalada all requiere integracion I5; no se crearon mediciones.')
        exit 2
    }
    if ($Configuration -ne 'Release') { throw 'La medicion exige Release.' }
    if ($Version -eq 'c_paralelo') {
        $arguments = @{}
        $supported = (Get-Command Invoke-BenchMain).Parameters
        foreach ($key in $PSBoundParameters.Keys) {
            if ($supported.ContainsKey($key)) { $arguments[$key] = $PSBoundParameters[$key] }
        }
        $arguments.Version = $Version
        $arguments.Seed = $Seed
        $arguments.ExplicitN = $PSBoundParameters.ContainsKey('N')
        $arguments.ExplicitPair = $PSBoundParameters.ContainsKey('Processes') -or $PSBoundParameters.ContainsKey('Threads')
        if ($PSBoundParameters.ContainsKey('Processes') -xor $PSBoundParameters.ContainsKey('Threads')) {
            throw 'Indique -Processes y -Threads juntos.'
        }
        exit (Invoke-BenchMain @arguments)
    }
    if ($DryRun -or $ForceUnlock -or $FailFast -or $NList.Count -gt 0 -or $Configurations.Count -gt 0 -or $OutputRoot -or $CampaignId) {
        throw 'NList/Configurations/OutputRoot/CampaignId/DryRun/FailFast/ForceUnlock pertenecen al caso c_paralelo.'
    }
    if ($Version -eq 'go_secuencial') {
        if ($Repetitions -ne 5 -or $Warmups -ne 1) { throw 'Go secuencial exige un calentamiento y cinco repeticiones.' }
        Invoke-GoSequentialBenchmark -N $N -Seed $Seed -TimeoutSeconds $TimeoutSeconds -OutputDirectory $OutputDirectory
    } else {
        if ($OutputDirectory) { throw 'OutputDirectory pertenece al caso go_secuencial; C secuencial y Go paralelo emiten CSV por stdout.' }
        if ($Warmups -ne 1) { throw 'Se exige un calentamiento.' }
        $dimensions = if ($PSBoundParameters.ContainsKey('N')) { @($N) } elseif ($Fase -eq 'piloto') { @(256,512,1024) } else { @(512,1024,2048) }
        if ($Version -eq 'c_secuencial') {
            $result = Invoke-CSecuencialCampaign -Dimensions $dimensions -CampaignSeed $Seed -MeasuredReps $Repetitions
        } else {
            $series = if ($PSBoundParameters.ContainsKey('Workers') -and $GoWorkers.Count -eq 0) { @($Workers) } else { $GoWorkers }
            $result = Invoke-GoParaleloCampaign -Dimensions $dimensions -CampaignSeed $Seed -MeasuredReps $Repetitions -WorkerSeries $series -TimeoutSeconds $TimeoutSeconds
        }
        if (-not $result) { throw "Campana $Version fallida." }
    }
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}