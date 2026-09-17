param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateRange(1,2147483647)][int]$N = 512,
    [uint32]$Seed = 42,
    [ValidateRange(1,1024)][int]$Workers = 2,
    [ValidateRange(1,1024)][int]$Processes = 2,
    [ValidateRange(1,1024)][int]$Threads = 2,
    [ValidateRange(1,1000)][int]$Repetitions = 5
)
. "$PSScriptRoot\common_windows.ps1"
Assert-Windows
$selected = if ($Version -eq 'all') { $script:Versions } else { @($Version) }
foreach ($item in $selected) {
    $status = Get-Content -LiteralPath (Join-Path $script:ProjectRoot "$item\status.json") -Raw | ConvertFrom-Json
    if ($status.algorithm -ne 'implemented' -or $status.validation -ne 'passed') {
        [Console]::Error.WriteLine("$item : algoritmo/validacion pendientes. No se ejecuta ni se generan mediciones.")
        exit 2
    }
}
[Console]::Error.WriteLine('TODO: implementar campana y validar capacidades reales, esquema y metadatos antes de habilitar mediciones. No se crearon resultados.')
exit 2
