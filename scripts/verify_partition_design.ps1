# Independent arithmetic review of the S2 design, not the S4 implementation.
$ErrorActionPreference = 'Stop'

function Get-PartitionDesign {
    param([int]$N, [int]$Processes)
    $q = [int][Math]::Floor($N / $Processes)
    $r = $N % $Processes
    $rows = @()
    $counts = @()
    $displacements = @()
    $offset = 0
    for ($rank = 0; $rank -lt $Processes; $rank++) {
        $localRows = $q + [int]($rank -lt $r)
        # Check the closed form against independently accumulated offsets.
        $closedFirst = $rank * $q + [Math]::Min($rank, $r)
        if ($closedFirst -ne $offset -or $offset + $localRows -gt $N) {
            throw "Invariante de filas: N=$N P=$Processes rank=$rank"
        }
        $rows += $localRows
        $counts += $localRows * $N
        $displacements += $offset * $N
        $offset += $localRows
    }
    if ($offset -ne $N -or ($counts | Measure-Object -Sum).Sum -ne $N * $N) {
        throw "Cobertura: N=$N P=$Processes"
    }
    for ($rank = 0; $rank -lt $Processes - 1; $rank++) {
        if ($displacements[$rank] + $counts[$rank] -ne $displacements[$rank + 1]) {
            throw "Continuidad: N=$N P=$Processes rank=$rank"
        }
    }
    if ($displacements[-1] + $counts[-1] -ne $N * $N) {
        throw "Fin del bloque: N=$N P=$Processes"
    }
    return [pscustomobject]@{ Rows = $rows; Counts = $counts; Displacements = $displacements }
}

$examples = @(
    @{ N=10; P=4; Rows='3,3,2,2'; Counts='30,30,20,20'; Displacements='0,30,60,80' },
    @{ N=7; P=3; Rows='3,2,2'; Counts='21,14,14'; Displacements='0,21,35' },
    @{ N=5; P=2; Rows='3,2'; Counts='15,10'; Displacements='0,15' },
    @{ N=8; P=4; Rows='2,2,2,2'; Counts='16,16,16,16'; Displacements='0,16,32,48' },
    @{ N=2; P=2; Rows='1,1'; Counts='2,2'; Displacements='0,2' },
    @{ N=1; P=1; Rows='1'; Counts='1'; Displacements='0' },
    @{ N=3; P=5; Rows='1,1,1,0,0'; Counts='3,3,3,0,0'; Displacements='0,3,6,9,9' },
    @{ N=4; P=8; Rows='1,1,1,1,0,0,0,0'; Counts='4,4,4,4,0,0,0,0'; Displacements='0,4,8,12,16,16,16,16' }
)

foreach ($example in $examples) {
    $actual = Get-PartitionDesign -N $example.N -Processes $example.P
    foreach ($field in @('Rows', 'Counts', 'Displacements')) {
        if (($actual.$field -join ',') -ne $example[$field]) {
            throw "Ejemplo incorrecto: N=$($example.N) P=$($example.P) $field"
        }
    }
}
$cases = 0
for ($dimension = 1; $dimension -le 64; $dimension++) {
    for ($processCount = 1; $processCount -le 70; $processCount++) {
        $null = Get-PartitionDesign -N $dimension -Processes $processCount
        $cases++
    }
}
if (([long]46340 * 46340) -gt [int]::MaxValue -or
    ([long]46341 * 46341) -le [int]::MaxValue) { throw 'Limites INT_MAX incorrectos.' }
Write-Output "OK: 8 ejemplos, $cases pares N/P y fronteras 46340/46341; 0 fallos."
Write-Output 'Comprobacion del diseno S2; no ejecuta partition.c ni valida multiplicacion MPI.'
