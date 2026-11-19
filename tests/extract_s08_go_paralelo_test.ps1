param([string]$SourceCampaign = '')

# Pruebas de scripts/extract_s08_go_paralelo.ps1 (S8, I4). Cada caso copia una
# campana real ya verificada (por defecto, el piloto S7 _05 de la PC oficial) a
# una carpeta temporal, introduce un defecto concreto y comprueba que el
# extractor lo detecte. La campana original no se modifica.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $SourceCampaign) { $SourceCampaign = Join-Path $root 'resultados\piloto\s07_windows_20261117_piloto_05' }
$extractor = Join-Path $root 'scripts\extract_s08_go_paralelo.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('extract-s08-go-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()
$utf8 = [Text.UTF8Encoding]::new($false)

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function New-CampaignCopy {
    param([string]$Name)
    $target = Join-Path $testRoot $Name
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    foreach ($file in @('entorno.json', 'estado.json', 'plan.csv', 'mediciones.csv', 'bitacora.txt')) {
        Copy-Item -LiteralPath (Join-Path $SourceCampaign $file) -Destination $target
    }
    Copy-Item -LiteralPath (Join-Path $SourceCampaign 'logs') -Destination $target -Recurse
    return $target
}

# Get-GoOrder devuelve el orden de ejecucion de la fila go_paralelo pedida.
function Get-GoOrder {
    param([string]$Campaign, [int]$N, [int]$Workers, [int]$Repetition)
    $row = Import-Csv (Join-Path $Campaign 'plan.csv') | Where-Object {
        $_.configuration -eq "go_paralelo_W$Workers" -and [int]$_.n -eq $N -and [int]$_.repetition -eq $Repetition
    }
    return [int]$row.execution_order
}

# Set-RowField cambia un campo de la fila en mediciones.csv y, si se pide, en
# stdout.txt, de modo que ambas copias sigan siendo coherentes.
function Set-RowField {
    param([string]$Campaign, [int]$Order, [string]$Field, [string]$Value, [switch]$MeasurementsOnly, [switch]$StdoutOnly)
    $header = 'timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status' -split ','
    $index = [array]::IndexOf($header, $Field)
    $targets = @()
    if (-not $StdoutOnly) { $targets += @{ Path = (Join-Path $Campaign 'mediciones.csv'); Line = $Order } }
    if (-not $MeasurementsOnly) { $targets += @{ Path = (Join-Path $Campaign ('logs\{0:D4}\stdout.txt' -f $Order)); Line = 1 } }
    foreach ($target in $targets) {
        $lines = [IO.File]::ReadAllLines($target.Path)
        $fields = $lines[$target.Line] -split ','
        $fields[$index] = $Value
        $lines[$target.Line] = $fields -join ','
        [IO.File]::WriteAllText($target.Path, (($lines -join "`n") + "`n"), $utf8)
    }
}

function Set-JsonValue {
    param([string]$Path, [scriptblock]$Change)
    $object = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    & $Change $object
    [IO.File]::WriteAllText($Path, ($object | ConvertTo-Json -Depth 8), $utf8)
}

function Invoke-Extractor {
    param([string]$Campaign, [string[]]$Arguments = @('-Phase', 'piloto'))
    $output = Join-Path $Campaign 'vista\go_paralelo.csv'
    $text = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $extractor -CampaignDirectory $Campaign -OutputPath $output @Arguments 2>&1 | Out-String
    $manifestPath = [IO.Path]::ChangeExtension($output, '.manifest.json')
    $manifest = if (Test-Path -LiteralPath $manifestPath) { Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = $text; Manifest = $manifest; Output = $output }
}

function Test-Case {
    param([string]$Name, [scriptblock]$Mutation, [int]$ExpectedExit, [string]$ExpectedStatus, [string]$ExpectedCode = '',
        [string]$ExpectedSeverity = 'critical', [string[]]$Arguments = @('-Phase', 'piloto'), [scriptblock]$Extra = $null)
    $campaign = New-CampaignCopy $Name
    if ($Mutation) { & $Mutation $campaign }
    $run = Invoke-Extractor -Campaign $campaign -Arguments $Arguments
    try {
        Assert-That ($run.ExitCode -eq $ExpectedExit) "codigo $($run.ExitCode), se esperaba $ExpectedExit."
        Assert-That ($null -ne $run.Manifest -and $run.Manifest.status -eq $ExpectedStatus) "estado '$($run.Manifest.status)', se esperaba '$ExpectedStatus'."
        if ($ExpectedCode) {
            $found = @($run.Manifest.anomalies | Where-Object { $_.code -eq $ExpectedCode -and $_.severity -eq $ExpectedSeverity })
            Assert-That ($found.Count -gt 0) "no se registro la anomalia $ExpectedSeverity '$ExpectedCode'."
        }
        if ($Extra) { & $Extra $run $campaign }
    } catch {
        throw "FAIL: $Name : $_`n$($run.Text)"
    }
    $results.Add([pscustomobject]@{ case = $Name; status = 'OK' })
}

try {
    Test-Case 'campana-valida' -ExpectedExit 0 -ExpectedStatus 'VERIFIED_PILOT' -Extra {
        param($run, $campaign)
        Assert-That ($run.Manifest.output.rows -eq 54 -and $run.Manifest.output.warmups -eq 9) 'Conteo de filas incorrecto.'
        $source = [IO.File]::ReadAllLines((Join-Path $campaign 'mediciones.csv'))
        $expected = @($source[0]) + @($source | Select-Object -Skip 1 | Where-Object { $_ -match '^[^,]*,go_paralelo,' })
        $view = [IO.File]::ReadAllLines($run.Output)
        Assert-That (@(Compare-Object $expected $view -SyncWindow 0).Count -eq 0) 'La vista no es copia exacta de las filas fuente.'
        Assert-That ($run.Manifest.output.sha256 -eq (Get-FileHash -LiteralPath $run.Output -Algorithm SHA256).Hash) 'Hash de la vista incorrecto.'
    }
    Test-Case 'fase-oficial-rechaza-piloto' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'fase' -Arguments @('-Phase', 'oficial') -Extra {
        param($run, $campaign)
        Assert-That (-not (Test-Path -LiteralPath $run.Output)) 'Se escribio la vista con anomalias criticas.'
    }
    Test-Case 'fase-oficial-rechaza-otro-host' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'host_oficial' -Arguments @('-Phase', 'oficial') -Mutation {
        param($campaign)
        Set-JsonValue (Join-Path $campaign 'entorno.json') { param($e) $e.hostname = 'PC-DE-PRUEBA' }
    }
    Test-Case 'fase-oficial-exige-semilla-42' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'semilla_oficial' -Arguments @('-Phase', 'oficial') -Mutation {
        param($campaign)
        Set-JsonValue (Join-Path $campaign 'entorno.json') { param($e) $e.experiment.seed = 101 }
    }
    Test-Case 'fase-oficial-rechaza-semilla-distinta-en-plan' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'semilla_plan' -Arguments @('-Phase', 'oficial') -Mutation {
        param($campaign)
        $order = Get-GoOrder $campaign 512 4 3
        $planPath = Join-Path $campaign 'plan.csv'
        $planRows = @(Import-Csv -LiteralPath $planPath)
        $planRows[$order - 1].seed = '101'
        $planRows | Export-Csv -LiteralPath $planPath -NoTypeInformation -Encoding UTF8
    }
    Test-Case 'incompleto-preserva-csv-y-manifiesto-oficiales' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'fase' -Arguments @('-Phase', 'oficial', '-AllowIncomplete') -Extra {
        param($run, $campaign)
        Assert-That (Test-Path -LiteralPath $run.Output) 'No se guardo la vista incompleta con una ruta fuera de raw.'
        $isolatedRoot = Join-Path $testRoot 'repositorio-aislado'
        $raw = Join-Path $isolatedRoot 'resultados\raw'
        New-Item -ItemType Directory -Path $raw -Force | Out-Null
        Copy-Item -LiteralPath (Split-Path -Parent $extractor) -Destination (Join-Path $isolatedRoot 'scripts') -Recurse
        $isolatedExtractor = Join-Path $isolatedRoot 'scripts\extract_s08_go_paralelo.ps1'
        $officialCsv = Join-Path $raw 'go_paralelo.csv'
        $officialManifest = Join-Path $raw 'go_paralelo.manifest.json'
        $original = 'Evidencia oficial previa.'
        foreach ($path in @($officialCsv, $officialManifest)) { [IO.File]::WriteAllText($path, $original, $utf8) }
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $isolatedExtractor -CampaignDirectory $campaign -Phase oficial -AllowIncomplete | Out-Null
        Assert-That ($LASTEXITCODE -eq 1) 'Un intento incompleto en fase oficial debe fallar.'
        foreach ($path in @($officialCsv, $officialManifest)) {
            Assert-That ([IO.File]::ReadAllText($path) -ceq $original) "Se sobrescribio un archivo oficial: $path"
        }
    }
    Test-Case 'gomaxprocs-entorno-hijo' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'gomaxprocs_entorno' -Mutation {
        param($campaign)
        $order = Get-GoOrder $campaign 512 4 3
        Set-JsonValue (Join-Path $campaign ('logs\{0:D4}\proceso.json' -f $order)) { param($p) $p.child_environment.GOMAXPROCS = '1' }
    }
    Test-Case 'gomaxprocs-informado' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'workers_efectivos' -Mutation {
        param($campaign)
        Set-RowField $campaign (Get-GoOrder $campaign 1024 2 1) 'gomaxprocs' '1'
    }
    Test-Case 'workers-informados' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'workers_efectivos' -Mutation {
        param($campaign)
        Set-RowField $campaign (Get-GoOrder $campaign 256 4 2) 'workers' '2'
    }
    Test-Case 'argumentos-workers' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'argumentos' -Mutation {
        param($campaign)
        $order = Get-GoOrder $campaign 512 2 5
        Set-JsonValue (Join-Path $campaign ('logs\{0:D4}\proceso.json' -f $order)) { param($p) $p.arguments[7] = '4' }
    }
    Test-Case 'stdout-difiere' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'stdout_desvio' -Mutation {
        param($campaign)
        Set-RowField $campaign (Get-GoOrder $campaign 1024 4 4) 'total_s' '9.999999999' -StdoutOnly
    }
    Test-Case 'proceso-fallido' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'proceso_fallido' -Mutation {
        param($campaign)
        $order = Get-GoOrder $campaign 256 1 1
        Set-JsonValue (Join-Path $campaign ('logs\{0:D4}\proceso.json' -f $order)) { param($p) $p.exit_code = 1 }
    }
    Test-Case 'medida-fallida-deja-grupo-incompleto' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'grupo_incompleto' -Mutation {
        param($campaign)
        $order = Get-GoOrder $campaign 512 1 2
        Set-RowField $campaign $order 'validation_status' 'ERROR'
        Set-RowField $campaign $order 'kernel_s' ''
        Set-RowField $campaign $order 'total_s' ''
    }
    Test-Case 'kernel-mayor-que-total' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'tiempos' -Mutation {
        param($campaign)
        Set-RowField $campaign (Get-GoOrder $campaign 1024 1 3) 'kernel_s' '9.000000000'
    }
    Test-Case 'commit-distinto' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'commit_entorno' -Arguments @('-Phase', 'piloto', '-ExpectedCommit', ('0' * 40))
    Test-Case 'bitacora-sin-registro' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'bitacora' -Mutation {
        param($campaign)
        $order = Get-GoOrder $campaign 1024 4 5
        $path = Join-Path $campaign 'bitacora.txt'
        $lines = @(Get-Content -LiteralPath $path -Encoding UTF8 | Where-Object { $_ -notmatch "^order=$order N=" })
        [IO.File]::WriteAllLines($path, $lines, $utf8)
    }
    Test-Case 'workers-sobre-capacidad-fisica' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'workers_fuera_de_capacidad' -Mutation {
        param($campaign)
        Set-JsonValue (Join-Path $campaign 'entorno.json') { param($e) $e.hardware.physical_cores = 2 }
    }
    Test-Case 'serie-incompleta-con-8-nucleos' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'serie_incompleta' -Mutation {
        param($campaign)
        Set-JsonValue (Join-Path $campaign 'entorno.json') { param($e) $e.hardware.physical_cores = 8 }
    }
    Test-Case 'dispersion-se-avisa-y-conserva' -ExpectedExit 0 -ExpectedStatus 'VERIFIED_PILOT' -ExpectedCode 'dispersion_alta' -ExpectedSeverity 'warning' -Mutation {
        param($campaign)
        foreach ($rep in 4, 5) {
            $order = Get-GoOrder $campaign 1024 1 $rep
            Set-RowField $campaign $order 'total_s' '1.600000000'
            Set-RowField $campaign $order 'kernel_s' '1.590000000'
            Set-JsonValue (Join-Path $campaign ('logs\{0:D4}\proceso.json' -f $order)) { param($p) $p.wall_s = 5.0 }
        }
    } -Extra {
        param($run, $campaign)
        Assert-That (@([IO.File]::ReadAllLines($run.Output) | Where-Object { $_ -match ',1\.600000000,OK$' }).Count -eq 2) 'Se eliminaron observaciones dispersas.'
        $group = @($run.Manifest.groups | Where-Object { $_.n -eq 1024 -and $_.workers -eq 1 })[0]
        Assert-That (@($group.flags) -contains 'dispersion_alta') 'El grupo no quedo marcado.'
    }
    Test-Case 'allow-incomplete-escribe-y-falla' -ExpectedExit 1 -ExpectedStatus 'INCOMPLETE' -ExpectedCode 'workers_efectivos' -Arguments @('-Phase', 'piloto', '-AllowIncomplete') -Mutation {
        param($campaign)
        Set-RowField $campaign (Get-GoOrder $campaign 512 4 1) 'gomaxprocs' '2'
    } -Extra {
        param($run, $campaign)
        Assert-That (Test-Path -LiteralPath $run.Output) '-AllowIncomplete no escribio la vista.'
    }
    Test-Case 'diagnostico-acepta-estado-incompleto' -ExpectedExit 0 -ExpectedStatus 'DIAGNOSTIC' -ExpectedCode 'estado' -ExpectedSeverity 'warning' -Arguments @('-Phase', 'diagnostico') -Mutation {
        param($campaign)
        Set-JsonValue (Join-Path $campaign 'estado.json') { param($s) $s.status = 'INCOMPLETE' }
    }
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$results | Format-Table -AutoSize | Out-String | Write-Output
Write-Output "OK: extract_s08_go_paralelo ($($results.Count) casos)."
exit 0
