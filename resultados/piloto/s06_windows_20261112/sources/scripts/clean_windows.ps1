param([ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all', [switch]$Cache)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
$targets = @($selected | ForEach-Object { Join-Path $script:ProjectRoot "$_\build" })
if ($Cache) { $targets += Join-Path $script:ProjectRoot '.cache' }
try {
    $root = [IO.Path]::GetFullPath($script:ProjectRoot).TrimEnd('\') + '\'
    # Validate every target and reject junctions before deleting anything.
    foreach ($target in $targets) {
        $full = [IO.Path]::GetFullPath($target)
        if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "Ruta fuera del proyecto: $full" }
        $cursor = $full
        while ($cursor -and $cursor.Length -ge $root.TrimEnd('\').Length) {
            if (Test-Path -LiteralPath $cursor) {
                if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "No se limpia un enlace: $cursor" }
            }
            $cursor = Split-Path -Parent $cursor
        }
        if (Test-Path -LiteralPath $full) {
            $links = Get-ChildItem -LiteralPath $full -Force -Recurse | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
            if ($links) { throw "Hay enlaces dentro de $full. Revise manualmente." }
        }
    }
    foreach ($target in $targets) {
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        Write-Host "Limpieza: $target"
    }
} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
exit 0
