# Sprint 7 Automatizar los experimentos

Estado: entrega técnica local de I3 validada en Windows; revisión cruzada I2→I3 pendiente. Las demás entregas y el cierre de equipo siguen pendientes. Plan de desarrollo de la [guía vigente](../guia-extraida.txt).

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
- **Pendiente para aprobar/cerrar I3:** revisión y aprobación reales de I2 y
  confirmación de coordinación con I5. La corrección queda local, sin publicación
  ni aprobación atribuida a terceros. El sprint completo del equipo sigue abierto.
- El registro anterior describe el estado previo; esta actualización sustituye
  sus pendientes técnicos de Windows e integración individual y sus horas pendientes.