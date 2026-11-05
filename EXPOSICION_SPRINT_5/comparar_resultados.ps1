param(
    [Parameter(Mandatory = $true)][string]$Expected,
    [Parameter(Mandatory = $true)][string]$Actual
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$numberStyle = [System.Globalization.NumberStyles]::Float
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$absoluteTolerance = 1e-9
$relativeTolerance = 1e-9

function Read-MatrixResult {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "No existe el archivo: $Path"
    }

    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "El archivo contiene BOM UTF-8: $Path"
    }
    if ($bytes -contains 0) {
        throw "El archivo contiene NUL: $Path"
    }

    try {
        $text = $utf8.GetString($bytes)
    } catch {
        throw "El archivo no es UTF-8 valido: $Path"
    }
    if ($text.Contains("`r") -and [regex]::IsMatch($text, "`r(?!`n)")) {
        throw "El archivo contiene CR aislado: $Path"
    }

    $lines = @($text.Replace("`r`n", "`n").Split("`n"))
    while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -match '^[\t ]*$') {
        if ($lines.Count -eq 1) { $lines = @(); break }
        $lines = @($lines[0..($lines.Count - 2)])
    }
    if ($lines.Count -eq 0) {
        throw "El archivo esta vacio: $Path"
    }
    if ($lines[0] -notmatch '^[1-9][0-9]*$') {
        throw "Dimension invalida en la primera linea: $Path"
    }

    [int]$dimension = 0
    if (-not [int]::TryParse($lines[0], [System.Globalization.NumberStyles]::None, $culture, [ref]$dimension)) {
        throw "Dimension fuera de rango: $Path"
    }
    if ($lines.Count -ne $dimension + 1) {
        throw "Se esperaban $dimension filas de datos y se encontraron $($lines.Count - 1): $Path"
    }

    $values = New-Object 'System.Collections.Generic.List[double]'
    $decimalPattern = '^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$'
    for ($row = 0; $row -lt $dimension; $row++) {
        $line = $lines[$row + 1]
        if ($line -match '^[\t ]*$') {
            throw "Fila vacia en la fila $($row + 1): $Path"
        }
        $tokens = @([regex]::Split($line.Trim(' ', "`t"), '[\t ]+'))
        if ($tokens.Count -ne $dimension) {
            throw "La fila $($row + 1) contiene $($tokens.Count) valores; se esperaban ${dimension}: $Path"
        }
        for ($column = 0; $column -lt $dimension; $column++) {
            $token = $tokens[$column]
            [double]$value = 0.0
            if ($token -notmatch $decimalPattern -or
                -not [double]::TryParse($token, $numberStyle, $culture, [ref]$value) -or
                [double]::IsNaN($value) -or [double]::IsInfinity($value)) {
                throw "Valor invalido en [$row,$column] ('$token'): $Path"
            }
            $values.Add($value)
        }
    }

    return [pscustomobject]@{
        Path = (Resolve-Path -LiteralPath $Path).Path
        Dimension = $dimension
        Values = $values.ToArray()
    }
}

function Compare-MatrixResult {
    param(
        [Parameter(Mandatory = $true)]$Reference,
        [Parameter(Mandatory = $true)]$Candidate,
        [double]$Atol,
        [double]$Rtol
    )

    if ($Candidate.Dimension -ne $Reference.Dimension) {
        throw "Dimension obtenida $($Candidate.Dimension), esperada $($Reference.Dimension)"
    }

    $maximumAbsoluteError = 0.0
    $maximumRelativeError = 0.0
    $firstMismatch = $null
    for ($index = 0; $index -lt $Reference.Values.Count; $index++) {
        $expectedValue = $Reference.Values[$index]
        $actualValue = $Candidate.Values[$index]
        $absoluteError = [Math]::Abs($actualValue - $expectedValue)
        if ($absoluteError -gt $maximumAbsoluteError) {
            $maximumAbsoluteError = $absoluteError
        }
        if ($expectedValue -ne 0.0) {
            $relativeError = $absoluteError / [Math]::Abs($expectedValue)
            if ($relativeError -gt $maximumRelativeError) {
                $maximumRelativeError = $relativeError
            }
        } elseif ($absoluteError -gt 0.0) {
            $maximumRelativeError = [double]::PositiveInfinity
        }
        $limit = $Atol + $Rtol * [Math]::Abs($expectedValue)
        if ($null -eq $firstMismatch -and $absoluteError -gt $limit) {
            $firstMismatch = [pscustomobject]@{
                Row = [Math]::Floor($index / $Reference.Dimension)
                Column = $index % $Reference.Dimension
                Actual = $actualValue
                Expected = $expectedValue
                AbsoluteError = $absoluteError
                Limit = $limit
            }
        }
    }

    return [pscustomobject]@{
        IsMatch = $null -eq $firstMismatch
        MaximumAbsoluteError = $maximumAbsoluteError
        MaximumRelativeError = $maximumRelativeError
        FirstMismatch = $firstMismatch
    }
}

$failed = $false
try {
    $reference = Read-MatrixResult -Path $Expected
} catch {
    [Console]::Error.WriteLine("ERROR referencia: $($_.Exception.Message)")
    exit 1
}

foreach ($candidatePath in @($Actual)) {
    try {
        $candidate = Read-MatrixResult -Path $candidatePath
        $result = Compare-MatrixResult -Reference $reference -Candidate $candidate -Atol $absoluteTolerance -Rtol $relativeTolerance
        $label = [IO.Path]::GetFileName($candidate.Path)
        $maxAbsolute = $result.MaximumAbsoluteError.ToString('G17', $culture)
        $maxRelative = $result.MaximumRelativeError.ToString('G17', $culture)
        if ($result.IsMatch) {
            Write-Output "OK: $label; n=$($candidate.Dimension); elementos=$($candidate.Values.Count); max_abs=$maxAbsolute; max_rel=$maxRelative"
        } else {
            $mismatch = $result.FirstMismatch
            $actualText = $mismatch.Actual.ToString('G17', $culture)
            $expectedText = $mismatch.Expected.ToString('G17', $culture)
            $errorText = $mismatch.AbsoluteError.ToString('G17', $culture)
            $limitText = $mismatch.Limit.ToString('G17', $culture)
            [Console]::Error.WriteLine("ERROR: $label; primera diferencia=[$($mismatch.Row),$($mismatch.Column)]; obtenido=$actualText; esperado=$expectedText; error_abs=$errorText; limite=$limitText; max_abs=$maxAbsolute; max_rel=$maxRelative")
            $failed = $true
        }
    } catch {
        [Console]::Error.WriteLine("ERROR: $candidatePath; $($_.Exception.Message)")
        $failed = $true
    }
}

if ($failed) { exit 1 }
exit 0
