<#
.SYNOPSIS
Medicion individual S7/I3. La campana de cuatro versiones sigue pendiente de I5.
.EXAMPLE
.\scripts\bench_windows.ps1 -Version go_secuencial -N 256 -Seed 42
#>
param(
    [ValidateSet('all','c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'all',
    [ValidateRange(1,2147483647)][int]$N = 512,
    [uint32]$Seed = 42,
    [ValidateRange(1,1024)][int]$Workers = 2,
    [ValidateRange(1,1024)][int]$Processes = 2,
    [ValidateRange(1,1024)][int]$Threads = 2,
    [ValidateSet(5)][int]$Repetitions = 5,
    [ValidateRange(1,86400)][int]$TimeoutSeconds = 300,
    [string]$OutputDirectory
)
. "$PSScriptRoot\common_windows.ps1"

# I3 owns these functions. Dot-source this file to reuse them without starting a
# batch; I5 can call Invoke-GoSequentialMeasurement once per row of the full plan.
$script:GoSequentialHeader = 'timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status'
$script:GoSequentialUtf8 = [Text.UTF8Encoding]::new($false)

function ConvertFrom-GoSequentialCsv {
    param(
        [Parameter(Mandatory=$true)][string]$Csv,
        [Parameter(Mandatory=$true)][int]$N,
        [Parameter(Mandatory=$true)][uint32]$Seed,
        [Parameter(Mandatory=$true)][ValidateRange(0,5)][int]$Repetition,
        [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-f]{40}$')][string]$Commit,
        [Parameter(Mandatory=$true)][string]$Hostname
    )
    # ConvertFrom-Csv alone silently tolerates missing/extra fields.
    Add-Type -AssemblyName Microsoft.VisualBasic
    $reader = [IO.StringReader]::new($Csv)
    $parser = [Microsoft.VisualBasic.FileIO.TextFieldParser]::new($reader)
    try {
        $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
        $parser.SetDelimiters(',')
        $parser.HasFieldsEnclosedInQuotes = $true
        $parser.TrimWhiteSpace = $false
        $header = $parser.ReadFields()
        if ($null -eq $header -or $header.Count -ne 20 -or
            ($header -join ',') -cne $script:GoSequentialHeader) { throw 'Cabecera CSV incorrecta.' }
        $fields = $parser.ReadFields()
        if ($null -eq $fields -or $fields.Count -ne 20 -or -not $parser.EndOfData) {
            throw 'Se exige exactamente una fila CSV de veinte campos.'
        }
    } finally { $parser.Dispose(); $reader.Dispose() }
    $row = [ordered]@{}
    $names = $script:GoSequentialHeader.Split(',')
    for ($i = 0; $i -lt $names.Count; $i++) { $row[$names[$i]] = $fields[$i] }
    $expected = @{
        version='go_secuencial'; configuration='go_secuencial'; n="$N"; seed="$Seed"
        processes='1'; threads='1'; observed_threads='1'; workers='1'; gomaxprocs='1'
        repetition="$Repetition"; is_warmup=($Repetition -eq 0).ToString().ToLowerInvariant()
        validation_status='OK'; hostname=$Hostname
    }
    foreach ($name in $expected.Keys) {
        if ($row[$name] -cne $expected[$name]) { throw "CSV: $name no coincide con el parametro esperado." }
    }
    if ($row.commit -cnotmatch '^[0-9a-f]{7,40}$' -or -not $Commit.StartsWith($row.commit)) {
        throw 'CSV: commit no coincide con el ejecutable.'
    }
    $timestamp = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($row.timestamp, "yyyy-MM-dd'T'HH:mm:ss'Z'",
            [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$timestamp)) {
        throw 'CSV: timestamp UTC invalido.'
    }
    foreach ($name in @('cpu_model','os_version')) {
        if ([string]::IsNullOrWhiteSpace($row[$name])) { throw "CSV: falta $name." }
    }
    $numbers = @{}
    foreach ($name in @('ram_gb','kernel_s','total_s')) {
        $number = 0.0
        if ($row[$name] -cnotmatch '^\d+\.\d+$' -or
            -not [double]::TryParse($row[$name], [Globalization.NumberStyles]::AllowDecimalPoint,
                [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -or
            [double]::IsNaN($number) -or [double]::IsInfinity($number) -or $number -lt 0) {
            throw "CSV: $name no es un decimal finito no negativo."
        }
        $numbers[$name] = $number
    }
    if ($numbers.ram_gb -le 0 -or $numbers.kernel_s -gt $numbers.total_s -or
        $row.kernel_s -notmatch '^\d+\.\d{9}$' -or $row.total_s -notmatch '^\d+\.\d{9}$') {
        throw 'CSV: RAM o fronteras/formato de tiempos invalidos.'
    }
    return [pscustomobject]$row
}

function Invoke-GoSequentialProcess {
    param(
        [Parameter(Mandatory=$true)][string]$Executable,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [Parameter(Mandatory=$true)][string]$RunDirectory,
        [ValidateRange(1,86400)][int]$TimeoutSeconds = 300
    )
    # No shell, compilation or go run. Numeric CLI arguments need no escaping;
    # quoted paths are also supported for controlled process tests on PS 5.1.
    foreach ($argument in $Arguments) {
        if ($argument.Contains('"') -or $argument.EndsWith('\')) { throw 'Argumento no soportado.' }
    }
    $RunDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RunDirectory)
    New-Item -ItemType Directory -Path $RunDirectory -ErrorAction Stop | Out-Null
    $process = [Diagnostics.Process]::new()
    $started = $false
    $stdoutTask = $null
    $stderrTask = $null
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $record = [ordered]@{
        executable=$Executable; arguments=$Arguments; gomaxprocs='1'
        start_utc=[datetime]::UtcNow.ToString('o'); wall_s=$null
        pid=$null; exit_code=$null; status='ERROR'; detail=''
    }
    try {
        $process.StartInfo.FileName = $Executable
        $process.StartInfo.Arguments = ($Arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.StandardOutputEncoding = $script:GoSequentialUtf8
        $process.StartInfo.StandardErrorEncoding = $script:GoSequentialUtf8
        # Set the child's environment only; the calling session is unchanged.
        $process.StartInfo.EnvironmentVariables['GOMAXPROCS'] = '1'
        $started = $process.Start()
        if (-not $started) { throw 'No se pudo iniciar Go secuencial.' }
        $record.pid = $process.Id
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $record.status = 'TIMEOUT'
            throw "Go secuencial excedio $TimeoutSeconds segundos."
        }
        $record.exit_code = $process.ExitCode
        if ($process.ExitCode -ne 0) { throw "Go secuencial termino con codigo $($process.ExitCode)." }
        if ($stderrTask.Result.Length -ne 0) { throw 'Go secuencial emitio diagnosticos; revisar stderr.txt.' }
        $record.status = 'OK'
        return $stdoutTask.Result
    } catch {
        $record.detail = $_.Exception.Message
        throw
    } finally {
        try {
            if ($started -and -not $process.HasExited) {
                # This Go executable creates no child processes or MPI ranks.
                $process.Kill()
                if (-not $process.WaitForExit(5000)) { throw 'No se pudo terminar Go secuencial.' }
            }
            if ($started) { $record.exit_code = $process.ExitCode }
            foreach ($entry in @(@('stdout.txt',$stdoutTask), @('stderr.txt',$stderrTask))) {
                $content = if ($null -ne $entry[1]) { $entry[1].GetAwaiter().GetResult() } else { '' }
                [IO.File]::WriteAllText((Join-Path $RunDirectory $entry[0]), $content, $script:GoSequentialUtf8)
            }
        } finally {
            $watch.Stop()
            $record.wall_s = $watch.Elapsed.TotalSeconds
            [IO.File]::WriteAllText((Join-Path $RunDirectory 'proceso.json'),
                ($record | ConvertTo-Json -Depth 4), $script:GoSequentialUtf8)
            $process.Dispose()
        }
    }
}

function ConvertFrom-GoSequentialBuildMetadata {
    param(
        [Parameter(Mandatory=$true)][string[]]$Metadata,
        [Parameter(Mandatory=$true)][string]$Commit
    )
    $settings = @{}
    foreach ($line in $Metadata) {
        if ($line -match '^\s*build\s+(\S+?)=(.*)$') { $settings[$matches[1]] = $matches[2] }
    }
    if ($settings['GOOS'] -ne 'windows' -or $settings['GOARCH'] -ne 'amd64' -or
        $settings['vcs'] -ne 'git' -or $settings['vcs.revision'] -cnotmatch '^[0-9a-f]{40}$' -or
        $settings['vcs.modified'] -notin @('true','false')) {
        throw 'Faltan metadatos VCS o destino windows/amd64.'
    }
    foreach ($key in @('-gcflags','-race','-msan','-asan','-cover')) {
        if ($settings.ContainsKey($key) -and $settings[$key] -notin @('','false')) {
            throw "El ejecutable no es Release sin instrumentacion: $key."
        }
    }
    if ($Commit -cnotmatch '^[0-9a-f]{40}$' -or $settings['vcs.revision'] -cne $Commit) {
        throw 'El ejecutable no corresponde al HEAD actual. Recompile Release.'
    }
    return $settings
}

function Get-GoSequentialBuild {
    param([Parameter(Mandatory=$true)][string]$Executable)
    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) { throw "Compile primero Release: $Executable" }
    if ((Get-PEArchitecture $Executable) -ne 'x64') { throw 'Go secuencial debe ser PE x64.' }
    $go = (Get-Command go.exe -ErrorAction Stop).Source
    $metadata = @(& $go version -m $Executable)
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron leer los metadatos Go del ejecutable.' }
    $commit = & git -C $script:ProjectRoot rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo resolver HEAD.' }
    $settings = ConvertFrom-GoSequentialBuildMetadata -Metadata $metadata -Commit $commit
    return [pscustomobject]@{
        executable=$Executable; commit=$commit; configuration='Release'
        sha256=(Get-FileHash -LiteralPath $Executable -Algorithm SHA256).Hash
        metadata=$metadata; settings=$settings
    }
}

function Invoke-GoSequentialMeasurement {
    param(
        [Parameter(Mandatory=$true)]$Build,
        [Parameter(Mandatory=$true)][ValidateRange(1,2147483647)][int]$N,
        [Parameter(Mandatory=$true)][uint32]$Seed,
        [Parameter(Mandatory=$true)][ValidateRange(0,5)][int]$Repetition,
        [Parameter(Mandatory=$true)][string]$RunDirectory,
        [ValidateRange(1,86400)][int]$TimeoutSeconds = 300
    )
    $RunDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RunDirectory)
    if ((Get-FileHash -LiteralPath $Build.executable -Algorithm SHA256).Hash -ne $Build.sha256) {
        throw 'El ejecutable cambio desde la preparacion.'
    }
    $arguments = @('--n',"$N",'--seed',"$Seed",'--repetition',"$Repetition")
    $csv = Invoke-GoSequentialProcess -Executable $Build.executable -Arguments $arguments `
        -RunDirectory $RunDirectory -TimeoutSeconds $TimeoutSeconds
    try {
        $row = ConvertFrom-GoSequentialCsv -Csv $csv -N $N -Seed $Seed -Repetition $Repetition `
            -Commit $Build.commit -Hostname ([Environment]::MachineName)
        if ((Get-FileHash -LiteralPath $Build.executable -Algorithm SHA256).Hash -ne $Build.sha256) {
            throw 'El ejecutable cambio durante la medicion.'
        }
        return $row
    } catch {
        [IO.File]::WriteAllText((Join-Path $RunDirectory 'validacion_error.txt'),
            $_.Exception.Message, $script:GoSequentialUtf8)
        throw
    }
}

function Invoke-GoSequentialBenchmark {
    param([int]$N, [uint32]$Seed, [int]$TimeoutSeconds, [string]$OutputDirectory)
    $status = Get-Content -LiteralPath (Join-Path $script:ProjectRoot 'go_secuencial\status.json') -Raw | ConvertFrom-Json
    if ($status.algorithm -ne 'implemented' -or $status.validation -ne 'passed') {
        throw 'Go secuencial: algoritmo/validacion pendientes.'
    }
    $build = Get-GoSequentialBuild (Join-Path $script:ProjectRoot 'go_secuencial\build\Release\go_secuencial.exe')
    if (-not $OutputDirectory) {
        $id = [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '_' + [guid]::NewGuid().ToString('N')
        $OutputDirectory = Join-Path $script:ProjectRoot "resultados\diagnostico\s07-i03\$id"
    }
    $OutputDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
    New-Item -ItemType Directory -Path $OutputDirectory -ErrorAction Stop | Out-Null
    $manifest = [ordered]@{
        scope='S7 I3: Go secuencial; no es el piloto integrado'; protocol='1.3'
        build=$build; hostname=[Environment]::MachineName; n=$N; seed=$Seed
        repetitions=5; warmups=1; gomaxprocs=1; timeout_s=$TimeoutSeconds; status='INCOMPLETE'
    }
    $manifestPath = Join-Path $OutputDirectory 'entorno.json'
    try {
        [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 6), $script:GoSequentialUtf8)
        $plan = @('execution_order,n,configuration,seed,repetition,is_warmup')
        foreach ($r in 0..5) { $plan += "$($r+1),$N,go_secuencial,$Seed,$r,$(($r -eq 0).ToString().ToLowerInvariant())" }
        [IO.File]::WriteAllText((Join-Path $OutputDirectory 'plan.csv'), ($plan -join "`r`n") + "`r`n", $script:GoSequentialUtf8)
        $csvPath = Join-Path $OutputDirectory 'mediciones.csv'
        [IO.File]::WriteAllText($csvPath, $script:GoSequentialHeader + "`r`n", $script:GoSequentialUtf8)
        foreach ($r in 0..5) {
            $row = Invoke-GoSequentialMeasurement -Build $build -N $N -Seed $Seed -Repetition $r `
                -RunDirectory (Join-Path $OutputDirectory "r$r") -TimeoutSeconds $TimeoutSeconds
            $lines = @($row | ConvertTo-Csv -NoTypeInformation)
            [IO.File]::AppendAllText($csvPath, $lines[1] + "`r`n", $script:GoSequentialUtf8)
        }
        $manifest.status = 'COMPLETE'
        Write-Host "OK: Go secuencial, calentamiento y cinco medidas: $OutputDirectory"
    } catch {
        $manifest.status = 'FAILED'
        throw
    } finally {
        [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 6), $script:GoSequentialUtf8)
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Assert-Windows
        if ($Version -ne 'go_secuencial') {
            [Console]::Error.WriteLine('PENDIENTE: I1/I2/I4 e integracion I5. Solo -Version go_secuencial esta implementado por I3. No se crearon resultados.')
            exit 2
        }
        Invoke-GoSequentialBenchmark -N $N -Seed $Seed -TimeoutSeconds $TimeoutSeconds -OutputDirectory $OutputDirectory
    } catch {
        [Console]::Error.WriteLine($_.Exception.Message)
        exit 1
    }
    exit 0
}
