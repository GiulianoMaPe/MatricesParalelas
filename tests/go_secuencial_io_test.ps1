param(
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug'
)

# I3/S5: standalone C/Go contract regression suite for I6 to integrate.
# Build both sequential executables with scripts/test_windows.ps1 first.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$executables = @{
    go_secuencial = Join-Path $projectRoot "go_secuencial\build\$Configuration\go_secuencial.exe"
    c_secuencial = Join-Path $projectRoot "c_secuencial\build\$Configuration\c_secuencial.exe"
}
foreach ($exe in $executables.Values) {
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Build missing: $exe" }
}
$runDir = Join-Path $projectRoot ("go_secuencial\build\$Configuration\s05-io\" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:sequence = 0
$results = New-Object 'System.Collections.Generic.List[object]'

function Invoke-Program {
    param([string]$Version, [string[]]$Arguments)
    $script:sequence++
    $stdout = Join-Path $runDir "$($script:sequence).stdout.csv"
    $stderr = Join-Path $runDir "$($script:sequence).stderr.txt"
    # All arguments are controlled flags, numbers or file paths (no quotes or
    # trailing backslash); quoting preserves spaces on Windows PowerShell 5.1.
    foreach ($argument in $Arguments) {
        if ($argument.Contains('"') -or $argument.EndsWith('\')) { throw 'Unsupported test argument.' }
    }
    $quoted = ($Arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $executables[$Version]
    $process.StartInfo.Arguments = $quoted
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    try {
        if (-not $process.Start()) { throw "Could not start $Version." }
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(15000)) {
            $process.Kill()
            $process.WaitForExit()
            throw "$Version exceeded 15 seconds: $quoted"
        }
        [IO.File]::WriteAllText($stdout, $outTask.Result, $utf8)
        [IO.File]::WriteAllText($stderr, $errTask.Result, $utf8)
        return [pscustomobject]@{
            Code = $process.ExitCode
            Stdout = $outTask.Result
            Stderr = $errTask.Result
        }
    } finally {
        $process.Dispose()
    }
}

function Assert-Success {
    param($Run, [string]$Label, [string]$Version)
    if ($Run.Code -ne 0 -or $Run.Stderr.Length -ne 0) {
        throw "$Label : exit=$($Run.Code); stderr=$($Run.Stderr)"
    }
    $records = @($Run.Stdout | ConvertFrom-Csv)
    if ($records.Count -ne 1 -or $records[0].validation_status -ne 'OK' -or
        $records[0].version -ne $Version -or @($records[0].PSObject.Properties).Count -ne 20) {
        throw "$Label : invalid CSV: $($Run.Stdout)"
    }
}

function Assert-SameMatrix {
    param([string]$Expected, [string]$Actual)
    $message = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'scripts\compare_results.ps1') -Expected $Expected -Actual $Actual
    if ($LASTEXITCODE -ne 0) { throw "Matrix mismatch: $Expected / $Actual; $message" }
}

function Test-InputCase {
    param([hashtable]$Case)
    $inputPath = Join-Path $runDir "$($Case.Name).input.txt"
    if ($Case.ContainsKey('Bytes')) {
        [IO.File]::WriteAllBytes($inputPath, $Case.Bytes)
    } else {
        [IO.File]::WriteAllText($inputPath, $Case.Input, $utf8)
    }
    $expectedPath = Join-Path $runDir "$($Case.Name).expected.txt"
    if ($Case.Valid) { [IO.File]::WriteAllText($expectedPath, $Case.Expected, $utf8) }
    foreach ($version in @('go_secuencial','c_secuencial')) {
        $output = Join-Path $runDir "$($Case.Name).$version.txt"
        if (-not $Case.Valid) { [IO.File]::WriteAllText($output, 'previous output', $utf8) }
        $run = Invoke-Program -Version $version -Arguments @('--input',$inputPath,'--output',$output)
        if ($Case.Valid) {
            Assert-Success $run "$($Case.Name)/$version" $version
            Assert-SameMatrix $expectedPath $output
        } else {
            if ($run.Code -ne 1 -or $run.Stdout.Length -ne 0 -or $run.Stderr.Length -eq 0) {
                throw "$($Case.Name)/$version : expected error=1, empty stdout, stderr; got $($run | ConvertTo-Json -Compress)"
            }
            if ([IO.File]::ReadAllText($output) -ne 'previous output') { throw "$($Case.Name)/$version replaced output on error." }
        }
        $results.Add([pscustomobject]@{ Case=$Case.Name; Version=$version; Exit=$run.Code; Status='OK' })
    }
    Write-Host "OK: $($Case.Name) (C/Go)"
}

try {
    $cases = @(
        @{ Name='lf'; Valid=$true; Input="1`n-3`n4`n"; Expected="1`n-12`n" },
        @{ Name='crlf'; Valid=$true; Input="1`r`n-3`r`n4`r`n"; Expected="1`n-12`n" },
        @{ Name='mixed'; Valid=$true; Input="1`r`n-3`n4`r`n"; Expected="1`n-12`n" },
        @{ Name='no-final-newline'; Valid=$true; Input="1`n-3`n4"; Expected="1`n-12`n" },
        @{ Name='whitespace'; Valid=$true; Input=" `t1 `n`t-3  `n4`t`n `t`n"; Expected="1`n-12`n" },
        @{ Name='long-row'; Valid=$true; Input=("1`n" + (' ' * 70000) + "-3`n4"); Expected="1`n-12`n" },
        @{ Name='decimals'; Valid=$true; Input="2`n+1 2.`n.5 -2e-1`n3 4`n5 6"; Expected="2`n13 16`n0.5 0.8`n" },
        @{ Name='asymmetric3'; Valid=$true; Input="3`n1 2 3`n4 5 6`n7 8 9`n9 8 7`n6 5 4`n3 2 1"; Expected="3`n30 24 18`n84 69 54`n138 114 90`n" },
        @{ Name='subnormal'; Valid=$true; Input="1`n4.9406564584124654e-324`n1"; Expected="1`n4.9406564584124654e-324`n" },
        @{ Name='underflow'; Valid=$true; Input="1`n-1e-9999`n1"; Expected="1`n0`n" },
        @{ Name='max-finite'; Valid=$true; Input="1`n1.7976931348623157e308`n1"; Expected="1`n1.7976931348623157e308`n" },
        @{ Name='empty'; Valid=$false; Input='' },
        @{ Name='header-data'; Valid=$false; Input="1 1`n2" },
        @{ Name='zero-n'; Valid=$false; Input="0`n1`n2" },
        @{ Name='negative-n'; Valid=$false; Input="-1`n1`n2" },
        @{ Name='signed-n'; Valid=$false; Input="+1`n1`n2" },
        @{ Name='fractional-n'; Valid=$false; Input="1.5`n1`n2" },
        @{ Name='byte-overflow-n'; Valid=$false; Input="1073741824`n1`n2" },
        @{ Name='integer-overflow-n'; Valid=$false; Input="18446744073709551616`n1`n2" },
        @{ Name='missing-row'; Valid=$false; Input="1`n1" },
        @{ Name='missing-value'; Valid=$false; Input="2`n1`n2 3`n4 5`n6 7" },
        @{ Name='fused-rows'; Valid=$false; Input="2`n1 2 3 4`n5 6`n7 8" },
        @{ Name='split-rows'; Valid=$false; Input="2`n1`n2 3 4`n5 6`n7 8" },
        @{ Name='blank-row'; Valid=$false; Input="1`n`n1`n2" },
        @{ Name='extra-value'; Valid=$false; Input="1`n1`n2 3" },
        @{ Name='extra-row'; Valid=$false; Input="1`n1`n2`n3" },
        @{ Name='bare-cr'; Valid=$false; Input="1`r1`r2" },
        @{ Name='bom'; Valid=$false; Input=([string][char]0xFEFF + "1`n1`n2") },
        @{ Name='nul'; Valid=$false; Input=("1`n1" + [char]0 + "`n2") },
        @{ Name='unicode-space'; Valid=$false; Input=("1`n1" + [char]0xA0 + "`n2") },
        @{ Name='invalid-utf8'; Valid=$false; Bytes=[byte[]](49,10,49,255,10,50) },
        @{ Name='invalid-tail'; Valid=$false; Input=("1`n1`n2`n" + [char]0) },
        @{ Name='product-overflow'; Valid=$false; Input="1`n1.7976931348623157e308`n2" }
    )
    $tokenIndex = 0
    foreach ($token in @('NaN','nan','Inf','-Infinity','1e309','-1e309','0x1p2','1_000','1,5','.','+','1e+','1#comment')) {
        $tokenIndex++
        $cases += @{ Name="token-a-$tokenIndex"; Valid=$false; Input="1`n$token`n2" }
        $cases += @{ Name="token-b-$tokenIndex"; Valid=$false; Input="1`n2`n$token" }
    }
    foreach ($fixture in @('producto2','escalar','identidad','cero','impar3')) {
        $cases += @{
            Name=$fixture; Valid=$true
            Input=[IO.File]::ReadAllText((Join-Path $projectRoot "tests\fixtures\$fixture.input.txt"))
            Expected=[IO.File]::ReadAllText((Join-Path $projectRoot "tests\fixtures\$fixture.expected.txt"))
        }
    }
    foreach ($case in $cases) { Test-InputCase $case }

    # Form a two-matrix input from actual C and Go writer output, with one N.
    $cRows = [IO.File]::ReadAllText((Join-Path $runDir 'producto2.c_secuencial.txt')).Replace("`r`n","`n")
    $goRows = [IO.File]::ReadAllText((Join-Path $runDir 'producto2.go_secuencial.txt')).Replace("`r`n","`n")
    $joined = $cRows.TrimEnd("`n") + "`n" + $goRows.Substring($goRows.IndexOf("`n") + 1)
    Test-InputCase @{ Name='writer-interoperability'; Valid=$true; Input=$joined; Expected="2`n1307 1518`n2967 3446`n" }

    foreach ($n in @(1,3,5)) {
        foreach ($seed in @('0','42','4294967295')) {
            $outputs = @{}
            foreach ($version in @('go_secuencial','c_secuencial')) {
                $output = Join-Path $runDir "generated-$n-$seed-$version.txt"
                $run = Invoke-Program -Version $version -Arguments @('--n',"$n",'--seed',$seed,'--output',$output)
                Assert-Success $run "N=$n seed=$seed/$version" $version
                $outputs[$version] = $output
                $results.Add([pscustomobject]@{ Case="generated-$n-$seed"; Version=$version; Exit=$run.Code; Status='OK' })
            }
            Assert-SameMatrix $outputs.c_secuencial $outputs.go_secuencial
        }
    }
    $leftovers = @(Get-ChildItem -LiteralPath $runDir -File | Where-Object { $_.Name -like '*.tmp*' -or $_.Name -like '.matrix-*' })
    if ($leftovers.Count -ne 0) { throw 'Temporary output files were not cleaned up.' }
    $results | Export-Csv -LiteralPath (Join-Path $runDir 'summary.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "OK: S05 I03 $Configuration; $($results.Count) C/Go executions; evidence: $runDir"
} catch {
    [Console]::Error.WriteLine("FAIL: $($_.Exception.Message); evidence: $runDir")
    exit 1
}
exit 0
