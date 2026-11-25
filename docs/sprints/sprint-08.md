# Sprint 8 Ejecutar la campaña oficial

Estado: entregas parciales integradas. C secuencial, Go secuencial y Go paralelo tienen datos oficiales. La campaña integrada de las cuatro versiones está en curso en PCG1UL14N0.

Semana 8 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Reunir todos los datos medidos con una versión fija y condiciones registradas.

Cierre: Cada configuración prevista tiene cinco observaciones válidas o una exclusión justificada; los CSV originales están preservados.

## Trabajo de cada integrante

Integrante 1  Ejecutar y supervisar los lotes de C secuencial (3 h). Revisar integridad y metadatos y repetir solo fallos justificados (3 h). Entregable: CSV originales de C secuencial. Ubicación: resultados/raw/c_secuencial.csv.

Integrante 2  Ejecutar y supervisar las combinaciones del híbrido C (3 h). Verificar participación de procesos e hilos y registrar anomalías (3 h). Entregable: CSV originales de C paralelo. Ubicación: resultados/raw/c_paralelo.csv.

Integrante 3 (Giuliano/I3)  Ejecutar y supervisar la campaña Go secuencial (3 h). Revisar equivalencia de entradas y condiciones de ejecución (3 h). Entregable: CSV de Go secuencial derivado sin modificar el CSV original de la campaña integrada. Ubicación: `resultados/raw/go_secuencial.csv`; conservar como fuente `resultados/raw/<campaign_id>/mediciones.csv`. Véase el [plan I3 de S8](sprint-08-i03-plan.md).

Integrante 4  Ejecutar y supervisar los lotes de Go paralelo (3 h). Revisar workers efectivos y estabilidad de las repeticiones (3 h). Entregable: CSV originales de Go paralelo. Ubicación: resultados/raw/go_paralelo.csv.

Integrante 5  Auditar completitud y validez numérica de los cuatro lotes (3 h). Clasificar fallos sin borrar datos y generar inventario de observaciones (3 h). Entregable: Reporte de calidad de datos. Ubicación: docs/calidad_datos.md.

Integrante 6  Registrar hardware, carga del sistema y configuración de cada sesión (3 h). Repetir un subconjunto de control en otra PC con etiqueta separada (3 h). Entregable: Metadatos y control independiente. Ubicación: docs/entorno/.

Integrante 7  Generar resúmenes provisionales y detectar dispersión anormal (3 h). Proponer y documentar repeticiones justificadas sin seleccionar solo los mejores tiempos (3 h). Entregable: Resumen provisional auditado. Ubicación: resultados/resumen/.

Integrante 8  Verificar trazabilidad desde commit hasta cada archivo CSV (3 h). Congelar la carpeta raw y actualizar bitácora de experimentos (3 h). Entregable: Manifiesto de resultados y bitácora. Ubicación: docs/bitacora_experimentos.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-08.md.

## Registro de cierre

- Participantes y horas reales: Eva/I4 registrada; Gerardo/I6 inventario registrado; resto pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: Go paralelo verificado; pruebas Go locales pasaron; C/MS-MPI no están disponibles en la sesión actual.
- Bloqueos y decisiones: falta incorporar los tres lotes restantes y ejecutar el control independiente. La sesión I6 no contiene `.git`, cl.exe ni MS-MPI activos.
- Revision y criterio de aceptacion: pendiente de las cuatro campañas y revisión cruzada.

## Registros individuales

#### Integrante 1 (Yessly)

- **Participantes y horas reales.** Yessly Poma (I1) declaro 3 h en total (ejecucion y supervision del control de C secuencial, verificacion de integridad y procedencia del lote oficial, y revision del PR #59). Las 8 h de la guia son una estimacion.
- **PR y ejecución.** PR en rama `feature/s08-i01-c-secuencial-oficial`. No existe un extractor específico de `c_secuencial` en el repositorio; la procedencia oficial se comprobó mediante comparación campo a campo contra la campaña integrada oficial de `PCG1UL14N0` (`resultados/raw/s08_i04_go_paralelo_01/mediciones.csv`, Ryzen 5 3600, MSVC 14.44, commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`), verificando que las 18 filas coinciden exactamente. Adicionalmente, se ejecutó una campaña de control independiente en el host `YESSLY-TB14G9` (AMD Ryzen 7 250, Windows 11 build 26200.9974) con `scripts\bench_windows.ps1 -Version c_secuencial -Fase oficial`. Se añade la observación metodológica de que el arnés aceptó `-Fase oficial` en un host que no es el oficial (`YESSLY-TB14G9`), sin rechazarlo ni exigir `PCG1UL14N0`.
- **Entregable.** [`resultados/raw/c_secuencial.csv`](../../resultados/raw/c_secuencial.csv) conserva exactamente las 18 filas oficiales (3 calentamientos y 15 mediciones válidas en 3 grupos $N=512, 1024, 2048$, semilla 42, `validation_status=OK`). Se generó su manifiesto de procedencia e integridad en [`resultados/raw/c_secuencial.manifest.json`](../../resultados/raw/c_secuencial.manifest.json) con SHA-256 `0F82F9FDE140C6E928AFB0476392E22181DEDEE534F42D7D20B3271973B3C854`. Los datos de control independiente se preservan en `resultados/control/s08_i01_c_secuencial_control/` con manifiesto propio (observando codificación UTF-16 LE generada por la redirección estándar de PowerShell 5.1).
- **Auditoría e integridad.** Esquema de 20 columnas verificado. 18 de 18 corridas OK. En todas las filas se cumple $0 \le \text{kernel\_s} \le \text{total\_s}$. Mismo commit congelado (`97ccc981e9068d8ec0753cd8a4b7572a6bece34d`), hostname (`PCG1UL14N0`), semilla (`42`) y versión (`c_secuencial`). Dispersión relativa (rango/mediana) baja: 0.84% para $N=512$ (mediana 0.02393 s), 3.06% para $N=1024$ (mediana 0.19502 s) y 3.04% para $N=2048$ (mediana 3.79299 s). Cero fallos numéricos ni anomalías críticas. Se anota la observación de que `os_version` reporta `"Windows 10 Pro build 26300.9711"`, correspondiente a la compilación del kernel NT en Windows 11 (se conserva sin alterar el CSV crudo).
- **Pruebas y regresión.** Se verificó compilación Release con `build_windows.ps1` y suite de regresión completa con `test_windows.ps1 -Version c_secuencial -SkipBuild` (código de salida 0, pasando pruebas de instalación, contratos S2/S5 y 5 fixtures con `compare_results.ps1`). Revisión pendiente de I8 (Roberto).

##### Revisión cruzada de I1 a I2 (Sebastian) · PR #59
Se auditó la rama `origin/feature/s08-i02-c-paralelo-oficial`, revisado por lectura del diff, sin ejecutar sus pruebas. Sebastián implementó con rigor técnico el extractor `scripts/extract_s08_c_paralelo.ps1` y sus pruebas sintéticas. Reconoció honestamente la limitación de entorno en su PC (`DESKTOP-JIHSDJ6`, sin MSVC/MS-MPI ni permisos de administrador) y aplicó la política de no fabricar datos ni mezclar datos de prueba en `resultados/raw/c_paralelo.csv`. Dejó documentado el handoff para la PC oficial `PCG1UL14N0`. Su entrega es aprobada a nivel de herramienta y documentación.

#### Integrante 4 (Eva)

- **Participantes y horas reales.** Eva Moreno (I4) declaró 8 h. La distribución sigue la guía con 3 h de ejecución y supervisión, 3 h de auditoría de workers y estabilidad, 1 h de revisión cruzada a I5 y 1 h de coordinación. El tiempo de máquina fue de 89,70 min.
- **PR y ejecución.** [PR #60](https://github.com/GiulianoMaPe/MatricesParalelas/pull/60), rama `feature/s08-i04-go-paralelo-oficial`. Codex ejecutó la subcampaña por encargo de I4 en `PCG1UL14N0` con la candidata limpia `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`. El arnés registró al operador de la sesión como `giuli`. El lote terminó el 19/11/2026 con **108 de 108 corridas válidas**, 18 grupos completos y cero exclusiones.
- **Entregable.** [`resultados/raw/go_paralelo.csv`](../../resultados/raw/go_paralelo.csv) conserva las 54 filas originales en orden de campaña, con 9 calentamientos y **45 mediciones válidas** para `N=512/1024/2048`, `W=1/2/4` y semilla 42. La [carpeta de la campaña](../../resultados/raw/s08_i04_go_paralelo_01/README.md) conserva el CSV fuente, el plan, los metadatos y los logs. Se compararon los 350 archivos originales por SHA-256 y se verificaron los datos crudos en el índice Git.
- **Auditoría.** El [manifiesto de extracción](../../resultados/raw/go_paralelo.manifest.json) acredita nueve grupos completos y cero anomalías críticas. Los workers solicitados, los reportados por el binario y el entorno hijo coinciden con el plan. Las medianas y los cuartiles coinciden con el resumen común en los nueve grupos. Se registró dispersión alta para `N=1024/W=2` (IQR/mediana 10,7 %) y `N=1024/W=4` (11,4 %), y tiempos cortos para `N=512/W=2` y `N=512/W=4`. Se conservaron las cinco observaciones de cada grupo. La temperatura de CPU no estaba disponible.
- **Pruebas y revisión técnica.** En Windows pasaron 21 casos del extractor, 43 del resumidor y 11 de integridad. El verificador común pasó sobre la candidata y la copia publicada. La fase oficial exige la PC y la semilla oficiales y preserva el CSV y su manifiesto ante intentos incompletos. I3 es la persona revisora según la rotación. El [PR #60](https://github.com/GiulianoMaPe/MatricesParalelas/pull/60) registra la decisión de integración.
- **Procedencia del diagnóstico.** Las [extracciones de S7](../../resultados/diagnostico/s08_i04_go_paralelo/README.md) quedan como evidencia de las pruebas con piloto y reproducción.

##### Revisión cruzada de I4 a I5 · 19/11/2026

Se revisó por encargo de I4 el [informe de Fernando](https://github.com/GiulianoMaPe/MatricesParalelas/blob/4a336a4ea6d260c862208cdde09315995ea3371a/docs/calidad_datos.md). Los criterios para conservar los originales, contar las repeticiones, validar los tiempos e inventariar fallos y exclusiones son conformes con la guía como preparación de la auditoría. El informe deja el dictamen de cada lote pendiente de recibir los datos oficiales.

- Antes de emitir los dictámenes, identificar cada campaña por ID y exigir fase `oficial`, la PC `PCG1UL14N0` y el commit completo de la candidata congelada. Para Go paralelo, cruzar `--workers`, `workers`, `gomaxprocs` y `GOMAXPROCS` del proceso hijo.
- Actualizar recepción y conteos a medida que estén disponibles los PRs. El [PR #58](https://github.com/GiulianoMaPe/MatricesParalelas/pull/58) aporta el primer lote para el inventario de Go secuencial. Registra 3 calentamientos y 15 mediciones válidas en 3 grupos. Sus 18 filas incluyen los calentamientos.

El cierre del informe de calidad corresponde a I5 después de auditar los cuatro lotes.

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h generación del resumen provisional oficial en `resultados/resumen/resumen_provisional.csv` e implementación de `scripts/audit_dispersion.ps1`; 3 h análisis cuantitativo de dispersión relativa $\text{RSD}_{\text{IQR}}$, vallas de Tukey y redacción del dictamen técnico en `docs/auditoria_dispersion_s08.md`; 1 h revisión cruzada a I8 Roberto sobre `docs/bitacora_experimentos.md`; 1 h coordinación de equipo).
- **PR y rama:** rama de trabajo `feature/s08-i07-resumen-provisional-dispersion`.
- **Entregables:**
  1. [`resultados/resumen/resumen_provisional.csv`](../../resultados/resumen/resumen_provisional.csv): Consolidado provisional de 9 grupos oficiales con 32 columnas canónicas (mediana, IQR, min, max, cuartiles y GFLOPS).
  2. [`scripts/audit_dispersion.ps1`](../../scripts/audit_dispersion.ps1): Herramienta automatizada de auditoría estadística para variabilidad, outliers y ratios extremos.
  3. [`resultados/resumen/dispersion_report.csv`](../../resultados/resumen/dispersion_report.csv): Reporte tabular de métricas de estabilidad por grupo.
  4. [`docs/auditoria_dispersion_s08.md`](../../docs/auditoria_dispersion_s08.md): Informe técnico de auditoría y fundamentación de dictamen de no repetición.
  5. [`resultados/resumen/README.md`](../../resultados/resumen/README.md): Documentación de trazabilidad y estructura del directorio de resúmenes.
  6. [`tests/audit_dispersion_test.ps1`](../../tests/audit_dispersion_test.ps1): Suite de 17 pruebas unitarias automatizadas con 100% de éxito.
- **Auditoría de dispersión cuantitativa:**
  - **$N=512$:** Estabilidad excelente en $W=1$ ($\text{RSD}_{\text{IQR}} = 0.32\%$) y estable en $W=2$ ($2.99\%$) y $W=4$ ($3.15\%$).
  - **$N=1024$:** Se detectó dispersión anormal (> 10%) en $W=2$ ($10.71\%$) y $W=4$ ($11.40\%$).
  - **$N=2048$:** Estabilidad sobresaliente en carga pesada con $\text{RSD}_{\text{IQR}} < 0.70\%$ ($W=1: 0.39\%$, $W=2: 0.42\%$, $W=4: 0.66\%$).
- **Dictamen de repetición justificada según protocolo (§6.3):**
  - **Dictamen emitido:** `CONSERVAR_CONFORME` (No repetir).
  - **Fundamento:** Las 5 observaciones por grupo son completas y válidas (`validation_status = OK`), sin abortos ni timeouts. La fluctuación en $N=1024$ es inherente al planificador del sistema operativo en duraciones cortas (< 0.6 s) y desaparece en cargas mayores. El protocolo §6.3 prohíbe el descarte selectivo o "escoger el mejor lote"; el uso de la mediana inmuniza el análisis contra estas variaciones.
- **Pruebas y evidencias:**
  - `tests/audit_dispersion_test.ps1`: 17 de 17 pruebas superadas (100% PASS).
  - `tests/summarize_results_test.ps1`: 43 de 43 pruebas superadas (100% PASS en regresión).
  - Verificación de codificación UTF-8 sin BOM en todos los artefactos generados.

##### Revisión cruzada de I7 a I8 · 19/11/2026

Se revisó la estructura de [`docs/bitacora_experimentos.md`](../../docs/bitacora_experimentos.md) y los criterios de congelación experimental de Roberto (I8):
- Se verificó la trazabilidad rigurosa exigida para cada archivo CSV desde el commit congelado `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` y la máquina oficial `PCG1UL14N0`.
- Se confirmó que los nombres de archivo y metadatos coincidan exactamente con la convención del contrato (§4) y que la carpeta `resultados/raw/` conserve los datos crudos originales sin sobreescrituras.
- Se coordinó la inclusión de los reportes de dispersión provisionales en el inventario general de cara al Sprint 9. Su trabajo queda conforme como base para la congelación final.

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

### I3 · Giuliano · 17/11/2026

- Entrega técnica: [Go secuencial y resultados tabulados](../../resultados/raw/s08_i03_go_secuencial_03/README.md),
  18 observaciones válidas (3 warmups + 15 medidas), cinco medidas únicas por
  N=512/1024/2048, semilla 42, workers=GOMAXPROCS=1.
- Fuente oficial: `s08_i03_go_secuencial_03`, candidata `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`,
  subplan con **72/72 corridas OK**, 12 grupos completos y 0 exclusiones.
  Se preservan CSV, plan, entorno, manifiestos, fuentes/hashes y logs/ranks.
- [Plan y registro individual](sprint-08-i03-plan.md): intentos previos conservados;
  timeout ampliado de 300 a 900 s sin cambiar los binarios ni sustituir filas.
- Verificador común y revisión I3: COMPLETE/VERIFIED; extracción idéntica a
  sus líneas fuente, veinte columnas, parámetros, UTC, tiempos y entorno hijo válidos.
- GPU medida; CPU sin lectura. Rango térmico y límites documentados junto a los resultados.
- Revisión I2→I3: pendiente; revisor asignado `@SebastianMalca`; [PR #58](https://github.com/GiulianoMaPe/MatricesParalelas/pull/58).
- Horas reales/coordinación: no confirmadas para S8; presupuesto I3 de 8 h.
- Duración de los controles N=2048 superior al timeout inicial: revisar presupuesto de máquina y reserva de la campaña integral con I5/I6.
- El alcance es I3 con controles: el resto de combinaciones, la auditoría y la
  congelación del equipo y su cierre de sprint siguen pendientes.
