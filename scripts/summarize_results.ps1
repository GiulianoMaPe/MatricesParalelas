<#
.SYNOPSIS
    Procesa observaciones de medición (CSV de 20 columnas) y genera el resumen
    estadístico no paramétrico (medianas, cuartiles, IQR, min, max) y métricas
    de rendimiento (Speedup, Eficiencia, GFLOPS).

.DESCRIPTION
    Implementación del Sprint 7 para el Integrante 7 (Andrés).
    Cumple rigurosamente con los lineamientos de:
      - docs/contrato.md §4 (Esquema de 20 columnas RFC 4180)
      - docs/protocolo_medicion.md §6.3 (Mediana y Rango Intercuartílico IQR)
      - docs/protocolo_medicion.md §7 (Speedup S, Eficiencia E, GFLOPS)
      - docs/protocolo_medicion.md §8 (Estructura de resúmenes)

.PARAMETER InputObject
    Líneas de texto recibidas a través de la tubería (pipeline).

.PARAMETER InputPath
    Ruta a uno o varios archivos CSV de observaciones de entrada.

.PARAMETER OutputPath
    Ruta opcional donde escribir el archivo CSV de resumen estadístico (UTF-8 sin BOM).

.PARAMETER PassThru
    Si se especifica, emite los objetos de resumen a la tubería de PowerShell.

.EXAMPLE
    .\scripts\summarize_results.ps1 -InputPath resultados\piloto\mediciones.csv -OutputPath resultados\piloto\resumen_estadistico.csv

.EXAMPLE
    Get-Content resultados\piloto\mediciones.csv | .\scripts\summarize_results.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [string[]]$InputObject,

    [Alias('InputCsv', 'Path', 'File')]
    [string[]]$InputPath,

    [Alias('OutputCsv')]
    [string]$OutputPath,

    [switch]$PassThru
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $rawLines = New-Object System.Collections.Generic.List[string]

    # Esquema canónico de 20 columnas (docs/contrato.md §4)
    $script:ExpectedHeader = @(
        'timestamp','version','commit','hostname','cpu_model','ram_gb',
        'os_version','configuration','n','seed','processes','threads',
        'observed_threads','workers','gomaxprocs','repetition','is_warmup',
        'kernel_s','total_s','validation_status'
    )

    # Cabecera oficial del resumen estadístico
    $script:SummaryHeader = @(
        'version','configuration','n','seed','processes','threads','workers','gomaxprocs',
        'reps_count','status',
        'kernel_s_median','kernel_s_q1','kernel_s_q3','kernel_s_iqr','kernel_s_min','kernel_s_max',
        'total_s_median','total_s_q1','total_s_q3','total_s_iqr','total_s_min','total_s_max',
        'speedup','efficiency','gflops_kernel','gflops_total',
        'hostname','cpu_model','ram_gb','os_version','commit'
    )

    # Parser RFC 4180 compatible con PowerShell 5.1 y 7+
    function Parse-CsvLine {
        param([string]$Line)
        $fields = New-Object System.Collections.Generic.List[string]
        $sb = New-Object System.Text.StringBuilder
        $inQuotes = $false
        $len = $Line.Length

        for ($i = 0; $i -lt $len; $i++) {
            $c = $Line[$i]
            if ($inQuotes) {
                if ($c -eq '"') {
                    if ($i + 1 -lt $len -and $Line[$i + 1] -eq '"') {
                        [void]$sb.Append('"')
                        $i++
                    } else {
                        $inQuotes = $false
                    }
                } else {
                    [void]$sb.Append($c)
                }
            } else {
                if ($c -eq '"') {
                    $inQuotes = $true
                } elseif ($c -eq ',') {
                    $fields.Add($sb.ToString())
                    $sb.Length = 0
                } else {
                    [void]$sb.Append($c)
                }
            }
        }
        $fields.Add($sb.ToString())
        return $fields.ToArray()
    }

    # Formateador RFC 4180
    function Format-CsvField {
        param([string]$Field)
        if ($null -eq $Field) { return '' }
        if ($Field.Contains(',') -or $Field.Contains('"') -or $Field.Contains("`n") -or $Field.Contains("`r")) {
            return '"' + $Field.Replace('"', '""') + '"'
        }
        return $Field
    }
}

process {
    if ($null -ne $InputObject) {
        foreach ($line in $InputObject) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $rawLines.Add($line)
            }
        }
    }
}

end {
    # 1. Cargar archivos si se especificaron por parámetro
    if ($null -ne $InputPath -and $InputPath.Count -gt 0) {
        foreach ($p in $InputPath) {
            if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
                throw "El archivo especificado no existe: $p"
            }
            $fileLines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p).Path)
            foreach ($fl in $fileLines) {
                if (-not [string]::IsNullOrWhiteSpace($fl)) {
                    $rawLines.Add($fl)
                }
            }
        }
    }

    if ($rawLines.Count -eq 0) {
        # Si no se pasó entrada, intentar buscar resultados/piloto/mediciones.csv por defecto
        $defaultCsv = Join-Path (Split-Path -Parent $PSScriptRoot) 'resultados\piloto\mediciones.csv'
        if (Test-Path -LiteralPath $defaultCsv -PathType Leaf) {
            $fileLines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $defaultCsv).Path)
            foreach ($fl in $fileLines) {
                if (-not [string]::IsNullOrWhiteSpace($fl)) {
                    $rawLines.Add($fl)
                }
            }
        } else {
            throw "No se proporcionaron observaciones para procesar. Especifique -InputPath <archivo.csv> o entregue datos mediante la tuberia."
        }
    }

    # 2. Parsear líneas e identificar cabecera
    $parsedRows = New-Object System.Collections.Generic.List[psobject]
    $headerMap = @{}
    $headerFound = $false

    foreach ($line in $rawLines) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith('#')) { continue } # Comentarios permitidos

        $fields = Parse-CsvLine -Line $trimmed
        if ($fields.Length -lt 20) { continue }

        # Detectar cabecera
        if (-not $headerFound -and $fields[0] -eq 'timestamp' -and $fields[1] -eq 'version') {
            for ($h = 0; $h -lt $fields.Length; $h++) {
                $colName = $fields[$h].Trim().ToLowerInvariant()
                $headerMap[$colName] = $h
            }
            # Validar que contenga las 20 columnas del contrato
            foreach ($expected in $script:ExpectedHeader) {
                if (-not $headerMap.ContainsKey($expected)) {
                    throw "La cabecera no contiene la columna requerida por contrato: $expected"
                }
            }
            $headerFound = $true
            continue
        }

        # Si ya se encontró la cabecera y encontramos otra fila con "timestamp,version...", ignorarla
        if ($fields[0] -eq 'timestamp' -and $fields[1] -eq 'version') {
            continue
        }

        if (-not $headerFound) {
            # Asumir cabecera canónica si los datos no traen fila de cabecera explícita
            for ($h = 0; $h -lt $script:ExpectedHeader.Length; $h++) {
                $headerMap[$script:ExpectedHeader[$h]] = $h
            }
            $headerFound = $true
        }

        # Extraer fila mapeada
        $rowObj = [ordered]@{}
        foreach ($col in $script:ExpectedHeader) {
            $idx = $headerMap[$col]
            $rowObj[$col] = if ($idx -lt $fields.Length) { $fields[$idx].Trim() } else { '' }
        }
        $parsedRows.Add([pscustomobject]$rowObj)
    }

    if ($parsedRows.Count -eq 0) {
        [Console]::Error.WriteLine("ADVERTENCIA: No se encontraron filas de datos validas.")
        return
    }

    # 3. Filtrar observaciones segun protocolo de medicion §6.1 y §6.3:
    #    - Descartar precalentamiento (is_warmup == true o repetition == 0)
    #    - Conservar unicamentes filas con validacion OK
    $validObservations = New-Object System.Collections.Generic.List[psobject]
    foreach ($r in $parsedRows) {
        $isWarmup = ($r.is_warmup.ToLowerInvariant() -eq 'true') -or ($r.repetition -eq '0')
        if ($isWarmup) { continue } # Excluir calentamiento de las estadisticas

        if ($r.validation_status -ne 'OK') {
            # Corridas fallidas no entran a las estadisticas de tiempo (protocolo §3.3 y §4.1)
            continue
        }

        $kParsed = 0.0
        $tParsed = 0.0
        $kOk = [double]::TryParse($r.kernel_s, [System.Globalization.NumberStyles]::Float, $culture, [ref]$kParsed)
        $tOk = [double]::TryParse($r.total_s, [System.Globalization.NumberStyles]::Float, $culture, [ref]$tParsed)

        if (-not $kOk -or -not $tOk -or $kParsed -lt 0.0 -or $tParsed -lt 0.0 -or $kParsed -gt $tParsed) {
            # Valores no validos o incoherentes
            continue
        }

        $validObservations.Add($r)
    }

    # 4. Agrupar por clave canónica (campaña / host / commit / version / configuration / N / seed)
    $groups = @{}
    foreach ($obs in $validObservations) {
        $groupKey = "$($obs.hostname)|$($obs.commit)|$($obs.version)|$($obs.configuration)|$($obs.n)|$($obs.seed)"
        if (-not $groups.ContainsKey($groupKey)) {
            $groups[$groupKey] = New-Object System.Collections.Generic.List[psobject]
        }
        $groups[$groupKey].Add($obs)
    }

    # 5. Calcular estadísticas no paramétricas por grupo (docs/protocolo_medicion.md §6.3)
    #    Para 5 repeticiones ordenadas x1 <= x2 <= x3 <= x4 <= x5:
    #      mediana = x3, Q1 = x2, Q3 = x4, IQR = x4 - x2, min = x1, max = x5
    $summaryGroups = New-Object System.Collections.Generic.List[psobject]

    foreach ($key in $groups.Keys) {
        $items = $groups[$key]
        $first = $items[0]

        $nVal = [int]$first.n
        $seedVal = [uint32]$first.seed
        $procVal = if ([string]::IsNullOrEmpty($first.processes)) { 1 } else { [int]$first.processes }
        $thVal = if ([string]::IsNullOrEmpty($first.threads)) { 1 } else { [int]$first.threads }
        $workVal = if ([string]::IsNullOrEmpty($first.workers)) { 1 } else { [int]$first.workers }
        $gomaxVal = $first.gomaxprocs

        # Extraer y ordenar duraciones
        $kList = New-Object System.Collections.Generic.List[double]
        $tList = New-Object System.Collections.Generic.List[double]
        foreach ($it in $items) {
            $kList.Add([double]::Parse($it.kernel_s, $culture))
            $tList.Add([double]::Parse($it.total_s, $culture))
        }
        $kList.Sort()
        $tList.Sort()

        $repsCount = $items.Count
        $isComplete = ($repsCount -eq 5)
        $statusStr = if ($isComplete) { 'COMPLETE' } else { 'INCOMPLETE' }

        # Estadísticas no paramétricas
        $kMed = 0.0; $kQ1 = 0.0; $kQ3 = 0.0; $kIqr = 0.0; $kMin = 0.0; $kMax = 0.0
        $tMed = 0.0; $tQ1 = 0.0; $tQ3 = 0.0; $tIqr = 0.0; $tMin = 0.0; $tMax = 0.0

        if ($repsCount -eq 5) {
            # Regla estricta del protocolo para 5 observaciones
            $kMin = $kList[0]; $kQ1 = $kList[1]; $kMed = $kList[2]; $kQ3 = $kList[3]; $kMax = $kList[4]
            $kIqr = $kQ3 - $kQ1

            $tMin = $tList[0]; $tQ1 = $tList[1]; $tMed = $tList[2]; $tQ3 = $tList[3]; $tMax = $tList[4]
            $tIqr = $tQ3 - $tQ1
        } elseif ($repsCount -gt 0) {
            # Cálculo de contingencia para grupos con distinta cantidad
            $kMin = $kList[0]; $kMax = $kList[$repsCount - 1]
            $tMin = $tList[0]; $tMax = $tList[$repsCount - 1]

            $mid = [int]($repsCount / 2)
            if ($repsCount % 2 -eq 1) {
                $kMed = $kList[$mid]
                $tMed = $tList[$mid]
            } else {
                $kMed = ($kList[$mid - 1] + $kList[$mid]) / 2.0
                $tMed = ($tList[$mid - 1] + $tList[$mid]) / 2.0
            }
            $kQ1 = $kMin; $kQ3 = $kMax; $kIqr = $kQ3 - $kQ1
            $tQ1 = $tMin; $tQ3 = $tMax; $tIqr = $tQ3 - $tQ1
        }

        $groupObj = [ordered]@{
            version          = $first.version
            configuration    = $first.configuration
            n                = $nVal
            seed             = $seedVal
            processes        = $procVal
            threads          = $thVal
            workers          = $workVal
            gomaxprocs       = $gomaxVal
            reps_count       = $repsCount
            status           = $statusStr
            kernel_s_median  = $kMed
            kernel_s_q1      = $kQ1
            kernel_s_q3      = $kQ3
            kernel_s_iqr     = $kIqr
            kernel_s_min     = $kMin
            kernel_s_max     = $kMax
            total_s_median   = $tMed
            total_s_q1       = $tQ1
            total_s_q3       = $tQ3
            total_s_iqr      = $tIqr
            total_s_min      = $tMin
            total_s_max      = $tMax
            speedup          = $null
            efficiency       = $null
            gflops_kernel    = $null
            gflops_total     = $null
            hostname         = $first.hostname
            cpu_model        = $first.cpu_model
            ram_gb           = $first.ram_gb
            os_version       = $first.os_version
            commit           = $first.commit
        }
        $summaryGroups.Add([pscustomobject]$groupObj)
    }

    # 6. Crear índice de referencias secuenciales para Speedup y Eficiencia (§7.1 y §7.2)
    #    Referencia C:   c_secuencial con mismo hostname, commit, N, seed
    #    Referencia Go:  go_secuencial con mismo hostname, commit, N, seed
    $secLookup = @{}
    foreach ($sg in $summaryGroups) {
        if ($sg.version -in @('c_secuencial', 'go_secuencial') -and $sg.status -eq 'COMPLETE' -and $sg.total_s_median -gt 0.0) {
            $secKey = "$($sg.hostname)|$($sg.commit)|$($sg.version)|$($sg.n)|$($sg.seed)"
            $secLookup[$secKey] = $sg
        }
    }

    # 7. Calcular Speedup, Eficiencia y GFLOPS
    foreach ($sg in $summaryGroups) {
        $nVal = [double]$sg.n
        # GFLOPS aritmético estimado: 2 * N^3 / (mediana * 1e9) (§7.3)
        if ($sg.status -eq 'COMPLETE' -and $sg.kernel_s_median -gt 0.0) {
            $flops = 2.0 * [Math]::Pow($nVal, 3)
            $sg.gflops_kernel = $flops / ($sg.kernel_s_median * 1.0e9)
        }
        if ($sg.status -eq 'COMPLETE' -and $sg.total_s_median -gt 0.0) {
            $flops = 2.0 * [Math]::Pow($nVal, 3)
            $sg.gflops_total = $flops / ($sg.total_s_median * 1.0e9)
        }

        # Speedup y Eficiencia
        if ($sg.version -in @('c_secuencial', 'go_secuencial')) {
            if ($sg.status -eq 'COMPLETE') {
                $sg.speedup = 1.0
                $sg.efficiency = 1.0
            }
        } elseif ($sg.version -eq 'c_paralelo') {
            $secKey = "$($sg.hostname)|$($sg.commit)|c_secuencial|$($sg.n)|$($sg.seed)"
            if ($sg.status -eq 'COMPLETE' -and $secLookup.ContainsKey($secKey)) {
                $base = $secLookup[$secKey]
                if ($sg.total_s_median -gt 0.0) {
                    $sVal = $base.total_s_median / $sg.total_s_median
                    $sg.speedup = $sVal
                    $nominalWorkers = [Math]::Max(1, ($sg.processes * $sg.threads))
                    $sg.efficiency = $sVal / [double]$nominalWorkers
                }
            }
        } elseif ($sg.version -eq 'go_paralelo') {
            $secKey = "$($sg.hostname)|$($sg.commit)|go_secuencial|$($sg.n)|$($sg.seed)"
            if ($sg.status -eq 'COMPLETE' -and $secLookup.ContainsKey($secKey)) {
                $base = $secLookup[$secKey]
                if ($sg.total_s_median -gt 0.0) {
                    $sVal = $base.total_s_median / $sg.total_s_median
                    $sg.speedup = $sVal
                    $nominalWorkers = [Math]::Max(1, $sg.workers)
                    $sg.efficiency = $sVal / [double]$nominalWorkers
                }
            }
        }
    }

    # 8. Ordenar grupos de salida canónicamente (version, n, configuration)
    $sortedSummary = $summaryGroups | Sort-Object -Property version, n, configuration

    # 9. Construir líneas CSV de salida
    $outCsvLines = New-Object System.Collections.Generic.List[string]
    $outCsvLines.Add(($script:SummaryHeader -join ','))

    foreach ($item in $sortedSummary) {
        $rowFields = New-Object System.Collections.Generic.List[string]
        foreach ($col in $script:SummaryHeader) {
            $val = $item.$col
            $strVal = ''
            if ($null -ne $val) {
                if ($val -is [double] -or $val -is [float]) {
                    if ($col.StartsWith('kernel_s_') -or $col.StartsWith('total_s_')) {
                        $strVal = ([double]$val).ToString('F9', $culture)
                    } elseif ($col -eq 'speedup' -or $col -eq 'efficiency') {
                        $strVal = ([double]$val).ToString('F6', $culture)
                    } elseif ($col.StartsWith('gflops_')) {
                        $strVal = ([double]$val).ToString('F6', $culture)
                    } else {
                        $strVal = ([double]$val).ToString('G', $culture)
                    }
                } else {
                    $strVal = [string]$val
                }
            }
            $rowFields.Add((Format-CsvField -Field $strVal))
        }
        $outCsvLines.Add(($rowFields -join ','))
    }

    # 10. Escribir en archivo o emitir a stdout
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $outFull = [System.IO.Path]::GetFullPath($OutputPath)
        $outDir = [System.IO.Path]::GetDirectoryName($outFull)
        if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path -LiteralPath $outDir)) {
            [void](New-Item -ItemType Directory -Path $outDir -Force)
        }
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllLines($outFull, $outCsvLines, $utf8NoBom)
    } elseif (-not $PassThru) {
        foreach ($l in $outCsvLines) {
            [Console]::Out.WriteLine($l)
        }
    }

    if ($PassThru) {
        return $sortedSummary
    }
}
