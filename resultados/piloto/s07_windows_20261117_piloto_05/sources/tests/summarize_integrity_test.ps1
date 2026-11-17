Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$summary = Join-Path $PSScriptRoot '../scripts/summarize_results.ps1'
$fixture = Join-Path $PSScriptRoot 'fixtures/control_mediciones.csv'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('s07-summary-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
$checks=0
function Check([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message }; $script:checks++ }
function Reject([scriptblock]$Action,[string]$Message) {
    $thrown=$false; try { & $Action | Out-Null } catch { $thrown=$true }; Check $thrown $Message
}
function Save-Rows($Rows,[string]$Name) {
    $path=Join-Path $temp $Name
    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8
    return $path
}
try {
    $rows = @(Import-Csv $fixture)
    $sec = @($rows | Where-Object { $_.version -eq 'c_secuencial' })
    $par = @($rows | Where-Object { $_.configuration -eq 'c_paralelo_P2_T2' })
    $a=Save-Rows $sec 'a.csv'; $b=Save-Rows $par 'b.csv'
    $result=@(& $summary -InputPath @($a,$b) -PassThru)
    Check ($result.Count -eq 2) 'Archivos separados conservados'
    Check ($null -eq ($result | Where-Object version -eq c_paralelo).speedup) 'Sin speedup entre campanas distintas'
    $sec[-1].repetition='4'
    $path=Save-Rows $sec 'duplicate.csv'
    $result=@(& $summary -InputPath $path -PassThru)[0]
    Check ($result.status -eq 'INCOMPLETE' -and $null -eq $result.speedup) 'Cinco filas con repeticiones duplicadas no completan grupo'
    $sec[-1].repetition='5'
    $path=Save-Rows @($sec | Select-Object -Skip 1) 'no-warmup.csv'
    Check ((& $summary -InputPath $path -PassThru).status -eq 'INCOMPLETE') 'Calentamiento obligatorio'
    $sec[1].kernel_s='NaN'
    $path=Save-Rows $sec 'nan.csv'
    Reject { & $summary -InputPath $path -PassThru } 'NaN rechazado'
    $sec[1].kernel_s='0.02'; $sec[1].total_s='Infinity'
    $path=Save-Rows $sec 'inf.csv'
    Reject { & $summary -InputPath $path -PassThru } 'Infinity rechazado'
    $sec[1].total_s='0.025'; $sec[1].is_warmup='true'
    $path=Save-Rows $sec 'bad-warmup.csv'
    Reject { & $summary -InputPath $path -PassThru } 'Warmup contradictorio rechazado'
    $sec[1].is_warmup='false'
    foreach ($row in $sec) { $row.kernel_s='0.000000000'; $row.total_s='0.000000000' }
    $path=Save-Rows $sec 'zero.csv'
    $result=& $summary -InputPath $path -PassThru
    Check ($result.status -eq 'COMPLETE' -and $null -eq $result.speedup -and $null -eq $result.gflops_total) 'Ceros validos sin division por cero'
    $path=Save-Rows @($rows | Where-Object { $_.validation_status -eq 'ERROR' }) 'failed.csv'
    $result=& $summary -InputPath $path -PassThru
    Check ($result.status -eq 'INCOMPLETE' -and $result.reps_count -eq 0) 'Grupo fallido visible'
    $bad=Join-Path $temp 'malformed.csv'
    [IO.File]::WriteAllText($bad, ([IO.File]::ReadAllText($fixture) -replace 'TEST-HOST','"unclosed'))
    Reject { & $summary -InputPath $bad -PassThru } 'Comillas sin cerrar rechazadas'
    $bad=Join-Path $temp 'extra-column.csv'
    [IO.File]::WriteAllText($bad, ([IO.File]::ReadAllText($fixture) -replace 'validation_status','validation_status,extra'))
    Reject { & $summary -InputPath $bad -PassThru } 'Esquema extra rechazado'
    Write-Output "Summary integrity: $checks checks PASS."
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
