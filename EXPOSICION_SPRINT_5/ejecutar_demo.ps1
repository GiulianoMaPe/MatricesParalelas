param(
    [ValidateSet('c_secuencial','c_paralelo','go_secuencial','go_paralelo')][string]$Version = 'c_secuencial',
    [ValidateSet('producto','dimension','limite','workers','truncado','sin_filas','comparar','comparar_todas','resumen','menu')][string]$Accion = 'producto'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$kitRoot = $PSScriptRoot
$outputRoot = Join-Path $kitRoot 'salidas'
$utf8 = [Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

function Find-MPILauncher {
    $command = Get-Command mpiexec.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    if ($env:MSMPI_BIN) {
        $candidate = Join-Path $env:MSMPI_BIN 'mpiexec.exe'
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $candidate = Join-Path $env:ProgramFiles 'Microsoft MPI\Bin\mpiexec.exe'
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    throw 'Falta MS-MPI Runtime. Use la comparacion C/Go sin MPI o prepare el runtime antes de exponer.'
}

function Show-Reference {
    Write-Host 'ENTRADA: N=2; A=[1 2; 3 4]; B=[5 6; 7 8]'
    Write-Host 'ESPERADO: C=[19 22; 43 50]'
    Write-Host ''
}

function Run-Demo([string]$Module, [string]$Case) {
    $exe = Join-Path $kitRoot "$Module\$Module.exe"
    if (-not (Test-Path -LiteralPath $exe)) { throw "Falta $exe. Ejecute 99_ACTUALIZAR_EJECUTABLES.bat antes de la exposicion." }
    $fixture = 'producto2'
    $processes = 2
    $threads = 2
    $expectedCode = 0
    $outputFile = Join-Path $outputRoot "$Module-$Case.txt"
    $keepPrevious = $false
    switch ($Case) {
        'producto' { $argsList = @('--input',(Join-Path $kitRoot 'datos\producto2.input.txt'),'--output',$outputFile) }
        'sin_filas' {
            if ($Module -ne 'c_paralelo') { throw 'La demostracion de procesos sin filas corresponde a C paralelo.' }
            $fixture = 'impar3'; $processes = 5; $threads = 1
            $argsList = @('--input',(Join-Path $kitRoot 'datos\impar3.input.txt'),'--output',$outputFile)
        }
        'dimension' { $expectedCode = 1; $argsList = @('--n','0','--seed','42') }
        'limite' {
            if ($Module -ne 'c_secuencial') { throw 'El limite 4096 corresponde a C secuencial.' }
            $expectedCode = 1; $argsList = @('--n','4097','--seed','42')
        }
        'workers' {
            if ($Module -ne 'go_paralelo') { throw 'El limite de workers corresponde a Go paralelo.' }
            $expectedCode = 1; $argsList = @('--n','2','--seed','42','--workers','1025')
        }
        'truncado' {
            $expectedCode = 1; $keepPrevious = $true
            [IO.File]::WriteAllText($outputFile, 'salida anterior conservada', $utf8)
            $argsList = @('--input',(Join-Path $kitRoot 'datos\truncado.input.txt'),'--output',$outputFile)
        }
        default { throw "Caso desconocido: $Case" }
    }
    if ($Module -eq 'go_paralelo' -and $Case -ne 'workers') { $argsList += @('--workers','2') }
    Write-Host "=== $Module / $Case ===" -ForegroundColor Cyan
    Write-Host "Codigo del programa esperado: $expectedCode"
    if ($Module -eq 'c_paralelo') { Write-Host "MPI: P=$processes procesos; OpenMP: T=$threads hilos por proceso" }
    if ($Case -eq 'sin_filas') { Write-Host 'N=3 y P=5: dos procesos no reciben filas y deben terminar correctamente.' }
    $process = [Diagnostics.Process]::new()
    try {
        $process.StartInfo.FileName = $exe
        if ($Module -eq 'c_paralelo') {
            $process.StartInfo.FileName = Find-MPILauncher
            $argsList = @('-n',"$processes",$exe) + $argsList
            $process.StartInfo.EnvironmentVariables['OMP_NUM_THREADS'] = "$threads"
            $process.StartInfo.EnvironmentVariables['OMP_DYNAMIC'] = 'FALSE'
        }
        foreach ($argument in $argsList) {
            if ($argument.Contains('"') -or $argument.EndsWith('\')) { throw 'Argumento de demostracion no soportado.' }
        }
        $process.StartInfo.Arguments = ($argsList | ForEach-Object { '"' + $_ + '"' }) -join ' '
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        if (-not $process.Start()) { throw 'No se pudo iniciar el programa.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(15000)) {
            & taskkill.exe /PID $process.Id /T /F | Out-Null
            throw 'La demostracion excedio 15 segundos; se detuvo el proceso de esta prueba.'
        }
        [IO.File]::WriteAllText((Join-Path $outputRoot "$Module-$Case.csv"),$stdout.Result,$utf8)
        [IO.File]::WriteAllText((Join-Path $outputRoot "$Module-$Case.stderr.txt"),$stderr.Result,$utf8)
        Write-Host "Codigo del programa observado: $($process.ExitCode)"
        if ($process.ExitCode -ne $expectedCode) { throw "Codigo inesperado. Diagnostico: $($stderr.Result) $($stdout.Result)" }
        if ($expectedCode -eq 1) {
            if ($stdout.Result.Length -ne 0 -or $stderr.Result.Length -eq 0) { throw 'Se esperaba stdout vacio y un diagnostico en stderr.' }
            Write-Host $stderr.Result.Trim() -ForegroundColor Yellow
            if ($keepPrevious) {
                if ([IO.File]::ReadAllText($outputFile) -ne 'salida anterior conservada') { throw 'Se reemplazo la salida previa.' }
                Write-Host 'La salida anterior permanece intacta.'
            }
            Write-Host 'PRUEBA APROBADA: rechazo controlado, codigo 1 y sin CSV valido.' -ForegroundColor Green
        } else {
            if ($stderr.Result.Length -ne 0) { throw "Diagnostico inesperado: $($stderr.Result)" }
            $rows = @($stdout.Result | ConvertFrom-Csv)
            if ($rows.Count -ne 1 -or $rows[0].version -ne $Module -or $rows[0].validation_status -ne 'OK') { throw 'CSV de validacion incorrecto.' }
            $rows | Format-Table version,n,processes,threads,workers,validation_status | Out-Host
            Write-Host 'MATRIZ C (primera linea: N):'
            Get-Content -LiteralPath $outputFile | Out-Host
            $expected = Join-Path $kitRoot "datos\$fixture.expected.txt"
            $comparison = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kitRoot 'comparar_resultados.ps1') -Expected $expected -Actual $outputFile)
            if ($LASTEXITCODE -ne 0) { throw "La matriz no coincide: $comparison" }
            $comparison | Out-Host
            Write-Host 'TIEMPOS DE ESTA DEMOSTRACION (no son una campana de rendimiento):'
            $rows | Format-Table kernel_s,total_s | Out-Host
            Write-Host 'PRUEBA APROBADA: producto contrastado con la referencia.' -ForegroundColor Green
        }
        Write-Host "Archivos de esta prueba: $outputRoot"
        Write-Host ''
    } finally { $process.Dispose() }
}

function Show-Summary {
    Write-Host '=== RESULTADOS HISTORICOS DEL CIERRE S5: 05/11/2026 ===' -ForegroundColor Cyan
    Get-Content -LiteralPath (Join-Path $kitRoot 'RESULTADOS_SPRINT_5.txt') | Out-Host
    Write-Host ''
    Write-Host 'Ultimas lineas de los logs originales (esta opcion no vuelve a ejecutar la bateria):'
    foreach ($name in @('evidencia_debug.log','evidencia_release.log')) {
        $path = Join-Path $kitRoot $name
        if (Test-Path -LiteralPath $path) { Write-Host $name; Get-Content -LiteralPath $path -Tail 2 | Out-Host }
    }
}

function Compare-Versions([switch]$All) {
    Show-Reference
    $modules = if ($All) { @('c_secuencial','go_secuencial','go_paralelo','c_paralelo') } else { @('c_secuencial','go_paralelo') }
    foreach ($module in $modules) { Run-Demo $module 'producto' }
    Write-Host "COMPARACION APROBADA: las $($modules.Count) versiones coinciden con el resultado esperado." -ForegroundColor Green
}

try {
    switch ($Accion) {
        'comparar' { Compare-Versions }
        'comparar_todas' { Compare-Versions -All }
        'resumen' { Show-Summary }
        'menu' {
            do {
                Write-Host ''
                Write-Host '=== EXPOSICION SPRINT 5 ===' -ForegroundColor Cyan
                Write-Host '1. Comparar C secuencial y Go paralelo (demo principal)'
                Write-Host '2. Rechazar N=4097 en C secuencial'
                Write-Host '3. Rechazar 1025 workers en Go paralelo'
                Write-Host '4. Mostrar resultados historicos Debug/Release'
                Write-Host '5. C paralelo: N=3 con P=5, procesos sin filas'
                Write-Host '6. Go secuencial: archivo truncado y destino conservado'
                Write-Host '7. Comparar las cuatro versiones (requiere MPI)'
                Write-Host '0. Salir'
                $selection = Read-Host 'Opcion'
                try {
                    switch ($selection) {
                        '1' { Compare-Versions }
                        '2' { Run-Demo 'c_secuencial' 'limite' }
                        '3' { Run-Demo 'go_paralelo' 'workers' }
                        '4' { Show-Summary }
                        '5' { Run-Demo 'c_paralelo' 'sin_filas' }
                        '6' { Run-Demo 'go_secuencial' 'truncado' }
                        '7' { Compare-Versions -All }
                        '0' { }
                        default { Write-Host 'Seleccione una opcion de la lista.' }
                    }
                } catch { Write-Host "DEMOSTRACION FALLIDA: $($_.Exception.Message)" -ForegroundColor Red }
                if ($selection -ne '0') { [void](Read-Host 'Enter para volver al menu') }
            } while ($selection -ne '0')
        }
        default { Run-Demo $Version $Accion }
    }
    exit 0
} catch { Write-Host "DEMOSTRACION FALLIDA: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
