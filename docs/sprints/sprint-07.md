# Sprint 7 Automatizar los experimentos

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 7 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Dejar preparada una campaña que se pueda ejecutar sin editar manualmente cada comando.

Cierre: El piloto genera CSV válidos, repite correctamente, detecta fallos y conserva la configuración completa.

## Trabajo de cada integrante

Integrante 1  Completar el caso C secuencial del script de medición existente (3 h). Verificar tamaños, calentamiento, cinco repeticiones y errores (3 h). Entregable: Medición C secuencial validada. Ubicación: scripts/bench_windows.ps1.

Integrante 2  Completar el caso híbrido del script para combinaciones P y T (3 h). Registrar procesos e hilos observados y parámetros de cada ejecución (3 h). Entregable: Medición C paralelo validada. Ubicación: scripts/bench_windows.ps1. Plan detallado: [sprint-07-i02-plan.md](sprint-07-i02-plan.md).

Integrante 3  Completar el caso Go secuencial del script de medición (3 h). Verificar que se mida el ejecutable y que se registren sus parámetros (3 h). Entregable: Medición Go secuencial validada. Ubicación: scripts/bench_windows.ps1.

Integrante 4  Completar el caso Go paralelo del script con distintos workers (3 h). Comprobar el paralelismo solicitado y evitar campañas simultáneas (3 h). Entregable: Medición Go paralelo validada. Ubicación: scripts/bench_windows.ps1.

Integrante 5  Integrar y revisar los cuatro casos en bench_windows.ps1 (3 h). Validar CSV y rechazar resultados de funciones aún pendientes (3 h). Entregable: Campaña automatizada validada. Ubicación: scripts/bench_windows.ps1.

Integrante 6  Realizar un piloto completo en la PC oficial (3 h). Estimar duración total y revisar temperatura, carga y memoria disponible (3 h). Entregable: Piloto y reserva de tiempo de máquina. Ubicación: resultados/piloto/.

Integrante 7  Preparar agregación de medianas, dispersión y speedup (3 h). Comprobar los cálculos con un pequeño CSV manual de control (3 h). Entregable: Procedimiento de análisis verificado. Ubicación: scripts/summarize_results.ps1.

Integrante 8  Reproducir el piloto a partir de la versión candidata (3 h). Fijar la versión del código y los parámetros aceptados para medir (3 h). Entregable: Acta de congelación experimental. Ubicación: docs/campana.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-07.md.

I1 a I4 trabajan en funciones separadas del script; I5 integra después de su revisión. El piloto se guarda separado de los CSV oficiales de S8.

## Entrega de I2 (Sprint 7) — caso C paralelo

**Estado:** implementación y pruebas unitarias entregadas en el PR; **no validado
todavía**. La validación la realiza el revisor asignado (I1) y la campaña real
corresponde a I6.

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

# Dry-run (no requiere MSVC ni MS-MPI)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -NList 256,512,1024 `
    -Configurations P1_T1,P1_T2,P2_T1,P1_T4,P2_T2,P4_T1 `
    -Seed 42 -Warmups 1 -Repetitions 5 -TimeoutSeconds 120 -DryRun

# Campaña real (el revisor debe compilar antes)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -Configuration Release -Seed 42 -Warmups 1 -Repetitions 5
```

**Evidencia local de I2:** el dry-run planifica 108 corridas para 6
configuraciones × 3 N (18 warmups + 90 medidas) y las 23 pruebas unitarias
pasan. No se ejecutó una campaña real: esta máquina no tiene `cl.exe`,
`mpiexec.exe` ni `c_paralelo.exe` Release.

**Checklist para el revisor (I1):**

- [ ] El dry-run respeta N, configuraciones, warmups y 5 repeticiones.
- [ ] `-Version all` falla con un mensaje claro (integración pendiente de I5).
- [ ] W=8 se excluye en máquinas con menos de 8 núcleos físicos.
- [ ] El parser rechaza filas corruptas, P/T incorrectos y `observed_threads != T`.
- [ ] Los fallos conservan tiempos vacíos y no se mezclan como `OK`.
- [ ] La campaña real genera `entorno.json`, `plan.csv`, `mediciones.csv`,
      `bitacora.txt` y logs por corrida.
- [ ] `commit`, `hostname` y SHA-256 del ejecutable coinciden con la campaña.
- [ ] El lock impide campañas simultáneas y se libera al terminar.

**Horas reales de I2:** pendiente de registrar al cierre (estimadas 8 h: 3 h de
caso híbrido, 3 h de registro/validación, 1 h de revisión de I3 y 1 h de
coordinación).

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: I2 — [PR #51](https://github.com/GiulianoMaPe/MatricesParalelas/pull/51), pendiente de revisión de I1.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.
