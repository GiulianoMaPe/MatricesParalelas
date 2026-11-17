# Sprint 7 Automatizar los experimentos

Estado: integración técnica S7 preparada y verificada con pruebas controladas en Linux; pendiente aceptación del piloto completo y reproducción en Windows nativo. El registro del 17/11/2026 al final sustituye los estados históricos anteriores.

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

### I3 · Giuliano · 12/11/2026

- Rama: `feature/s07-i03-medicion-go-secuencial`, desde `352858d`.
- Implementación: caso `-Version go_secuencial` en `scripts/bench_windows.ps1`.
  Ejecuta exclusivamente `go_secuencial/build/Release/go_secuencial.exe`, con
  `--n`, `--seed`, `--repetition` y `GOMAXPROCS=1` en el proceso hijo.
- Comprueba PE x64, metadatos VCS/HEAD, ausencia de opciones Debug/instrumentación,
  SHA-256 antes/después, veinte columnas CSV, parámetros solicitados/efectivos y
  tiempos internos. Registra calentamiento y cinco medidas; conserva stdout,
  stderr, argumentos, PID, código real, timeout y estado del lote.
- Validación local: **75 casos aprobados con PowerShell 7.4.6 sobre Linux**,
  incluidos procesos controlados, stderr de 200000 bytes, terminación por timeout,
  lotes sintéticos completos/fallidos y conservación de resultados parciales.
  Estos datos sintéticos no son observaciones experimentales.
- [Procedimiento, evidencia y límites](../validacion_s07_i03.md). Falta ejecutar
  `tests/bench_go_secuencial_test.ps1 -WithExecutable` en Windows PowerShell 5.1
  con Release recién compilado. No se acredita todavía aceptación Windows.
- Integración: I5 puede invocar `Invoke-GoSequentialMeasurement` para cada fila
  del plan general. `all`, C y Go paralelo mantienen salida 2 sin mediciones.
- Revisión I2→I3 y coordinación con I5: pendientes de confirmación humana.
  No se ejecutó el piloto ni se completaron tareas de otros integrantes.

- Participantes y horas reales: I3 · Giuliano · **8 h reales**, declaradas por el integrante el 12/11/2026. Desglose no declarado; no se presume revisión ni coordinación completadas.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

### Actualización I3 · aceptación Windows · 12/11/2026

- **Aceptación técnica individual ejecutada:** Windows PowerShell 5.1.26100.9711,
  Go Release recién compilado, `tests/bench_go_secuencial_test.ps1 -WithExecutable`:
  **81/81 casos OK**, incluidos 6 lotes reales, N=1/3/17 y semillas
  0/4294967295 (un calentamiento y cinco medidas por lote).
- Refactorización: despacho común en `scripts/bench_windows.ps1` y funciones
  separadas en `bench_c_secuencial.ps1`, `bench_c_paralelo.ps1`,
  `bench_go_secuencial.ps1`, `bench_go_paralelo.ps1`. Se conservan las funciones
  de I1/I2/I4; se excluyó el despacho duplicado y el separador `=======` presentes
  en la fuente remota de I2. No se importaron esos errores a la entrega.
- Regresión Windows: I2 **23/23**, I4 **26/26**. Despachos reales de C secuencial
  N=1, Go paralelo N=1/W=1 y Go secuencial N=256 terminan con código 0.
  C paralelo N=1/P1_T1 genera su plan con `-DryRun`, código 0; esto no acredita
  una campaña MPI real ni reemplaza la aceptación de I2.
- Compatibilidad: `Repetitions` conserva el rango público 1..1000 de I2.
  El caso Go secuencial exige exactamente 5 y calentamiento 1 antes de medir.
  `all` rechaza sin mediciones: la campaña intercalada corresponde a I5.
- [Evidencia persistente](../../resultados/diagnostico/s07-i03/aceptacion_windows_20261112/aceptacion.json):
  entorno, commit de compilación, hash, logs, resumen de pruebas y CSV/bitácoras
  de seis lotes reales más el ensayo N=256. Son ensayos de aceptación, no el piloto oficial.
- **Horas reales I3: 8 h**, confirmadas por Giuliano; sin desglose inventado.
- **Revisión I2→I3:** Sebastián aprobó el [PR #49](https://github.com/GiulianoMaPe/MatricesParalelas/pull/49#pullrequestreview-5882691934) el 12/11/2026.
  La aceptación Windows y la corrección están publicadas en `dc9040e`. Sigue
  pendiente confirmar la coordinación con I5; el sprint completo del equipo sigue abierto.
- El registro anterior describe el estado previo; esta actualización sustituye
  sus pendientes técnicos de Windows e integración individual y sus horas pendientes.

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

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h desarrollo del motor de agregación no paramétrica, speedup, eficiencia y GFLOPS en `scripts/summarize_results.ps1`; 3 h diseño del fixture manual de control `tests/fixtures/control_mediciones.csv` y suite automatizada de 43 pruebas en `tests/summarize_results_test.ps1`; 1 h revisión cruzada a I8 Roberto sobre los criterios de congelación experimental de `docs/campana.md`; 1 h coordinación de equipo y documentación).

- **Issues y pull requests:** rama de trabajo `feature/s07-i07-analisis-estadistico-speedup`. PR pendiente de apertura y fusión tras revisión.

- **Entregables principales:**
  1. [`scripts/summarize_results.ps1`](../../scripts/summarize_results.ps1): Script PowerShell (compatible con PS 5.1 y 7+) de agregación estadística y cálculo de métricas canónicas de rendimiento.
  2. [`tests/fixtures/control_mediciones.csv`](../../tests/fixtures/control_mediciones.csv): Conjunto de datos manual de control con valores predecibles y cobertura exhaustiva de casos normales, errores (`ERROR`), warmups y referencias faltantes.
  3. [`tests/summarize_results_test.ps1`](../../tests/summarize_results_test.ps1): Batería automatizada de 43 pruebas que validan rigurosamente los cálculos matemáticos contra los valores analíticos esperados.

- **Cambios e implementación técnica:**
  - **Flexibilidad de Entrada y Salida:** Acepta datos mediante `-InputPath` (uno o varios archivos), objetos en la tubería (`Get-Content ... | .\scripts\summarize_results.ps1`), parámetro posicional `-InputObject`, o lectura por defecto desde `resultados/piloto/mediciones.csv`. Admite exportación directa a `-OutputPath` en formato UTF-8 sin BOM, emisión a stdout para concatenar scripts, o retorno estructurado de objetos con `-PassThru`.
  - **Conformidad Estricta con el Protocolo (§6.1, §6.3):**
    - Descarte riguroso de precalentamiento (`is_warmup == 'true'` o `repetition == 0`).
    - Descarte de ejecuciones fallidas (`validation_status != 'OK'`).
    - Validación de duraciones finitas, positivas y consistentes ($0 \le \text{kernel\_s} \le \text{total\_s}$).
  - **Agrupamiento Canónico y Estadísticas No Paramétricas:**
    - Agrupación por clave canónica `hostname|commit|version|configuration|n|seed`.
    - Para $R=5$ observaciones válidas ordenadas ($x_1 \le x_2 \le x_3 \le x_4 \le x_5$): $\text{mediana} = x_3$, $Q_1 = x_2$, $Q_3 = x_4$, $\text{IQR} = Q_3 - Q_1$, $\min = x_1$, $\max = x_5$, tanto para `kernel_s` como para `total_s`.
    - Marcado de estado: `status = COMPLETE` para $R=5$; `status = INCOMPLETE` para $R < 5$.
  - **Formulación Canónica de Rendimiento (§7.1, §7.2, §7.3):**
    - **Speedup ($S$):** Referenciado obligatoriamente a la línea base secuencial del **mismo lenguaje**, nodo (`hostname`), commit y semilla:
      $$S_{\text{C}} = \frac{\widetilde{T}_{\text{total, c\_secuencial}}}{\widetilde{T}_{\text{total, c\_paralelo}}}, \quad S_{\text{Go}} = \frac{\widetilde{T}_{\text{total, go\_secuencial}}}{\widetilde{T}_{\text{total, go\_paralelo}}}$$
      Para las versiones secuenciales, $S = 1.0$. Si el grupo está incompleto o falta la referencia secuencial, el speedup queda explícitamente vacío (`null`), impidiendo métricas falsas.
    - **Eficiencia Paralela ($E$):** $E_{\text{C}} = S_{\text{C}} / (P \times T)$ y $E_{\text{Go}} = S_{\text{Go}} / W$. Para secuenciales, $E = 1.0$.
    - **Rendimiento Aritmético (GFLOPS):** $\text{GFLOPS}_{\text{kernel}} = 2 \cdot N^3 / (\text{mediana}(kernel\_s) \cdot 10^9)$ y $\text{GFLOPS}_{\text{total}} = 2 \cdot N^3 / (\text{mediana}(total\_s) \cdot 10^9)$ únicamente para grupos completos con mediana positiva.
  - **Esquema de Salida:** Generación de CSV estructurado con 31 columnas estándar para los análisis de los Sprints 8 y 9 (`version`, `configuration`, `n`, `seed`, `processes`, `threads`, `workers`, `gomaxprocs`, `reps_count`, `status`, estadísticos de `kernel_s`, estadísticos de `total_s`, `speedup`, `efficiency`, `gflops_kernel`, `gflops_total` y metadatos de entorno).

- **Pruebas y evidencias:**
  - Ejecución de la batería de pruebas: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\summarize_results_test.ps1`
    - **Resultado:** 43 pruebas superadas, 0 fallidas (100% PASS).
    - Verificación de concordancia matemática exacta con los cálculos manuales de control en `c_secuencial` ($S=1, E=1, \text{GFLOPS}=1.677722$), `c_paralelo_P2_T2` ($S=2.5, E=0.625, \text{GFLOPS}=6.710886$), `go_secuencial` ($S=1, E=1$), `go_paralelo_W4` ($S=2.5, E=0.625$), grupos incompletos con errores excluidos y archivos sin BOM.
  - Validación con datos reales del piloto de Yessly (I1) (`c_secuencial`, host `YESSLY-TB14G9`, commit `352858d`):
    - $N=256$: $\widetilde{T}_{\text{kernel}} = 0.002678 \text{ s}$ ($\text{IQR} = 0.000113 \text{ s}$), $\widetilde{T}_{\text{total}} = 0.002703 \text{ s}$, $\text{GFLOPS}_{\text{kernel}} = 12.53$.
    - $N=512$: $\widetilde{T}_{\text{kernel}} = 0.023823 \text{ s}$ ($\text{IQR} = 0.002280 \text{ s}$), $\widetilde{T}_{\text{total}} = 0.024417 \text{ s}$, $\text{GFLOPS}_{\text{kernel}} = 11.27$.
    - $N=1024$: $\widetilde{T}_{\text{kernel}} = 0.268481 \text{ s}$ ($\text{IQR} = 0.085657 \text{ s}$), $\widetilde{T}_{\text{total}} = 0.269936 \text{ s}$, $\text{GFLOPS}_{\text{kernel}} = 8.00$.

- **Bloqueos y decisiones:**
  - Se confirmó que no existe dependencia de bloqueo respecto a los runners de I2, I3 e I4, dado que el contrato CSV de 20 columnas y las fórmulas estadísticas estaban congeladas desde el Sprint 5.
  - Se aplicó estrictamente la restricción del protocolo §7.1 que prohíbe inventar ceros o publicar speedup si no existe la referencia secuencial correspondiente del mismo lenguaje o si el grupo tiene menos de 5 repeticiones válidas.

- **Revisión y criterio de aceptación:**
  - **Revisión cruzada a Roberto (I8):** Se coordinaron los requerimientos del acta de congelación (`docs/campana.md`), validando que las carpetas de salida (`resultados/piloto/<campaign_id>/`), los esquemas de metadatos de entorno y la secuencia de calentamiento + 5 repeticiones cumplan con la entrada requerida por `summarize_results.ps1`.
  - El entregable satisface al 100% el criterio de aceptación del Sprint 7 para I7.
### Resolución de conflictos del PR #49 · 12/11/2026

- Se incorporó `main` (`7cf0aae`, [PR #50 de I1](https://github.com/GiulianoMaPe/MatricesParalelas/pull/50)) a la rama de I3.
  Se conservaron íntegros el registro de Yessly y las tres funciones de C secuencial;
  la comparación de sus definiciones PowerShell confirma que no cambian al pasar
  a `bench_c_secuencial.ps1`. El despacho común y los módulos de I2/I3/I4 se mantienen.
- Tras resolver los conflictos: **75/75 pruebas controladas I3** y **23/23 pruebas
  de funciones I2** aprobadas en PowerShell 7.4.6 Linux; estas últimas con `TEMP=/tmp`.
  Los ocho scripts de benchmark/pruebas no tienen errores de sintaxis.
- Se verificó la evidencia Windows ya publicada en `dc9040e`: 81 pruebas OK y
  42 observaciones válidas repartidas en siete lotes completos. No se repitieron
  aquí los ejecutables Windows; el código de los medidores se conserva sin cambios.
- [Sebastián aprobó el PR #49](https://github.com/GiulianoMaPe/MatricesParalelas/pull/49#pullrequestreview-5882691934).
  Giuliano autorizó resolver los conflictos y fusionarlo a `main`. La coordinación
  con I5 y la campaña integrada siguen pendientes; no se declara cerrado S7.

### I8 · Roberto · 16/11/2026

> Registro individual histórico. La [campaña vigente](../campana.md) corrige sus reglas incompatibles con el protocolo y limita la evidencia a los dos casos Go declarados; la aceptación integral Windows permanece pendiente.

- **Rama:** `feature/s07-i08-congelacion-experimental`, desde `aba95790f0b9eb793a014ec6b69c09cd2ff6b249`.
- **Participantes y horas reales:** Roberto (**8 h reales**: 3 h fijación de versión candidata y parámetros oficiales de medición en `docs/campana.md`, 3 h reproducción y análisis empírico del piloto automatizado en Windows, 1 h coordinación general del equipo, 1 h revisión cruzada asignada).
- **Entregable oficial:** [`docs/campana.md`](../campana.md) ("*Acta de Congelación Experimental y Definición de Parámetros de Campaña*").
- **Implementación y alcance:**
  - Formalización del Marco de Congelamiento Experimental para dar paso a la campaña masiva del Sprint 8.
  - Fijación del commit base congelado (`aba95790f0b9eb793a014ec6b69c09cd2ff6b249`), estableciendo la inmutabilidad estricta de las rutinas de cómputo aritmético (`matrix_accumulate`, `multiplyKernel`, `multiplyBlock`) y el orden canónico $i \to k \to j$.
  - Definición de la matriz oficial de parámetros para el Sprint 8: dimensiones $N \in \{512, 1024, 2048\}$ (con $N=4096$ como estrés condicional seguro), semilla canónica obligatoria `--seed 42`, 1 warmup + 5 repeticiones formales medidas, y espacio de configuraciones de concurrencia ($W \in \{1, 2, 4, 6, 8, 12, 16\}$ en Go; $P \in \{1, 2, 4\}$ y $T \in \{1, 2, 4\}$ en C).
  - Criterios normativos de validez y descarte: cumplimiento del invariante temporal $0.0 < \text{kernel}_s \le \text{total}_s$, verificación numérica `validation_status=OK`, esquema estricto de 20 columnas y protocolo de aislamiento térmico de la máquina (CPU idle $< 5\%$ previo al lote).
- **Pruebas y evidencias (Reproducción del Piloto en `PC-PETEL`):**
  - Reproducción empírica en hardware físico: AMD Ryzen 5 7600X (6C/12T Zen 4, 4.7-5.3 GHz, 32 MB L3), 16 GB DDR5 5200 MT/s, Windows 11 Pro 64-bit build 26300.9974, Go 1.27.1 windows/amd64.
  - **Go Secuencial:** Ejecutado mediante `powershell -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version go_secuencial -N 256 -Repetitions 5`. Resultado: 6/6 corridas exitosas (1 warmup + 5 medidas). Mediana de `kernel_s` = 0.0092288 s con dispersión $< 3.8\%$. Esquema CSV de 20 columnas íntegro y `validation_status=OK`.
  - **Go Paralelo:** Ejecutado mediante `powershell -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version go_paralelo -N 256 -Workers 2 -Repetitions 5`. Resultado: 6/6 corridas exitosas. Mediana de `kernel_s` = 0.0055860 s, alcanzando un speedup preliminar $S_2 \approx 1.65\times$ y una eficiencia del $82.5\%$ para $N=256$.
  - Invariante de cronometría verificado en todas las observaciones: $0.0 < \text{kernel}_s \le \text{total}_s$.
- **Bloqueos y decisiones:**
  - Código fuente y parámetros de campaña oficialmente congelados de cara al inicio del Sprint 8.
  - El arnés automatizado `bench_windows.ps1` queda validado empíricamente en Windows para la generación desatendida de resultados.
- **Revisión y criterio de aceptación:** Entregable de I8 (`docs/campana.md`) completado y conforme. Listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly completada sobre su entrega de C secuencial.



## Entregas recuperadas de las ramas de S7

Los siguientes registros conservan lo declarado por I2/I4 en sus ramas; las referencias a integración pendiente describen su estado original. La actualización del 17/11/2026 rige el estado actual.

## Entrega de I2 (Sprint 7) — caso C paralelo

**Estado:** implementación, pruebas unitarias y dry-run del piloto entregados;
**pendiente de revisión final de I1** y de campaña real por I6.

**Rama/PR:** `feature/s07-i02-c-paralelo-bench`.

**Archivos:**

- `scripts/bench_windows.ps1`: caso `c_paralelo` (P × T), `plan.csv`,
  `entorno.json`, `bitacora.txt`, `mediciones.csv`, logs, parser/validador,
  filas de fallo, timeout, lock y `-DryRun`.
- `tests/bench_c_paralelo_test.ps1`: 23 pruebas unitarias sin MSVC ni MS-MPI.
- `docs/sprints/sprint-07-i02-plan.md`: plan y decisiones de I2.

**Alcance entregado:**

- Combinaciones `P1_T1` … `P4_T1` siempre; `P1_T8` … `P8_T1` solo con ≥ 8
  núcleos físicos (la PC de I2 tiene 6, así que el dry-run usa W ≤ 4).
- Commit derivado con `git rev-parse HEAD` y registrado con estado limpio/sucio
  y diff; no se fija un hash a mano.
- Solo se implementa `c_paralelo`: `-Version all` falla de forma explícita hasta
  que I5 integre los cuatro casos.
- Filas de fallo con `kernel_s`/`total_s` vacíos y estado `PENDING`, `MISMATCH`,
  `OOM`, `TIMEOUT` o `ERROR`; nunca se inventan tiempos.

**Comandos reproducibles:**

```powershell
# Pruebas unitarias (23)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_c_paralelo_test.ps1

# Dry-run piloto parcial (no requiere MSVC ni MS-MPI)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -NList 256,512,1024 `
    -Configurations P1_T1,P1_T2,P2_T1,P1_T4,P2_T2,P4_T1 `
    -Seed 42 -Warmups 1 -Repetitions 5 -TimeoutSeconds 120 -DryRun

# Campaña real (el revisor debe compilar antes)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -Configuration Release -Seed 42 -Warmups 1 -Repetitions 5
```

**Evidencia local de I2:**

- Dry-run ejecutado el 12/11/2026 en `DESKTOP-JIHSDJ6`, commit `d180f4e`,
  `dirty=False`.
- Plan generado: 108 corridas = 6 configuraciones (P1_T1, P1_T2, P2_T1, P1_T4,
  P2_T2, P4_T1) × 3 tamaños (256, 512, 1024) × (1 warmup + 5 repeticiones)
  = 18 warmups + 90 medidas.
- Pruebas unitarias: **23/23 OK** (parser, validador, clasificador de fallos,
  configuración P×T, exclusiones por núcleos/memoria, lock de campaña, parser
  CSV con comillas y comas).
- Destino previsto del piloto: `resultados\piloto\20261112T180148Z_DESKTOP-JIHSDJ6_d180f4e_i02`
- No se ejecutó campaña real: esta máquina no tiene `cl.exe`, `mpiexec.exe` ni
  `c_paralelo.exe` Release.

**Checklist para el revisor (I1):**

- [x] El dry-run respeta N, configuraciones, warmups y 5 repeticiones.
- [ ] `-Version all` falla con un mensaje claro (integración pendiente de I5).
- [ ] W=8 se excluye en máquinas con menos de 8 núcleos físicos.
- [ ] El parser rechaza filas corruptas, P/T incorrectos y `observed_threads != T`.
- [ ] Los fallos conservan tiempos vacíos y no se mezclan como `OK`.
- [ ] La campaña real genera `entorno.json`, `plan.csv`, `mediciones.csv`,
      `bitacora.txt` y logs por corrida.
- [ ] `commit`, `hostname` y SHA-256 del ejecutable coinciden con la campaña.
- [ ] El lock impide campañas simultáneas y se libera al terminar.

**Horas reales de I2:** 8 h (3 h caso híbrido P×T, 3 h registro/validación de
procesos e hilos observados, 1 h revisión cruzada de I3, 1 h coordinación).

## Registro de cierre

- Participantes y horas reales: I2 (Sebastian) — 8 h reales.
- Issues y pull requests: I2 — [PR #51](https://github.com/GiulianoMaPe/MatricesParalelas/pull/51), aprobado por I1.
- Pruebas y evidencias: 23 pruebas unitarias OK; dry-run de 108 corridas planificadas
  (18 warmups + 90 medidas) en commit d180f4e (reproducido con 180 corridas en host de 8 núcleos físicos por I1).
- Bloqueos y decisiones: campaña real bloqueada por falta de cl.exe/mpiexec.exe en
  la máquina de I2; validado en entorno MSVC/MS-MPI por I1 e I6 ejecutará el piloto en la PC oficial.
- Revision y criterio de aceptacion: conforme según revisión de I1.


#### Integrante 4 (Eva)

- **Participantes y horas reales:** Eva Moreno (I4). El plan contempla 3 h para completar el caso go_paralelo con distintos workers, 3 h para comprobar el paralelismo solicitado y evitar campañas simultáneas, 1 h de revisión cruzada a I5 (Fernando) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s07-i04-bench-go-paralelo`; [PR #53](https://github.com/GiulianoMaPe/MatricesParalelas/pull/53). La revisión corresponde a I3 (Giuliano) según la rotación; la integración de los cuatro casos, a I5.

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


#### Integrante 5 (Fernando)

- **Estado de avance:** rama `feature/s07-i05-integracion-campana` creada desde `main` para integrar y revisar la campaña.
- **Trabajo preparatorio realizado:** reforcé `Validate-CsvRow` en `scripts/bench_windows.ps1` para rechazar comillas CSV mal formadas, metadatos obligatorios vacíos, timestamp/commit inválidos y valores numéricos fuera de formato/rango; la lectura decimal usa cultura invariante.
- **Dependencias para completar el entregable:** faltan las implementaciones de campaña de I2 (`c_paralelo`), I3 (`go_secuencial`) e I4 (`go_paralelo`). Hasta que estén disponibles no se puede revisar la integración de los cuatro casos ni aceptar la campaña completa.
- **Verificaciones y bloqueos del entorno:** la sintaxis de `bench_windows.ps1` pasó con el parser de PowerShell y `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_csv_validation_test.ps1` pasó: acepta una fila válida y rechaza comilla fuera de lugar, fecha inexistente y decimal con coma. No se encontraron `cl.exe`, `vswhere.exe` ni `VsDevCmd.bat` en las ubicaciones estándar; `build_windows.ps1 -Version c_secuencial -Configuration Release` no pudo compilar porque no hay MSVC inicializado ni `vswhere`. El intento de piloto con `-Version c_secuencial -Fase piloto -Repetitions 1` se detuvo antes de medir: falta `c_secuencial/build/Release/c_secuencial.exe`. No se instaló ninguna herramienta. Para desbloquear esa verificación hay que usar una consola x64 Native Tools de Visual Studio o disponer de Visual Studio Build Tools C++ y Windows SDK; después compilar Release y repetir el piloto.
- **Alcance que sí queda disponible:** el control inicial del estado de cada versión continúa rechazando campañas si el algoritmo o su validación están pendientes, y el manejador de cada ejecutable rechaza el código de salida `2` sin aceptar una fila de medición. La revisión empírica de esos rechazos y la validación completa de todas las variantes quedan pendientes de disponer de los ejecutables y de las campañas I2–I4.
- **Horas reales, revisión cruzada y aceptación:** pendientes de confirmar al cierre; no se declaran como completadas en este avance.


## Integración técnica · Codex · 17/11/2026

Autorizada por el responsable para completar e integrar S7. Al confirmarse que
Windows está en otra partición, el alcance de esta sesión se limita a integración,
verificación Linux y preparación de la aceptación nativa. No se atribuyen nuevas
horas, coordinaciones ni conformidades personales a integrantes del equipo.

### Trabajo integrado y completado

| Entrega | Procedencia y estado actual |
| --- | --- |
| I1 · C secuencial | PR #50 ya integrado; se conserva su medidor y normalización de etiquetas. |
| I2 · C paralelo | Funciones ya recuperadas en PR #49; se importan registro y plan de su rama/PR #51. |
| I3 · Go secuencial | PR #49 ya integrado, con aceptación individual Windows 81/81 y aprobación I2. |
| I4 · Go paralelo | Funciones ya recuperadas en PR #49; se importan registro y 72 observaciones originales del PR #53. |
| I5 · Integración | Se incorpora el validador estricto y sus pruebas del PR #55; se completa `all` con tabla común, rondas alternadas, un CSV y lock compartido. |
| I6 · Piloto | Procedimiento automatizado listo; falta ejecución en PC oficial. Los ensayos de I1/I3/I4/I8 no sustituyen la campaña integrada. |
| I7 · Análisis | Rama/PR #54 integrada conservando sus commits y 43 pruebas. Se refuerza aislamiento entre archivos, completitud, duplicados, fallos, NaN/Inf y cero temporal. |
| I8 · Congelación | PR #56 recibido desde main; acta original preservada, reglas corregidas según protocolo v1.3. Falta reproducir la candidata integrada y aceptar la congelación final. |

`scripts/bench_campaign.ps1` combina los módulos individuales y reutiliza el
planificador, CSV y lock de I1/I2/I4/I5 y el registrador de procesos de I3.
Verifica builds Release x64, HEAD, SHA-256, inventario/hash de fuentes y metadatos
VCS Go. Las fuentes del piloto sucio se archivan; oficial exige limpieza.
Cada corrida conserva stdout/stderr, argumentos, PID, código real, timeout y
entorno de runtime relevante. C híbrido registra y comprueba filas e hilos de
cada rank mediante los diagnósticos existentes, posteriores al cronómetro.
No se modifican algoritmos C/Go ni sus fronteras temporales.

La selección respeta W=1/2/4/8 según núcleos físicos y la memoria disponible;
se conserva el orden real y se aborta al primer error, guardando parciales.
La carga y memoria se registran por corrida en Windows. Temperatura/sensores y
condiciones de uso requieren revisión humana; no se declaran observaciones
que el sistema no pueda obtener.

### Verificación ejecutada

PowerShell **7.4.6 linux-x64 portable**, 17/11/2026. Evidencia persistente en
[resultados/diagnostico/s07-integracion-linux-20261117/](../../resultados/diagnostico/s07-integracion-linux-20261117/verificacion.json).

| Batería | Resultado |
| --- | --- |
| Validador CSV I5 | Fila válida aceptada y tres entradas inválidas rechazadas |
| Manifiestos de compilación | 10 comprobaciones aprobadas |
| Resumen I7 original | 43/43 aprobadas |
| Integridad de resumen | 11 comprobaciones aprobadas |
| Funciones C paralelo I2 | 23/23 aprobadas |
| Go secuencial I3 controlado | 75/75 aprobadas |
| Campaña integrada controlada | 48 comprobaciones aprobadas |
| Sintaxis PowerShell de scripts y pruebas | Sin errores |

La prueba integrada ejecuta procesos PowerShell controlados para las cuatro
versiones, valida grupos completos y fallidos, planificación de 198/288 corridas,
locks, ranks MPI simulados y el verificador de evidencia. Son pruebas del arnés,
no campañas experimentales. La batería original I4 usa `.cmd`: el intento Linux
falló al iniciar ese formato; debe ejecutarse en Windows y no figura como aprobada.
No se ejecutaron MSVC, MS-MPI, PowerShell 5.1 ni nuevos binarios Windows.

### Pendientes para aceptar el cierre

1. Ejecutar `scripts/accept_sprint07_windows.ps1` en Windows PowerShell 5.1 con
   MSVC/SDK/MS-MPI/Go nativos, sobre esta candidata y en la PC oficial.
2. Completar piloto N=256/512/1024 con toda la tabla habilitada; revisar carga,
   memoria, alimentación y temperatura/incidencias, además de los CSV/logs.
3. Reproducir en una carpeta nueva con la misma candidata, binarios y parámetros.
4. Confirmar estimación/reserva de máquina y congelación final antes de S8.
5. Registrar aceptación y conformidades/horas personales que aún falten,
   conservando la distinción entre lo declarado y lo realmente verificado.

El procedimiento y criterios actuales están en [docs/campana.md](../campana.md).
S7 permanece abierto hasta acreditar estos puntos; el dry-run y los datos previos
no se reclasifican como piloto completo.
