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

- **Participantes y horas reales:** Eva Moreno (I4). El plan contempla 3 h para ejecutar y supervisar los lotes de Go paralelo, 3 h para revisar los workers efectivos y la estabilidad de las repeticiones, 1 h de revisión cruzada a I5 (Fernando, `docs/calidad_datos.md`) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s08-i04-go-paralelo-oficial`. La revisión corresponde a I3 (Giuliano) según la rotación.

- **Estado del entregable `resultados/raw/go_paralelo.csv`: pendiente de la campaña en la PC oficial.** Según [docs/campana.md](../campana.md), la PC oficial es `PCG1UL14N0` (Ryzen 5 3600, 6 núcleos físicos, Go 1.27.4) y la candidata congelada es `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`. El equipo de I4 (Ryzen 7 3700X, 8 núcleos, Go 1.27.1) no es esa PC: medir aquí produciría otro hardware y otras herramientas, y activaría W=8, que la PC oficial no tiene. Por eso no se generó ni se simuló el CSV oficial, igual que en la entrega de I2.

- **Entregado:**
  - [`scripts/extract_s08_go_paralelo.ps1`](../../scripts/extract_s08_go_paralelo.ps1): audita una campaña ya ejecutada, sin medir, y escribe la vista `go_paralelo` byte a byte junto con un manifiesto JSON (hashes, grupos, estadísticas y anomalías).
    - **Workers efectivos:** W permitido por los núcleos físicos registrados (W=8 solo con 8 o más) y serie completa del protocolo en fases oficial y piloto. Además, `workers = gomaxprocs = W` en la fila, `GOMAXPROCS` del entorno hijo y `--workers W` en `proceso.json`, un proceso y un hilo observado, `stdout.txt` idéntico a la fila, código 0 y registro en la bitácora.
    - **Estabilidad:** mediana, Q1/Q3 e IQR con la definición de `summarize_results.ps1`, mínimo y máximo, y speedup interno frente a W=1. Marca `dispersion_alta` (IQR/mediana > 10 %), `tiempo_corto` (mediana < 100 ms, política de reloj S6), `tendencia_creciente` y `sin_aceleracion`. Son avisos: no elimina ni reordena observaciones.
  - [`tests/extract_s08_go_paralelo_test.ps1`](../../tests/extract_s08_go_paralelo_test.ps1): **17/17 casos.** Cada caso copia una campaña real a una carpeta temporal y le introduce un defecto: GOMAXPROCS del hijo, `gomaxprocs` o `workers` informados, argumentos, stdout distinto, proceso fallido, medida fallida, `kernel_s > total_s`, commit, bitácora, W sobre la capacidad, serie incompleta, dispersión conservada, `-AllowIncomplete` y fase diagnóstico.
  - [`resultados/diagnostico/s08_i04_go_paralelo/`](../../resultados/diagnostico/s08_i04_go_paralelo/README.md) (**no oficial**): extracción de los intentos S7 `_05` y `_06` de la PC oficial. Resultados:
    - VERIFIED_PILOT en ambos, con 54 filas y 0 críticas cada uno.
    - Speedup interno de 1,94–1,99 con W=2 y de 3,36–3,71 con W=4.
    - Cambio mediano de 0,98 % entre intentos; máximo de 10,0 % en N=256/W=4, un grupo de unos 5 ms ya marcado como tiempo corto.
    - Las medianas, Q1 y Q3 coinciden con el resumen de I7 en los 9 grupos.
    - Sobre la subcampaña oficial de I3 (PR #58), el extractor da DIAGNOSTIC con 18 filas W=1 válidas en fase diagnóstico, e INCOMPLETE por `serie_incompleta` en fase oficial, como corresponde.

- **Traspaso a la PC oficial (I3):**
  - **Comando.** Desde la raíz del repositorio en `PCG1UL14N0`, con AC, plan Equilibrado y sin otras mediciones:

    ```powershell
    Set-Location .\.cache\s08-candidata-97ccc98
    git rev-parse HEAD     # debe ser 97ccc981e9068d8ec0753cd8a4b7572a6bece34d
    git status --short     # debe estar vacío
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Fase oficial -CampaignId s08_i04_go_paralelo_01 -Configurations P1_T1 -TimeoutSeconds 900
    ```

  - **Plan resultante.** Con 6 núcleos físicos son 108 corridas: `c_secuencial`, `go_secuencial`, `c_paralelo_P1_T1` y `go_paralelo_W1/W2/W4` para N=512/1024/2048, con 1 calentamiento y 5 medidas cada una. La línea base `go_secuencial` queda en la misma campaña, de modo que I7 puede calcular el speedup sin cruzar archivos. Se verificó la selección con `Get-IntegratedConfigurations -PhysicalCores 6`.
  - **No usar `-GoWorkers 1,2,4` con `powershell.exe -File`.** El argumento llega como texto y, con configuración regional en español, `"1,2,4"` se interpreta como 124; la campaña lo rechaza ("Workers fuera del protocolo/capacidad: 124"). Sin `-GoWorkers` se aplica la serie del protocolo, que con 6 núcleos es W=1/2/4.
  - **Duración.** Con las paredes del piloto `_05` (N=2048 escalado ×8) se proyectan unos 34 min, o 52 min con 50 % de margen. La subcampaña de I3 tardó 77 min porque su control MPI con N=2048 tardó unos 450 s por corrida, así que se recomienda reservar 1,5 h.
  - **Después de medir.** Copiar la carpeta `resultados\raw\s08_i04_go_paralelo_01` de la candidata a `resultados\raw\` de este repositorio, comprobar los SHA-256 y, desde la raíz:

    ```powershell
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_campaign.ps1 -CampaignDirectory .\resultados\raw\s08_i04_go_paralelo_01
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_go_paralelo.ps1 -CampaignDirectory .\resultados\raw\s08_i04_go_paralelo_01
    ```

    La segunda orden escribe `resultados/raw/go_paralelo.csv` y `go_paralelo.manifest.json`, y termina con código 1 si hay anomalías críticas. Si el equipo ejecuta en cambio la campaña integrada completa (`s08_oficial_01`), basta con pasar esa carpeta como `-CampaignDirectory`.

- **Bloqueos y decisiones:**
  - El entregable oficial depende de la PC oficial y de su responsable; I4 no tiene acceso a ella.
  - El extractor exige la serie completa en fase oficial; el control W=1 de I3 no completa el lote.
  - No se modificaron los scripts de campaña ni la candidata congelada; el problema de `-GoWorkers` se documenta y se evita, no se corrige en la candidata.

- **Revisión y criterio de aceptación:** la herramienta y su evidencia no oficial están completas y verificadas. Quedan pendientes la ejecución oficial y su extracción en la PC oficial, la revisión de I3, mi revisión cruzada de `docs/calidad_datos.md` (I5), las horas reales y la aceptación del equipo.
