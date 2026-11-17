Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../scripts/bench_windows.ps1"
$originalRoot=$script:ProjectRoot
$temp=Join-Path ([IO.Path]::GetTempPath()) ('s07-build-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
$checks=0
function Check([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message }; $script:checks++ }
function Reject([scriptblock]$Action,[string]$Message) {
    $thrown=$false; try { & $Action | Out-Null } catch { $thrown=$true }; Check $thrown $Message
}
try {
    $script:ProjectRoot=$temp
    $script:testCommit='0123456789012345678901234567890123456789'
    $source=Join-Path $temp 'source.txt'
    [IO.File]::WriteAllText($source,'CONTROLLED SOURCE')
    $script:inventory=@('source.txt')
    # These tests validate provenance checks using controlled files. They never
    # claim the fake binaries are PE/Go executable observations.
    function Get-PEArchitecture { param($Path) return 'x64' }
    function git { $global:LASTEXITCODE=0; return $script:inventory }
    $script:fakeGo=Join-Path $temp 'fake-go.ps1'
    $metadata=@('build GOOS=windows','build GOARCH=amd64','build vcs=git',"build vcs.revision=$testCommit",'build vcs.modified=false')
    [IO.File]::WriteAllLines($fakeGo, @('$global:LASTEXITCODE=0') + @($metadata | ForEach-Object { "'$_'" }))
    function Get-Command {
        param($Name,$ErrorAction)
        if ($Name -eq 'go.exe') { return [pscustomobject]@{ Source=$script:fakeGo } }
        return Microsoft.PowerShell.Core\Get-Command $Name -ErrorAction Stop
    }
    foreach ($version in $script:Versions) {
        $directory=Join-Path $temp "$version/build/Release"
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $exe=Join-Path $directory "$version.exe"
        [IO.File]::WriteAllText($exe,'CONTROLLED BINARY')
        $manifest=@{ version=$version; configuration='Release'; target='x64'; commit=$testCommit; dirty=$false
            sha256=(Get-FileHash $exe).Hash; source_sha256=@{ 'source.txt'=(Get-FileHash $source).Hash } }
        $manifest | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $directory 'build.json')
    }
    $result=Read-IntegratedBuilds -Commit $testCommit -Official
    Check ($result.Count -eq 4) 'Cuatro manifiestos coherentes aceptados'
    Reject { Read-IntegratedBuilds -Commit ('a'*40) } 'Build de otro commit rechazado'
    [IO.File]::WriteAllText($source,'CHANGED')
    Reject { Read-IntegratedBuilds -Commit $testCommit } 'Fuente cambiada rechazada'
    [IO.File]::WriteAllText($source,'CONTROLLED SOURCE')
    $script:inventory=@('source.txt','extra.txt')
    Reject { Read-IntegratedBuilds -Commit $testCommit } 'Archivo agregado detectado'
    $script:inventory=@('source.txt')
    $exe=Join-Path $temp 'c_secuencial/build/Release/c_secuencial.exe'
    [IO.File]::WriteAllText($exe,'CHANGED')
    Reject { Read-IntegratedBuilds -Commit $testCommit } 'Binario cambiado rechazado'
    [IO.File]::WriteAllText($exe,'CONTROLLED BINARY')
    $file=Join-Path (Split-Path -Parent $exe) 'build.json'
    $manifest=Get-Content $file -Raw | ConvertFrom-Json
    $manifest.dirty=$true
    $manifest | ConvertTo-Json -Depth 4 | Set-Content $file
    Reject { Read-IntegratedBuilds -Commit $testCommit -Official } 'Build sucio rechazado en oficial'
    Check ((Read-IntegratedBuilds -Commit $testCommit).Count -eq 4) 'Build sucio permitido como piloto documentado'
    $manifest.dirty=$false; $manifest.configuration='Debug'
    $manifest | ConvertTo-Json -Depth 4 | Set-Content $file
    Reject { Read-IntegratedBuilds -Commit $testCommit } 'Debug rechazado'
    $manifest.configuration='Release'
    $manifest | ConvertTo-Json -Depth 4 | Set-Content $file
    Add-Content $fakeGo "'build -race=true'"
    Reject { Read-IntegratedBuilds -Commit $testCommit } 'Go instrumentado rechazado'
    Remove-Item $file
    Reject { Read-IntegratedBuilds -Commit $testCommit } 'Manifiesto ausente rechazado'
    Write-Output "Build manifests: $checks checks PASS (controlled files)."
} finally {
    $script:ProjectRoot=$originalRoot
    Remove-Item -LiteralPath $temp -Recurse -Force
}
