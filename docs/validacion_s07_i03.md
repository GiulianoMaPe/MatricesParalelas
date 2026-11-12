# Sprint 7 · I3 · Medición Go secuencial

La entrega de Giuliano añade únicamente el caso Go secuencial a
`scripts/bench_windows.ps1`. La campaña integrada, el piloto, la agregación y la
congelación siguen a cargo de I5–I8. No cambia el algoritmo ni los cronómetros Go.

## Ejecutar en Windows

Desde la raíz, en Windows x64 con Go y Git en PATH:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version go_secuencial -Configuration Release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_go_secuencial_test.ps1 -WithExecutable
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version go_secuencial -N 256 -Seed 42 -TimeoutSeconds 300
```

Recompilar después de cambiar de commit. El medidor exige que el commit VCS del
binario coincida con HEAD. Rechaza un ejecutable ausente, un PE que no sea x64,
un destino distinto de windows/amd64 y opciones `-gcflags`, race, msan, asan o
coverage activas. `go version -m` inspecciona el ejecutable; nunca se usa `go run`
ni se compila dentro de las mediciones. El SHA-256 se comprueba antes y después
de cada corrida. El manifiesto conserva también `vcs.modified`: este ensayo de
desarrollo permite un binario compilado con cambios locales y no acredita la
revisión limpia ni los metadatos completos de la campaña oficial.

`-N` selecciona una dimensión; `-Seed` admite uint32 completo. `-Repetitions`
ahora admite exclusivamente 5: los valores anteriores hasta 1000 nunca estuvieron
implementados y excedían el contrato `--repetition 0..5`. Se ejecutan seis
procesos sucesivos: repetición 0 de calentamiento y medidas 1–5. Para una sola
combinación, el orden coincide con las seis rondas del protocolo. Ejecutar solo
un ensayo a la vez. El bloqueo y las rondas entre las cuatro versiones quedan
para la integración del equipo.

El proceso hijo recibe `GOMAXPROCS=1`; no se modifica la variable de la sesión.
Los valores efectivos del CSV deben ser P=T=observed_threads=workers=GOMAXPROCS=1.
También se validan N, semilla, repetición, calentamiento, versión/configuración,
commit y host. Se exige una sola fila de veinte campos, estado OK, metadatos
presentes y tiempos finitos con nueve decimales y `0 <= kernel_s <= total_s`.
El tiempo de pared del lanzador queda en la bitácora del proceso y no reemplaza
los tiempos internos del programa.

El destino predeterminado es
`resultados/diagnostico/s07-i03/<UTC_guid>/`; `-OutputDirectory` permite elegir
una carpeta nueva. No reutiliza ni sobrescribe una carpeta existente. Cada
intento guarda:

- `entorno.json`: alcance individual, binario/hashes/metadatos Go, host,
  parámetros, timeout y estado INCOMPLETE, FAILED o COMPLETE.
- `plan.csv`: calentamiento y cinco medidas con el orden previsto.
- `mediciones.csv`: una cabecera y únicamente observaciones aceptadas.
- `r0/` a `r5/`: `stdout.txt`, `stderr.txt`, `proceso.json` con argumentos, PID,
  código real, estado y duración de pared; `validacion_error.txt` si el CSV falla.

Los archivos de medición y diagnóstico se escriben en UTF-8 sin BOM. Ante fallo
se detiene el lote, conserva observaciones anteriores y marca FAILED. Un timeout
termina ese proceso Go, que no crea procesos hijos. No hay reintentos silenciosos
ni tiempos cero inventados. Los códigos del script son 0 para lote individual
completo, 1 para error y 2 para versiones/integración pendientes. `all` sigue
devolviendo 2 sin medir parcialmente Go.

## Integración para I5

```powershell
. .\scripts\bench_windows.ps1
$build = Get-GoSequentialBuild (Join-Path $script:ProjectRoot 'go_secuencial\build\Release\go_secuencial.exe')
$row = Invoke-GoSequentialMeasurement -Build $build -N 256 -Seed 42 -Repetition 0 -RunDirectory '.\tests\outputs\i5-go-r0' -TimeoutSeconds 300
```

La carga con dot-source define funciones sin iniciar procesos ni salir de la
sesión. Preparar `$build` una vez y usar una carpeta nueva por fila del plan;
la función devuelve un objeto de veinte propiedades solo al aceptar la corrida.
I5 conserva la responsabilidad de mezclar versiones en rondas alternadas, hacer
el control global de capacidad/concurrencia y completar el manifiesto del
protocolo. No incorporar estos ensayos individuales como piloto de I6.

## Evidencia y aceptación pendiente

El 12/11/2026 se ejecutaron **75 casos con resultado OK**, usando PowerShell
7.4.6 Linux x64 descargado temporalmente en `/tmp`, sin instalación del sistema:

```powershell
pwsh -NoProfile -NonInteractive -File ./tests/bench_go_secuencial_test.ps1
```

Se probaron las seis repeticiones, semillas 0/42/4294967295, CSV con comas/comillas,
parámetros incoherentes, campos extra/faltantes, filas/cabeceras duplicadas,
NaN/Inf, tiempos invertidos, cultura con coma decimal, commit/arquitectura VCS,
opciones de instrumentación, rutas con espacios, entorno hijo, salida 7, stderr
abundante, timeout, ejecutable ausente, hashes cambiados, rechazo de sobrescritura
y lotes sintéticos completos/fallidos con persistencia de observaciones válidas.
La prueba de timeout comprueba que el PID ya no existe. Los archivos de proceso
se comprueban sin BOM. Los datos de control quedan exclusivamente bajo
`tests/outputs/s07-i03/`, ignorados por Git.

La última salida local y `summary.csv` se conservan en
`tests/outputs/s07-i03/b09042ba8a7948dfa1d272bcc472f085/`.
Las pruebas usan procesos PowerShell controlados y metadatos/CSV sintéticos;
no acreditan tiempos del programa ni compatibilidad ejecutada en PowerShell 5.1.

La opción `-WithExecutable` exige Windows y añade seis lotes del binario real
para N=1,3,17 y semillas 0/4294967295, verificando seis observaciones por lote.
Está **pendiente de ejecución en Windows**; una plataforma o dependencia ausente
falla, no se omite como PASS. La revisión I2→I3 y las horas reales siguen
pendientes de declaración. Este documento no cierra el sprint del equipo.

## Resultado Windows y coexistencia · 12/11/2026

La aceptación Windows pendiente arriba ya se ejecutó: **81/81 casos OK** en
Windows PowerShell **5.1.26100.9711**, después de compilar el Release.
El historial previo se conserva como antecedente, no como estado vigente.

[Evidencia](../resultados/diagnostico/s07-i03/aceptacion_windows_20261112/aceptacion.json)
y [resumen de los 81 casos](../resultados/diagnostico/s07-i03/aceptacion_windows_20261112/summary.csv).
La misma carpeta contiene logs de pruebas y despachos, lotes reales completos
N=1/3/17 con semillas extremas y un lote Go secuencial N=256/seed=42.
El commit VCS del binario es `97f77291025b207b32331316294f262610db33bd`;
los cambios del medidor están en el árbol local, documentados como tal.
No se presenta esta evidencia como una versión congelada limpia.

Las funciones Go están en `scripts/bench_go_secuencial.ps1`, cargadas por el
punto de entrada común. Los otros módulos conservan las implementaciones de:

- I1: `59ac83f`, C secuencial.
- I2: `e1185a8133fa070e1855b533c93107480d0f8ee4`, C paralelo; se conservan
  funciones y configuración, sin el despacho duplicado/separador residual de esa rama.
- I4: `165115df9d81069e1a11204ef36aa0394b53a867`, Go paralelo.

Pruebas originales de regresión: **23/23 C paralelo** y **26/26 Go paralelo**.
Los cuatro despachos individuales funcionan: C secuencial y Go paralelo N=1
con seis corridas reales; Go secuencial N=256 con seis corridas reales;
C paralelo con N=1/P1_T1 en DryRun. DryRun no valida ejecución MPI.
Los módulos auxiliares se cargan desde `bench_windows.ps1`; para I5 sigue siendo
válido dot-sourcear ese archivo y llamar `Invoke-GoSequentialMeasurement`.

La firma común conserva `ValidateRange(1,1000)` para no restringir llamadas de
otros integrantes. Go secuencial rechaza valores distintos de 5 antes de medir.
C secuencial y Go paralelo conservan salida CSV por stdout; Go secuencial usa
OutputDirectory; C paralelo conserva sus opciones OutputRoot, CampaignId,
Configurations, NList y DryRun. Las opciones exclusivas de C paralelo se rechazan
explícitamente al usarlas con otro caso, en vez de ignorarlas.
`all` sigue reservado a la integración intercalada I5 y sale con código 2.
No hay afirmación de aceptación del piloto completo ni del cierre de equipo.

Giuliano declaró **8 horas reales totales**, sin desglose. Quedan pendientes
la aprobación humana I2→I3 y la confirmación de coordinación con I5.
No se atribuyen revisiones ni horas por actividad que no se hayan confirmado.