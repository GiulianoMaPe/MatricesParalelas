$script:MeasurementProcessNames = @('c_secuencial','c_paralelo','go_secuencial','go_paralelo','mpiexec')
# Integrated S7 campaign. Reuses the individual CSV validators, process recorder,
# plan writer and lock supplied by I1-I5. Dot-source through bench_windows.ps1.
function Get-IntegratedConfigurations {
    param([int]$PhysicalCores, [string[]]$RequestedC = @(), [int[]]$RequestedGo = @())
    $RequestedC = @($RequestedC | Where-Object { $_ })
    $RequestedGo = @($RequestedGo | Where-Object { $null -ne $_ })
    if ($PhysicalCores -lt 1) { throw 'No se pudo determinar capacidad fisica.' }
    $c = @(Get-DefaultCParallelConfigurations -PhysicalCores $PhysicalCores)
    $go = @(1,2,4,8 | Where-Object { $_ -le $PhysicalCores })
    if ($RequestedC.Count) {
        $c = @($RequestedC | ForEach-Object { $_ -split ',' } | ForEach-Object { (Parse-BenchConfiguration $_).Name })
        foreach ($name in $c) {
            if ($name -notin @(Get-DefaultCParallelConfigurations $PhysicalCores)) { throw "Configuracion fuera del protocolo/capacidad: $name" }
        }
    }
    if ($RequestedGo.Count) {
        foreach ($w in $RequestedGo) { if ($w -notin $go) { throw "Workers fuera del protocolo/capacidad: $w" } }
        $go = @($RequestedGo | Sort-Object -Unique)
    }
    $configs = New-Object System.Collections.Generic.List[object]
    foreach ($version in @('c_secuencial','go_secuencial')) {
        $configs.Add([pscustomobject]@{ Name=$version; Version=$version; Processes=1; Threads=1; Workers=1; Budget=1 })
    }
    # Match protocol table order within each worker budget.
    foreach ($budget in @(1,2,4,8)) {
        foreach ($name in @(Get-DefaultCParallelConfigurations $PhysicalCores)) {
            $pair = Parse-BenchConfiguration $name
            if ($pair.Budget -eq $budget -and $name -in $c) {
                $configs.Add([pscustomobject]@{ Name="c_paralelo_$name"; Version='c_paralelo'; Processes=$pair.Processes; Threads=$pair.Threads; Workers=1; Budget=$budget })
            }
        }
        if ($budget -in $go) {
            $configs.Add([pscustomobject]@{ Name="go_paralelo_W$budget"; Version='go_paralelo'; Processes=1; Threads=1; Workers=$budget; Budget=$budget })
        }
    }
    return $configs.ToArray()
}

function New-IntegratedPlan {
    param([int[]]$Sizes, [object[]]$Configs, [uint32]$Seed, [uint64]$AvailableBytes)
    $excluded = New-Object System.Collections.Generic.List[object]
    foreach ($size in $Sizes) {
        if ($size -lt 1 -or $size -gt 4096) { throw 'N debe estar en 1..4096 para las cuatro versiones.' }
        # Exclude the whole N to retain both same-language baselines.
        $peak = 0.0
        foreach ($config in $Configs) {
            $factor = if ($config.Version -eq 'c_paralelo') { $config.Processes + 5 } else { 4 }
            $peak = [Math]::Max($peak, $factor * 8.0 * $size * $size)
        }
        if ($peak -gt 0.5 * $AvailableBytes) {
            foreach ($config in $Configs) {
                $excluded.Add([pscustomobject]@{ N=$size; Configuration=$config.Name; Reason='Huella matricial supera 50% de RAM disponible; N excluido en todas las versiones.' })
            }
        }
    }
    $plan = New-CampaignPlan -Sizes @($Sizes | Sort-Object -Unique) -Configurations $Configs -Seed $Seed -Warmups 1 -Repetitions 5 -Exclusions $excluded.ToArray()
    return [pscustomobject]@{ List=$plan.List; Rows=$plan.Rows; Exclusions=$excluded.ToArray() }
}

function Read-IntegratedBuilds {
    param([string]$Commit, [switch]$Official)
    $builds = @{}
    foreach ($version in $script:Versions) {
        $exe = Join-Path $script:ProjectRoot "$version/build/Release/$version.exe"
        $file = Join-Path (Split-Path -Parent $exe) 'build.json'
        if (-not (Test-Path -LiteralPath $file)) { throw "Recompile Release con build_windows.ps1: falta $file" }
        $manifest = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
        if ($manifest.version -cne $version -or $manifest.commit -cne $Commit -or
            $manifest.configuration -cne 'Release' -or $manifest.target -cne 'x64' -or
            (Get-PEArchitecture $exe) -ne 'x64' -or
            (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -cne $manifest.sha256) {
            throw "Build obsoleto o modificado: $version; recompile las cuatro versiones."
        }
        $expectedSources = @(& git -C $script:ProjectRoot ls-files --cached --others --exclude-standard -- $version scripts/build_windows.ps1 scripts/common_windows.ps1)
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo comprobar inventario de fuentes.' }
        $actualSources = @($manifest.source_sha256.PSObject.Properties.Name)
        if ($actualSources.Count -eq 0 -or (@($expectedSources | Sort-Object) -join "`n") -cne (@($actualSources | Sort-Object) -join "`n")) { throw "Inventario de fuentes cambiado: $version" }
        foreach ($property in $manifest.source_sha256.PSObject.Properties) {
            $source = Join-Path $script:ProjectRoot $property.Name
            if (-not (Test-Path -LiteralPath $source) -or (Get-FileHash -LiteralPath $source).Hash -cne $property.Value) { throw "Fuente cambiada desde build: $($property.Name)" }
        }
        if ($Official -and $manifest.dirty) { throw "Build con cambios locales: $version; recompile desde una candidata limpia." }
        if ($version.StartsWith('go_')) {
            $go = (Get-Command go.exe -ErrorAction Stop).Source
            $metadata = @(& $go version -m $exe)
            if ($LASTEXITCODE -ne 0) { throw "No se pudo inspeccionar $exe" }
            $settings = ConvertFrom-GoSequentialBuildMetadata -Metadata $metadata -Commit $Commit
            if ($Official -and $settings['vcs.modified'] -ne 'false') { throw "Go con VCS modificado: $version" }
        }
        $builds[$version] = [pscustomobject]@{ executable=$exe; sha256=$manifest.sha256; commit=$Commit; manifest=$manifest }
    }
    return $builds
}

function ConvertFrom-IntegratedMeasurement {
    param([string]$Csv, $Run, $Config, [string]$Commit, [string]$Hostname)
    $lines = @(Split-CsvOutput $Csv)
    if ($lines.Count -ne 2) { throw 'Se exige cabecera y exactamente una observacion.' }
    $row = Validate-CsvRow -HeaderLine $lines[0] -DataLine $lines[1] -ExpectedVersion $Config.Version -ExpectedN $Run.n -ExpectedSeed $Run.seed -ExpectedRepetition $Run.repetition
    if ($null -eq $row) { throw 'CSV no cumple el contrato comun.' }
    # Preserve stdout verbatim; normalize only the two legacy C sequential labels.
    if ($Config.Version -eq 'c_secuencial') {
        if ($row.configuration -notin @('Release','c_secuencial') -or $row.gomaxprocs -notin @('','1')) { throw 'Etiquetas C secuencial inesperadas.' }
        $row.configuration = 'c_secuencial'; $row.gomaxprocs = ''
    }
    $expected = @{ configuration=$Config.Name; processes=[string]$Config.Processes; threads=[string]$Config.Threads; workers=[string]$Config.Workers }
    $expected.observed_threads = if ($Config.Version -eq 'c_paralelo') { [string]$Config.Threads } else { '1' }
    $expected.gomaxprocs = if ($Config.Version.StartsWith('go_')) { [string]$Config.Workers } else { '' }
    foreach ($key in $expected.Keys) { if ($row[$key] -cne $expected[$key]) { throw "Paralelismo/configuracion incorrecto: $key" } }
    if (-not $Commit.StartsWith($row.commit, [StringComparison]::OrdinalIgnoreCase) -or $row.hostname -cne $Hostname) { throw 'Commit/PC no coincide con la campana.' }
    return $row
}

function Assert-IntegratedRanks {
    param($Run, $Config, [string]$Directory)
    $files = @(Get-ChildItem -LiteralPath $Directory -Filter 'rank-*.json')
    if ($files.Count -ne $Config.Processes) { throw 'Falta diagnostico por rank MPI.' }
    for ($rank=0; $rank -lt $Config.Processes; $rank++) {
        $item = Get-Content -LiteralPath (Join-Path $Directory "rank-$rank.json") -Raw | ConvertFrom-Json
        $q = [int][Math]::Floor($Run.n / [double]$Config.Processes)
        $r = [int]$Run.n % $Config.Processes
        $rows = $q; if ($rank -lt $r) { $rows++ }
        $first = $rank*$q + [Math]::Min($rank,$r)
        $observed = if ($rows -gt 0) { $Config.Threads } else { 0 }
        if ($item.rank -ne $rank -or $item.pid -lt 1 -or $item.rows -ne $rows -or $item.first_row -ne $first -or
            $item.requested_threads -ne $Config.Threads -or $item.timed_observed_threads -ne $observed) {
            throw "Reparto/hilos efectivos incorrectos en rank $rank."
        }
    }
}

function New-IntegratedFailure {
    param($Run, $Config, $Hardware, [string]$Commit, [string]$Status)
    $row = @{}
    foreach ($key in $script:CsvHeader) { $row[$key] = '' }
    $row.timestamp = Get-UtcTimestamp; $row.version = $Config.Version; $row.commit = $Commit
    $row.hostname = [Environment]::MachineName; $row.cpu_model = $Hardware.CpuModel
    $row.ram_gb = Format-InvariantDouble ($Hardware.RamBytes / 1GB)
    $row.os_version = "$($Hardware.OsEdition) build $($Hardware.OsBuild)"
    $row.configuration = $Config.Name; $row.n = [string]$Run.n; $row.seed = [string]$Run.seed
    $row.processes = [string]$Config.Processes; $row.threads = [string]$Config.Threads
    $row.workers = [string]$Config.Workers
    $row.gomaxprocs = if ($Config.Version.StartsWith('go_')) { [string]$Config.Workers } else { '' }
    $row.repetition = [string]$Run.repetition; $row.is_warmup = $Run.is_warmup; $row.validation_status = $Status
    return $row
}

function Invoke-IntegratedRuns {
    param($Plan, [object[]]$Configs, [hashtable]$Builds, $Hardware, [string]$Commit,
        [string]$Directory, [string]$Launcher, [int]$TimeoutSeconds)
    $csvPath = Join-Path $Directory 'mediciones.csv'
    $logPath = Join-Path $Directory 'bitacora.txt'
    Write-Utf8NoBom $csvPath (($script:CsvHeader -join ',') + "`n")
    Write-Utf8NoBom $logPath "Inicio $(Get-UtcTimestamp); ejecucion serial; timeout=$TimeoutSeconds s`n"
    $accepted = 0; $failed = $false
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        foreach ($run in $Plan.Rows) {
            $config = @($Configs | Where-Object { $_.Name -ceq $run.configuration })[0]
            $build = $Builds[$config.Version]
            $runDir = Join-Path $Directory ('logs/{0:D4}' -f $run.execution_order)
            $detail = ''; $record = $null
            if ($env:OS -eq 'Windows_NT') {
                $load = @(Get-CimInstance Win32_Processor | ForEach-Object { $_.LoadPercentage })
                $free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
                Write-Utf8NoBom -Path $logPath -Text ("order=$($run.execution_order) cpu_load_percent=$($load -join ',') free_memory_kib=$free temperature=unavailable`n") -Append
            }
            try {
                if ((Get-FileHash -LiteralPath $build.executable).Hash -cne $build.sha256) { throw 'El ejecutable cambio antes de medir.' }
                $arguments = @('--n',[string]$run.n,'--seed',[string]$run.seed,'--repetition',[string]$run.repetition)
                $childEnv = @{ GOMAXPROCS=$null; OMP_NUM_THREADS=$null; OMP_DYNAMIC=$null; S06_DIAGNOSTICS=$null }
                $exe = $build.executable
                if ($config.Version -eq 'c_paralelo') {
                    $arguments = @('-n',[string]$config.Processes,$exe) + $arguments; $exe = $Launcher
                    $childEnv.OMP_NUM_THREADS = [string]$config.Threads; $childEnv.OMP_DYNAMIC = 'FALSE'
                    $childEnv.S06_DIAGNOSTICS = $runDir
                } elseif ($config.Version.StartsWith('go_')) {
                    $childEnv.GOMAXPROCS = [string]$config.Workers
                    if ($config.Version -eq 'go_paralelo') { $arguments += @('--workers',[string]$config.Workers) }
                }
                $csv = Invoke-GoSequentialProcess -Executable $exe -Arguments $arguments -RunDirectory $runDir -TimeoutSeconds $TimeoutSeconds -ChildEnvironment $childEnv -TerminateTree
                $row = ConvertFrom-IntegratedMeasurement -Csv $csv -Run $run -Config $config -Commit $Commit -Hostname ([Environment]::MachineName)
                if ((Get-FileHash -LiteralPath $build.executable).Hash -cne $build.sha256) { throw 'El ejecutable cambio durante la corrida.' }
                if ($config.Version -eq 'c_paralelo') {
                    Assert-IntegratedRanks -Run $run -Config $config -Directory $runDir
                    foreach ($rankFile in @(Get-ChildItem -LiteralPath $runDir -Filter 'rank-*.json')) {
                        Write-Utf8NoBom -Path $logPath -Text ("order=$($run.execution_order) " + (Get-Content -LiteralPath $rankFile.FullName -Raw).Trim() + "`n") -Append
                    }
                }
                $accepted++
            } catch {
                $failed = $true; $detail = $_.Exception.Message
                $status = 'ERROR'
                $recordPath = Join-Path $runDir 'proceso.json'
                if (Test-Path -LiteralPath $recordPath) {
                    $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
                    if ($record.status -eq 'TIMEOUT') { $status = 'TIMEOUT' }
                    elseif ($record.exit_code -eq 2) { $status = 'PENDING' }
                }
                $row = New-IntegratedFailure -Run $run -Config $config -Hardware $Hardware -Commit $Commit -Status $status
            }
            Write-Utf8NoBom -Path $csvPath -Text ((ConvertTo-CsvLine @($script:CsvHeader | ForEach-Object { $row[$_] })) + "`n") -Append
            Write-Utf8NoBom -Path $logPath -Text ("order=$($run.execution_order) N=$($run.n) $($config.Name) rep=$($run.repetition) status=$($row.validation_status) $detail`n") -Append
            # Never continue measuring after a process, validation or timeout failure.
            if ($failed) { break }
        }
    } finally {
        $watch.Stop()
        $state = [ordered]@{ status='INCOMPLETE'; planned=$Plan.Rows.Count; accepted=$accepted; wall_s=$watch.Elapsed.TotalSeconds; ended_at_utc=Get-UtcTimestamp }
        if (-not $failed -and $accepted -eq $Plan.Rows.Count) { $state.status = 'COMPLETE' }
        Write-Utf8NoBom (Join-Path $Directory 'estado.json') (($state | ConvertTo-Json) + "`n")
    }
    return (-not $failed -and $accepted -eq $Plan.Rows.Count)
}

function Invoke-IntegratedCampaign {
    param([int[]]$Sizes, [uint32]$Seed, [string[]]$RequestedC, [int[]]$RequestedGo,
        [string]$Phase, [string]$OutputRoot, [string]$CampaignId, [int]$TimeoutSeconds, [switch]$DryRun)
    Assert-Windows
    $hardware = Get-HardwareInfo
    $git = Get-GitInfo $script:ProjectRoot
    if ($Phase -eq 'oficial' -and $git.Dirty) { throw 'Campana oficial exige arbol limpio.' }
    $configs = @(Get-IntegratedConfigurations -PhysicalCores $hardware.PhysicalCores -RequestedC $RequestedC -RequestedGo $RequestedGo)
    $plan = New-IntegratedPlan -Sizes $Sizes -Configs $configs -Seed $Seed -AvailableBytes $hardware.RamAvailableBytes
    if (-not $OutputRoot) {
        $folder = if ($Phase -eq 'piloto') { 'piloto' } else { 'raw' }
        $OutputRoot = Join-Path $script:ProjectRoot "resultados/$folder"
    }
    $OutputRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputRoot)
    if (-not $CampaignId) { $CampaignId = [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '_' + [Environment]::MachineName + '_' + $git.Commit.Substring(0,7) }
    if ($CampaignId -notmatch '^[A-Za-z0-9_-]+$') { throw 'CampaignId solo admite letras, numeros, guion y guion bajo.' }
    $lockPath = Join-Path $script:ProjectRoot '.cache/bench.lock'
    $lock = Enter-GoParaleloLock -LockPath $lockPath -CampaignId $CampaignId
    try {
        Assert-NoConcurrentMeasurement
        $builds = @{}; $launcher = ''
        if (-not $DryRun) {
            foreach ($version in $script:Versions) {
                $status = Get-Content (Join-Path $script:ProjectRoot "$version/status.json") -Raw | ConvertFrom-Json
                if ($status.algorithm -cne 'implemented' -or $status.validation -cne 'passed') { throw "$version pendiente de algoritmo/validacion." }
            }
            $builds = Read-IntegratedBuilds -Commit $git.Commit -Official:($Phase -eq 'oficial')
            $launcher = Get-MPILauncher
        }
        $directory = New-CampaignDirectory -Root $OutputRoot -CampaignId $CampaignId
        Write-CampaignPlan -Path (Join-Path $directory 'plan.csv') -Rows $plan.Rows
        $options = [ordered]@{}; $binaryHashes = [ordered]@{}
        foreach ($version in $script:Versions) {
            $options[$version] = if ($builds.ContainsKey($version)) { $builds[$version].manifest.arguments } else { $null }
            $binaryHashes[$version] = if ($builds.ContainsKey($version)) { $builds[$version].sha256 } else { $null }
        }
        $ompMap = [ordered]@{}; $goMap = [ordered]@{}; $peak = 0.0
        foreach ($item in $plan.List) {
            $config = @($configs | Where-Object { $_.Name -ceq $item.Configuration })[0]
            $factor = if ($config.Version -eq 'c_paralelo') { $config.Processes + 5 } else { 4 }
            $peak = [Math]::Max($peak, $factor * 8.0 * $item.N * $item.N)
            if ($config.Version -eq 'c_paralelo') { $ompMap[$config.Name] = $config.Threads }
            elseif ($config.Version.StartsWith('go_')) { $goMap[$config.Name] = $config.Workers }
        }
        $environment = [ordered]@{
            protocol_version='1.3'; campaign_id=(Split-Path -Leaf $directory); phase=$Phase; dry_run=[bool]$DryRun
            started_at_utc=Get-UtcTimestamp; operator=$env:USERNAME; hostname=[Environment]::MachineName
            git=@{ commit_full=$git.Commit; dirty=$git.Dirty; diff_file=$null }
            hardware=@{ cpu_model=$hardware.CpuModel; physical_cores=$hardware.PhysicalCores; logical_processors=$hardware.LogicalProcessors
                ram_visible_bytes=$hardware.RamBytes; ram_available_at_start_bytes=$hardware.RamAvailableBytes
                os_edition=$hardware.OsEdition; os_build=$hardware.OsBuild; power_source=$hardware.PowerSource; power_plan=$hardware.PowerPlan
                temperature_monitoring='unavailable: registrar manualmente sensor y episodios de throttling en bitacora.txt' }
            build=@{ configuration='Release'; target='x64'; goos='windows'; goarch='amd64'
                msvc_version=$null; windows_sdk_version=$null; msmpi_runtime_version=$null; msmpi_sdk_version=$null; go_version=$null
                effective_options_by_version=$options; executable_sha256_by_version=$binaryHashes; manifests=$builds }
            experiment=@{ matrix_sizes=$Sizes; seed=$Seed; enabled_budgets=@($configs.Budget | Sort-Object -Unique)
                ordered_configurations=@($configs.Name); warmups_per_combination=1; measured_repetitions=5
                order_policy='N ascending, protocol table order; odd rounds forward, even rounds reverse'
                timeout_per_run_seconds=$TimeoutSeconds; campaign_machine_time_budget_seconds=($plan.Rows.Count * [int64]$TimeoutSeconds)
                maximum_matrix_fraction_of_available_ram=0.5; estimated_matrix_peak_bytes=$peak
                omp_dynamic='FALSE'; omp_num_threads_by_configuration=$ompMap; gomaxprocs_by_configuration=$goMap
                excluded_combinations_and_reasons=$plan.Exclusions
                plan_file='plan.csv'; observations_file='mediciones.csv'; log_file='bitacora.txt' }
        }
        if (-not $DryRun) {
            $environment.build.msvc_version = $builds.c_paralelo.manifest.tools.msvc
            $environment.build.windows_sdk_version = $builds.c_paralelo.manifest.tools.windows_sdk
            $environment.build.msmpi_runtime_version = $builds.c_paralelo.manifest.tools.msmpi_runtime
            $environment.build.msmpi_sdk_version = $builds.c_paralelo.manifest.tools.msmpi_sdk
            $environment.build.go_version = $builds.go_secuencial.manifest.tools.go
        }
        # Snapshot includes untracked source files as well as tracked diffs for dirty pilots.
        if ($git.Dirty) {
            Write-Utf8NoBom (Join-Path $directory 'diff_codigo.patch') ($git.Diff + "`n")
            Write-Utf8NoBom (Join-Path $directory 'git_status.txt') ($git.Status + "`n")
            $environment.git.diff_file = 'diff_codigo.patch'
        }
        $sourceFiles = @(& $git.GitPath -C $script:ProjectRoot ls-files --cached --others --exclude-standard -- scripts tests c_secuencial c_paralelo go_secuencial go_paralelo docs)
        $hashes = [ordered]@{}
        foreach ($relative in $sourceFiles) {
            $source = Join-Path $script:ProjectRoot $relative
            if (Test-Path -LiteralPath $source -PathType Leaf) {
                $hashes[$relative] = (Get-FileHash -LiteralPath $source).Hash
                if ($git.Dirty) {
                    $dest = Join-Path $directory "sources/$relative"
                    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
                    Copy-Item -LiteralPath $source -Destination $dest
                }
            }
        }
        Write-Utf8NoBom (Join-Path $directory 'source-hashes.json') ($hashes | ConvertTo-Json -Depth 4)
        Write-Utf8NoBom (Join-Path $directory 'entorno.json') ($environment | ConvertTo-Json -Depth 12)
        [Console]::Error.WriteLine("Campana: $directory; $($plan.Rows.Count) corridas planificadas.")
        if ($DryRun) {
            Write-Utf8NoBom (Join-Path $directory 'estado.json') '{"status":"DRY_RUN","observations":0}'
            return
        }
        $ok = Invoke-IntegratedRuns -Plan $plan -Configs $configs -Builds $builds -Hardware $hardware -Commit $git.Commit -Directory $directory -Launcher $launcher -TimeoutSeconds $TimeoutSeconds
        & (Join-Path $PSScriptRoot 'summarize_results.ps1') -InputPath (Join-Path $directory 'mediciones.csv') -OutputPath (Join-Path $directory 'resumen_estadistico.csv')
        if (-not $ok) { throw "Campana incompleta. Se conservaron datos y logs en $directory" }
    } finally { Exit-GoParaleloLock -Stream $lock -LockPath $lockPath }
}
