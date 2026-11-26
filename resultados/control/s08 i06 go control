param(
    [string]$CampaignId = 's08_i06_go_control',
    [int[]]$Sizes = @(512, 1024, 2048),
    [uint32]$Seed = 42,
    [int[]]$GoWorkers = @(1, 2, 4),
    [ValidateRange(1,86400)][int]$TimeoutSeconds = 900
)
# Control independiente S8 de I6 (Gerardo): subconjunto Go en una PC distinta de la oficial.
# No sustituye ni se mezcla con la campana oficial. Se usa porque el arnes oficial exige
# un repositorio Git y MSVC/MS-MPI, ausentes en esta PC. Plan: 1 calentamiento + 5
# repeticiones por configuracion, rondas alternadas directo/inverso como el arnes oficial.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "resultados\control\$CampaignId"
if (Test-Path -LiteralPath $out) { throw "Ya existe $out; use otro CampaignId para no sobrescribir datos." }
New-Item -ItemType Directory -Path (Join-Path $out 'logs') | Out-Null

$exe = @{
    go_secuencial = Join-Path $root 'go_secuencial\build\Release\go_secuencial.exe'
    go_paralelo   = Join-Path $root 'go_paralelo\build\Release\go_paralelo.exe'
}
foreach ($p in $exe.Values) { if (-not (Test-Path -LiteralPath $p)) { throw "Falta $p; compile en Release." } }

$configs = @(@{ version = 'go_secuencial'; workers = 1 })
foreach ($w in $GoWorkers) { $configs += @{ version = 'go_paralelo'; workers = $w } }

function Get-Sample {
    $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $os = Get-CimInstance Win32_OperatingSystem
    [pscustomobject]@{ cpu_load_percent = $cpu; free_memory_kib = [int64]$os.FreePhysicalMemory }
}

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
$plan = (powercfg /getactivescheme) -join ' '
$battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$entorno = [ordered]@{
    campaign_id = $CampaignId
    phase = 'control_independiente'
    purpose = 'Control S8 de I6 en PC distinta de la oficial PCG1UL14N0; no interviene en comparaciones oficiales.'
    started_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    hostname = $env:COMPUTERNAME
    operator = $env:USERNAME
    reference_commit = '97ccc981e9068d8ec0753cd8a4b7572a6bece34d'
    git = 'sin repositorio local (.git ausente); trazabilidad por hash de fuentes contra source-hashes.json de s08_oficial_integrada_03'
    hardware = [ordered]@{
        cpu_model = $cpuInfo.Name.Trim()
        physical_cores = $cpuInfo.NumberOfCores
        logical_processors = $cpuInfo.NumberOfLogicalProcessors
        ram_visible_bytes = [int64]$cs.TotalPhysicalMemory
        ram_available_at_start_bytes = [int64]$os.FreePhysicalMemory * 1024
        os_edition = $os.Caption
        os_build = $os.BuildNumber
        power_plan = $plan
        power_source = if ($battery) { 'bateria presente' } else { 'AC (sin bateria detectada)' }
        temperature_monitoring = 'unavailable'
    }
    build = [ordered]@{
        go_version = (& go version)
        executable_sha256_by_version = [ordered]@{
            go_secuencial = (Get-FileHash -Algorithm SHA256 -LiteralPath $exe.go_secuencial).Hash
            go_paralelo   = (Get-FileHash -Algorithm SHA256 -LiteralPath $exe.go_paralelo).Hash
        }
    }
    plan = [ordered]@{ sizes = $Sizes; seed = $Seed; go_workers = $GoWorkers; warmups = 1; repetitions = 5; timeout_s = $TimeoutSeconds; order = 'por N; rondas 0..5; directo en pares, inverso en impares' }
}
$entorno | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'entorno.json') -Encoding UTF8

$csvPath = Join-Path $out 'mediciones.csv'
$bitacora = Join-Path $out 'bitacora.txt'
"Inicio $($entorno.started_at_utc); ejecucion serial; timeout=$TimeoutSeconds s; host=$env:COMPUTERNAME" | Set-Content -LiteralPath $bitacora -Encoding UTF8
$header = $null
$order = 0
$failures = 0
$t0 = Get-Date

foreach ($n in $Sizes) {
    for ($rep = 0; $rep -le 5; $rep++) {
        $round = if ($rep % 2 -eq 0) { $configs } else { $configs[($configs.Count - 1)..0] }
        foreach ($c in $round) {
            $order++
            $s = Get-Sample
            Add-Content -LiteralPath $bitacora -Value ("order={0} cpu_load_percent={1} free_memory_kib={2} temperature=unavailable" -f $order, $s.cpu_load_percent, $s.free_memory_kib)
            $runArgs = @('--n', "$n", '--seed', "$Seed", '--repetition', "$rep")
            if ($c.version -eq 'go_paralelo') { $runArgs += @('--workers', "$($c.workers)") }
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $exe[$c.version]
            $psi.Arguments = ($runArgs -join ' ')
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            [void]$psi.EnvironmentVariables.Remove('GOMAXPROCS')
            if ($c.version -eq 'go_secuencial') { $psi.EnvironmentVariables['GOMAXPROCS'] = '1' }
            $start = Get-Date
            $p = [System.Diagnostics.Process]::Start($psi)
            $stdoutTask = $p.StandardOutput.ReadToEndAsync()
            $stderrTask = $p.StandardError.ReadToEndAsync()
            $finished = $p.WaitForExit($TimeoutSeconds * 1000)
            if (-not $finished) { $p.Kill(); $p.WaitForExit() }
            $wall = ((Get-Date) - $start).TotalSeconds
            $stdout = $stdoutTask.Result; $stderr = $stderrTask.Result
            $dir = Join-Path $out ("logs\{0:D4}" -f $order)
            New-Item -ItemType Directory -Path $dir | Out-Null
            [IO.File]::WriteAllText((Join-Path $dir 'stdout.txt'), $stdout)
            [IO.File]::WriteAllText((Join-Path $dir 'stderr.txt'), $stderr)
            $lines = @($stdout -split "`r?`n" | Where-Object { $_ -match ',' })
            $status = 'OK'
            if (-not $finished) { $status = 'TIMEOUT' }
            elseif ($p.ExitCode -ne 0) { $status = "EXIT_$($p.ExitCode)" }
            elseif ($lines.Count -lt 2 -or $lines[-1] -notmatch ',OK$') { $status = 'CSV_INVALIDO' }
            if ($status -eq 'OK') {
                if (-not $header) { $header = $lines[0]; Set-Content -LiteralPath $csvPath -Value $header -Encoding UTF8 }
                Add-Content -LiteralPath $csvPath -Value $lines[-1] -Encoding UTF8
            } else { $failures++ }
            [ordered]@{ executable = $psi.FileName; arguments = $runArgs; gomaxprocs_env = $psi.EnvironmentVariables['GOMAXPROCS']; start_utc = $start.ToUniversalTime().ToString('o'); wall_s = [math]::Round($wall, 6); pid = $p.Id; exit_code = if ($finished) { $p.ExitCode } else { $null }; status = $status } |
                ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir 'proceso.json') -Encoding UTF8
            $label = if ($c.version -eq 'go_paralelo') { "go_paralelo_W$($c.workers)" } else { 'go_secuencial' }
            Add-Content -LiteralPath $bitacora -Value ("order={0} N={1} {2} rep={3} status={4} wall_s={5:N3}" -f $order, $n, $label, $rep, $status, $wall)
            Write-Host ("[{0}] N={1} {2} rep={3} {4} {5:N2}s" -f $order, $n, $label, $rep, $status, $wall)
        }
    }
}
$wallTotal = ((Get-Date) - $t0).TotalSeconds
[ordered]@{ status = if ($failures) { 'INCOMPLETE' } else { 'COMPLETE' }; planned = $order; accepted = $order - $failures; wall_s = [math]::Round($wallTotal, 3); ended_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'); data_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $csvPath).Hash } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out 'estado.json') -Encoding UTF8
if ($failures) { exit 1 }
exit 0
