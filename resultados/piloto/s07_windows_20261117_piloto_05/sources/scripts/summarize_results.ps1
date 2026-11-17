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

    [string]$CampaignId,

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
        'campaign_id','version','configuration','n','seed','processes','threads','workers','gomaxprocs',
        'reps_count','status',
        'kernel_s_median','kernel_s_q1','kernel_s_q3','kernel_s_iqr','kernel_s_min','kernel_s_max',
        'total_s_median','total_s_q1','total_s_q3','total_s_iqr','total_s_min','total_s_max',
        'speedup','efficiency','gflops_kernel','gflops_total',
        'hostname','cpu_model','ram_gb','os_version','commit'
    )

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
    $InputPath = @($InputPath | Where-Object { $_ })
    # Each input file is an independent campaign/attempt. Never pool files merely
    # because their host/commit match; filenames are retained in summary identity.
    if ($rawLines.Count -and $InputPath.Count) { throw 'Use archivos o pipeline, no ambos.' }
    if ($CampaignId -and $InputPath.Count -gt 1) { throw 'CampaignId requiere una sola entrada.' }
    $sources = New-Object System.Collections.Generic.List[object]
    foreach ($path in $InputPath) {
        $full = (Resolve-Path -LiteralPath $path -ErrorAction Stop).Path
        $id = if ($CampaignId) { $CampaignId } else { $full }
        $sources.Add([pscustomobject]@{ Id=$id; Text=[IO.File]::ReadAllText($full) })
    }
    if ($rawLines.Count) {
        $id = if ($CampaignId) { $CampaignId } else { 'pipeline' }
        $sources.Add([pscustomobject]@{ Id=$id; Text=($rawLines -join "`n") })
    }
    if ($sources.Count -eq 0) { throw 'Indique -InputPath o datos por pipeline.' }
    Add-Type -AssemblyName Microsoft.VisualBasic
    $parsedRows = New-Object System.Collections.Generic.List[psobject]
    foreach ($source in $sources) {
        $reader = [IO.StringReader]::new($source.Text)
        $parser = [Microsoft.VisualBasic.FileIO.TextFieldParser]::new($reader)
        try {
            $parser.SetDelimiters(','); $parser.HasFieldsEnclosedInQuotes=$true; $parser.TrimWhiteSpace=$false
            $header = $parser.ReadFields()
            if ($null -eq $header -or $header.Count -ne 20 -or ($header -join ',') -cne ($script:ExpectedHeader -join ',')) {
                throw 'Cabecera debe contener exactamente las veinte columnas canonicas en orden.'
            }
            while (-not $parser.EndOfData) {
                $fields = $parser.ReadFields()
                if ($fields.Count -ne 20) { throw 'Observacion debe contener exactamente veinte campos.' }
                $row = [ordered]@{ campaign_id=$source.Id }
                for ($i=0; $i -lt 20; $i++) { $row[$script:ExpectedHeader[$i]]=$fields[$i] }
                $parsedRows.Add([pscustomobject]$row)
            }
        } finally { $parser.Dispose(); $reader.Dispose() }
    }
    # Validate before excluding warmups/failures; invalid rows cannot silently
    # disappear and turn a damaged experiment into a complete sample.
    $validObservations = New-Object System.Collections.Generic.List[psobject]
    foreach ($r in $parsedRows) {
        $rep=0; $n=0; $seed=[uint32]0
        if (-not [int]::TryParse($r.repetition,[ref]$rep) -or $rep -lt 0 -or $rep -gt 5 -or
            -not [int]::TryParse($r.n,[ref]$n) -or $n -lt 1 -or
            -not [uint32]::TryParse($r.seed,[ref]$seed)) { throw 'N, semilla o repeticion invalida.' }
        $warm = ($rep -eq 0).ToString().ToLowerInvariant()
        if ($r.is_warmup -cne $warm) { throw 'is_warmup no coincide con repetition.' }
        if ($r.version -notin @('c_secuencial','c_paralelo','go_secuencial','go_paralelo')) { throw 'Version desconocida.' }
        if ($r.commit -notmatch '^[a-fA-F0-9]{7,40}$') { throw 'Commit invalido.' }
        foreach ($key in @('hostname','cpu_model','os_version')) { if ([string]::IsNullOrWhiteSpace($r.$key)) { throw "Falta $key" } }
        $time = [datetime]::MinValue
        if (-not [datetime]::TryParseExact($r.timestamp,'yyyy-MM-ddTHH:mm:ssZ',$culture,[Globalization.DateTimeStyles]::None,[ref]$time)) { throw 'Timestamp invalido.' }
        $ram=0.0
        if (-not [double]::TryParse($r.ram_gb,[Globalization.NumberStyles]::Float,$culture,[ref]$ram) -or [double]::IsNaN($ram) -or [double]::IsInfinity($ram) -or $ram -le 0) { throw 'RAM invalida.' }
        foreach ($key in @('processes','threads','workers')) {
            $number=0
            if (-not [int]::TryParse($r.$key,[ref]$number) -or $number -lt 1) { throw "$key invalido." }
        }
        $p=[int]$r.processes; $t=[int]$r.threads; $w=[int]$r.workers
        $canonical = switch ($r.version) {
            'c_paralelo' { "c_paralelo_P${p}_T${t}" }
            'go_paralelo' { "go_paralelo_W$w" }
            default { $r.version }
        }
        if ($r.configuration -cne $canonical) { throw 'Configuracion no canonica.' }
        if ($r.version -ne 'c_paralelo' -and ($p -ne 1 -or $t -ne 1)) { throw 'Procesos/hilos fuera de C paralelo.' }
        if ($r.version -ne 'go_paralelo' -and $w -ne 1) { throw 'Workers fuera de Go paralelo.' }
        if ($r.version.StartsWith('c_')) {
            if ($r.gomaxprocs -cne '') { throw 'GOMAXPROCS debe estar vacio para C.' }
        } elseif ($r.gomaxprocs -cne [string]$w) { throw 'GOMAXPROCS no coincide con workers.' }
        if ($r.validation_status -cne 'OK') {
            if ($r.validation_status -notin @('ERROR','PENDING','MISMATCH','OOM','TIMEOUT') -or $r.kernel_s -ne '' -or $r.total_s -ne '') { throw 'Estado fallido o tiempos invalidos.' }
            continue
        }
        $observed=0
        if (-not [int]::TryParse($r.observed_threads,[ref]$observed) -or $observed -ne $t) { throw 'Hilos observados incorrectos.' }
        $kParsed=0.0; $tParsed=0.0
        if (-not [double]::TryParse($r.kernel_s,[Globalization.NumberStyles]::Float,$culture,[ref]$kParsed) -or
            -not [double]::TryParse($r.total_s,[Globalization.NumberStyles]::Float,$culture,[ref]$tParsed) -or
            [double]::IsNaN($kParsed) -or [double]::IsInfinity($kParsed) -or
            [double]::IsNaN($tParsed) -or [double]::IsInfinity($tParsed) -or
            $kParsed -lt 0 -or $tParsed -lt 0 -or $kParsed -gt $tParsed) { throw 'Tiempos no finitos o incoherentes.' }
        if ($rep -gt 0) { $validObservations.Add($r) }
    }

    # 4. Agrupar por clave canónica (campaña / host / commit / version / configuration / N / seed)
    $groups = @{}
    foreach ($obs in $parsedRows) {
        $groupKey = @($obs.campaign_id,$obs.hostname,$obs.cpu_model,$obs.ram_gb,$obs.os_version,$obs.commit,$obs.version,$obs.configuration,$obs.n,$obs.seed) | ConvertTo-Json -Compress
        if (-not $groups.ContainsKey($groupKey)) { $groups[$groupKey] = New-Object System.Collections.Generic.List[psobject] }
        $groups[$groupKey].Add($obs)
    }

    # 5. Calcular estadísticas no paramétricas por grupo (docs/protocolo_medicion.md §6.3)
    #    Para 5 repeticiones ordenadas x1 <= x2 <= x3 <= x4 <= x5:
    #      mediana = x3, Q1 = x2, Q3 = x4, IQR = x4 - x2, min = x1, max = x5
    $summaryGroups = New-Object System.Collections.Generic.List[psobject]

    foreach ($key in $groups.Keys) {
        $allItems = $groups[$key]
        $first = $allItems[0]
        $items = @($allItems | Where-Object { $_.validation_status -ceq 'OK' -and $_.repetition -ne '0' })

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
        $isComplete = ($repsCount -eq 5 -and $allItems.Count -eq 6 -and
            (@($allItems | Where-Object { $_.validation_status -cne 'OK' }).Count -eq 0) -and
            ((@($allItems.repetition | Sort-Object) -join ',') -ceq '0,1,2,3,4,5'))
        $statusStr = if ($isComplete) { 'COMPLETE' } else { 'INCOMPLETE' }

        # Estadísticas no paramétricas
        $kMed = $null; $kQ1 = $null; $kQ3 = $null; $kIqr = $null; $kMin = $null; $kMax = $null
        $tMed = $null; $tQ1 = $null; $tQ3 = $null; $tIqr = $null; $tMin = $null; $tMax = $null

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

            $mid = [int][Math]::Floor($repsCount / 2.0)
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
            campaign_id      = $first.campaign_id
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
            $secKey = @($sg.campaign_id,$sg.hostname,$sg.cpu_model,$sg.ram_gb,$sg.os_version,$sg.commit,$sg.version,$sg.n,$sg.seed) | ConvertTo-Json -Compress
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
            if ($sg.status -eq 'COMPLETE' -and $sg.total_s_median -gt 0.0) {
                $sg.speedup = 1.0
                $sg.efficiency = 1.0
            }
        } elseif ($sg.version -eq 'c_paralelo') {
            $secKey = @($sg.campaign_id,$sg.hostname,$sg.cpu_model,$sg.ram_gb,$sg.os_version,$sg.commit,'c_secuencial',$sg.n,$sg.seed) | ConvertTo-Json -Compress
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
            $secKey = @($sg.campaign_id,$sg.hostname,$sg.cpu_model,$sg.ram_gb,$sg.os_version,$sg.commit,'go_secuencial',$sg.n,$sg.seed) | ConvertTo-Json -Compress
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
    $sortedSummary = $summaryGroups | Sort-Object -Property campaign_id, version, n, configuration

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
