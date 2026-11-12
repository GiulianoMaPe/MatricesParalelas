# Pruebas de Sprint 7 - Integrante 2
# Caso c_paralelo de scripts/bench_windows.ps1.
# No requieren MSVC ni MS-MPI: prueban las funciones puras del script.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\scripts\bench_windows.ps1')

$script:TestFailures = 0
$script:TestCount = 0

function Invoke-Test {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Block
    )
    $script:TestCount++
    try {
        & $Block
        Write-Host "PASS $Name"
    } catch {
        $script:TestFailures++
        Write-Host "FAIL $Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message. Esperado: '$Expected'. Obtenido: '$Actual'."
    }
}

function Assert-Throws {
    param([scriptblock]$Block, [string]$Message)
    $threw = $false
    try {
        & $Block | Out-Null
    } catch {
        $threw = $true
    }
    if (-not $threw) { throw "$Message. No se lanzo ninguna excepcion." }
}

$commit = 'a' * 40
$context = [pscustomobject]@{
    CampaignId = '20261112T100000Z_PC-TEST_aaaaaaaa_i02'
    Commit = $commit
    Hostname = 'PC-TEST'
    CpuModel = 'AMD Ryzen 5 5500'
    RamBytes = [uint64]16962355200
    OsVersion = 'Windows 10 build 19045'
}
$run = [pscustomobject]@{
    ExecutionOrder = 1
    N = 256
    Configuration = 'P2_T2'
    Processes = 2
    Threads = 2
    Seed = [uint32]42
    Repetition = 1
    IsWarmup = $false
}

$headerLine = 'timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status'
$validRow = "2026-11-12T10:00:00Z,c_paralelo,$commit,PC-TEST,AMD Ryzen 5 5500,15.798,Windows 10 build 19045,c_paralelo_P2_T2,256,42,2,2,2,1,,1,false,0.123456789,0.130000000,OK"
$validCsv = @($headerLine, $validRow) -join "`n"

Invoke-Test 'Cabecera CSV exacta' {
    Assert-True (Test-CsvHeader $script:CsvHeader) 'La cabecera canonica debe aceptarse.'
    $bad = @($script:CsvHeader)
    $bad[0] = 'fecha'
    Assert-True (-not (Test-CsvHeader $bad)) 'Una cabecera alterada debe rechazarse.'
}

Invoke-Test 'Parser CSV con comillas y comas' {
    $fields = @(ConvertFrom-CsvLine 'a,"b,c",d')
    Assert-Equal 3 $fields.Count 'Numero de campos'
    Assert-Equal 'b,c' $fields[1] 'Campo entre comillas'
    $line = ConvertTo-CsvLine @('a', 'b,c', 'd"e')
    Assert-Equal 'a,"b,c","d""e"' $line 'Serializacion CSV'
}

Invoke-Test 'Parser acepta una fila valida' {
    $parsed = Parse-CsvMeasurement $validCsv
    Assert-True $parsed.Ok "La fila valida debe aceptarse: $($parsed.Reason)"
    Assert-Equal 'c_paralelo' $parsed.Row.version 'version'
    $check = Test-MeasurementRow -Row $parsed.Row -Run $run -Context $context
    Assert-True $check.Valid "La fila debe pasar la validacion: $($check.Reason)"
}

Invoke-Test 'Parser acepta cpu_model con coma entre comillas' {
    $quoted = $validCsv.Replace('AMD Ryzen 5 5500', '"AMD, Ryzen 5 5500"')
    $parsed = Parse-CsvMeasurement $quoted
    Assert-True $parsed.Ok "La fila con coma entre comillas debe aceptarse: $($parsed.Reason)"
    Assert-Equal 'AMD, Ryzen 5 5500' $parsed.Row.cpu_model 'cpu_model'
}

Invoke-Test 'Parser rechaza linea extra' {
    $parsed = Parse-CsvMeasurement ($validCsv + "`nextra")
    Assert-True (-not $parsed.Ok) 'Una linea extra debe rechazarse.'
}

Invoke-Test 'Parser rechaza campo faltante' {
    $brokenRow = $validRow.Substring(0, $validRow.LastIndexOf(','))
    $parsed = Parse-CsvMeasurement (@($headerLine, $brokenRow) -join "`n")
    Assert-True (-not $parsed.Ok) 'Una fila con 19 campos debe rechazarse.'
}

Invoke-Test 'Validador rechaza observed_threads distinto de T' {
    $parsed = Parse-CsvMeasurement $validCsv
    $copy = $parsed.Row.PSObject.Copy()
    $copy.observed_threads = '1'
    $check = Test-MeasurementRow -Row $copy -Run $run -Context $context
    Assert-True (-not $check.Valid) 'observed_threads=1 con T=2 debe rechazarse.'
}

Invoke-Test 'Validador rechaza configuracion que no coincide' {
    $parsed = Parse-CsvMeasurement $validCsv
    $copy = $parsed.Row.PSObject.Copy()
    $copy.configuration = 'c_paralelo_P1_T2'
    $check = Test-MeasurementRow -Row $copy -Run $run -Context $context
    Assert-True (-not $check.Valid) 'Una configuracion distinta debe rechazarse.'
}

Invoke-Test 'Validador rechaza is_warmup incoherente' {
    $parsed = Parse-CsvMeasurement $validCsv
    $copy = $parsed.Row.PSObject.Copy()
    $copy.is_warmup = 'true'
    $check = Test-MeasurementRow -Row $copy -Run $run -Context $context
    Assert-True (-not $check.Valid) 'is_warmup=true con repetition=1 debe rechazarse.'
}

Invoke-Test 'Validador rechaza kernel_s mayor que total_s' {
    $parsed = Parse-CsvMeasurement $validCsv
    $copy = $parsed.Row.PSObject.Copy()
    $copy.kernel_s = '0.200000000'
    $copy.total_s = '0.100000000'
    $check = Test-MeasurementRow -Row $copy -Run $run -Context $context
    Assert-True (-not $check.Valid) 'kernel_s > total_s debe rechazarse.'
}

Invoke-Test 'Validador rechaza commit ajeno' {
    $parsed = Parse-CsvMeasurement $validCsv
    $copy = $parsed.Row.PSObject.Copy()
    $copy.commit = 'b' * 40
    $check = Test-MeasurementRow -Row $copy -Run $run -Context $context
    Assert-True (-not $check.Valid) 'Un commit distinto debe rechazarse.'
}

Invoke-Test 'Validador rechaza validation_status distinto de OK' {
    $parsed = Parse-CsvMeasurement $validCsv
    $copy = $parsed.Row.PSObject.Copy()
    $copy.validation_status = 'ERROR'
    $check = Test-MeasurementRow -Row $copy -Run $run -Context $context
    Assert-True (-not $check.Valid) 'validation_status=ERROR no puede pasar como OK.'
}

Invoke-Test 'Clasificacion de fallos' {
    Assert-Equal 'TIMEOUT' (Get-FailureStatus -ExitCode 1 -TimedOut $true -StdErr '') 'timeout'
    Assert-Equal 'PENDING' (Get-FailureStatus -ExitCode 2 -TimedOut $false -StdErr '') 'pendiente'
    Assert-Equal 'MISMATCH' (Get-FailureStatus -ExitCode 1 -TimedOut $false -StdErr 'ERROR: resultado incorrecto en C[1,2].') 'mismatch'
    Assert-Equal 'OOM' (Get-FailureStatus -ExitCode 1 -TimedOut $false -StdErr 'ERROR: no se pudo reservar memoria.') 'oom'
    Assert-Equal 'ERROR' (Get-FailureStatus -ExitCode 1 -TimedOut $false -StdErr 'otra cosa') 'error'
}

Invoke-Test 'Fila de fallo sin tiempos inventados' {
    $failure = New-FailureRow -Run $run -Context $context -Status 'TIMEOUT'
    Assert-Equal '' $failure.kernel_s 'kernel_s'
    Assert-Equal '' $failure.total_s 'total_s'
    Assert-Equal '' $failure.observed_threads 'observed_threads'
    Assert-Equal 'TIMEOUT' $failure.validation_status 'validation_status'
    Assert-Equal 'false' $failure.is_warmup 'is_warmup'
    Assert-Equal 'c_paralelo_P2_T2' $failure.configuration 'configuration'
}

Invoke-Test 'Configuracion P x T' {
    $config = Parse-BenchConfiguration 'P2_T4'
    Assert-Equal 'P2_T4' $config.Name 'nombre'
    Assert-Equal 2 $config.Processes 'procesos'
    Assert-Equal 4 $config.Threads 'hilos'
    Assert-Equal 8 $config.Budget 'presupuesto'
    $alternate = Parse-BenchConfiguration '1x2'
    Assert-Equal 'P1_T2' $alternate.Name 'formato alternativo'
}

Invoke-Test 'Configuraciones por defecto segun nucleos fisicos' {
    $six = Get-CParallelConfigurations -PhysicalCores 6
    Assert-Equal 'P1_T1,P1_T2,P2_T1,P1_T4,P2_T2,P4_T1' (($six.Configurations | ForEach-Object { $_.Name }) -join ',') '6 nucleos'
    $eight = Get-CParallelConfigurations -PhysicalCores 8
    Assert-Equal 10 $eight.Configurations.Count '8 nucleos'
    Assert-Equal 'P8_T1' $eight.Configurations[9].Name 'ultima configuracion W=8'
}

Invoke-Test 'Configuracion que excede nucleos fisicos se excluye' {
    $resolved = Get-CParallelConfigurations -Requested @('P1_T4', 'P1_T8') -PhysicalCores 6
    Assert-Equal 1 $resolved.Configurations.Count 'configuraciones validas'
    Assert-Equal 'P1_T4' $resolved.Configurations[0].Name 'configuracion conservada'
    Assert-Equal 1 $resolved.Excluded.Count 'exclusiones'
}

Invoke-Test 'Exclusion por memoria disponible' {
    $configs = @(
        [pscustomobject]@{ Name = 'P1_T1'; Processes = 1; Threads = 1; Budget = 1 }
    )
    $excluded = @(Get-CParallelCapacityExclusions -Sizes @(256) -Configurations $configs -AvailableRamBytes ([uint64]1048576)
    )
    Assert-Equal 1 $excluded.Count 'debe excluirse con 1 MiB disponible'
}

Invoke-Test 'Plan con warmup y rondas alternadas' {
    $configs = @(
        [pscustomobject]@{ Name = 'P1_T1'; Processes = 1; Threads = 1; Budget = 1 },
        [pscustomobject]@{ Name = 'P1_T2'; Processes = 1; Threads = 2; Budget = 2 }
    )
    $plan = New-CampaignPlan -Sizes @(256) -Configurations $configs -Seed 42 -Warmups 1 -Repetitions 5
    Assert-Equal 12 $plan.Rows.Count '12 corridas'
    Assert-Equal 0 $plan.Rows[0].repetition 'warmup 1'
    Assert-Equal 0 $plan.Rows[1].repetition 'warmup 2'
    Assert-Equal 'P1_T1' $plan.Rows[0].configuration 'warmup P1_T1'
    Assert-Equal 'P1_T2' $plan.Rows[1].configuration 'warmup P1_T2'
    Assert-Equal 'P1_T1' $plan.Rows[2].configuration 'ronda 1 directa'
    Assert-Equal 'P1_T2' $plan.Rows[3].configuration 'ronda 1 directa'
    Assert-Equal 'P1_T2' $plan.Rows[4].configuration 'ronda 2 inversa'
    Assert-Equal 'P1_T1' $plan.Rows[5].configuration 'ronda 2 inversa'
    Assert-Equal 5 $plan.Rows[11].repetition 'ultima ronda'
}

Invoke-Test 'plan.csv tiene cabecera y orden consecutivo' {
    $configs = @(
        [pscustomobject]@{ Name = 'P1_T1'; Processes = 1; Threads = 1; Budget = 1 }
    )
    $plan = New-CampaignPlan -Sizes @(256) -Configurations $configs -Seed 42 -Warmups 1 -Repetitions 2
    $path = Join-Path $env:TEMP ('plan-test-{0}.csv' -f ([guid]::NewGuid().ToString('N')))
    try {
        Write-CampaignPlan -Path $path -Rows $plan.Rows
        $lines = @(Get-Content -LiteralPath $path)
        Assert-Equal 'execution_order,n,configuration,seed,repetition,is_warmup' $lines[0] 'cabecera'
        Assert-Equal 4 $lines.Count 'cabecera + 3 corridas'
        Assert-Equal '1,256,P1_T1,42,0,true' $lines[1] 'primera fila'
        Assert-Equal '3,256,P1_T1,42,2,false' $lines[3] 'ultima fila'
    } finally {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
}

Invoke-Test 'entorno.json se genera con los campos obligatorios' {
    $configs = @(
        [pscustomobject]@{ Name = 'P1_T1'; Processes = 1; Threads = 1; Budget = 1 }
    )
    $plan = New-CampaignPlan -Sizes @(256) -Configurations $configs -Seed 42 -Warmups 1 -Repetitions 5
    $directory = Join-Path $env:TEMP ('entorno-test-{0}' -f ([guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    try {
        $fullContext = [pscustomobject]@{
            CampaignId = 'campaign-test'
            StartedAtUtc = '2026-11-12T10:00:00Z'
            Operator = 'tester'
            Hostname = 'PC-TEST'
            Commit = $commit
            Dirty = $false
            GitStatus = ''
            GitDiff = ''
            CpuModel = 'AMD Ryzen 5 5500'
            PhysicalCores = 6
            LogicalProcessors = 12
            RamBytes = [uint64]16962355200
            RamAvailableBytes = [uint64]8589934592
            OsEdition = 'Windows 10'
            OsBuild = '19045'
            OsVersion = 'Windows 10 build 19045'
            PowerSource = 'AC'
            PowerPlan = 'Alto rendimiento'
            MsvcVersion = '19.44'
            WindowsSdkVersion = '10.0'
            MsmPiRuntimeVersion = '10.1'
            MsmPiSdkVersion = '10.1'
            ExePath = 'C:\c_paralelo.exe'
            ExeSha256 = ('c' * 64)
            EffectiveOptions = '/O2 /MD'
            Configuration = 'Release'
        }
        New-CampaignEnvironment -Context $fullContext -Plan $plan -Exclusions @() -Sizes @(256) -Seed 42 -Warmups 1 -Repetitions 5 -TimeoutSeconds 120 -CampaignPath $directory
        $json = Get-Content -LiteralPath (Join-Path $directory 'entorno.json') -Raw | ConvertFrom-Json
        Assert-Equal 'campaign-test' $json.campaign_id 'campaign_id'
        Assert-Equal '1.3' $json.protocol_version 'protocol_version'
        Assert-Equal $commit $json.git.commit_full 'commit'
        Assert-Equal $fullContext.ExeSha256 $json.build.executable_sha256_by_version.c_paralelo 'sha256'
        Assert-Equal 'P1_T1' $json.experiment.ordered_configurations[0] 'configuracion'
        Assert-Equal 1 $json.experiment.omp_num_threads_by_configuration.P1_T1 'hilos OMP'
    } finally {
        if (Test-Path -LiteralPath $directory) { Remove-Item -LiteralPath $directory -Recurse -Force }
    }
}

Invoke-Test 'Lock impide dos campanas simultaneas' {
    $lockPath = Join-Path $env:TEMP ('bench-lock-test-{0}.lock' -f ([guid]::NewGuid().ToString('N')))
    $lock = $null
    $lock2 = $null
    try {
        $lock = Enter-CampaignLock -LockPath $lockPath -CampaignId 'campaign-a'
        Assert-True (Test-Path -LiteralPath $lockPath) 'El lock debe existir.'
        Assert-Throws { Enter-CampaignLock -LockPath $lockPath -CampaignId 'campaign-b' } 'La segunda campana debe rechazarse.'
        Exit-CampaignLock -Stream $lock -LockPath $lockPath -CampaignId 'campaign-a'
        $lock = $null
        Assert-True (-not (Test-Path -LiteralPath $lockPath)) 'El lock debe liberarse.'
        $lock2 = Enter-CampaignLock -LockPath $lockPath -CampaignId 'campaign-c'
        Assert-True (Test-Path -LiteralPath $lockPath) 'El lock debe poder reutilizarse.'
    } finally {
        if ($null -ne $lock) { Exit-CampaignLock -Stream $lock -LockPath $lockPath -CampaignId 'campaign-a' }
        if ($null -ne $lock2) { Exit-CampaignLock -Stream $lock2 -LockPath $lockPath -CampaignId 'campaign-c' }
        if (Test-Path -LiteralPath $lockPath) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
}

Invoke-Test 'Comando MPI cita rutas con espacios' {
    $text = ConvertTo-ProcessArgumentString @('-n', '2', 'C:\Program Files\c_paralelo.exe', '--n', '256')
    Assert-True $text.Contains('"C:\Program Files\c_paralelo.exe"') 'La ruta con espacios debe ir entre comillas.'
}

Write-Host ''
if ($script:TestFailures -gt 0) {
    Write-Host "FALLARON $($script:TestFailures) de $($script:TestCount) pruebas." -ForegroundColor Red
    exit 1
}
Write-Host "OK: $($script:TestCount) pruebas de c_paralelo pasaron." -ForegroundColor Green
exit 0
