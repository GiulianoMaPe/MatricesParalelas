# Sprint 6 Optimizar con evidencia

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 6 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Mejorar el rendimiento sin cambiar la corrección ni introducir comparaciones injustas.

Cierre: Cada cambio conservado tiene medición antes y después y pasa la batería común; se fija el algoritmo para la campaña.

## Trabajo de cada integrante

Integrante 1  Medir localidad y accesos del núcleo C secuencial (3 h). Aplicar como máximo una mejora justificada y documentar su efecto (3 h). Entregable: Comparativa de una optimización C. Ubicación: c_secuencial/src/matrix.c.

Integrante 2  Medir reparto OpenMP y configuraciones iniciales de P y T (3 h). Ajustar granularidad o copias y verificar que no se fuerce un único núcleo (3 h). Entregable: Comparativa del híbrido C. Ubicación: c_paralelo/src/matrix.c.

Integrante 3  Medir asignaciones y acceso a slices del Go secuencial (3 h). Reducir asignaciones evitables y comprobar equivalencia numérica (3 h). Entregable: Comparativa de una optimización Go. Ubicación: go_secuencial/matrix.go.

Integrante 4  Medir tamaño de bloque y coste del canal de Go paralelo (3 h). Ajustar bloques y cantidad de workers sin crear tareas por celda (3 h). Entregable: Comparativa de granularidad Go. Ubicación: go_paralelo/workers.go.

Integrante 5  Estimar memoria del proceso raíz y del resto de procesos (3 h). Medir el pico en tamaños piloto y fijar límites seguros para la campaña (3 h). Entregable: Tabla de memoria y capacidad. Ubicación: docs/memoria.md.

Integrante 6  Ejecutar pruebas de regresión después de cada cambio aceptado (3 h). Revisar diferencias de orden de bucles y oportunidades de optimización desigual (3 h). Entregable: Informe de equidad algorítmica. Ubicación: docs/equidad_algoritmica.md.

Integrante 7  Recopilar mediciones del piloto con metadatos completos (3 h). Descartar cambios sin mejora consistente o mantenerlos como experimento separado (3 h). Entregable: Registro de decisiones de rendimiento. Ubicación: docs/optimizaciones.md.

Integrante 8  Actualizar decisiones de diseño y su relación con la literatura (3 h). Definir qué cambios se conservan y los criterios para congelar el algoritmo (3 h). Entregable: Diseño validado y decisiones de optimización. Ubicación: docs/arquitectura.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-06.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

#### Integrante 4

- **Participantes y horas reales:** Eva (I4). El plan contempla 3 h de medición del tamaño de bloque y del coste del canal, 3 h de ajuste de bloques y cantidad de workers, 1 h de revisión cruzada a I5 (Fernando, `docs/memoria.md`) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s06-i04-granularidad-go`. La revisión corresponde a I3 (Giuliano) según la rotación.

- **Pruebas y evidencias:** entregable [Comparativa de granularidad Go](../granularidad_go.md).
  - **Cambio en el código:** en [workers.go](../../go_paralelo/workers.go), `multiplyParallelKernelBlocks` y `dispatchRowBlocksOfSize` reciben el tamaño de bloque explícito. El camino canónico sigue usando `ceil(N/W)`.
  - **Medición:** el arnés [granularity_test.go](../../go_paralelo/granularity_test.go) midió el 11/11/2026, en el Ryzen 7 3700X con Go 1.27.1, 720 corridas: N ∈ {256, 512, 1024, 2048}, W ∈ {1, 2, 4, 8, 16} y seis granularidades, desde un bloque por worker hasta una fila por tarea. Hubo 1 calentamiento y 5 repeticiones, con el orden rotado en cada ronda. `total_s` se midió con `QueryPerformanceCounter`, y todas las corridas fueron idénticas bit a bit a W=1.
  - **Benchmarks:** el canal cuesta 0,15–0,25 µs por tarea y la coordinación fija, menos de 10 µs por corrida, lo que da menos del 0,05 % de `total_s` incluso con una fila por tarea.
  - **Resultado:** los bloques finos bajan `total_s` entre un 4 y un 12 % con W=4 y W=8 y N ≥ 1024, por balance de carga. Con W=1, W=16 y N=512, el efecto es nulo o irregular.
  - **Datos:** en [resultados/experimentos/granularidad_go/](../../resultados/experimentos/granularidad_go/).

- **Bloqueos y decisiones:**
  - **Se conserva el bloque canónico `ceil(N/W)` para la campaña.** La mejora no es consistente en todas las configuraciones (regla de arquitectura §11), y el balance dinámico solo en Go sería asimétrico frente al reparto estático de C (`Scatterv` y `schedule(static)`). La variante fina queda como experimento aislado.
  - **Serie de workers recomendada:** W ∈ {1, 2, 4, 8, 16}.
  - **Hallazgo a coordinar con I3 e I7 antes del piloto:** `time.Now()` de Go avanza a saltos de 0,5 ms en este Windows, mientras C mide con `QueryPerformanceCounter` o `MPI_Wtime` (100 ns). Los tiempos cortos de Go en la campaña tendrían una resolución mucho más gruesa que los de C. Las opciones están en el informe.

- **Revisión y criterio de aceptación:** el ejecutable no cambia de comportamiento. `go vet`, `go test`, `go test -race` y `test_windows.ps1 -Version go_paralelo` en Debug y Release terminaron con código 0 (detalle en el PR). Quedan pendientes la revisión de I3, mi revisión de `docs/memoria.md` de I5 cuando se publique, las horas reales y la aceptación del equipo.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h actualización de decisiones de diseño y fundamentación con la literatura científica, 3 h formulación de criterios de congelamiento algorítmico y evaluación de optimizaciones descartadas, 1 h coordinación general, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s06-i08-diseno-optimizaciones`.
- Pruebas y evidencias: Entregable `docs/arquitectura.md` completado y actualizado con las Secciones 9 a 12. Se fundamenta la jerarquía de memoria (L1/L2/L3), líneas de caché de 64 bytes y la superioridad de stride-1 en el orden canónico $i \to k \to j$ frente a $i \to j \to k$ (Dongarra et al., Hennessy & Patterson). Se analiza el particionado jerárquico comparado con H-SUMMA (Quintin & Wagner 2013) y la ausencia de sobrecostes de empaquetado 2D en el reparto 1D continuo por filas. Se fundamenta el modelo CSP de Go (Hoare, Golani et al. 2021). Se formulan las decisiones de diseño para descartar tiling manual y SIMD asimétrico en favor de la auto-vectorización del compilador y la equidad algorítmica. Se formaliza el Marco Normativo de Congelamiento Algorítmico en 5 criterios inviolables para las campañas de los Sprints 7 y 8.
- Bloqueos y decisiones: Se declara oficialmente congelado el algoritmo canónico $i \to k \to j$ en sus cuatro versiones (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`), prohibiendo alteraciones de bucles que distorsionen la comparabilidad de rendimiento.
- Revision y criterio de aceptacion: Entregable de I8 finalizado y conforme; listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly pendiente a la publicación de su PR de Sprint 6.

