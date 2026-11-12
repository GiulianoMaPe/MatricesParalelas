param([string]$Output = 'resultados/piloto/s06_windows_20261112', [switch]$Run)
. "$PSScriptRoot/common_windows.ps1"
Assert-Windows
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
# Process-only trust exception for this transferred working tree.
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = $script:ProjectRoot.Replace('\','/')
$null = Initialize-MSVC
$null = Initialize-Go
$arguments = @("$PSScriptRoot/sprint06_windows.py", '--output', $Output)
if ($Run) { $arguments += '--run' }
Invoke-Native python.exe $arguments
