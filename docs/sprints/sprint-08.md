# Sprint 8 Ejecutar la campaña oficial

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 8 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Reunir todos los datos medidos con una versión fija y condiciones registradas.

Cierre: Cada configuración prevista tiene cinco observaciones válidas o una exclusión justificada; los CSV originales están preservados.

## Trabajo de cada integrante

Integrante 1  Ejecutar y supervisar los lotes de C secuencial (3 h). Revisar integridad y metadatos y repetir solo fallos justificados (3 h). Entregable: CSV originales de C secuencial. Ubicación: resultados/raw/c_secuencial.csv.

Integrante 2  Ejecutar y supervisar las combinaciones del híbrido C (3 h). Verificar participación de procesos e hilos y registrar anomalías (3 h). Entregable: CSV originales de C paralelo. Ubicación: resultados/raw/c_paralelo.csv.

Integrante 3  Ejecutar y supervisar la campaña Go secuencial (3 h). Revisar equivalencia de entradas y condiciones de ejecución (3 h). Entregable: CSV originales de Go secuencial. Ubicación: resultados/raw/go_secuencial.csv.

Integrante 4  Ejecutar y supervisar los lotes de Go paralelo (3 h). Revisar workers efectivos y estabilidad de las repeticiones (3 h). Entregable: CSV originales de Go paralelo. Ubicación: resultados/raw/go_paralelo.csv.

Integrante 5  Auditar completitud y validez numérica de los cuatro lotes (3 h). Clasificar fallos sin borrar datos y generar inventario de observaciones (3 h). Entregable: Reporte de calidad de datos. Ubicación: docs/calidad_datos.md.

Integrante 6  Registrar hardware, carga del sistema y configuración de cada sesión (3 h). Repetir un subconjunto de control en otra PC con etiqueta separada (3 h). Entregable: Metadatos y control independiente. Ubicación: docs/entorno/.

Integrante 7  Generar resúmenes provisionales y detectar dispersión anormal (3 h). Proponer y documentar repeticiones justificadas sin seleccionar solo los mejores tiempos (3 h). Entregable: Resumen provisional auditado. Ubicación: resultados/resumen/.

Integrante 8  Verificar trazabilidad desde commit hasta cada archivo CSV (3 h). Congelar la carpeta raw y actualizar bitácora de experimentos (3 h). Entregable: Manifiesto de resultados y bitácora. Ubicación: docs/bitacora_experimentos.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-08.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

## Avance Integrante 2 (Sebastian) — híbrido C

**Estado:** herramienta de extracción y verificación entregada y probada;
**campaña oficial pendiente de ejecución en la PC oficial**.
Plan y handoff completos en [sprint-08-i02-plan.md](sprint-08-i02-plan.md).

### Entregado

- `scripts/extract_s08_c_paralelo.ps1`: extrae y verifica el lote
  `version=c_paralelo` de una campaña integrada. Comprueba esquema de 20 campos,
  plan y rondas, `processes=P`, `threads=T`, `observed_threads=T`,
  `OMP_NUM_THREADS`, `OMP_DYNAMIC=FALSE`, `mpiexec -n P`, filas por rank,
  igualdad con `mediciones.csv`, bitácora, commit, hostname y tamaños. Copia las
  filas byte a byte y escribe un manifiesto con hashes y anomalías.
- `tests/extract_s08_c_paralelo_test.ps1`: 13 pruebas sobre campañas sintéticas
  (extracción válida, bytes, hilos, ranks, fallos, `-AllowIncomplete`, divergencia
  de `stdout`, commit, BOM, plan alterado y rechazos de fase oficial).
- `resultados/diagnostico/s08_i02_piloto_s07/`: extracción **no oficial** del
  piloto S7 `s07_windows_20261117_reproduccion_06`, con README de procedencia.

### Evidencia y pruebas

| Evidencia | Resultado |
| --- | --- |
| `tests/extract_s08_c_paralelo_test.ps1` | 13/13 |
| `tests/bench_c_paralelo_test.ps1` (regresión S7) | 23/23 |
| Diagnóstico sobre piloto S7 | `VERIFIED_PILOT`, 108 filas, 18 grupos, 0 críticas |
| `resultados/raw/c_paralelo.csv` | **No generado** (pendiente de campaña oficial) |

Comandos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\extract_s08_c_paralelo_test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\piloto\s07_windows_20261117_reproduccion_06 `
    -Phase piloto -ExpectedSizes 256,512,1024 `
    -OutputPath .\resultados\diagnostico\s08_i02_piloto_s07\c_paralelo_piloto.csv `
    -ManifestPath .\resultados\diagnostico\s08_i02_piloto_s07\revision_i02.json
```

### Bloqueo y decisión

Esta PC (`DESKTOP-JIHSDJ6`) no tiene MSVC C++, Windows SDK ni MS-MPI, y su
instalación exige permisos de administrador que no están disponibles. Por eso no
se ejecutó el híbrido C ni se creó un CSV oficial simulado. Decisión: entregar la
herramienta de cierre y un diagnóstico real etiquetado como no oficial, y dejar
la campaña oficial como handoff verificable para la PC oficial.

En la PC oficial (`PCG1UL14N0`, Ryzen 5 3600, MSVC 14.44, Windows SDK
10.0.26100, MS-MPI 10.1.12498.52), tras compilar, probar y confirmar árbol limpio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version all -Fase oficial -OutputRoot resultados\raw `
    -CampaignId s08_i02_c_paralelo_01 -TimeoutSeconds 300
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\raw\s08_i02_c_paralelo_01 -Phase oficial `
    -ExpectedCommit 97ccc981e9068d8ec0753cd8a4b7572a6bece34d
```

### Pendiente

- Ejecutar la campaña oficial y generar `resultados/raw/c_paralelo.csv`
  (`VERIFIED`, 108 filas esperadas con 6 núcleos físicos).
- Registrar horas reales de ejecución y verificación, y la revisión cruzada.
- Confirmar con I5/I6/I8 la franja de máquina y la candidata congelada.
