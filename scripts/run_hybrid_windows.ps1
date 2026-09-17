param([ValidateSet('Debug','Release')][string]$Configuration = 'Debug')
. "$PSScriptRoot\common_windows.ps1"
try {
    Assert-Windows
    $launcher = Get-MPILauncher
    $exe = Join-Path $script:ProjectRoot "c_paralelo\build\$Configuration\c_paralelo.exe"
    if (-not (Test-Path -LiteralPath $exe)) { throw 'Compile c_paralelo primero.' }
    $previousThreads = $env:OMP_NUM_THREADS
    $previousDynamic = $env:OMP_DYNAMIC
    try {
        $env:OMP_NUM_THREADS = '2'
        $env:OMP_DYNAMIC = 'FALSE'
        Invoke-Native $launcher @('-n','2',$exe,'--smoke-test')
    } finally {
        $env:OMP_NUM_THREADS = $previousThreads
        $env:OMP_DYNAMIC = $previousDynamic
    }
} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
exit 0
