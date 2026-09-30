param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug',
    [switch]$Tests
)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
$failures = @()
foreach ($item in $selected) {
    try {
        $module = Join-Path $script:ProjectRoot $item
        $build = Join-Path $module "build\$Configuration"
        New-Item -ItemType Directory -Force -Path $build | Out-Null
        Write-Host "Compilando $item ($Configuration)..."
        if ($item.StartsWith('go_')) {
            $go = Initialize-Go
            Push-Location $module
            try {
                $arguments = @('build', '-o', (Join-Path $build "$item.exe"))
                if ($Configuration -eq 'Debug') { $arguments += '-gcflags=all=-N -l' }
                Invoke-Native $go ($arguments + '.')
            } finally { Pop-Location }
        } else {
            $cl = Initialize-MSVC
            $options = @('/nologo','/TC','/std:c11','/W4','/WX','/fp:precise', '/I', (Join-Path $module 'include'))
            $options += if ($Configuration -eq 'Debug') { @('/Od','/Zi','/MDd') } else { @('/O2','/MD') }
            $linkOptions = @('/link','/MACHINE:X64')
            if ($Configuration -eq 'Debug') { $linkOptions += '/DEBUG' }
            if ($item -eq 'c_paralelo') {
                $mpi = Assert-MPISdk
                $options += @('/openmp','/I',$mpi.Include)
                $linkOptions += @("/LIBPATH:$($mpi.Library)",'msmpi.lib')
            }
            $sources = @(Get-ChildItem -LiteralPath (Join-Path $module 'src') -Filter '*.c' | ForEach-Object FullName)
            Push-Location $build
            try { Invoke-MSVC $cl ($options + $sources + "/Fe:$item.exe" + $linkOptions) }
            finally { Pop-Location }
            if ($Tests) {
                $testBuild = Join-Path $build 'tests'
                New-Item -ItemType Directory -Force -Path $testBuild | Out-Null
                $testSources = @($sources | Where-Object { (Split-Path -Leaf $_) -ne 'main.c' })
                $testSources += Join-Path $module 'tests\pending_test.c'
                Push-Location $testBuild
                try { Invoke-MSVC $cl ($options + $testSources + '/Fe:pending_test.exe' + $linkOptions) }
                finally { Pop-Location }
            }
        }
    } catch {
        $failures += $item
        Write-Warning "$item : $($_.Exception.Message)"
    }
}
if ($failures.Count) { [Console]::Error.WriteLine("Compilacion incompleta: $($failures -join ', ')."); exit 1 }
exit 0
