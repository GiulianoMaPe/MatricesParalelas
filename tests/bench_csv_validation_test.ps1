$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\bench_windows.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw "bench_windows.ps1 no parsea: $($parseErrors[0])" }

$functionAst = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Validate-CsvRow' }, $true)
if (-not $functionAst) { throw 'No se encontró Validate-CsvRow.' }
. ([scriptblock]::Create($functionAst.Extent.Text))

$script:CsvHeader = @(
    'timestamp','version','commit','hostname','cpu_model','ram_gb',
    'os_version','configuration','n','seed','processes','threads',
    'observed_threads','workers','gomaxprocs','repetition','is_warmup',
    'kernel_s','total_s','validation_status'
)

$fields = @('2026-11-12T16:16:08Z','c_secuencial','abcdef0123456','HOST','CPU model','16.0',
    'Windows 11','c_secuencial','256','42','1','1','1','1','','0','true','0.002','0.003','OK')
$validLine = $fields -join ','
$valid = Validate-CsvRow -HeaderLine ($script:CsvHeader -join ',') -DataLine $validLine `
    -ExpectedVersion 'c_secuencial' -ExpectedN 256 -ExpectedSeed 42 -ExpectedRepetition 0
if (-not $valid) { throw 'Fila válida rechazada.' }

$malformedQuote = $validLine.Replace(',HOST,', ',HOST"x,')
if (Validate-CsvRow -HeaderLine ($script:CsvHeader -join ',') -DataLine $malformedQuote `
    -ExpectedVersion 'c_secuencial' -ExpectedN 256 -ExpectedSeed 42 -ExpectedRepetition 0) {
    throw 'Se aceptó una comilla fuera de lugar.'
}

$invalidTimestamp = $validLine.Replace('2026-11-12T16:16:08Z', '2026-02-30T16:16:08Z')
if (Validate-CsvRow -HeaderLine ($script:CsvHeader -join ',') -DataLine $invalidTimestamp `
    -ExpectedVersion 'c_secuencial' -ExpectedN 256 -ExpectedSeed 42 -ExpectedRepetition 0) {
    throw 'Se aceptó un timestamp inexistente.'
}

$invalidDecimal = $validLine.Replace(',16.0,', ',"16,0",')
if (Validate-CsvRow -HeaderLine ($script:CsvHeader -join ',') -DataLine $invalidDecimal `
    -ExpectedVersion 'c_secuencial' -ExpectedN 256 -ExpectedSeed 42 -ExpectedRepetition 0) {
    throw 'Se aceptó una fila con separador decimal incorrecto.'
}

Write-Output 'CSV validation tests: PASS (valid row accepted; malformed quote, invalid date and decimal rejected).'
