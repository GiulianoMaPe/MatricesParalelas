# Aceptación Windows del Sprint 6

Ejecución nativa del 12/11/2026. Base medida `72417b989c5ef8792970f57724a8f7bd639ca7e2`; entregas I4/I7
integradas antes de medir e I8 ya recibida en main. Se conserva el algoritmo de
las cuatro versiones. Son ensayos exploratorios de S6, separados de S7 y S8.

## Entorno y trazabilidad

AMD Ryzen 5 3600 6-Core Processor, 6 núcleos físicos y
12 lógicos, Microsoft Windows 11 Pro 10.0.26300.
RAM visible 16294.00 MiB; disponible al inicio
7872.51 MiB. Plan de energía registrado en el
[manifiesto](../resultados/piloto/s06_windows_20261112/environment.json); PC de escritorio sin batería detectada.
No se controló temperatura ni toda la carga de fondo: no se atribuyen causas
de caché o planificador a partir del tiempo solamente.

MSVC 19.44.35230 x64, herramientas 14.44.35207, Windows SDK 10.0.26100.0,
MS-MPI Runtime 10.1.12498.52 / SDK 10.1.12498.18 y Go 1.27.4 windows/amd64.
C usa `/std:c11 /O2 /MD /fp:precise`, `/openmp` en el híbrido. No `/GL`, LTO,
fast-math ni SIMD manual. Base/candidata C son unidades separadas.

Los [hashes de fuentes](../resultados/piloto/s06_windows_20261112/source-hashes.json), las fuentes archivadas,
el diff del árbol y los SHA-256 de [programas](../resultados/piloto/s06_windows_20261112/program-binaries.json) y
[harnesses](../resultados/piloto/s06_windows_20261112/laboratory-binaries.json) identifican lo realmente medido.
El diff de procedencia excluye los dos resumen.csv Linux que ya estaban
modificados al empezar. Los CSV y sus diferencias completas se conservan
localmente, sin incorporarlos a esta entrega pública.

## Plan y aceptación

El [plan previo](../resultados/piloto/s06_windows_20261112/plan.json) contiene 540 corridas: 90
calentamientos y 450 medidas, con N=256,512,1024,
semilla 42, W/T=1,2,4; un proceso nuevo por corrida, sin benchmarks simultáneos.
Se alternan rondas directas/inversas. Timeout por corrida 180 s, presupuesto
7200 s; no se usó el timeout corto de las pruebas funcionales.
Las 540 corridas finalizaron con código 0, comparación por celda y
`0 <= kernel_s <= total_s`; no hubo grupos incompletos.
Pared del lote con perfiles: 1456.3 s. No equivale a horas de trabajo.

Mediana=x3 e IQR=x4-x2 de cinco medidas; se conservan mínimo y máximo.
Los JSON `s06-laboratory-v1` y el CSV contractual de 20 columnas se mantienen
separados en los [originales](../resultados/piloto/s06_windows_20261112/runs/) y en las
[observaciones](../resultados/piloto/s06_windows_20261112/observations.jsonl). No son speedups oficiales de S8.

## Programas completos: mediana [IQR] total/kernel, ms

| Programa | N | P/T/W | Total | Kernel |
| --- | ---: | --- | ---: | ---: |
| go_paralelo | 1024 | 1/1/4 | 445.936 [77.183] | 444.928 [77.197] |
| go_paralelo | 1024 | 1/1/2 | 743.903 [215.424] | 742.898 [215.930] |
| go_paralelo | 1024 | 1/1/1 | 1349.703 [109.855] | 1348.162 [110.361] |
| go_secuencial | 1024 | 1/1/1 | 848.057 [59.975] | 847.052 [59.436] |
| c_paralelo | 1024 | 4/1/4 | 307.362 [5.266] | 298.920 [6.738] |
| c_paralelo | 1024 | 2/2/4 | 243.578 [28.270] | 237.580 [27.887] |
| c_paralelo | 1024 | 1/4/4 | 208.683 [64.702] | 204.701 [64.540] |
| c_paralelo | 1024 | 2/1/2 | 454.774 [114.542] | 448.310 [114.444] |
| c_paralelo | 1024 | 1/2/2 | 401.315 [101.296] | 396.953 [100.787] |
| c_paralelo | 1024 | 1/1/1 | 523.793 [41.984] | 519.761 [42.256] |
| c_secuencial | 1024 | 1/1/1 | 227.090 [20.418] | 226.069 [21.841] |
| go_paralelo | 512 | 1/1/4 | 47.777 [3.754] | 47.777 [3.754] |
| go_paralelo | 512 | 1/1/2 | 76.982 [3.364] | 76.471 [3.364] |
| go_paralelo | 512 | 1/1/1 | 141.976 [4.079] | 141.473 [4.583] |
| go_secuencial | 512 | 1/1/1 | 99.509 [10.167] | 99.509 [10.670] |
| c_paralelo | 512 | 4/1/4 | 26.762 [4.283] | 24.756 [3.603] |
| c_paralelo | 512 | 2/2/4 | 21.971 [3.396] | 20.420 [3.448] |
| c_paralelo | 512 | 1/4/4 | 21.350 [3.999] | 20.319 [4.095] |
| c_paralelo | 512 | 2/1/2 | 37.411 [1.820] | 35.745 [2.784] |
| c_paralelo | 512 | 1/2/2 | 34.610 [7.942] | 33.474 [7.954] |
| c_paralelo | 512 | 1/1/1 | 68.615 [5.065] | 67.664 [4.827] |
| c_secuencial | 512 | 1/1/1 | 25.411 [2.125] | 25.061 [2.125] |
| go_paralelo | 256 | 1/1/4 | 6.020 [1.099] | 6.020 [1.600] |
| go_paralelo | 256 | 1/1/2 | 9.863 [1.412] | 9.362 [1.912] |
| go_paralelo | 256 | 1/1/1 | 16.847 [0.677] | 16.708 [0.250] |
| go_secuencial | 256 | 1/1/1 | 11.627 [0.096] | 11.548 [0.358] |
| c_paralelo | 256 | 4/1/4 | 3.810 [0.509] | 2.860 [0.430] |
| c_paralelo | 256 | 2/2/4 | 3.655 [0.466] | 3.076 [0.486] |
| c_paralelo | 256 | 1/4/4 | 3.970 [1.014] | 3.628 [0.865] |
| c_paralelo | 256 | 2/1/2 | 4.166 [1.487] | 3.751 [1.232] |
| c_paralelo | 256 | 1/2/2 | 4.809 [0.520] | 4.514 [0.527] |
| c_paralelo | 256 | 1/1/1 | 8.342 [1.796] | 8.064 [1.710] |
| c_secuencial | 256 | 1/1/1 | 3.537 [0.801] | 3.496 [0.806] |

Los extremos y el tiempo de pared de cada grupo están en el
[resumen completo](../resultados/piloto/s06_windows_20261112/summary.csv). Las decisiones de candidatas están en
[optimizaciones](optimizaciones.md); las cifras anteriores del híbrido incluyen
Bcast, Scatterv, vaciado, región OpenMP y Gatherv, con reducciones fuera de T1.

## MPI real y memoria

En cada perfil MPI se conservan rank/PID, filas, primera fila, hilos solicitados
y observados en la región cronometrada, tiempos locales y máscaras de afinidad.
Los ranks vacíos declaran cero hilos de cálculo y kernel cero; el agregado CSV
histórico sigue reportando la configuración solicitada. No se copia ese agregado
para inventar observaciones individuales.

Se usa `-affinity_layout 0` y `MPIEXEC_AFFINITY=0`, con
`OMP_NUM_THREADS=T`, `OMP_DYNAMIC=FALSE`. Las máscaras se comprueban en los
procesos reales; desactivar afinidad permite múltiples procesadores, sin prometer
una fijación por núcleo físico ni un reparto exclusivo entre ranks.

La [verificación adicional](../resultados/piloto/s06_windows_20261112/verification/checks.json) confirma reparto con
resto, P>N, fallo OpenMP colectivo y dos timeouts (MS-MPI y supervisor externo),
con cero procesos de esas corridas restantes. El diagnóstico FUNNELED y los
errores de entradas truncadas/dimensiones están en la regresión común.
Las tablas y límites de memoria están en [memoria](memoria.md).

## Regresión, estabilidad y reloj

Debug y Release: cuatro versiones, 24 comparaciones, 49 errores controlados y
148 invocaciones C/Go por configuración. Logs y códigos en
[regresión](../resultados/piloto/s06_windows_20261112/regression/). Estabilidad Go: tres pasadas completas por módulo,
semillas complementarias, entradas inmutables y workers>N en las suites.
Veinte ejecuciones adicionales de candidatas C en N=1,3,7,17,65 validan cada celda.
Cuatro pruebas del runner cubren exclusión del calentamiento y rechazo de
duplicados/grupos fallidos. No se alteran matrices de salida para aceptar errores.

Resultado local del diagnóstico de reloj (texto original):

```text
=== RUN   TestPreciseClockResolution
    granularity_test.go:101: QueryPerformanceCounter: paso mínimo 100ns; time.Now: paso mínimo 495.6µs
--- PASS: TestPreciseClockResolution (0.12s)
PASS
ok  	matrices/go_paralelo	0.391s
```

La observación de resolución de I4 pertenece a Go 1.27.1 y otro equipo.
No se extrapola a todos los Windows. S7 debe registrar la resolución con el
toolchain/equipo final y tratar los tiempos cortos como diagnóstico cuando la
cuantización sea material. No se cambió el reloj de los programas de campaña.
En este equipo también se observó un paso cercano a 0,5 ms en Go. Se adopta
un umbral conservador de 100 ms para total y kernel en comparaciones Go: los
grupos que no lo alcanzan en todas sus medidas quedan como diagnóstico de
tiempos cortos. El margen cubre unos 200 pasos; no demuestra precisión absoluta
del 1%. Se conservan todas las filas, sin recortar ni rellenar sus tiempos.
La clasificación exacta está en `clock-policy.json` de la evidencia.
Los intentos locales `go test -race` se conservan con su código y diagnóstico;
si falta cgo/GCC no se presentan como PASS. La evidencia de race Linux y la de I4
en su equipo permanecen diferenciadas; no se exige instalar cgo para la batería nativa.

## Reproducir

Desde la raíz, con un directorio nuevo para no sobrescribir datos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_windows.ps1 -Version all -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_windows.ps1 -Version all -Configuration Release
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sprint06_windows.ps1 -Output resultados/piloto/s06_windows_nuevo
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sprint06_windows.ps1 -Output resultados/piloto/s06_windows_nuevo -Run
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sprint06_windows.ps1 -Output resultados/piloto/s06_windows_nuevo -Verify
```

Si Git detecta el propietario anterior, aplicar la excepción temporal a la
consola de pruebas, sin cambiar la confianza global:

```powershell
$env:GIT_CONFIG_COUNT='1'
$env:GIT_CONFIG_KEY_0='safe.directory'
$env:GIT_CONFIG_VALUE_0=(Get-Location).Path.Replace('\','/')
```

El wrapper inicializa MSVC y usa esa excepción solo en su proceso. `-Run` no
recompila los programas: ejecutar la regresión Release antes de medir.
La versión nueva del arnés I4 conserva QPC como diagnóstico auxiliar, pero
calcula total/kernel con el mismo reloj monotónico y rechaza tiempos inválidos.
Sus 72 corridas pequeñas de verificación no reemplazan ni reetiquetan las 720 históricas.
