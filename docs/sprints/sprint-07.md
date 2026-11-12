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
