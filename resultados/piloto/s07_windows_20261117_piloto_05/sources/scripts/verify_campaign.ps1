param([Parameter(Mandatory=$true)][string]$CampaignDirectory, [switch]$PassThru)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bench_windows.ps1"
$CampaignDirectory = (Resolve-Path -LiteralPath $CampaignDirectory).Path
foreach ($name in @('entorno.json','plan.csv','mediciones.csv','bitacora.txt','estado.json','source-hashes.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $CampaignDirectory $name))) { throw "Falta $name" }
}
$environment = Get-Content (Join-Path $CampaignDirectory 'entorno.json') -Raw | ConvertFrom-Json
$state = Get-Content (Join-Path $CampaignDirectory 'estado.json') -Raw | ConvertFrom-Json
if ($environment.dry_run -or $state.status -cne 'COMPLETE') { throw 'Un dry-run o intento incompleto no acredita el piloto.' }
$plan = @(Import-Csv (Join-Path $CampaignDirectory 'plan.csv'))
$dataFile = Join-Path $CampaignDirectory 'mediciones.csv'
$bytes = [IO.File]::ReadAllBytes($dataFile)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { throw 'CSV contiene BOM.' }
$data = @(Import-Csv -LiteralPath $dataFile)
if ($data.Count -eq 0 -or $data.Count -ne $plan.Count -or $state.accepted -ne $data.Count -or $state.planned -ne $plan.Count) { throw 'Plan, CSV y estado no tienen igual numero de corridas.' }
if ((@($data[0].PSObject.Properties.Name) -join ',') -cne ($script:CsvHeader -join ',')) { throw 'Esquema no canonico.' }
$configs = @(Get-IntegratedConfigurations -PhysicalCores $environment.hardware.physical_cores)
for ($i=0; $i -lt $plan.Count; $i++) {
    if ([int]$plan[$i].execution_order -ne $i+1) { throw 'Orden de plan no consecutivo.' }
    foreach ($field in @('n','configuration','seed','repetition','is_warmup')) {
        if ($data[$i].$field -cne $plan[$i].$field) { throw "Desvio del plan en fila $($i+1): $field" }
    }
    $config = @($configs | Where-Object { $_.Name -ceq $plan[$i].configuration })
    if ($config.Count -ne 1) { throw 'Configuracion ajena al protocolo/capacidad.' }
    $csv = @($data[$i] | ConvertTo-Csv -NoTypeInformation) -join "`n"
    $null = ConvertFrom-IntegratedMeasurement -Csv $csv -Run $plan[$i] -Config $config[0] -Commit $environment.git.commit_full -Hostname $environment.hostname
    $log = Join-Path $CampaignDirectory ('logs/{0:D4}/proceso.json' -f ($i+1))
    $process = Get-Content -LiteralPath $log -Raw | ConvertFrom-Json
    if ($process.exit_code -ne 0 -or $process.status -cne 'OK' -or $null -eq $process.pid) { throw "Proceso no aceptado: $log" }
    if ($config[0].Version -eq 'c_paralelo') { Assert-IntegratedRanks -Run $plan[$i] -Config $config[0] -Directory (Split-Path -Parent $log) }
    foreach ($stream in @('stdout.txt','stderr.txt')) {
        if (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $log) $stream))) { throw "Falta $stream" }
    }
    $raw = [IO.File]::ReadAllText((Join-Path (Split-Path -Parent $log) 'stdout.txt'))
    $original = ConvertFrom-IntegratedMeasurement -Csv $raw -Run $plan[$i] -Config $config[0] -Commit $environment.git.commit_full -Hostname $environment.hostname
    foreach ($field in $script:CsvHeader) { if ($original[$field] -cne $data[$i].$field) { throw "CSV no coincide con stdout preservado: fila $($i+1), $field" } }
    if ([IO.File]::ReadAllText((Join-Path (Split-Path -Parent $log) 'stderr.txt')).Length -gt 0) { throw 'Proceso con diagnosticos requiere revision.' }

}
# Rebuild the expected table and order, including capacity exclusions. A shuffled
# plan plus identically shuffled CSV must not pass the check.
$selectedC = @($environment.experiment.ordered_configurations | Where-Object { $_ -like 'c_paralelo_*' } | ForEach-Object { $_.Substring(11) })
$selectedGo = @($environment.experiment.ordered_configurations | Where-Object { $_ -like 'go_paralelo_W*' } | ForEach-Object { [int]$_.Substring(13) })
$expectedConfigs = @(Get-IntegratedConfigurations -PhysicalCores $environment.hardware.physical_cores -RequestedC $selectedC -RequestedGo $selectedGo)
$expectedPlan = New-IntegratedPlan -Sizes $environment.experiment.matrix_sizes -Configs $expectedConfigs -Seed $environment.experiment.seed -AvailableBytes $environment.hardware.ram_available_at_start_bytes
if ($expectedPlan.Rows.Count -ne $plan.Count) { throw 'Plan no corresponde al entorno registrado.' }
for ($i=0; $i -lt $plan.Count; $i++) {
    foreach ($field in $script:PlanHeader) { if ([string]$expectedPlan.Rows[$i].$field -cne $plan[$i].$field) { throw "Plan no respeta las rondas alternadas: fila $($i+1)." } }
}
$summary = @(& "$PSScriptRoot/summarize_results.ps1" -InputPath $dataFile -PassThru)
if (@($summary | Where-Object { $_.status -cne 'COMPLETE' }).Count -gt 0 -or @($summary.version | Sort-Object -Unique).Count -ne 4) { throw 'No hay grupos completos en las cuatro versiones.' }
foreach ($version in $script:Versions) {
    $hash = $environment.build.executable_sha256_by_version.$version
    if ($hash -notmatch '^[A-Fa-f0-9]{64}$') { throw "Falta SHA-256 de $version" }
    $build = $environment.build.manifests.$version.manifest
    if ($build.commit -cne $environment.git.commit_full -or $build.configuration -cne 'Release' -or $build.sha256 -cne $hash) { throw 'Manifiesto de compilacion inconsistente.' }
}
$result = [ordered]@{
    status='VERIFIED'; campaign_id=$environment.campaign_id; verified_at_utc=Get-UtcTimestamp
    observations=$data.Count; groups=$summary.Count; commit=$environment.git.commit_full
    native_execution_required='La procedencia Windows se acredita con entorno y logs; esta verificacion no ejecuta los binarios.'
    human_environment_review='Confirmar PC oficial, carga/temperatura/alimentacion y reproduccion antes de cerrar S7.'
    data_sha256=(Get-FileHash -LiteralPath $dataFile).Hash
}
Write-Utf8NoBom (Join-Path $CampaignDirectory 'verificacion.json') ($result | ConvertTo-Json)
if ($PassThru) { [pscustomobject]$result } else { "VERIFIED: $($data.Count) observaciones, $($summary.Count) grupos: $CampaignDirectory" }
