$script:CsvHeader = @(
    'timestamp','version','commit','hostname','cpu_model','ram_gb',
    'os_version','configuration','n','seed','processes','threads',
    'observed_threads','workers','gomaxprocs','repetition','is_warmup',
    'kernel_s','total_s','validation_status'
)

# ---------------------------------------------------------------------------
#  Validate-CsvRow: parse one CSV data row and enforce protocol constraints
#   Returns a hashtable with column values or $null on error.
# ---------------------------------------------------------------------------
function Validate-CsvRow {
    param(
        [string]$HeaderLine,
        [string]$DataLine,
        [string]$ExpectedVersion,
        [int]$ExpectedN,
        [uint32]$ExpectedSeed,
        [int]$ExpectedRepetition
    )

    # Parse header
    $headers = $HeaderLine -split ','
    if ($headers.Count -ne 20) {
        [Console]::Error.WriteLine("ERROR: cabecera CSV tiene $($headers.Count) campos, se esperaban 20.")
        return $null
    }
    for ($i = 0; $i -lt 20; $i++) {
        $got = $headers[$i].Trim('"').Trim()
        $want = $script:CsvHeader[$i]
        if ($got -ne $want) {
            [Console]::Error.WriteLine("ERROR: campo $i de cabecera es '$got', se esperaba '$want'.")
            return $null
        }
    }

    # Parse data row — handle quoted fields
    $fields = @()
    $current = ''
    $inQuote = $false
    for ($ci = 0; $ci -lt $DataLine.Length; $ci++) {
        $ch = $DataLine[$ci]
        if ($inQuote) {
            if ($ch -eq '"') {
                if ($ci + 1 -lt $DataLine.Length -and $DataLine[$ci + 1] -eq '"') {
                    $current += '"'
                    $ci++
                } else {
                    $inQuote = $false
                }
            } else {
                $current += $ch
            }
        } else {
            if ($ch -eq '"') {
                $inQuote = $true
            } elseif ($ch -eq ',') {
                $fields += $current
                $current = ''
            } else {
                $current += $ch
            }
        }
    }
    $fields += $current

    if ($fields.Count -ne 20) {
        [Console]::Error.WriteLine("ERROR: fila CSV tiene $($fields.Count) campos, se esperaban 20.")
        return $null
    }

    $row = @{}
    for ($i = 0; $i -lt 20; $i++) {
        $row[$script:CsvHeader[$i]] = $fields[$i]
    }

    # Validate version
    if ($row['version'] -ne $ExpectedVersion) {
        [Console]::Error.WriteLine("ERROR: version='$($row['version'])', se esperaba '$ExpectedVersion'.")
        return $null
    }

    # Validate N
    if ([int]$row['n'] -ne $ExpectedN) {
        [Console]::Error.WriteLine("ERROR: n=$($row['n']), se esperaba $ExpectedN.")
        return $null
    }

    # Validate seed
    if ([uint32]$row['seed'] -ne $ExpectedSeed) {
        [Console]::Error.WriteLine("ERROR: seed=$($row['seed']), se esperaba $ExpectedSeed.")
        return $null
    }

    # Validate repetition
    if ([int]$row['repetition'] -ne $ExpectedRepetition) {
        [Console]::Error.WriteLine("ERROR: repetition=$($row['repetition']), se esperaba $ExpectedRepetition.")
        return $null
    }

    # Validate is_warmup consistency with repetition
    $expectedWarmup = if ($ExpectedRepetition -eq 0) { 'true' } else { 'false' }
    if ($row['is_warmup'] -ne $expectedWarmup) {
        [Console]::Error.WriteLine("ERROR: is_warmup='$($row['is_warmup'])', se esperaba '$expectedWarmup' para repetition=$ExpectedRepetition.")
        return $null
    }

    # Validate validation_status
    if ($row['validation_status'] -ne 'OK') {
        [Console]::Error.WriteLine("ERROR: validation_status='$($row['validation_status'])', se requiere 'OK'.")
        return $null
    }

    # Validate kernel_s and total_s (PS 5.1 compatible — no [double]::IsFinite)
    $kernelS = [double]$row['kernel_s']
    $totalS  = [double]$row['total_s']

    if ([double]::IsNaN($kernelS) -or [double]::IsInfinity($kernelS) -or $kernelS -lt 0.0) {
        [Console]::Error.WriteLine("ERROR: kernel_s=$kernelS invalido (no finito o negativo).")
        return $null
    }
    if ([double]::IsNaN($totalS) -or [double]::IsInfinity($totalS) -or $totalS -lt 0.0) {
        [Console]::Error.WriteLine("ERROR: total_s=$totalS invalido (no finito o negativo).")
        return $null
    }
    if ($kernelS -gt $totalS) {
        [Console]::Error.WriteLine("ERROR: kernel_s ($kernelS) > total_s ($totalS) — viola protocolo.")
        return $null
    }

    return $row
}

# ---------------------------------------------------------------------------
#  Run-CSecuencial: executes the c_secuencial binary for one (N, seed, rep)
#   Returns validated row hashtable or $null on error.
# ---------------------------------------------------------------------------
function Run-CSecuencial {
    param(
        [int]$MatrixN,
        [uint32]$MatrixSeed,
        [int]$RepIndex   # 0 = warmup, 1..5 = measured
    )

    $exe = Join-Path $script:ProjectRoot 'c_secuencial\build\Release\c_secuencial.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
        [Console]::Error.WriteLine("ERROR: no se encontro el binario Release: $exe")
        [Console]::Error.WriteLine("       Compile primero con: scripts\build_windows.ps1 -Version c_secuencial -Configuration Release")
        return $null
    }

    $isWarmup = ($RepIndex -eq 0)
    $label = if ($isWarmup) { "warmup" } else { "rep $RepIndex" }
    [Console]::Error.WriteLine("[c_secuencial] N=$MatrixN seed=$MatrixSeed $label — ejecutando...")

    # Run the binary and capture stdout/stderr separately
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $exe
    $psi.Arguments = "--n $MatrixN --seed $MatrixSeed --repetition $RepIndex"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi

    try {
        if (-not $proc.Start()) {
            [Console]::Error.WriteLine("ERROR: no se pudo iniciar el proceso c_secuencial.")
            return $null
        }
    } catch {
        [Console]::Error.WriteLine("ERROR: excepcion al iniciar c_secuencial: $_")
        return $null
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    $proc.Dispose()

    # Report stderr (diagnostic info from the binary)
    if ($stderr) {
        foreach ($errLine in ($stderr -split "`n")) {
            $trimmed = $errLine.TrimEnd("`r")
            if ($trimmed) {
                [Console]::Error.WriteLine("  [c_secuencial stderr] $trimmed")
            }
        }
    }

    # Check exit code
    if ($exitCode -eq 2) {
        [Console]::Error.WriteLine("ERROR: c_secuencial devolvio codigo 2 (operacion pendiente). N=$MatrixN rep=$RepIndex")
        return $null
    }
    if ($exitCode -ne 0) {
        [Console]::Error.WriteLine("ERROR: c_secuencial devolvio codigo $exitCode. N=$MatrixN rep=$RepIndex")
        return $null
    }

    # Parse stdout lines (header + data)
    $lines = @($stdout -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_.Length -gt 0 })
    if ($lines.Count -lt 2) {
        [Console]::Error.WriteLine("ERROR: stdout de c_secuencial tiene $($lines.Count) linea(s), se esperaban al menos 2 (cabecera + datos).")
        return $null
    }

    $row = Validate-CsvRow `
        -HeaderLine $lines[0] `
        -DataLine $lines[1] `
        -ExpectedVersion 'c_secuencial' `
        -ExpectedN $MatrixN `
        -ExpectedSeed $MatrixSeed `
        -ExpectedRepetition $RepIndex

    if (-not $row) {
        [Console]::Error.WriteLine("ERROR: la fila CSV de c_secuencial no paso la validacion. N=$MatrixN rep=$RepIndex")
        return $null
    }

    # Validate c_secuencial-specific fields
    # NOTE: the binary emits PROJECT_CONFIGURATION (build config, e.g. "Release")
    # in the configuration field. Per contrato.md §4.1 the canonical value must be
    # "c_secuencial". We override it here to comply with the 20-field CSV contract
    # without modifying the source code (out of scope for I1).
    if ($row['configuration'] -ne 'c_secuencial') {
        [Console]::Error.WriteLine("  [c_secuencial] AVISO: configuration='$($row['configuration'])' del binario; se reemplaza por 'c_secuencial' segun contrato.")
        $row['configuration'] = 'c_secuencial'
    }
    if ($row['processes'] -ne '1' -or $row['threads'] -ne '1') {
        [Console]::Error.WriteLine("ERROR: c_secuencial debe reportar processes=1, threads=1.")
        return $null
    }

    # Per contrato.md §4, gomaxprocs must be empty in C versions. The binary
    # currently emits "1" as a placeholder; we clear it here.
    if ($row['gomaxprocs'] -ne '') {
        $row['gomaxprocs'] = ''
    }

    [Console]::Error.WriteLine("  [c_secuencial] OK — kernel_s=$($row['kernel_s']) total_s=$($row['total_s'])")
    return $row
}

# ---------------------------------------------------------------------------
#  Invoke-CSecuencialCampaign: full measurement campaign for c_secuencial
#   Respects protocol: warmup (rep 0) + 5 measured repetitions (rep 1..5)
#   per each dimension N, with seed=42.
# ---------------------------------------------------------------------------
function Invoke-CSecuencialCampaign {
    param(
        [int[]]$Dimensions,
        [uint32]$CampaignSeed,
        [int]$MeasuredReps
    )

    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("========== CAMPANA c_secuencial ==========")
    [Console]::Error.WriteLine("  Dimensiones : $($Dimensions -join ', ')")
    [Console]::Error.WriteLine("  Semilla     : $CampaignSeed")
    [Console]::Error.WriteLine("  Repeticiones: 1 warmup + $MeasuredReps medidas")
    [Console]::Error.WriteLine("===========================================")
    [Console]::Error.WriteLine("")

    $allRows = [System.Collections.Generic.List[hashtable]]::new()
    $headerWritten = $false
    $totalRuns = $Dimensions.Count * (1 + $MeasuredReps)
    $runCount = 0

    foreach ($dim in $Dimensions) {
        # Warmup (repetition 0)
        $runCount++
        [Console]::Error.WriteLine("--- [$runCount/$totalRuns] Warmup N=$dim ---")
        $warmupRow = Run-CSecuencial -MatrixN $dim -MatrixSeed $CampaignSeed -RepIndex 0
        if (-not $warmupRow) {
            [Console]::Error.WriteLine("FATAL: warmup fallido para N=$dim. Se detiene la campana c_secuencial.")
            return $null
        }

        # Write header once to stdout
        if (-not $headerWritten) {
            [Console]::Out.WriteLine(($script:CsvHeader -join ','))
            $headerWritten = $true
        }

        # Write warmup row (re-quote fields that contain commas, quotes, or newlines)
        $csvLine = ($script:CsvHeader | ForEach-Object {
            $v = $warmupRow[$_]
            if ($v -match '[,"\r\n]') { '"' + ($v -replace '"','""') + '"' } else { $v }
        }) -join ','
        [Console]::Out.WriteLine($csvLine)
        $allRows.Add($warmupRow)

        # Measured repetitions 1..5
        for ($rep = 1; $rep -le $MeasuredReps; $rep++) {
            $runCount++
            [Console]::Error.WriteLine("--- [$runCount/$totalRuns] Medicion N=$dim rep=$rep ---")
            $measuredRow = Run-CSecuencial -MatrixN $dim -MatrixSeed $CampaignSeed -RepIndex $rep
            if (-not $measuredRow) {
                [Console]::Error.WriteLine("FATAL: medicion fallida para N=$dim rep=$rep. Se detiene la campana c_secuencial.")
                return $null
            }

            $csvLine = ($script:CsvHeader | ForEach-Object {
                $v = $measuredRow[$_]
                if ($v -match '[,"\r\n]') { '"' + ($v -replace '"','""') + '"' } else { $v }
            }) -join ','
            [Console]::Out.WriteLine($csvLine)
            $allRows.Add($measuredRow)
        }
    }

    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("========== c_secuencial COMPLETADO ==========")
    [Console]::Error.WriteLine("  Corridas exitosas: $($allRows.Count) / $totalRuns")
    [Console]::Error.WriteLine("===============================================")

    return $allRows
}

# ===========================================================================
