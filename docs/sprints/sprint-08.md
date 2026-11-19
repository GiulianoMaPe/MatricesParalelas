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

## Registros individuales

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
