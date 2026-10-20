param(
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug',
    [ValidateRange(1, 1024)][int]$Processes = 2,
    [ValidateRange(1, 1024)][int]$Threads = 2,
    [string]$InputPath,
    [string]$OutputPath,
    [int]$N = 0,
    [uint32]$Seed = 0,
    [switch]$SmokeTest
)
. "$PSScriptRoot\common_windows.ps1"
try {
    Assert-Windows
    $launcher = Get-MPILauncher
    $exe = Join-Path $script:ProjectRoot "c_paralelo\build\$Configuration\c_paralelo.exe"
    if (-not (Test-Path -LiteralPath $exe)) { throw 'Compile c_paralelo primero.' }
    if ($InputPath -and $N -gt 0) {
        throw 'Use --input o --n/--seed, no ambos.'
    }
    if ($SmokeTest -and ($InputPath -or $N -gt 0 -or $OutputPath)) {
        throw 'La prueba de instalacion no combina con entrada ni salida.'
    }
    $programArguments = @()
    if ($SmokeTest -or (-not $InputPath -and $N -le 0)) {
        $programArguments += '--smoke-test'
    } else {
        if ($InputPath) { $programArguments += @('--input', $InputPath) }
        if ($N -gt 0) { $programArguments += @('--n', "$N", '--seed', "$Seed") }
        if ($OutputPath) { $programArguments += @('--output', $OutputPath) }
    }
    $previousThreads = $env:OMP_NUM_THREADS
    $previousDynamic = $env:OMP_DYNAMIC
    try {
        $env:OMP_NUM_THREADS = "$Threads"
        $env:OMP_DYNAMIC = 'FALSE'
        Invoke-Native $launcher (@('-n', "$Processes", $exe) + $programArguments)
    } finally {
        $env:OMP_NUM_THREADS = $previousThreads
        $env:OMP_DYNAMIC = $previousDynamic
    }
} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
exit 0
