param(
    [ValidateSet('c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version,
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug'
)
. "$PSScriptRoot\..\scripts\common_windows.ps1"
Assert-Windows
if (-not $Version) { throw 'Indique -Version.' }
$exe = Join-Path $script:ProjectRoot "$Version\build\$Configuration\$Version.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Compile primero: $exe" }
$runDir = Join-Path $script:ProjectRoot ("$Version\build\$Configuration\s05-errors\" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
$results = [Collections.Generic.List[object]]::new()
$badInput = Join-Path $runDir 'truncated.txt'
$nanInput = Join-Path $runDir 'nan.txt'
$overflowInput = Join-Path $runDir 'overflow.txt'
[IO.File]::WriteAllText($badInput, "2`n1 2`n3 4`n5 6`n", $utf8)
[IO.File]::WriteAllText($nanInput, "1`nNaN`n1`n", $utf8)
[IO.File]::WriteAllText($overflowInput, "1`n1e308`n1e308`n", $utf8)
$cases = @(
    @{ Name='missing-value'; Args=@('--n') },
    @{ Name='zero-dimension'; Args=@('--n','0','--seed','42') },
    @{ Name='negative-dimension'; Args=@('--n','-1','--seed','42') },
    @{ Name='nonnumeric-dimension'; Args=@('--n','abc','--seed','42') },
    @{ Name='seed-overflow'; Args=@('--n','2','--seed','4294967296') },
    @{ Name='invalid-repetition'; Args=@('--n','2','--seed','42','--repetition','6') },
    @{ Name='missing-input'; Args=@('--input',(Join-Path $runDir 'missing.txt')) },
    @{ Name='truncated-input'; Args=@('--input',$badInput) },
    @{ Name='nonfinite-input'; Args=@('--input',$nanInput) },
    @{ Name='nonfinite-product'; Args=@('--input',$overflowInput) },
    @{ Name='output-directory'; Args=@('--n','2','--seed','42','--output',$runDir); OutputFailure=$true }
)
if ($Version -eq 'go_paralelo') {
    foreach ($workers in @('0','-1','1025')) {
        $cases += @{ Name="workers-$workers"; Args=@('--n','2','--seed','42','--workers',$workers) }
    }
}
if ($Version -eq 'c_paralelo') {
    $cases += @{ Name='mpi-dimension-limit'; Args=@('--n','46341','--seed','42') }
    $cases += @{ Name='invalid-openmp'; Args=@('--n','2','--seed','42'); InvalidOpenMP=$true }
}

foreach ($case in $cases) {
    $process = [Diagnostics.Process]::new()
    try {
        $outputPath = Join-Path $runDir "$($case.Name).output.txt"
        [IO.File]::WriteAllText($outputPath, 'previous output', $utf8)
        $programArgs = @($case.Args)
        if (-not $case.ContainsKey('OutputFailure')) { $programArgs += @('--output',$outputPath) }
        if ($Version -eq 'c_paralelo') {
            $process.StartInfo.FileName = Get-MPILauncher
            # P>N for N=2: failures must also terminate ranks without rows.
            $programArgs = @('-n','3',$exe) + $programArgs
            $process.StartInfo.EnvironmentVariables['OMP_NUM_THREADS'] = '2'
            $process.StartInfo.EnvironmentVariables['OMP_DYNAMIC'] = if ($case.ContainsKey('InvalidOpenMP')) { 'TRUE' } else { 'FALSE' }
        } else { $process.StartInfo.FileName = $exe }
        foreach ($argument in $programArgs) {
            if ($argument.Contains('"') -or $argument.EndsWith('\')) { throw 'Argumento de prueba no soportado.' }
        }
        $process.StartInfo.Arguments = ($programArgs | ForEach-Object { '"' + $_ + '"' }) -join ' '
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        if (-not $process.Start()) { throw 'No se pudo lanzar el proceso.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(15000)) {
            # Kill only this test's process tree, including its MPI launcher.
            & taskkill.exe /PID $process.Id /T /F | Out-Null
            throw 'Timeout: el caso no termino en 15 s.'
        }
        [IO.File]::WriteAllText((Join-Path $runDir "$($case.Name).stdout.txt"), $stdout.Result, $utf8)
        [IO.File]::WriteAllText((Join-Path $runDir "$($case.Name).stderr.txt"), $stderr.Result, $utf8)
        if ($process.ExitCode -ne 1 -or $stdout.Result.Length -ne 0 -or $stderr.Result.Length -eq 0) {
            throw "Se esperaba exit=1, stdout vacio y stderr; exit=$($process.ExitCode); stderr=$($stderr.Result)"
        }
        if ([IO.File]::ReadAllText($outputPath) -ne 'previous output') { throw 'Se altero la salida anterior.' }
        $results.Add([pscustomobject]@{ Case=$case.Name; Version=$Version; Exit=$process.ExitCode; Status='OK' })
        Write-Host "OK: $Version/$($case.Name)"
    } catch {
        $results.Add([pscustomobject]@{ Case=$case.Name; Version=$Version; Exit=$null; Status='FAIL' })
        throw "$Version/$($case.Name): $($_.Exception.Message)"
    } finally {
        $process.Dispose()
        $results | Export-Csv -LiteralPath (Join-Path $runDir 'summary.csv') -NoTypeInformation -Encoding UTF8
    }
}
Write-Host "OK: S05 $Version $Configuration; $($results.Count) errores controlados; evidencia: $runDir"
