param([switch]$WithExecutable)

# Controlled tests never produce experimental observations. WithExecutable adds
# Windows acceptance with the actual, freshly compiled Release Go executable.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\scripts\bench_windows.ps1"
$testRoot = Join-Path $script:ProjectRoot ('tests\outputs\s07-i03\' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$results = [Collections.Generic.List[object]]::new()
$commit = '0123456789abcdef0123456789abcdef01234567'
$header = $script:GoSequentialHeader
$sample = [ordered]@{
    timestamp='2026-11-12T14:00:00Z'; version='go_secuencial'; commit=$commit
    hostname='PC-PRUEBA'; cpu_model='CPU, "prueba"'; ram_gb='15.900'
    os_version='Windows 11 Pro build 26200'; configuration='go_secuencial'
    n='3'; seed='42'; processes='1'; threads='1'; observed_threads='1'
    workers='1'; gomaxprocs='1'; repetition='1'; is_warmup='false'
    kernel_s='0.100000000'; total_s='0.200000000'; validation_status='OK'
}

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
function Test-Case {
    param([string]$Name, [scriptblock]$Action, [switch]$Reject)
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_ }
    if ($Reject -and $null -eq $caught) { throw "FAIL: $Name no fue rechazado." }
    if (-not $Reject -and $null -ne $caught) { throw "FAIL: $Name : $caught" }
    $results.Add([pscustomobject]@{ case=$Name; status='OK' })
}
function New-TestCsv {
    param([hashtable]$Changes = @{})
    $data = [ordered]@{}
    foreach ($key in $sample.Keys) { $data[$key] = $sample[$key] }
    foreach ($key in $Changes.Keys) { $data[$key] = $Changes[$key] }
    return (@([pscustomobject]$data | ConvertTo-Csv -NoTypeInformation) -join "`n") + "`n"
}
function Read-TestCsv {
    param([string]$Csv, [int]$Repetition = 1, [uint32]$Seed = 42)
    ConvertFrom-GoSequentialCsv -Csv $Csv -N 3 -Seed $Seed -Repetition $Repetition -Commit $commit -Hostname 'PC-PRUEBA'
}

try {
    Test-Case 'csv-valido-comillas-coma-y-20-campos' {
        $row = Read-TestCsv (New-TestCsv)
        Assert-That ($row.cpu_model -ceq $sample.cpu_model) 'Se altero el texto citado.'
    }
    foreach ($r in 0..5) {
        Test-Case "repeticion-$r" {
            Read-TestCsv (New-TestCsv @{repetition="$r"; is_warmup=($r -eq 0).ToString().ToLowerInvariant()}) -Repetition $r
        }
    }
    foreach ($seedValue in @([uint32]0, [uint32]::MaxValue)) {
        Test-Case "semilla-$seedValue" { Read-TestCsv (New-TestCsv @{seed="$seedValue"}) -Seed $seedValue }
    }
    Test-Case 'commit-prefijo-valido' { Read-TestCsv (New-TestCsv @{commit=$commit.Substring(0,7)}) }
    Test-Case 'tiempos-cero-validos' { Read-TestCsv (New-TestCsv @{kernel_s='0.000000000';total_s='0.000000000'}) }
    $bad = @{
        version='go_paralelo'; configuration='go_paralelo_W1'; n='4'; seed='43'
        processes='2'; threads='2'; observed_threads='2'; workers='2'; gomaxprocs='2'
        repetition='2'; is_warmup='true'; validation_status='PENDING'; hostname='OTRA-PC'
        commit=('f' * 40); timestamp='2026-02-30T14:00:00Z'; cpu_model=''; os_version=''
        ram_gb='0.000'; kernel_s='0.300000000'; total_s='-1.000000000'
    }
    foreach ($key in $bad.Keys) {
        Test-Case "rechazar-campo-$key" { Read-TestCsv (New-TestCsv @{$key=$bad[$key]}) } -Reject
    }
    foreach ($value in @('NaN','Inf','Infinity','1e309','0,2','1.2','')) {
        foreach ($field in @('kernel_s','total_s')) {
            Test-Case "rechazar-$field-$value" { Read-TestCsv (New-TestCsv @{$field=$value}) } -Reject
        }
    }
    Test-Case 'sin-fila' { Read-TestCsv ($header + "`n") } -Reject
    Test-Case 'doble-fila' { Read-TestCsv ((New-TestCsv) + (New-TestCsv).Split("`n")[1]) } -Reject
    Test-Case 'doble-cabecera' { Read-TestCsv ((New-TestCsv) + $header) } -Reject
    Test-Case 'campo-extra' { Read-TestCsv ((New-TestCsv).TrimEnd("`n") + ',extra') } -Reject
    Test-Case 'campo-faltante' { Read-TestCsv ((New-TestCsv).Replace(',"OK"','')) } -Reject
    Test-Case 'cabecera-invertida' { Read-TestCsv ((New-TestCsv).Replace('"timestamp","version"','"version","timestamp"')) } -Reject
    Test-Case 'comilla-sin-cerrar' { Read-TestCsv ($header + "`n`"sin cerrar") } -Reject
    Test-Case 'cultura-con-coma-decimal' {
        $previousCulture = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('es-ES')
            Read-TestCsv (New-TestCsv)
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture = $previousCulture }
    }

    $metadata = @('build GOOS=windows','build GOARCH=amd64','build vcs=git',"build vcs.revision=$commit",'build vcs.modified=false')
    Test-Case 'metadatos-release-vcs' { ConvertFrom-GoSequentialBuildMetadata $metadata $commit }
    Test-Case 'metadatos-arbol-modificado-diagnostico' {
        ConvertFrom-GoSequentialBuildMetadata ($metadata -replace 'modified=false','modified=true') $commit
    }
    foreach ($line in @('GOOS=linux','GOARCH=386','vcs=svn',('vcs.revision=' + ('f' * 40)),'vcs.modified=unknown')) {
        $key = $line.Split('=')[0]
        Test-Case "rechazar-build-$key" {
            $changed = @($metadata | Where-Object { -not $_.StartsWith("build $key=") }) + "build $line"
            ConvertFrom-GoSequentialBuildMetadata $changed $commit
        } -Reject
    }
    foreach ($flag in @('-gcflags=all=-N -l','-race=true','-msan=true','-asan=true','-cover=true')) {
        Test-Case "rechazar-instrumentacion-$flag" { ConvertFrom-GoSequentialBuildMetadata ($metadata + "build $flag") $commit } -Reject
    }
    Test-Case 'rechazar-build-sin-vcs' { ConvertFrom-GoSequentialBuildMetadata $metadata[0..1] $commit } -Reject

    # Run real OS processes to check capture, child-only environment and timeout.
    $fixture = Join-Path $testRoot 'proceso con espacios.ps1'
    $fixtureText = @'
param([string]$Mode, [string]$Value)
if ($Mode -eq 'timeout') { Start-Sleep -Seconds 30; exit 0 }
if ($Mode -eq 'stderr') { [Console]::Error.Write(('e' * 200000)); exit 0 }
if ($Mode -eq 'failure') { [Console]::Error.Write('fallo controlado'); exit 7 }
[Console]::Out.Write("GOMAXPROCS=$env:GOMAXPROCS; valor=$Value")
exit 0
'@
    [IO.File]::WriteAllText($fixture, $fixtureText, $script:GoSequentialUtf8)
    $shell = (Get-Process -Id $PID).Path
    $previousGomaxprocs = [Environment]::GetEnvironmentVariable('GOMAXPROCS','Process')
    try {
        $env:GOMAXPROCS = '7'
        foreach ($mode in @('success','failure','stderr','timeout')) {
            $runDirectory = Join-Path $testRoot "proceso-$mode"
            $arguments = @('-NoProfile','-NonInteractive','-File',$fixture,'-Mode',$mode,'-Value','ruta con espacios')
            $timeout = if ($mode -eq 'timeout') { 1 } else { 15 }
            $processError = $null
            try {
                $output = Invoke-GoSequentialProcess -Executable $shell -Arguments $arguments -RunDirectory $runDirectory -TimeoutSeconds $timeout
            } catch { $processError = $_ }
            Test-Case "proceso-$mode" {
                Assert-That (($null -ne $processError) -eq ($mode -ne 'success')) "Resultado del proceso inesperado: $processError"
                Assert-That ($env:GOMAXPROCS -ceq '7') 'Se altero GOMAXPROCS del padre.'
                $log = Get-Content -LiteralPath (Join-Path $runDirectory 'proceso.json') -Raw | ConvertFrom-Json
                $expectedStatus = if ($mode -eq 'timeout') { 'TIMEOUT' } elseif ($mode -eq 'success') { 'OK' } else { 'ERROR' }
                Assert-That ($log.status -ceq $expectedStatus) 'Estado de bitacora incorrecto.'
                Assert-That ($log.arguments.Count -eq $arguments.Count) 'Argumentos no conservados.'
                Assert-That ($null -eq (Get-Process -Id $log.pid -ErrorAction SilentlyContinue)) 'El proceso sigue vivo.'
                if ($mode -eq 'success') { Assert-That ($output -ceq 'GOMAXPROCS=1; valor=ruta con espacios') 'Argumentos/entorno hijo incorrectos.' }
                if ($mode -eq 'failure') { Assert-That ($log.exit_code -eq 7) 'Se perdio el codigo real.' }
                if ($mode -eq 'stderr') {
                    Assert-That ((Get-Item -LiteralPath (Join-Path $runDirectory 'stderr.txt')).Length -eq 200000) 'Captura stderr incompleta.'
                }
                foreach ($file in @('stdout.txt','stderr.txt','proceso.json')) {
                    $bytes = [IO.File]::ReadAllBytes((Join-Path $runDirectory $file))
                    Assert-That (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)) 'UTF-8 con BOM.'
                }
            }
        }
        Test-Case 'no-sobrescribir-corrida' {
            Invoke-GoSequentialProcess -Executable $shell -Arguments $arguments -RunDirectory $runDirectory
        } -Reject
        Test-Case 'ejecutable-ausente' {
            Invoke-GoSequentialProcess -Executable (Join-Path $testRoot 'ausente.exe') -Arguments @('--n','3') -RunDirectory (Join-Path $testRoot 'ausente')
        } -Reject
    } finally { [Environment]::SetEnvironmentVariable('GOMAXPROCS',$previousGomaxprocs,'Process') }

    # Synthetic batch checks. Only the process boundary and build lookup are
    # replaced; the plan, validator, hashes and CSV persistence are production.
    $syntheticExecutable = Join-Path $testRoot 'binario-sintetico.txt'
    [IO.File]::WriteAllText($syntheticExecutable, 'fixture, no ejecutable', $script:GoSequentialUtf8)
    $syntheticBuild = [pscustomobject]@{
        executable=$syntheticExecutable; commit=$commit
        sha256=(Get-FileHash -LiteralPath $syntheticExecutable -Algorithm SHA256).Hash
    }
    foreach ($batchMode in @('complete','invalid-r2')) {
        Test-Case "lote-sintetico-$batchMode" {
            function Get-GoSequentialBuild { param([string]$Executable); return $syntheticBuild }
            function Invoke-GoSequentialProcess {
                param($Executable, $Arguments, $RunDirectory, $TimeoutSeconds)
                New-Item -ItemType Directory -Path $RunDirectory | Out-Null
                $r = [int]$Arguments[5]
                $changes = @{
                    n=$Arguments[1]; seed=$Arguments[3]; hostname=[Environment]::MachineName
                    repetition="$r"; is_warmup=($r -eq 0).ToString().ToLowerInvariant()
                }
                if ($batchMode -eq 'invalid-r2' -and $r -eq 2) { $changes.gomaxprocs = '2' }
                return New-TestCsv $changes
            }
            $destination = Join-Path $testRoot "sintetico-$batchMode"
            $batchError = $null
            try { Invoke-GoSequentialBenchmark -N 3 -Seed 42 -TimeoutSeconds 10 -OutputDirectory $destination }
            catch { $batchError = $_ }
            $manifest = Get-Content -LiteralPath (Join-Path $destination 'entorno.json') -Raw | ConvertFrom-Json
            $rows = @(Import-Csv -LiteralPath (Join-Path $destination 'mediciones.csv'))
            $plan = @(Import-Csv -LiteralPath (Join-Path $destination 'plan.csv'))
            Assert-That ($plan.Count -eq 6 -and ($plan.repetition -join ',') -ceq '0,1,2,3,4,5') 'Plan incorrecto.'
            if ($batchMode -eq 'complete') {
                Assert-That ($null -eq $batchError -and $manifest.status -ceq 'COMPLETE' -and $rows.Count -eq 6) 'Lote completo incorrecto.'
                Assert-That (($rows.repetition -join ',') -ceq '0,1,2,3,4,5') 'Orden de medidas incorrecto.'
            } else {
                Assert-That ($null -ne $batchError -and $manifest.status -ceq 'FAILED' -and $rows.Count -eq 2) 'Fallo no conservado.'
                Assert-That (Test-Path -LiteralPath (Join-Path $destination 'r2\validacion_error.txt')) 'Falta motivo de rechazo.'
            }
            $before = [IO.File]::ReadAllText((Join-Path $destination 'mediciones.csv'))
            $overwriteRejected = $false
            try { Invoke-GoSequentialBenchmark -N 3 -Seed 42 -TimeoutSeconds 10 -OutputDirectory $destination }
            catch { $overwriteRejected = $true }
            Assert-That ($overwriteRejected -and $before -ceq [IO.File]::ReadAllText((Join-Path $destination 'mediciones.csv'))) 'Se sobrescribio un intento.'
        }
    }
    Test-Case 'rechazar-hash-alterado-antes-del-lanzamiento' {
        $changed = [pscustomobject]@{executable=$syntheticExecutable; commit=$commit; sha256=('0' * 64)}
        Invoke-GoSequentialMeasurement -Build $changed -N 3 -Seed 42 -Repetition 0 -RunDirectory (Join-Path $testRoot 'hash-invalido')
    } -Reject

    if ($WithExecutable) {
        Assert-Windows
        foreach ($dimension in @(1,3,17)) {
            foreach ($seedValue in @([uint32]0, [uint32]::MaxValue)) {
                Test-Case "ejecutable-N$dimension-semilla$seedValue" {
                    $destination = Join-Path $testRoot "real-N$dimension-semilla$seedValue"
                    Invoke-GoSequentialBenchmark -N $dimension -Seed $seedValue -TimeoutSeconds 30 -OutputDirectory $destination
                    $rows = @(Import-Csv -LiteralPath (Join-Path $destination 'mediciones.csv'))
                    Assert-That ($rows.Count -eq 6) 'No hay calentamiento y cinco medidas.'
                    Assert-That (($rows.repetition -join ',') -ceq '0,1,2,3,4,5') 'Repeticiones incorrectas.'
                    $manifest = Get-Content -LiteralPath (Join-Path $destination 'entorno.json') -Raw | ConvertFrom-Json
                    Assert-That ($manifest.status -ceq 'COMPLETE') 'Lote incompleto.'
                }
            }
        }
    }
    $results | Export-Csv -LiteralPath (Join-Path $testRoot 'summary.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "OK: S7 I3; $($results.Count) casos; ejecutable Windows=$WithExecutable; evidencia: $testRoot"
} catch {
    [Console]::Error.WriteLine("$($_.Exception.Message); evidencia: $testRoot")
    exit 1
}
exit 0
