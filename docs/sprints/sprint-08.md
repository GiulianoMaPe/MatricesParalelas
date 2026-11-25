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

#### Integrante 1 (Yessly)

- **Participantes y horas reales.** Yessly (I1) declaró 8 h (3 h ejecución y supervisión de lotes C secuencial, 3 h revisión de integridad, metadatos y control independiente, 1 h revisión cruzada a I2 en PR #59 y 1 h coordinación de equipo).
- **PR y ejecución.** PR en rama `feature/s08-i01-c-secuencial-oficial`. Siguiendo el protocolo de precedencia de I4 (PR #60), se extrajo y auditó formalmente el lote oficial de C secuencial medido en la PC oficial `PCG1UL14N0` (Ryzen 5 3600, MSVC 14.44, commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`) a partir de la campaña integrada oficial (`resultados/raw/s08_i04_go_paralelo_01/mediciones.csv`). Adicionalmente, se ejecutó una campaña de control independiente en el host `YESSLY-TB14G9` (AMD Ryzen 7 250, Windows 11 build 26200.9974) con `scripts\bench_windows.ps1 -Version c_secuencial -Fase oficial`.
- **Entregable.** [`resultados/raw/c_secuencial.csv`](../../resultados/raw/c_secuencial.csv) conserva exactamente las 18 filas oficiales (3 calentamientos y 15 mediciones válidas en 3 grupos $N=512, 1024, 2048$, semilla 42, `validation_status=OK`). Se generó su manifiesto de procedencia e integridad en [`resultados/raw/c_secuencial.manifest.json`](../../resultados/raw/c_secuencial.manifest.json) con SHA-256 `0F82F9FDE140C6E928AFB0476392E22181DEDEE534F42D7D20B3271973B3C854`. Los datos de control independiente se preservan en `resultados/control/s08_i01_c_secuencial_control/` con manifiesto propio.
- **Auditoría e integridad.** Esquema de 20 columnas verificado. 18 de 18 corridas OK. En todas las filas se cumple $0 \le \text{kernel\_s} \le \text{total\_s}$. Mismo commit congelado (`97ccc981e9068d8ec0753cd8a4b7572a6bece34d`), hostname (`PCG1UL14N0`), semilla (`42`) y versión (`c_secuencial`). Dispersión relativa (rango/mediana) baja: 0.84% para $N=512$ (mediana 0.02393 s), 3.06% para $N=1024$ (mediana 0.19502 s) y 3.04% para $N=2048$ (mediana 3.79299 s). Cero fallos numéricos ni anomalías críticas. Se anota la observación de que `os_version` reporta `"Windows 10 Pro build 26300.9711"`, correspondiente a la compilación del kernel NT en Windows 11 (se conserva sin alterar el CSV crudo).
- **Pruebas y regresión.** Se verificó compilación Release con `build_windows.ps1` y suite de regresión completa con `test_windows.ps1 -Version c_secuencial -SkipBuild` (código de salida 0, pasando pruebas de instalación, contratos S2/S5 y 5 fixtures con `compare_results.ps1`). Revisión pendiente de I8 (Roberto).

##### Revisión cruzada de I1 a I2 (Sebastian) · PR #59
Se auditó la rama `origin/feature/s08-i02-c-paralelo-oficial`. Sebastián implementó con rigor técnico el extractor `scripts/extract_s08_c_paralelo.ps1` con 13 pruebas unitarias sintéticas (13/13 OK) y regresión de S7 (23/23 OK). Reconoció honestamente la limitación de entorno en su PC (`DESKTOP-JIHSDJ6`, sin MSVC/MS-MPI ni permisos de administrador) y aplicó la política de no fabricar datos ni mezclar datos de prueba en `resultados/raw/c_paralelo.csv`. Dejó documentado el handoff para la PC oficial `PCG1UL14N0`. Su entrega es aprobada a nivel de herramienta y documentación.

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
