Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$comparator = Join-Path $projectRoot 'scripts\compare_results.ps1'
$fixtures = Join-Path $PSScriptRoot 'fixtures'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ("matrices-comparator-" + [guid]::NewGuid().ToString('N'))
$failures = New-Object 'System.Collections.Generic.List[string]'

function Invoke-Comparator {
    param(
        [string]$Expected,
        [string[]]$Actual,
        [int]$ExpectedExit,
        [string]$Name,
        [string]$OutputPattern = '^(OK|ERROR)'
    )
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $comparator, '-Expected', $Expected, '-Actual') + $Actual
    $previousErrorAction = $ErrorActionPreference
    $stderrPath = Join-Path $temporary ("stderr-" + [guid]::NewGuid().ToString('N') + '.txt')
    try {
        $ErrorActionPreference = 'Continue'
        $stdout = @(& powershell.exe @arguments 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        $stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne $ExpectedExit) {
        $failures.Add("$Name (codigo $exitCode, esperado $ExpectedExit): stdout=$($stdout -join ' | '); stderr=$stderr")
    } elseif ($ExpectedExit -eq 0 -and ($stderr -ne '' -or ($stdout -join "`n") -notmatch ("(?s)" + $OutputPattern))) {
        $failures.Add("$Name (canales o salida OK invalidos): stdout=$($stdout -join ' | '); stderr=$stderr")
    } elseif ($ExpectedExit -ne 0 -and ($stdout.Count -ne 0 -or $stderr -notmatch ("(?s)" + $OutputPattern))) {
        $failures.Add("$Name (el error no salio solo por stderr con patron '$OutputPattern'): stdout=$($stdout -join ' | '); stderr=$stderr")
    }
}

try {
    New-Item -ItemType Directory -Path $temporary | Out-Null

    foreach ($fixture in @('producto2', 'escalar', 'identidad', 'cero', 'impar3')) {
        $expected = Join-Path $fixtures "$fixture.expected.txt"
        Invoke-Comparator -Expected $expected -Actual @($expected) -ExpectedExit 0 -Name "fixture $fixture"
    }

    $reference = Join-Path $temporary 'reference.txt'
    $withinTolerance = Join-Path $temporary 'within.txt'
    $outsideTolerance = Join-Path $temporary 'outside.txt'
    $wrongDimension = Join-Path $temporary 'dimension.txt'
    $notFinite = Join-Path $temporary 'nan.txt'
    $badRows = Join-Path $temporary 'rows.txt'
    $validCRLF = Join-Path $temporary 'valid-crlf.txt'
    $bom = Join-Path $temporary 'bom.txt'
    $nul = Join-Path $temporary 'nul.txt'
    $invalidUtf8 = Join-Path $temporary 'invalid-utf8.txt'
    $isolatedCR = Join-Path $temporary 'isolated-cr.txt'
    $empty = Join-Path $temporary 'empty.txt'
    $infinity = Join-Path $temporary 'infinity.txt'
    $internalBlank = Join-Path $temporary 'internal-blank.txt'
    $extraRow = Join-Path $temporary 'extra-row.txt'
    $missing = Join-Path $temporary 'missing.txt'
    [IO.File]::WriteAllText($reference, "1`n1`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($withinTolerance, "1`n1.0000000015`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($outsideTolerance, "1`n1.0000000021`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($wrongDimension, "2`n1 0`n0 1`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($notFinite, "1`nNaN`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($badRows, "2`n1 2 3`n4 5`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($validCRLF, "1`r`n `t1.0  ", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($bom, "1`n1`n", [Text.UTF8Encoding]::new($true))
    [IO.File]::WriteAllText($nul, "1`n1`0`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllBytes($invalidUtf8, [byte[]](0x31, 0x0A, 0xC3, 0x28))
    [IO.File]::WriteAllText($isolatedCR, "1`r1", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($empty, '', [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($infinity, "1`nInfinity`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($internalBlank, "3`n1 2 3`n`n4 5 6`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($extraRow, "1`n1`n2`n", [Text.UTF8Encoding]::new($false))

    Invoke-Comparator -Expected $reference -Actual @($withinTolerance) -ExpectedExit 0 -Name 'doble tolerancia acepta limite' -OutputPattern '^OK:.*max_abs=.*max_rel='
    Invoke-Comparator -Expected $reference -Actual @($outsideTolerance) -ExpectedExit 1 -Name 'doble tolerancia rechaza diferencia' -OutputPattern 'ERROR:.*primera diferencia=.*max_abs=.*max_rel='
    Invoke-Comparator -Expected $reference -Actual @($wrongDimension) -ExpectedExit 1 -Name 'dimension diferente' -OutputPattern 'ERROR:.*Dimension\s+obtenida'
    Invoke-Comparator -Expected $reference -Actual @($notFinite) -ExpectedExit 1 -Name 'NaN rechazado' -OutputPattern 'ERROR:.*Valor invalido'
    Invoke-Comparator -Expected $reference -Actual @($badRows) -ExpectedExit 1 -Name 'cantidad por fila' -OutputPattern 'ERROR:.*contiene\s+3\s+valores'
    Invoke-Comparator -Expected $reference -Actual @($validCRLF) -ExpectedExit 0 -Name 'CRLF espacios y sin salto final' -OutputPattern '^OK:'
    Invoke-Comparator -Expected $reference -Actual @($bom) -ExpectedExit 1 -Name 'BOM rechazado' -OutputPattern 'ERROR:.*BOM UTF-8'
    Invoke-Comparator -Expected $reference -Actual @($nul) -ExpectedExit 1 -Name 'NUL rechazado' -OutputPattern 'ERROR:.*NUL'
    Invoke-Comparator -Expected $reference -Actual @($invalidUtf8) -ExpectedExit 1 -Name 'UTF-8 invalido' -OutputPattern 'ERROR:.*UTF-8 valido'
    Invoke-Comparator -Expected $reference -Actual @($isolatedCR) -ExpectedExit 1 -Name 'CR aislado' -OutputPattern 'ERROR:.*CR aislado'
    Invoke-Comparator -Expected $reference -Actual @($empty) -ExpectedExit 1 -Name 'archivo vacio' -OutputPattern 'ERROR:.*esta\s+vacio'
    Invoke-Comparator -Expected $reference -Actual @($infinity) -ExpectedExit 1 -Name 'infinito rechazado' -OutputPattern 'ERROR:.*Valor invalido'
    Invoke-Comparator -Expected $reference -Actual @($internalBlank) -ExpectedExit 1 -Name 'linea interna vacia' -OutputPattern 'ERROR:.*Fila vacia'
    Invoke-Comparator -Expected $reference -Actual @($extraRow) -ExpectedExit 1 -Name 'fila sobrante' -OutputPattern 'ERROR:.*esperaban\s+1\s+filas'
    Invoke-Comparator -Expected $reference -Actual @($missing) -ExpectedExit 1 -Name 'archivo inexistente' -OutputPattern 'ERROR:.*No\s+existe\s+el\s+archivo'
} finally {
    if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Recurse -Force
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { [Console]::Error.WriteLine("ERROR: $failure") }
    exit 1
}
Write-Output 'OK: compare_results.ps1 (5 fixtures, tolerancia y formato estricto).'
exit 0
