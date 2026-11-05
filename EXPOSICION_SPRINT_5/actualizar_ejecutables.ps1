param([switch]$SoloCopiar)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    $kitRoot = $PSScriptRoot
    $projectRoot = Split-Path -Parent $kitRoot
    $builder = Join-Path $projectRoot 'scripts\build_windows.ps1'
    if (-not (Test-Path -LiteralPath $builder)) { throw 'Para actualizar, coloque esta carpeta dentro del proyecto MatricesParalelas.' }
    if (-not $SoloCopiar) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $builder -Version all -Configuration Release
        if ($LASTEXITCODE -ne 0) { throw 'Fallo la compilacion. No se actualizo el paquete.' }
    }
    $modules = @('c_secuencial','c_paralelo','go_secuencial','go_paralelo')
    foreach ($module in $modules) {
        $source = Join-Path $projectRoot "$module\build\Release\$module.exe"
        if (-not (Test-Path -LiteralPath $source)) { throw "Falta el ejecutable compilado: $source" }
    }
    $files = @()
    foreach ($module in $modules) {
        $source = Join-Path $projectRoot "$module\build\Release\$module.exe"
        $target = Join-Path $kitRoot "$module\$module.exe"
        Copy-Item -LiteralPath $source -Destination $target -Force
        $files += [pscustomobject]@{ Archivo="$module/$module.exe"; SHA256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash }
    }
    $commit = & git.exe -C $projectRoot rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo identificar el commit compilado.' }
    $manifest = [pscustomobject]@{ Commit=([string]$commit).Trim(); PreparadoUTC=[DateTime]::UtcNow.ToString('o'); Configuracion='Release'; Ejecutables=$files }
    [IO.File]::WriteAllText((Join-Path $kitRoot 'EJECUTABLES.json'),($manifest | ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
    Write-Host 'Listos los cuatro ejecutables Release.' -ForegroundColor Green
    Write-Host "Commit: $commit"
    Write-Host 'La evidencia historica del cierre se mantiene con su fecha original.'
    exit 0
} catch { Write-Host "No se pudo actualizar: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
