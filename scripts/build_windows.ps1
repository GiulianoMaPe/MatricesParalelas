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
        $toolVersions = [ordered]@{}
        $effectiveArguments = @()
        if ($item.StartsWith('go_')) {
            $go = Initialize-Go
            Push-Location $module
            try {
                $arguments = @('build', '-o', (Join-Path $build "$item.exe"))
                $arguments += '-buildvcs=true'
                if ($Configuration -eq 'Debug') { $arguments += '-gcflags=all=-N -l' }
                $effectiveArguments = @($arguments + '.')
                $toolVersions.go = (& $go version) -join ' '
                Invoke-Native $go $effectiveArguments
                $toolVersions.go_build_metadata = @(& $go version -m (Join-Path $build "$item.exe"))
                if ($LASTEXITCODE -ne 0) { throw 'No se pudo inspeccionar el build Go.' }
            } finally { Pop-Location }
        } else {
            $cl = Initialize-MSVC
            $toolVersions.msvc = [string](Get-Item -LiteralPath $cl).VersionInfo.FileVersion
            $toolVersions.windows_sdk = $env:WindowsSDKVersion.TrimEnd('\')
            $options = @('/nologo','/TC','/std:c11','/W4','/WX','/fp:precise', '/I', (Join-Path $module 'include'))
            $options += if ($Configuration -eq 'Debug') { @('/Od','/Zi','/MDd') } else { @('/O2','/MD') }
            $linkOptions = @('/link','/MACHINE:X64')
            if ($Configuration -eq 'Debug') { $linkOptions += '/DEBUG' }
            if ($item -in @('c_secuencial','c_paralelo')) {
                $commit = 'dev'
                $git = Get-Command git.exe -ErrorAction SilentlyContinue
                if ($git) {
                    $resolvedCommit = & $git.Source -C $script:ProjectRoot rev-parse HEAD
                    if ($LASTEXITCODE -eq 0 -and $resolvedCommit -match '^[0-9a-fA-F]{40}$') {
                        $commit = $resolvedCommit.ToLowerInvariant()
                    }
                }
                $buildInfo = Join-Path $build 'build_info.h'
                $buildInfoText = "#define PROJECT_COMMIT `"$commit`"`r`n#define PROJECT_CONFIGURATION `"$Configuration`"`r`n"
                [IO.File]::WriteAllText($buildInfo, $buildInfoText, [Text.UTF8Encoding]::new($false))
                $options += @('/D_WIN32_WINNT=0x0600','/I',$build)
                $linkOptions += 'advapi32.lib'
            }
            if ($item -eq 'c_paralelo') {
                $mpi = Assert-MPISdk
                $toolVersions.msmpi_runtime = [string](Get-Item -LiteralPath (Get-MPILauncher)).VersionInfo.FileVersion
                $toolVersions.msmpi_sdk = [ordered]@{ mpi_h_sha256 = (Get-FileHash (Join-Path $mpi.Include 'mpi.h')).Hash; msmpi_lib_sha256 = (Get-FileHash (Join-Path $mpi.Library 'msmpi.lib')).Hash }
                $options += @('/openmp','/I',$mpi.Include)
                $linkOptions += @("/LIBPATH:$($mpi.Library)",'msmpi.lib')
            }
            $sources = @(Get-ChildItem -LiteralPath (Join-Path $module 'src') -Filter '*.c' | ForEach-Object FullName)
            Push-Location $build
            $effectiveArguments = @($options + $sources + "/Fe:$item.exe" + $linkOptions)
            try { Invoke-MSVC $cl $effectiveArguments }
            finally { Pop-Location }
            if ($Tests) {
                $testBuild = Join-Path $build 'tests'
                New-Item -ItemType Directory -Force -Path $testBuild | Out-Null
                $testSources = @($sources | Where-Object { (Split-Path -Leaf $_) -ne 'main.c' })
                $testSources += Join-Path $module 'tests\pending_test.c'
                Push-Location $testBuild
                try { Invoke-MSVC $cl ($options + $testSources + '/Fe:pending_test.exe' + $linkOptions) }
                finally { Pop-Location }
                if ($item -eq 'c_paralelo') {
                    $partitionSources = @(
                        (Join-Path $module 'src\partition.c'),
                        (Join-Path $module 'tests\partition_test.c')
                    )
                    Push-Location $testBuild
                    try { Invoke-MSVC $cl ($options + $partitionSources + '/Fe:partition_test.exe' + $linkOptions) }
                    finally { Pop-Location }
                }
            }
        }
        $binary = Join-Path $build "$item.exe"
        $buildCommit = & git -C $script:ProjectRoot rev-parse HEAD
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo registrar HEAD del build.' }
        $sourceStatus = @(& git -C $script:ProjectRoot status --porcelain)
        $sourceHashes = [ordered]@{}
        $buildSources = @(& git -C $script:ProjectRoot ls-files --cached --others --exclude-standard -- $item scripts/build_windows.ps1 scripts/common_windows.ps1)
        foreach ($relative in $buildSources) {
            $source = Join-Path $script:ProjectRoot $relative
            if (Test-Path -LiteralPath $source -PathType Leaf) { $sourceHashes[$relative] = (Get-FileHash -LiteralPath $source).Hash }
        }
        $manifest = [ordered]@{
            version=$item; configuration=$Configuration; target='x64'; commit=$buildCommit
            dirty=($sourceStatus.Count -gt 0); built_at_utc=[datetime]::UtcNow.ToString('o')
            sha256=(Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash
            arguments=$effectiveArguments; tools=$toolVersions; source_sha256=$sourceHashes
            build_environment=[ordered]@{ CL=$env:CL; _CL_=$env:_CL_; LINK=$env:LINK; GOFLAGS=$env:GOFLAGS; GOEXPERIMENT=$env:GOEXPERIMENT }
        }
        [IO.File]::WriteAllText((Join-Path $build 'build.json'),
            ($manifest | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    } catch {
        $failures += $item
        Write-Warning "$item : $($_.Exception.Message)"
    }
}
if ($failures.Count) { [Console]::Error.WriteLine("Compilacion incompleta: $($failures -join ', ')."); exit 1 }
exit 0
