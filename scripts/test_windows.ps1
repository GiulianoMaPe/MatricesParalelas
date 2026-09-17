param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug'
)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
$failures = @()
foreach ($item in $selected) {
    try {
        Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\build_windows.ps1",'-Version',$item,'-Configuration',$Configuration,'-Tests')
        $module = Join-Path $script:ProjectRoot $item
        $build = Join-Path $module "build\$Configuration"
        $exe = Join-Path $build "$item.exe"
        if ($item.StartsWith('go_')) {
            $go = Initialize-Go
            Push-Location $module
            try {
                Invoke-Native $go @('fmt','./...')
                Invoke-Native $go @('vet','./...')
                Invoke-Native $go @('test','-count=1','-timeout=30s','./...')
            } finally { Pop-Location }
        } else {
            Invoke-Native (Join-Path $build 'tests\pending_test.exe')
        }
        if ($item -eq 'c_paralelo') {
            Invoke-Native powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSScriptRoot\run_hybrid_windows.ps1",'-Configuration',$Configuration)
        } else { Invoke-Native $exe @('--smoke-test') }
        & $exe --n 2 --seed 42
        if ($LASTEXITCODE -ne 2) { throw 'El esqueleto debe rechazar el calculo pendiente con codigo 2.' }
        Write-Host "OK: $item (entorno y rechazo de operaciones pendientes; no valida multiplicacion)."
    } catch {
        $failures += $item
        Write-Warning "$item : $($_.Exception.Message)"
    }
}
if ($failures.Count) { [Console]::Error.WriteLine("Pruebas incompletas: $($failures -join ', ')."); exit 1 }
exit 0
