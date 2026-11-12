. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$missing = @()
Write-Host "Windows: $([Environment]::OSVersion.VersionString); sistema 64 bits: $([Environment]::Is64BitOperatingSystem)"
Write-Host "Terminal MSVC inicializada: $($env:VSCMD_ARG_TGT_ARCH -eq 'x64'); vswhere: $(Find-Vswhere)"
try {
    $cl = Initialize-MSVC
    Write-Host "MSVC: $cl; destino: $env:VSCMD_ARG_TGT_ARCH; version: $env:VCToolsVersion"
    Write-Host "Windows SDK: $env:WindowsSdkDir $env:WindowsSDKVersion (cabeceras y kernel32.lib x64 presentes)"
} catch { $missing += 'MSVC/Windows SDK'; Write-Warning $_.Exception.Message }
$mpi = Find-MPI
Write-Host "mpi.h: $($mpi.Include); msmpi.lib candidata x64: $($mpi.Library)"
if (-not $mpi.Include -or -not $mpi.Library) { $missing += 'MS-MPI SDK' }
elseif (Get-Command dumpbin.exe -ErrorAction SilentlyContinue) {
    try { $null = Assert-MPISdk; Write-Host 'msmpi.lib: x64 confirmado' }
    catch { $missing += 'MS-MPI SDK x64'; Write-Warning $_.Exception.Message }
} else { $missing += 'verificacion arquitectura msmpi.lib'; Write-Warning 'Se requiere dumpbin de MSVC para confirmar la arquitectura de msmpi.lib.' }
try {
    $launcher = Get-MPILauncher
    Write-Host "MS-MPI Runtime: $launcher; x64; version: $((Get-Item -LiteralPath $launcher).VersionInfo.FileVersion)"
} catch { $missing += 'MS-MPI Runtime'; Write-Warning $_.Exception.Message }
try { $go = Initialize-Go; Invoke-Native $go @('version'); Write-Host 'Go host/destino: windows/amd64' }
catch { $missing += 'Go windows/amd64'; Write-Warning $_.Exception.Message }
try {
    $git = Get-Command git.exe -ErrorAction Stop
    Invoke-Native $git.Source @('--version')
    Write-Host "Git: $($git.Source); arquitectura: $(Get-PEArchitecture $git.Source)"
} catch { $missing += 'Git'; Write-Warning $_.Exception.Message }
if ($missing.Count) {
    [Console]::Error.WriteLine("Diagnostico incompleto: $($missing -join ', '). Consulte docs/instalacion-windows.md.")
    exit 1
}
Write-Host 'Dependencias detectadas. Ejecute test_windows.ps1 para verificar compilacion y ejecucion.'
exit 0
