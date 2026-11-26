<#
.SYNOPSIS
    Regenera las tablas del análisis de Go paralelo (Sprint 9, I4) desde los CSV
    oficiales preservados.

.DESCRIPTION
    Para cada campaña indicada lee mediciones.csv, toma solo las mediciones
    válidas (validation_status=OK, sin calentamientos) de go_secuencial y
    go_paralelo_W*, y calcula por grupo (N, W) la mediana, Q1, Q3, mínimo y
    máximo de total_s y kernel_s, con la definición de summarize_results.ps1
    (cinco medidas: Q1=x2, mediana=x3, Q3=x4). Con las medianas calcula:

      speedup_seq    = mediana total go_secuencial(N) / mediana total go_paralelo(N, W)
      speedup_w1     = mediana total go_paralelo(N, 1) / mediana total go_paralelo(N, W)
      efficiency_*   = speedup_* / W
      kernel_vs_seq  = mediana kernel go_paralelo(N, W) / mediana kernel go_secuencial(N)
      work_inflation = W * mediana kernel(N, W) / mediana kernel(N, 1)
      overhead       = mediana por corrida de total_s - kernel_s

    Los speedups solo usan referencias de la misma campaña; nunca se cruzan
    archivos. Los CSV fuente no se modifican.

.PARAMETER CampaignIds
    Campañas bajo resultados/raw/. Por defecto, la integrada oficial y el lote de I4.

.PARAMETER OutputPath
    CSV de salida. Por defecto, resultados/resumen/s09_i04_go_paralelo/analisis_go_paralelo.csv.
#>
param(
    [string[]]$CampaignIds = @('s08_oficial_integrada_03', 's08_i04_go_paralelo_01'),
    [string]$OutputPath = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $OutputPath) { $OutputPath = Join-Path $root 'resultados\resumen\s09_i04_go_paralelo\analisis_go_paralelo.csv' }
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$culture = [Globalization.CultureInfo]::InvariantCulture

function ConvertTo-Double {
    param([string]$Text)
    $value = 0.0
    if (-not [double]::TryParse($Text, [Globalization.NumberStyles]::Float, $culture, [ref]$value)) { throw "Valor no numerico: '$Text'." }
    return $value
}

function Get-Quartiles {
    param([double[]]$Values)
    $sorted = @($Values | Sort-Object)
    $count = $sorted.Count
    $middle = [int][math]::Floor($count / 2)
    $median = if ($count % 2) { $sorted[$middle] } else { ($sorted[$middle - 1] + $sorted[$middle]) / 2 }
    return [pscustomobject]@{
        Min = $sorted[0]; Q1 = $sorted[[int][math]::Floor(($count - 1) / 4)]; Median = $median
        Q3 = $sorted[[int][math]::Ceiling(3 * ($count - 1) / 4)]; Max = $sorted[$count - 1]
    }
}

function Format-Value {
    param([double]$Value, [string]$Format = '0.000000000')
    return $Value.ToString($Format, $culture)
}

$output = New-Object System.Collections.Generic.List[object]
foreach ($campaignId in $CampaignIds) {
    $source = Join-Path $root "resultados\raw\$campaignId\mediciones.csv"
    if (-not (Test-Path -LiteralPath $source)) { throw "No existe $source." }
    $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $rows = @(Import-Csv -LiteralPath $source | Where-Object {
        $_.version -in @('go_secuencial', 'go_paralelo') -and $_.is_warmup -eq 'false' -and $_.validation_status -eq 'OK'
    })
    $groups = @{}
    foreach ($group in ($rows | Group-Object configuration, n)) {
        $first = $group.Group[0]
        $workers = if ($first.version -eq 'go_secuencial') { 0 } else { [int]$first.workers }
        $total = @($group.Group | ForEach-Object { ConvertTo-Double $_.total_s })
        $kernel = @($group.Group | ForEach-Object { ConvertTo-Double $_.kernel_s })
        $overhead = @($group.Group | ForEach-Object { (ConvertTo-Double $_.total_s) - (ConvertTo-Double $_.kernel_s) })
        $groups["$([int]$first.n)|$workers"] = [pscustomobject]@{
            N = [int]$first.n; Workers = $workers; Configuration = $first.configuration; Count = $group.Count
            Total = Get-Quartiles $total; Kernel = Get-Quartiles $kernel; Overhead = Get-Quartiles $overhead
            Hostname = $first.hostname; Commit = $first.commit
        }
    }
    foreach ($key in ($groups.Keys | Sort-Object { [int]($_ -split '\|')[0] }, { [int]($_ -split '\|')[1] })) {
        $group = $groups[$key]
        if ($group.Count -ne 5) { throw "${campaignId}: $($group.Configuration) N=$($group.N) tiene $($group.Count) medidas validas; se esperaban 5." }
        $sequential = $groups["$($group.N)|0"]
        $single = $groups["$($group.N)|1"]
        if ($null -eq $sequential) { throw "${campaignId}: falta go_secuencial para N=$($group.N)." }
        $record = [ordered]@{
            campaign_id = $campaignId; configuration = $group.Configuration; n = $group.N
            workers = if ($group.Workers -eq 0) { 1 } else { $group.Workers }; measured = $group.Count
            median_total_s = Format-Value $group.Total.Median; q1_total_s = Format-Value $group.Total.Q1
            q3_total_s = Format-Value $group.Total.Q3; min_total_s = Format-Value $group.Total.Min
            max_total_s = Format-Value $group.Total.Max
            iqr_over_median = Format-Value (($group.Total.Q3 - $group.Total.Q1) / $group.Total.Median) '0.0000'
            median_kernel_s = Format-Value $group.Kernel.Median
            median_overhead_s = Format-Value $group.Overhead.Median
            speedup_seq = Format-Value ($sequential.Total.Median / $group.Total.Median) '0.000'
            efficiency_seq = ''; speedup_w1 = ''; efficiency_w1 = ''
            kernel_vs_seq = Format-Value ($group.Kernel.Median / $sequential.Kernel.Median) '0.000'
            work_inflation = ''
            gflops_total = Format-Value (2.0 * [math]::Pow($group.N, 3) / $group.Total.Median / 1e9) '0.000'
            hostname = $group.Hostname; commit = $group.Commit; source_sha256 = $sourceHash
        }
        if ($group.Workers -gt 0) {
            $speedupSeq = $sequential.Total.Median / $group.Total.Median
            $record.efficiency_seq = Format-Value ($speedupSeq / $group.Workers) '0.000'
            if ($null -ne $single) {
                $speedupW1 = $single.Total.Median / $group.Total.Median
                $record.speedup_w1 = Format-Value $speedupW1 '0.000'
                $record.efficiency_w1 = Format-Value ($speedupW1 / $group.Workers) '0.000'
                $record.work_inflation = Format-Value ($group.Workers * $group.Kernel.Median / $single.Kernel.Median) '0.000'
            }
        }
        $output.Add([pscustomobject]$record)
    }
}

$directory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Force -Path $directory | Out-Null }
$csv = ($output | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' }) -join "`n"
[IO.File]::WriteAllText($OutputPath, $csv + "`n", [Text.UTF8Encoding]::new($false))
$output | Format-Table campaign_id, configuration, n, median_total_s, iqr_over_median, speedup_seq, speedup_w1, efficiency_w1, kernel_vs_seq, work_inflation, median_overhead_s -AutoSize | Out-String -Width 220 | Write-Output
Write-Output "Tabla: $OutputPath"
