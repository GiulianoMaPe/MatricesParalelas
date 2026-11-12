# Sprint 6 — Optimizar con evidencia

**Cierre técnico y revisión de integración completados el 12/11/2026.**
Se integraron las entregas I4 e I7 con prioridad de sus ramas; I8 ya estaba en
main mediante PR #43. Se conserva el algoritmo de las cuatro versiones,
con candidatas aisladas y decisiones basadas en evidencia Windows nativa.
El [PR #47](https://github.com/GiulianoMaPe/MatricesParalelas/pull/47) registra
esta entrega y su integración hacia main; su estado es la referencia del cierre.

Rama: `feature/s06-optimizacion-evidencia`. Issue de cierre:
[#46](https://github.com/GiulianoMaPe/MatricesParalelas/issues/46).
Base medida `72417b989c5ef8792970f57724a8f7bd639ca7e2`, con fuentes exactas, diff y hashes archivados.
La [antigua acta Linux](sprint-06-linux.md) se conserva sin convertir sus
pruebas en ejecuciones Windows.

## Entregables y aceptación

| Área | Entrega de cierre | Estado |
| --- | --- | --- |
| C secuencial | Comparativa MSVC baseline/restrict_c, validación por celda; base conservada | Completo |
| C híbrido | Kernel local static/static1 y programa MPI P1T1, P1T2, P2T1, P1T4, P2T2, P4T1; hilos, afinidad, restos/vacíos y errores/timeouts | Completo |
| Go secuencial | Baseline/row_slices, asignaciones API/kernel, GOMAXPROCS=1 y base conservada | Completo |
| Go paralelo | Entrega I4, bloque/canal experimentales, estabilidad y corrección del reloj del arnés; bloque canónico conservado | Completo |
| Memoria | 33 perfiles de programas, PID/rank, raíz/resto y suma simultánea, modelos/límites para S7 | Completo |
| Equidad | Representación, generación, orden, propiedad de filas y cronometraje auditados; regresión nativa | Completo |
| Decisiones | Entrega I7 incorporada, afirmaciones sin originales limitadas, datos Linux/otros hosts separados | Completo |
| Diseño | Entrega I8 conservada y arquitectura actualizada; algoritmo aceptado para piloto S7 | Completo |
| Revisión | Revisión de código y evidencia por Codex, expresamente encargada por el responsable | Completo |

Evidencia principal: [aceptación Windows](../cierre_s06_windows.md),
[optimización](../optimizaciones.md), [memoria](../memoria.md),
[equidad](../equidad_algoritmica.md), [arquitectura](../arquitectura.md) y
[revisión](../revision_s06.md). Datos originales en
[`s06_windows_20261112`](../../resultados/piloto/s06_windows_20261112/).

540 corridas válidas (90 calentamientos,
450 medidas), cero fallos y cero grupos incompletos.
Debug/Release: 24 comparaciones, 49 errores controlados y 148 invocaciones C/Go
por configuración. Se conservaron todos los originales, incluidos los 189
incumplimientos temporales históricos de I4, sin reetiquetarlos como válidos.

## Autorías, horas y alcance de la revisión

El registro técnico de I6 y las regresiones ejecutadas en el workspace están
documentados en [Sprint 6 · Registro técnico de I6](sprint-06-i6.md).

| Persona | Horas reales declaradas | Fuente |
| --- | ---: | --- |
| Giuliano (I3), integración asistida por Codex | 8 h | Confirmación del responsable en esta sesión |
| Eva (I4) | 8 h | Confirmación del responsable en esta sesión; sustituye el pendiente de su registro original |
| Andrés (I7) | 8 h | Declaración recibida en su rama |
| Roberto (I8) | 8 h | Declaración recibida en PR #43 |

Se registran 32 h declaradas; las 64 h del plan siguen siendo estimación del
equipo, no se convierten en horas realizadas. No se atribuyen nuevas horas a
I1/I2/I5/I6 sin declaración. Los entregables faltantes se completaron en la
integración asistida, sin fingir PR individuales ni firmas de esos integrantes.
El tiempo de máquina está en los manifiestos y no se suma como horas personales.

El responsable indicó: «la revisión externa también la haces tú». Para este
cierre se acepta la revisión por Codex en lugar de esperar revisión humana
cruzada. Esta excepción explícita no implica conformidades personales ficticias
ni modifica el flujo general de otros sprints. Los hallazgos y sus resoluciones
quedan en el informe de revisión. Las conformidades históricas S4/S5 permanecen
fuera de este cierre y no se dan por completadas aquí.

## Base y fronteras para S7

Se conserva el cálculo i,k,j, float64/double row-major, entradas LCG y A/B de
lectura, C independiente y vaciado dentro de total_s. C mantiene `schedule(static)`;
Go mantiene bloque `ceil(N/W)`, canal W y MaxWorkers=1024. Ninguna candidata
se promueve; no se exige inventar cambios para cerrar S6.

S7 recibe N=256,512,1024 explorados, W=1,2,4 y las seis configuraciones P/T.
N=2048 queda condicionado a su piloto de duración; N=4096 se excluye por ahora.
S7 debe implementar `bench_windows.ps1`, el agregador, captura/validación de
campaña y piloto reproducible. No se habilitó el TODO ni se produjo campaña S8.
Debe registrar de nuevo resolución de relojes y RAM disponible en su equipo final.
Para Go se fija aquí un umbral conservador de 100 ms en total y kernel para
usar un grupo en comparaciones, debido al paso local cercano a 0,5 ms.
Los grupos cortos se preservan como diagnóstico; N=1024 es el punto de partida
local para el piloto comparable, y N=2048 queda condicionado a su prueba de duración.

`go test -race` local se registra con su resultado real; si falta cgo/GCC se
conserva como limitación no bloqueante del entorno básico, junto a las pruebas
race Linux y de I4 en su equipo. Los intentos ASan Linux sin libasan permanecen
documentados; no se los presenta como aprobados ni como pruebas Windows pendientes.

## Plan original de asignaciones

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


## Registros originales recibidos

Los apartados siguientes conservan las declaraciones de sus autores. Sus
pendientes y conclusiones corresponden a las entregas originales; la tabla de
aceptación y la revisión de arriba describen su resolución durante el cierre.

#### Integrante 4

- **Participantes y horas reales:** Eva (I4). El plan contempla 3 h de medición del tamaño de bloque y del coste del canal, 3 h de ajuste de bloques y cantidad de workers, 1 h de revisión cruzada a I5 (Fernando, `docs/memoria.md`) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s06-i04-granularidad-go`; [PR #45](https://github.com/GiulianoMaPe/MatricesParalelas/pull/45). La revisión corresponde a I3 (Giuliano) según la rotación.

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


#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h recopilación y análisis de mediciones del piloto en hardware nativo x64; 3 h redacción del informe técnico y registro formal de decisiones en `docs/optimizaciones.md`; 1 h revisión cruzada formal a Roberto I8 sobre `docs/arquitectura.md`; 1 h coordinación de acuerdos del sprint con Gerardo I6).
- **Issues y pull requests:** rama de trabajo `feature/s06-i07-registro-optimizaciones`. Pull request listo para apertura.
- **Entregable principal:** [`docs/optimizaciones.md`](../optimizaciones.md) (Registro de decisiones de rendimiento y evaluación de optimizaciones).
- **Pruebas y evidencias:**
  - Se recopilaron mediciones preliminares de la línea base piloto en hardware AMD Ryzen 7 8845HS (8C/16T, 16 GB RAM DDR5, Windows 11 Build 26300) cubriendo tamaños $N \in \{128, 256, 512, 1024\}$ con metadatos completos y esquema CSV unificado de 20 campos.
  - Se evaluaron formalmente seis propuestas de optimización (OPT-01 a OPT-06), cuantificando su impacto en rendimiento, sobrecostes de memoria y equidad algorítmica.
  - Se ratificó y congeló el orden canónico $i \to k \to j$ por su óptimo aprovechamiento de la jerarquía de memoria (accesos *stride-1* continuos en $B$ y $C$ y compatibilidad con auto-vectorización del compilador).
  - Se descartó el bloqueo/tiling manual por bloques de caché (BMM) tras comprobar que en $N \le 1024$ añade sobrecostes de bifurcación e indexación que degradan entre $4\%$ y $9\%$ el rendimiento y genera asimetría entre compiladores C y Go.
  - Se descartó la pre-transposición de $B$ por requerir $O(N^2)$ memoria adicional y violar el principio de inmutabilidad de solo lectura.
  - Se prohibieron intrínsecos SIMD manuales en C para evitar comparaciones asimétricas contra Go, preservando la equidad algorítmica.
  - Se validaron y congelaron las optimizaciones de pre-asignación en Go (cero alocaciones en el kernel) y particionado 1D en bloques de filas continuas ($N/W$ y $N/P$).
- **Bloqueos y decisiones:** Se formaliza el congelamiento algorítmico definitivo de las cuatro versiones para asegurar que las mediciones de los Sprints 7 y 8 reflejen fielmente el escalamiento de los modelos de paralelismo y no artefactos de sintonización espuria.
- **Revisión a I8 (Roberto):** Revisé exhaustivamente las Secciones 9 a 12 añadidas por Roberto en [`docs/arquitectura.md`](../arquitectura.md). La fundamentación teórica de la jerarquía de memoria (L1/L2/L3), el análisis de saltos en líneas de 64 bytes, la justificación de no empaquetamiento 2D frente a H-SUMMA y la formulación de los 5 Criterios Normativos de Congelamiento Algorítmico son impecables y sustentan con rigor científico las decisiones de rendimiento. El entregable de I8 queda **CONFORME**.
- **Revisión y criterio de aceptación:** Mi entregable técnico (`docs/optimizaciones.md`), la matriz de decisiones y la revisión cruzada quedan completados y conformes al Sprint 6.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h actualización de decisiones de diseño y fundamentación con la literatura científica, 3 h formulación de criterios de congelamiento algorítmico y evaluación de optimizaciones descartadas, 1 h coordinación general, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s06-i08-diseno-optimizaciones`.
- Pruebas y evidencias: Entregable `docs/arquitectura.md` completado y actualizado con las Secciones 9 a 12. Se fundamenta la jerarquía de memoria (L1/L2/L3), líneas de caché de 64 bytes y la superioridad de stride-1 en el orden canónico $i \to k \to j$ frente a $i \to j \to k$ (Dongarra et al., Hennessy & Patterson). Se analiza el particionado jerárquico comparado con H-SUMMA (Quintin & Wagner 2013) y la ausencia de sobrecostes de empaquetado 2D en el reparto 1D continuo por filas. Se fundamenta el modelo CSP de Go (Hoare, Golani et al. 2021). Se formulan las decisiones de diseño para descartar tiling manual y SIMD asimétrico en favor de la auto-vectorización del compilador y la equidad algorítmica. Se formaliza el Marco Normativo de Congelamiento Algorítmico en 5 criterios inviolables para las campañas de los Sprints 7 y 8.
- Bloqueos y decisiones: Se declara oficialmente congelado el algoritmo canónico $i \to k \to j$ en sus cuatro versiones (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`), prohibiendo alteraciones de bucles que distorsionen la comparabilidad de rendimiento.
- Revision y criterio de aceptacion: Entregable de I8 finalizado y conforme; listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly pendiente a la publicación de su PR de Sprint 6.

## Integración y base entregada

Entrega consolidada: [PR #47](https://github.com/GiulianoMaPe/MatricesParalelas/pull/47),
que resuelve [issue #46](https://github.com/GiulianoMaPe/MatricesParalelas/issues/46).
Las ramas I4/I7 se conservan como padres de la integración; I8 ya era parte
de main. El árbol publicado antes de esta referencia editorial fue
4e2710379e50b09202b0e27aa9e58b4f3fd1154f, idéntico al árbol local revisado.
La [comprobación de fuentes](../../resultados/piloto/s06_windows_20261112/production-source-check.json)
confirma que las 30 fuentes de producción coinciden con las medidas.
Los cambios editoriales de cierre no alteran cálculo, buffers ni cronómetros.
S7 debe identificar su revisión de automatización después del piloto.
