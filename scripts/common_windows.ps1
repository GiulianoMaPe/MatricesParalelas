# Shared helpers. Environment changes affect this process and its children only.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:Versions = @('c_secuencial', 'c_paralelo', 'go_secuencial', 'go_paralelo')

function Assert-Windows {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem) {
        throw 'Se requiere Windows nativo de 64 bits.'
    }
}
function Invoke-Native {
    param([string]$File, [string[]]$Arguments = @())
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$File termino con codigo $LASTEXITCODE." }
}
function Find-Vswhere {
    $command = Get-Command vswhere.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidate = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    return $null
}
function Initialize-MSVC {
    Assert-Windows
    if (-not ($env:VSCMD_ARG_TGT_ARCH -eq 'x64' -and (Get-Command cl.exe -ErrorAction SilentlyContinue))) {
        $vswhere = Find-Vswhere
        if (-not $vswhere) { throw 'MSVC no inicializado y vswhere no encontrado. Instale Build Tools C++ o abra una consola x64 Native Tools.' }
        $installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($LASTEXITCODE -ne 0) { throw 'Fallo vswhere.' }
        if (-not $installation) { throw 'No se encontro una instalacion con MSVC x64/x86. Modifique Visual Studio Installer.' }
        $devcmd = Join-Path ([string]$installation) 'Common7\Tools\VsDevCmd.bat'
        if (-not (Test-Path -LiteralPath $devcmd)) { throw 'Falta VsDevCmd.bat en la instalacion detectada.' }
        # CMD is used only to initialize the official development environment.
        $devArgs = '"' + $devcmd + '" -no_logo -arch=x64 -host_arch=x64 >nul && set'
        $lines = & $env:ComSpec /d /s /c $devArgs
        if ($LASTEXITCODE -ne 0) { throw 'VsDevCmd no pudo inicializar MSVC x64.' }
        foreach ($line in $lines) {
            if ($line -match '^([^=]+)=(.*)$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
            }
        }
    }
    if ($env:VSCMD_ARG_TGT_ARCH -ne 'x64') { throw 'El destino MSVC debe ser x64.' }
    $compiler = Get-Command cl.exe -ErrorAction Stop
    if (-not $env:WindowsSdkDir -or -not $env:WindowsSDKVersion) { throw 'No hay SDK de Windows inicializado.' }
    $sdkInclude = Join-Path $env:WindowsSdkDir ('Include\' + $env:WindowsSDKVersion.TrimEnd('\'))
    $sdkLib = Join-Path $env:WindowsSdkDir ('Lib\' + $env:WindowsSDKVersion.TrimEnd('\'))
    foreach ($path in @((Join-Path $sdkInclude 'um\Windows.h'), (Join-Path $sdkInclude 'ucrt\stdio.h'), (Join-Path $sdkLib 'um\x64\kernel32.lib'))) {
        if (-not (Test-Path -LiteralPath $path)) { throw "SDK de Windows incompleto: $path" }
    }
    return $compiler.Source
}
function Get-PEArchitecture {
    param([string]$Path)
    $stream = [IO.File]::OpenRead($Path)
    $reader = [IO.BinaryReader]::new($stream)
    try {
        $stream.Position = 0x3c
        $offset = $reader.ReadInt32()
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x4550) { throw "PE no valido: $Path" }
        switch ($reader.ReadUInt16()) {
            0x8664 { return 'x64' }
            0x14c { return 'x86' }
            0xaa64 { return 'arm64' }
            default { return 'desconocida' }
        }
    } finally { $reader.Dispose() }
}
function Find-MPI {
    $includes = @($env:MSMPI_INC)
    $libraries = @($env:MSMPI_LIB64)
    $executables = @()
    $command = Get-Command mpiexec.exe -ErrorAction SilentlyContinue
    if ($command) { $executables += $command.Source }
    if ($env:MSMPI_BIN) { $executables += Join-Path $env:MSMPI_BIN 'mpiexec.exe' }
    foreach ($key in @('HKLM:\SOFTWARE\Microsoft\MPI', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\MPI', 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\MPI', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\MPI')) {
        $entry = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($entry) {
            foreach ($property in @('InstallRoot', 'InstallPath', 'InstallationFolder')) {
                $p = $entry.PSObject.Properties[$property]
                if ($p -and $p.Value) {
                    $includes += Join-Path $p.Value 'Include'
                    $libraries += Join-Path $p.Value 'Lib\x64'
                    $executables += Join-Path $p.Value 'Bin\mpiexec.exe'
                }
            }
        }
    }
    # Conventional locations are candidates only; actual files must exist.
    $includes += Join-Path ${env:ProgramFiles(x86)} 'Microsoft SDKs\MPI\Include'
    $libraries += Join-Path ${env:ProgramFiles(x86)} 'Microsoft SDKs\MPI\Lib\x64'
    $executables += Join-Path $env:ProgramFiles 'Microsoft MPI\Bin\mpiexec.exe'
    $inc = $includes | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'mpi.h')) } | Select-Object -First 1
    $lib = $libraries | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'msmpi.lib')) } | Select-Object -First 1
    $exe = $executables | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    return [pscustomobject]@{ Include = $inc; Library = $lib; Launcher = $exe }
}
function Assert-MPISdk {
    $mpi = Find-MPI
    if (-not $mpi.Include -or -not $mpi.Library) { throw 'Falta MS-MPI SDK: mpi.h y/o msmpi.lib x64. Instale msmpisdk.msi.' }
    $headers = & dumpbin.exe /headers (Join-Path $mpi.Library 'msmpi.lib')
    if ($LASTEXITCODE -ne 0 -or -not ($headers -match '8664 machine') -or ($headers -match '14C machine')) {
        throw 'No se pudo confirmar msmpi.lib x64 con dumpbin.'
    }
    return $mpi
}
function Get-MPILauncher {
    $mpi = Find-MPI
    if (-not $mpi.Launcher) { throw 'Falta MS-MPI Runtime: mpiexec.exe. Instale msmpisetup.exe.' }
    if ((Get-PEArchitecture $mpi.Launcher) -ne 'x64') { throw 'mpiexec debe ser x64.' }
    return $mpi.Launcher
}
function Initialize-Go {
    Assert-Windows
    $go = Get-Command go.exe -ErrorAction SilentlyContinue
    if (-not $go) { throw 'Go no encontrado. Instale Go para Windows amd64 y abra otra terminal.' }
    # Keep caches local, including in restricted workspaces; no go env -w.
    $env:GOCACHE = Join-Path $script:ProjectRoot '.cache\go-build'
    $env:GOMODCACHE = Join-Path $script:ProjectRoot '.cache\go-mod'
    $env:GOTOOLCHAIN = 'local'
    $env:GOWORK = 'off'
    $platform = @(& $go.Source env GOOS GOARCH GOHOSTOS GOHOSTARCH)
    if ($LASTEXITCODE -ne 0 -or ($platform -join '/') -ne 'windows/amd64/windows/amd64') {
        throw 'Se requiere Go host y destino windows/amd64; revise GOOS y GOARCH.'
    }
    return $go.Source
}
