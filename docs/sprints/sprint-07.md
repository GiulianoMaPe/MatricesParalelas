# Sprint 7 Automatizar los experimentos

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 7 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Dejar preparada una campaña que se pueda ejecutar sin editar manualmente cada comando.

Cierre: El piloto genera CSV válidos, repite correctamente, detecta fallos y conserva la configuración completa.

## Trabajo de cada integrante

Integrante 1  Completar el caso C secuencial del script de medición existente (3 h). Verificar tamaños, calentamiento, cinco repeticiones y errores (3 h). Entregable: Medición C secuencial validada. Ubicación: scripts/bench_windows.ps1.

Integrante 2  Completar el caso híbrido del script para combinaciones P y T (3 h). Registrar procesos e hilos observados y parámetros de cada ejecución (3 h). Entregable: Medición C paralelo validada. Ubicación: scripts/bench_windows.ps1.

Integrante 3  Completar el caso Go secuencial del script de medición (3 h). Verificar que se mida el ejecutable y que se registren sus parámetros (3 h). Entregable: Medición Go secuencial validada. Ubicación: scripts/bench_windows.ps1.

Integrante 4  Completar el caso Go paralelo del script con distintos workers (3 h). Comprobar el paralelismo solicitado y evitar campañas simultáneas (3 h). Entregable: Medición Go paralelo validada. Ubicación: scripts/bench_windows.ps1.

Integrante 5  Integrar y revisar los cuatro casos en bench_windows.ps1 (3 h). Validar CSV y rechazar resultados de funciones aún pendientes (3 h). Entregable: Campaña automatizada validada. Ubicación: scripts/bench_windows.ps1.

Integrante 6  Realizar un piloto completo en la PC oficial (3 h). Estimar duración total y revisar temperatura, carga y memoria disponible (3 h). Entregable: Piloto y reserva de tiempo de máquina. Ubicación: resultados/piloto/.

Integrante 7  Preparar agregación de medianas, dispersión y speedup (3 h). Comprobar los cálculos con un pequeño CSV manual de control (3 h). Entregable: Procedimiento de análisis verificado. Ubicación: scripts/summarize_results.ps1.

Integrante 8  Reproducir el piloto a partir de la versión candidata (3 h). Fijar la versión del código y los parámetros aceptados para medir (3 h). Entregable: Acta de congelación experimental. Ubicación: docs/campana.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-07.md.

I1 a I4 trabajan en funciones separadas del script; I5 integra después de su revisión. El piloto se guarda separado de los CSV oficiales de S8.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

## Registros individuales

#### Integrante 1 (Yessly)

- **Participantes y horas reales:** Yessly Poma (I1). Total: 8 h reales (3 h implementación del caso C secuencial en `scripts/bench_windows.ps1`; 3 h verificación de tamaños/warmup/repeticiones/errores y validación del esquema CSV de 20 campos; 1 h revisión cruzada a I2 Sebastian sobre el caso `c_paralelo`; 1 h coordinación).

- **Issues y pull requests:** rama de trabajo `feature/s07-i01-bench-c-secuencial`. PR pendiente de apertura.

- **Entregable principal:** Caso `c_secuencial` completado dentro de [`scripts/bench_windows.ps1`](../../scripts/bench_windows.ps1).

- **Cambios implementados en `scripts/bench_windows.ps1`:**
  - Soporte para selección de modo (`-Mode piloto` / `-Mode oficial`) que selecciona las dimensiones automáticamente: piloto $N \in \{256, 512, 1024\}$; oficial $N \in \{512, 1024, 2048\}$[cite: 9].
  - Definición de `$script:CsvHeader` con las 20 columnas exactas del contrato (§4 de `docs/contrato.md`)[cite: 3, 4].
  - Función `Validate-CsvRow`: parsea cabecera y fila de datos del binario, valida el esquema de 20 campos, verifica `version`, `n`, `seed`, `repetition`, coherencia `is_warmup`↔`repetition`, `validation_status=OK`, tiempos finitos no negativos y $0 \le \text{kernel\_s} \le \text{total\_s}$. Compatible con PowerShell 5.1 (sin `[double]::IsFinite`). Incluye parser RFC 4180 para campos entrecomillados.
  - Función `Run-CSecuencial`: localiza el binario en `c_secuencial/build/Release/c_secuencial.exe`, lo ejecuta con `System.Diagnostics.Process` capturando stdout/stderr por separado, verifica código de salida (`0`=OK, `1`=error, `2`=pendiente), parsea la salida CSV, aplica correcciones de contrato (`configuration` → `c_secuencial`, `gomaxprocs` → vacío para C) y retorna la fila validada o `$null` en caso de error.
  - Función `Invoke-CSecuencialCampaign`: ciclo completo de medición por cada dimensión $N$ — 1 warmup (rep `0`, `is_warmup=true`) + 5 repeticiones medidas (rep `1..5`, `is_warmup=false`)[cite: 8, 9]. Emite una sola cabecera CSV a stdout seguida de todas las filas y detiene la campaña ante cualquier fallo.
  - Despacho principal con `switch` por versión: `c_secuencial` invoca la campaña; `c_paralelo`, `go_secuencial` y `go_paralelo` reservados con `exit 2` para I2, I3 e I4 respectivamente.
  - Re-entrecomillado RFC 4180 de campos con comas/comillas al escribir las filas de salida.

- **Pruebas y evidencias:**
  - Validación de sintaxis PowerShell con `[PSParser]::Tokenize` y `git diff --check`: sin errores de formato ni espacios en blanco indebidos.
  - Compilación Release ejecutada el 12/11/2026 con `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_secuencial -Configuration Release` (código 0).
  - **Ejecución piloto completa (18/18 corridas exitosas, 100%)** en host `YESSLY-TB14G9` (AMD Ryzen 7 250, 15.183 GB RAM, Windows 10 Pro build 26200.9711, commit `352858d354706c2434b37c639d0910f4b9352f3e`):
    - Comando: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version c_secuencial -Mode piloto`
    - Esquema CSV de 20 columnas verificado en todas las filas, `validation_status=OK`, tiempos finitos y monotónicos ($0 \le \text{kernel\_s} \le \text{total\_s}$):
      - **$N=256$:** warmup `kernel_s=0.002619600` (`total_s=0.002640900`); repeticiones 1–5 en rango `0.002654300 s` – `0.003311000 s` (`total_s` en `0.002680200 s` – `0.003337600 s`).
      - **$N=512$:** warmup `kernel_s=0.028055000` (`total_s=0.028679000`); repeticiones 1–5 en rango `0.023453200 s` – `0.030295900 s` (`total_s` en `0.023783500 s` – `0.030676100 s`).
      - **$N=1024$:** warmup `kernel_s=0.291605600` (`total_s=0.292918000`); repeticiones 1–5 en rango `0.188395200 s` – `0.315428900 s` (`total_s` en `0.189407800 s` – `0.317795700 s`).

```csv
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status
2026-11-12T16:16:08Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,256,42,1,1,1,1,,0,true,0.002619600,0.002640900,OK
2026-11-12T16:16:08Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,256,42,1,1,1,1,,1,false,0.002778600,0.002804000,OK
2026-11-12T16:16:09Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,256,42,1,1,1,1,,2,false,0.002654300,0.002680200,OK
2026-11-12T16:16:09Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,256,42,1,1,1,1,,3,false,0.003311000,0.003337600,OK
2026-11-12T16:16:09Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,256,42,1,1,1,1,,4,false,0.002665600,0.002690000,OK
2026-11-12T16:16:09Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,256,42,1,1,1,1,,5,false,0.002678000,0.002702800,OK
2026-11-12T16:16:10Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,512,42,1,1,1,1,,0,true,0.028055000,0.028679000,OK
2026-11-12T16:16:11Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,512,42,1,1,1,1,,1,false,0.023453200,0.023783500,OK
2026-11-12T16:16:12Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,512,42,1,1,1,1,,2,false,0.030295900,0.030676100,OK
2026-11-12T16:16:13Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,512,42,1,1,1,1,,3,false,0.026058800,0.026719400,OK
2026-11-12T16:16:14Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,512,42,1,1,1,1,,4,false,0.023779300,0.024417100,OK
2026-11-12T16:16:15Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,512,42,1,1,1,1,,5,false,0.023823100,0.024193400,OK
2026-11-12T16:16:25Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,1024,42,1,1,1,1,,0,true,0.291605600,0.292918000,OK
2026-11-12T16:16:35Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,1024,42,1,1,1,1,,1,false,0.268481400,0.269935600,OK
2026-11-12T16:16:44Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,1024,42,1,1,1,1,,2,false,0.188395200,0.189407800,OK
2026-11-12T16:16:52Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,1024,42,1,1,1,1,,3,false,0.211929200,0.213725900,OK
2026-11-12T16:17:01Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,1024,42,1,1,1,1,,4,false,0.297586100,0.302498200,OK
2026-11-12T16:17:11Z,c_secuencial,352858d354706c2434b37c639d0910f4b9352f3e,YESSLY-TB14G9,AMD Ryzen 7 250 w/ Radeon 780M Graphics        ,15.183,Windows 10 Pro build 26200.9711,c_secuencial,1024,42,1,1,1,1,,5,false,0.315428900,0.317795700,OK
```

- **Bloqueos y decisiones:**
  - El binario compilado emite `configuration=Release` (de `PROJECT_CONFIGURATION`) en lugar de `c_secuencial`. Como no se modifica el código fuente (fuera del alcance de I1), el script corrige el campo a `c_secuencial` según el contrato y emite un aviso en stderr. Se recomienda coordinar con I5 para que el build script defina `PROJECT_CONFIGURATION` con el nombre de la versión.
  - El binario emite `gomaxprocs=1` para C; el script lo vacía según contrato §4 (vacío en versiones C).
  - Compatibilidad verificada con PowerShell 5.1.26100.

- **Revisión y criterio de aceptación:** El caso `c_secuencial` de `bench_windows.ps1` genera CSV válido, respeta el protocolo de warmup + repeticiones, detecta y reporta errores, y no interfiere con las secciones reservadas para I2/I3/I4. Pendiente: revisión cruzada de I2 y aceptación del equipo.

#### Integrante 4 (Eva)

- **Participantes y horas reales:** Eva Moreno (I4). El plan contempla 3 h para completar el caso go_paralelo con distintos workers, 3 h para comprobar el paralelismo solicitado y evitar campañas simultáneas, 1 h de revisión cruzada a I5 (Fernando) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s07-i04-bench-go-paralelo`. La revisión corresponde a I3 (Giuliano) según la rotación; la integración de los cuatro casos, a I5.

- **Entregable:** caso `go_paralelo` de [`scripts/bench_windows.ps1`](../../scripts/bench_windows.ps1). Solo se tocaron el bloque reservado para I4, su entrada en el despacho, el parámetro `-GoWorkers` y la guarda de dot-source, para no interferir con I1, I2 e I3.
  - **Serie de workers:** sin `-GoWorkers` se usa la del [protocolo](../protocolo_medicion.md): W=1, 2, 4 y W=8 solo con 8 o más núcleos físicos. Una lista explícita se ordena, se eliminan duplicados y se rechaza W=0, W>1024 o W mayor que los procesadores lógicos, porque `GOMAXPROCS=W` no daría paralelismo real.
  - **Paralelismo efectivo:** además del contrato CSV (`Validate-CsvRow` de I1), cada fila debe cumplir `workers=W`, `gomaxprocs=W` (valor efectivo de `runtime.GOMAXPROCS(0)`), `configuration=go_paralelo_W{W}` y `processes=threads=observed_threads=1`. Se elimina `GOMAXPROCS` del entorno del proceso hijo, para que no lo altere una variable heredada. Como diagnóstico, se registra en stderr el cociente entre tiempo de CPU y tiempo de pared del proceso.
  - **Campañas simultáneas:** se rechaza la campaña si hay un ejecutable de medición del proyecto en marcha (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`, `mpiexec` o `smpd`). Además, se toma `.cache\bench.lock` con el mismo modo exclusivo y el mismo formato JSON que el lock del caso c_paralelo (I2, [PR #51](https://github.com/GiulianoMaPe/MatricesParalelas/pull/51)), para que ambas campañas se excluyan. El lock se libera en `finally` y nunca se borra uno ajeno.
  - **Robustez:** cada corrida tiene un plazo de 1800 s; si lo supera, se termina el árbol de procesos. La campaña se detiene ante el primer error, rechaza más de 5 repeticiones medidas (el ejecutable acepta `--repetition` 0..5) y registra en stderr el SHA-256 del ejecutable.

- **Pruebas y evidencias:**
  - **Pruebas automáticas:** [`tests/bench_go_paralelo_test.ps1`](../../tests/bench_go_paralelo_test.ps1) usa ejecutables falsos (`.cmd`) y pasa sus 27 casos con `-WithExecutable`, que añade una campaña real corta con N=64 y W=1, 2 y 16. Cubre fila válida y calentamiento, cinco formas de paralelismo no efectivo, versión, repetición, estado, `kernel_s > total_s`, filas sobrantes, códigos 1 y 2, ejecutable ausente, plazo excedido, la serie de workers y sus rechazos, el lock (exclusivo, liberado y con huérfano ajeno conservado) y la detección de mediciones en curso.
  - **Comprobación de las pruebas:** en una copia aislada del repositorio inyecté tres fallos: quitar la comprobación de `gomaxprocs`, hacer el lock no exclusivo y no detectar procesos en curso. Las pruebas fallaron en los tres casos.
  - **Piloto real · 12/11/2026:** con `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version go_paralelo -Fase piloto` en el equipo de I4 (FLDSMDFR: AMD Ryzen 7 3700X, 8 núcleos y 16 hilos, 15,9 GB, Windows 11 Pro 26200, Go 1.27.1), sobre el commit `7cf0aae` más los cambios de esta rama. Resultados:
    - 72 de 72 corridas correctas en 156 s: N ∈ {256, 512, 1024} y W ∈ {1, 2, 4, 8}, con 1 calentamiento y 5 medidas cada una;
    - cabecera idéntica al contrato y todas las filas con `validation_status=OK`, `gomaxprocs=workers` y `kernel_s ≤ total_s`;
    - SHA-256 del ejecutable: `498153DA…103CE7`.
    - Los datos están en [`resultados/piloto/s07_i04_go_paralelo/`](../../resultados/piloto/s07_i04_go_paralelo/).

    | N | W=1 | W=2 | W=4 | W=8 |
    | ---: | ---: | ---: | ---: | ---: |
    | 256 | 0,0158 s | 0,0110 s | 0,0042 s | 0,0044 s |
    | 512 | 0,1360 s | 0,0710 s | 0,0398 s | 0,0229 s |
    | 1024 | 1,1304 s | 0,6310 s | 0,4007 s | 0,2270 s |

    *Mediana de `total_s` de las 5 medidas.*
  - **Campaña simultánea:** con el piloto en curso, una segunda campaña se rechazó en 1,5 s con "Hay mediciones en curso: go_paralelo[17472]", sin medir ni tocar el lock de la primera.
  - **Reloj:** con Go 1.27.1, `time.Now()` avanzó a pasos de 303,8 µs, frente a 100 ns de `QueryPerformanceCounter` ([`resolucion_reloj.txt`](../../resultados/piloto/s07_i04_go_paralelo/resolucion_reloj.txt)). Según la política de cierre del S6, los grupos con `total_s` menor de 100 ms (N=256 y N=512 con W≥2) quedan como diagnóstico de tiempos cortos.

- **Bloqueos y decisiones:**
  - El diagnóstico CPU/pared crece con W a partir de N ≥ 512 (con N=1024: 0,97 con W=1 y 1,24 con W=8), pero no llega a W. El tiempo de pared del proceso incluye la generación y la referencia secuencial. La verificación del paralelismo es `gomaxprocs=W`; el cociente es solo orientativo y no se usa para aceptar o rechazar.
  - Para la integración de I5: el lock y la detección de procesos se pueden unificar con los de I2, y la guarda de dot-source con la de I3.
  - Con `-Version all` el script sigue emitiendo una cabecera por caso; la unificación de la salida corresponde a I5.

- **Revisión y criterio de aceptación:** el caso go_paralelo genera CSV válido, repite correctamente, comprueba el paralelismo efectivo, detecta fallos y rechaza campañas simultáneas. Quedan pendientes la revisión de I3, mi revisión cruzada a I5 cuando publique su integración, las horas reales y la aceptación del equipo.
