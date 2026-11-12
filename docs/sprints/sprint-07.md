# Sprint 7 Automatizar los experimentos

Estado: implementación local de I3 disponible, con aceptación Windows y revisión cruzada pendientes. Las demás entregas y el cierre de equipo siguen pendientes. Plan de desarrollo de la [guía vigente](../guia-extraida.txt).

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
- Revisión I2→I3 y coordinación con I5: pendientes; horas reales no declaradas.
  No se ejecutó el piloto ni se completaron tareas de otros integrantes.

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.
