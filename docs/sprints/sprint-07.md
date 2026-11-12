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

#### Integrante 5 (Fernando)

- **Estado de avance:** rama `feature/s07-i05-integracion-campana` creada desde `main` para integrar y revisar la campaña.
- **Trabajo preparatorio realizado:** reforcé `Validate-CsvRow` en `scripts/bench_windows.ps1` para rechazar comillas CSV mal formadas, metadatos obligatorios vacíos, timestamp/commit inválidos y valores numéricos fuera de formato/rango; la lectura decimal usa cultura invariante.
- **Dependencias para completar el entregable:** faltan las implementaciones de campaña de I2 (`c_paralelo`), I3 (`go_secuencial`) e I4 (`go_paralelo`). Hasta que estén disponibles no se puede revisar la integración de los cuatro casos ni aceptar la campaña completa.
- **Verificaciones y bloqueos del entorno:** la sintaxis de `bench_windows.ps1` pasó con el parser de PowerShell y `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_csv_validation_test.ps1` pasó: acepta una fila válida y rechaza comilla fuera de lugar, fecha inexistente y decimal con coma. No se encontraron `cl.exe`, `vswhere.exe` ni `VsDevCmd.bat` en las ubicaciones estándar; `build_windows.ps1 -Version c_secuencial -Configuration Release` no pudo compilar porque no hay MSVC inicializado ni `vswhere`. El intento de piloto con `-Version c_secuencial -Fase piloto -Repetitions 1` se detuvo antes de medir: falta `c_secuencial/build/Release/c_secuencial.exe`. No se instaló ninguna herramienta. Para desbloquear esa verificación hay que usar una consola x64 Native Tools de Visual Studio o disponer de Visual Studio Build Tools C++ y Windows SDK; después compilar Release y repetir el piloto.
- **Alcance que sí queda disponible:** el control inicial del estado de cada versión continúa rechazando campañas si el algoritmo o su validación están pendientes, y el manejador de cada ejecutable rechaza el código de salida `2` sin aceptar una fila de medición. La revisión empírica de esos rechazos y la validación completa de todas las variantes quedan pendientes de disponer de los ejecutables y de las campañas I2–I4.
- **Horas reales, revisión cruzada y aceptación:** pendientes de confirmar al cierre; no se declaran como completadas en este avance.
