# Sprint 4 Construir las versiones paralelas

**Estado al 28/10/2026: cierre técnico completado; cierre administrativo pendiente.**
Las ocho entregas están integradas en `main` y cumplen la aceptación funcional
de S4. El registro de cierre siguiente reúne la revisión general, la trazabilidad
y las pruebas reproducidas sobre `2f22e3a`. Los registros individuales se conservan
como evidencia histórica: sus pendientes técnicos y su distribución de horas
quedan actualizados por esta síntesis. Las cuatro revisiones personales sin
evidencia siguen pendientes.

Semana 4 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Implementar el híbrido C y el conjunto de trabajadores Go usando las referencias existentes.

Cierre: Las cuatro versiones coinciden en los fixtures. C usa MPI y OpenMP y Go espera correctamente a todos sus trabajadores.

## Trabajo de cada integrante

Integrante 1  Implementar Scatterv y Gatherv con el reparto acordado (3 h). Probar P igual a uno y particiones no divisibles con el núcleo secuencial (3 h). Entregable: Comunicación MPI funcional. Ubicación: c_paralelo/src/main.c y partition.c.

Integrante 2  Integrar OpenMP en las filas locales del híbrido (3 h). Verificar FUNNELED, variables privadas y ausencia de llamadas MPI en hilos secundarios (3 h). Entregable: Híbrido MPI y OpenMP funcional. Ubicación: c_paralelo/src/matrix.c.

Integrante 3  Implementar workers Go y distribución de bloques de filas (3 h). Comprobar que cada fila tiene un solo escritor y todas son calculadas (3 h). Entregable: Núcleo Go paralelo funcional. Ubicación: go_paralelo/workers.go.

Integrante 4  Integrar flags, cierre del canal y WaitGroup en Go paralelo (3 h). Probar workers igual a uno, varios workers y más workers que filas (3 h). Entregable: Ejecutable Go paralelo integrado. Ubicación: go_paralelo/main.go.

Integrante 5  Crear pruebas del reparto MPI y bloques vacíos (3 h). Ejecutar casos impares y revisar errores de counts y desplazamientos (3 h). Entregable: Reporte de particionado C. Ubicación: c_paralelo/tests/.

Integrante 6  Crear pruebas de concurrencia Go por repetición y tamaños variados (3 h). Verificar terminación, resultados estables y no pérdida de tareas (3 h). Entregable: Reporte de concurrencia Go. Ubicación: go_paralelo/workers_test.go.

Integrante 7  Comparar salidas de las cuatro versiones con los fixtures (3 h). Investigar discrepancias y ampliar casos de equivalencia cruzada (3 h). Entregable: Reporte de equivalencia de cuatro versiones. Ubicación: docs/equivalencia.md.

Integrante 8  Documentar los flujos de datos y sincronización de ambos paralelos (3 h). Relacionar los mecanismos reales con el diseño y la rúbrica (3 h). Entregable: Descripción de arquitectura actualizada. Ubicación: docs/arquitectura.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-04.md.

## Registro de cierre

### Resultado y base revisada

**Sprint 4 técnicamente completado.** Las cuatro versiones coinciden con los
cinco fixtures compartidos; el híbrido ejecuta MPI y OpenMP, y Go paralelo cierra
el canal y espera a todos sus trabajadores antes de validar o escribir C.
La revisión general y las pruebas automatizadas no sustituyen las revisiones
personales del ciclo ni constituyen firmas de los integrantes.

- **Base:** `main` y `origin/main` coinciden en
  `2f22e3a23aad5d248a2f999dae1d280c24001bf1`, comprobado mediante
  `git fetch origin main` y `git rev-list --left-right --count main...origin/main`
  (resultado `0 0`). El cierre documental se publica directamente en `main`
  por instrucción del responsable del repositorio.
- **Alcance:** dos tareas principales por integrante, ocho entregables técnicos
  integrados. La evidencia procede del código, los PR, las revisiones publicadas
  y las pruebas ejecutadas el 28/10/2026.
- **Coordinación prevista:** Eva (I4), según el ciclo de
  [responsabilidades](README.md). Esta acta no atribuye a Eva una aprobación
  personal ni horas adicionales.

### Tareas y trazabilidad de las ocho entregas

| Integrante | Entrega revisada | Integración en main | Resultado técnico |
| --- | --- | --- | --- |
| I1 · Yessly | `partition.c`, `main.c`: Bcast, Scatterv y Gatherv; P=1, P>N y restos | [PR #33](https://github.com/GiulianoMaPe/MatricesParalelas/pull/33), `bb6a4dc` | Conforme |
| I2 · Sebastian | `matrix.c`: filas locales con OpenMP, variables de bucle privadas y MPI fuera de la región paralela | Commit `dd5891d`, incluido en [PR #33](https://github.com/GiulianoMaPe/MatricesParalelas/pull/33); no hay PR exclusivo de I2 | Conforme |
| I3 · Giuliano | `workers.go`: pool acotado, bloques contiguos, cobertura y único escritor por fila | [PR #29](https://github.com/GiulianoMaPe/MatricesParalelas/pull/29) y ajustes del [PR #32](https://github.com/GiulianoMaPe/MatricesParalelas/pull/32) | Conforme |
| I4 · Eva | `main.go`: flags, integración del canal/WaitGroup, repetición, tiempos y CSV | [PR #30](https://github.com/GiulianoMaPe/MatricesParalelas/pull/30) y [PR #32](https://github.com/GiulianoMaPe/MatricesParalelas/pull/32) | Conforme |
| I5 · Fernando | `partition_test.c` y [reporte de particionado](../../c_paralelo/tests/reporte_particionado.md): counts, desplazamientos y bloques vacíos | [PR #34](https://github.com/GiulianoMaPe/MatricesParalelas/pull/34), `865f901` | Conforme |
| I6 · Gerardo | `workers_test.go`: 720 productos repetidos, cobertura de filas y ocho llamadas concurrentes | [PR #31](https://github.com/GiulianoMaPe/MatricesParalelas/pull/31), `f46a6af` | Conforme; detector de carreras reproducido en este cierre |
| I7 · Andrés | [Equivalencia](../equivalencia.md) y herramienta auxiliar de comparación | [PR #35](https://github.com/GiulianoMaPe/MatricesParalelas/pull/35), `2f22e3a` | Equivalencia conforme; limitación de la herramienta auxiliar indicada abajo |
| I8 · Roberto | [Arquitectura](../arquitectura.md): flujos MPI/OpenMP y Go, sincronización y relación con el diseño | [PR #28](https://github.com/GiulianoMaPe/MatricesParalelas/pull/28), `2888afa` | Conforme |

La consulta de GitHub no encontró issues del repositorio. Se conserva la
trazabilidad real por PR y commits; no se crean issues retroactivas ni se toma
el texto de ejemplo «Closes #1» del PR #33 como una issue existente.

### Pruebas y criterio de aceptación

Entorno de reproducción: Windows x64, build 26300, AMD Ryzen 5 3600, 15.912 GiB
de RAM; MSVC 14.51.36231, Windows SDK 10.0.26100.0, MS-MPI Runtime
10.1.12498.52, Go 1.27.0 windows/amd64. El detector de carreras se ejecutó con
`CGO_ENABLED=1` y GCC 15.1.0 de `C:\msys64\ucrt64\bin`.

| Comprobación | Resultado observado el 28/10/2026 |
| --- | --- |
| `test_windows.ps1 -Version all -Configuration Debug` | C secuencial y ambos Go conformes. El comando global devolvió 1 al no poder lanzar MPI dentro del entorno restringido; no se registra como una ejecución global exitosa. |
| `test_windows.ps1 -Version c_paralelo -Configuration Debug`, fuera del entorno restringido | Código 0; compilación, ambas pruebas C, smoke MPI/OpenMP, nueve comparaciones y CSV conformes. |
| `test_windows.ps1 -Version all -Configuration Release`, fuera del entorno restringido | Código 0; las cuatro versiones pasan las pruebas del módulo, los fixtures y las comprobaciones de CSV. |
| `verify_partition_design.ps1` | Código 0; ocho ejemplos, 4480 pares N/P y fronteras 46340/46341. |
| `go test -race -count=1 -timeout=120s ./...`, desde `go_paralelo` | Código 0, sin carreras reportadas; incluye las pruebas de I6 y resuelve su limitación inicial de CGO. |
| LCG N=2, seed=42, Release: C secuencial, Go paralelo W=1,2,4,8 y C paralelo P=2/T=2 frente a Go secuencial | Seis comparaciones adicionales con código 0 y `max_abs=max_rel=0`; se corrigieron tres valores transcritos en el ejemplo de `docs/equivalencia.md`. |

Las comparaciones Debug y Release cubren `producto2`, `escalar`, `identidad`,
`cero` e `impar3` en las cuatro versiones: 24 comparaciones por configuración,
48 en total contra los resultados esperados, todas con `max_abs=0` y `max_rel=0`
a tolerancia `atol=rtol=1e-9`. Para C paralelo
se comprueban P=1, P>N, reparto no divisible y T=1 o 2; las pruebas Go cubren
W=1,2,4,8, workers mayores que filas, terminación y resultados estables.
Los CSV comprobados tienen una fila por invocación, validación `OK` y tiempos
finitos con `0 <= kernel_s <= total_s`; Go verifica además calentamiento y
repeticiones. `go vet` y las pruebas de ambos módulos Go pasaron en Debug y Release.

La inspección de `main.c` y `matrix.c` confirma `MPI_THREAD_FUNNELED`, las
colectivas llamadas por el hilo inicial y la región OpenMP sobre filas locales.
En `workers.go`, el productor despacha bloques disjuntos, cierra `tasks` y llama
a `wg.Wait()`; cada trabajador escribe su propio tiempo y las filas asignadas.
La validación numérica y la escritura quedan fuera de los intervalos medidos.
Se ajustó `docs/arquitectura.md` al código: máximo de tiempos locales MPI,
límites de `total_s` en Go, fragmento OpenMP esquemático y consumo dinámico de
tareas sin prometer una asignación fija a los primeros N workers.

Los logs locales de esta revisión están en `.cache/sprint-04-cierre/`, ignorado
por Git; los comandos anteriores permiten reproducirlos. La evidencia anterior
de I5 del 22/10 permanece en su reporte y no se confunde con esta reproducción.

### Horas y revisiones cruzadas

Se consolida una distribución de **8 h por integrante y 64 h para el equipo**.
I1, I7 e I8 conservan sus 8 h declaradas. Para I2, I3, I4, I5 e I6 se incorpora
una distribución estimada, reconstruida a solicitud del responsable según las
tareas entregadas; no procede de un registro de tiempo real. Las horas de
revisión asignadas no sustituyen la conformidad pendiente de cada revisor.

| Integrante | Implementación o documentación | Pruebas o análisis | Revisión cruzada | Coordinación | Total | Origen |
| --- | --- | --- | --- | --- | --- | --- |
| I1 · Yessly | 3 h: comunicación MPI y partición | 3 h: P=1, P>N y repartos no divisibles | 1 h: I2 | 1 h: acuerdos de integración C | **8 h** | Declaración individual existente |
| I2 · Sebastian | 3,5 h: núcleo local OpenMP e integración con MPI | 2,5 h: FUNNELED, variables privadas y filas locales | 1 h: I3 | 1 h: interfaces del híbrido con I1 | **8 h** | Estimación reconstruida para el cierre |
| I3 · Giuliano | 4 h: pool de workers, despacho y ajustes de integración | 2 h: cobertura de filas, entradas y estabilidad | 1 h: I4 | 1 h: contrato del núcleo con I4 | **8 h** | Estimación reconstruida para el cierre |
| I4 · Eva | 3,5 h: CLI, archivos, repetición y CSV | 2 h: workers=1, varios workers y workers>filas | 1 h: I5 | 1,5 h: integración Go y coordinación de S4 | **8 h** | Estimación reconstruida para el cierre |
| I5 · Fernando | 2,5 h: pruebas de particionado y conexión con los scripts | 3,5 h: Debug/Release, counts, desplazamientos y reporte | 1 h: I6 | 1 h: integración y evidencia del híbrido | **8 h** | Estimación reconstruida para el cierre |
| I6 · Gerardo | 3 h: batería de concurrencia y organización de pruebas | 3 h: repeticiones, terminación y estabilidad numérica | 1 h: I7 | 1 h: cobertura acordada con I3/I4 | **8 h** | Estimación reconstruida para el cierre |
| I7 · Andrés | 3 h: ejecución y comparación de fixtures | 3 h: discrepancias y reporte de equivalencia | 1 h: I8 | 1 h: acuerdos del equipo | **8 h** | Declaración individual existente |
| I8 · Roberto | 3 h: flujos de datos y sincronización | 3 h: rúbrica, sobrecostes y fallos concurrentes | 1 h: I1 | 1 h: acuerdos de arquitectura | **8 h** | Declaración individual existente |
| **Equipo** | **25,5 h** | **22 h** | **8 h** | **8,5 h** | **64 h** | **24 h declaradas y 40 h estimadas** |

Esta tabla actualiza los pendientes de distribución de horas de los registros
históricos inferiores. Las pruebas de reproducción realizadas para este cierre
se documentan como evidencia general y no se añaden a las horas individuales.

| Revisión prevista | Evidencia disponible | Estado del registro |
| --- | --- | --- |
| I1 → I2 | Registro de I1: FUNNELED, MPI fuera de OpenMP y counts/desplazamientos | Conforme registrado |
| I2 → I3 | No se encontró conformidad personal en el acta ni revisión publicada del PR #29/#32 | Pendiente de I2 |
| I3 → I4 | Registro de I3 y ajustes/pruebas del PR #32 | Conforme registrado |
| I4 → I5 | Registro de I4 y aprobación de Eva en el PR #34 del 22/10/2026 | Conforme registrado |
| I5 → I6 | No se encontró el registro personal de revisión | Pendiente de I5 |
| I6 → I7 | No se encontró el registro personal de revisión; solicitar revisor no equivale a aprobar | Pendiente de I6 |
| I7 → I8 | Registro de I7: revisión de `docs/arquitectura.md` | Conforme registrado |
| I8 → I1 | No se encontró el registro personal de revisión | Pendiente de I8 |

La asignación I1 → I4 mencionada en el registro histórico de Eva no corresponde
al ciclo vigente: I4 es revisada por I3, cuya conformidad ya está documentada.
El registro consolidado de I2 se incluye debajo: su implementación se acredita
por `dd5891d` y su revisión por I1; queda pendiente su revisión personal de I3.

### Decisiones y continuidad hacia S5

- No quedan bloqueos funcionales identificados en la batería de aceptación S4.
  El error MPI `Error (5) Acceso denegado` / código -4 se resolvió al ejecutar
  los mismos scripts fuera del entorno restringido, sin cambiar el algoritmo.
- `validation=passed` en los módulos paralelos representa los casos comprobados
  en S4. La validación integral de errores, límites y estabilidad sigue siendo
  trabajo de [S5](sprint-05.md), que ya puede comenzar.
- `test_equivalencia.ps1` solo ejecuta tres versiones, omite binarios ausentes
  y no agrega los fallos en un código de salida global fiable. Por ello este
  cierre usa `test_windows.ps1`, sus comparaciones explícitas y los tests Go.
  I6 debe incorporar en S5 la cobertura completa y la propagación de fallos;
  I7 debe mantener el alcance de su reporte ligado a las evidencias realmente
  ejecutadas. La coincidencia observada en fixtures no garantiza identidad
  binaria para cualquier matriz, compilador o configuración.
- La campaña y las conclusiones de rendimiento corresponden a S7/S8. Los CSV
  producidos aquí validan funcionamiento y formato; no son mediciones oficiales.
- La distribución de horas queda registrada en la tabla del cierre, con un
  máximo de 8 h por integrante y su origen declarado o estimado. Para completar
  el cierre administrativo, I2/I5/I6/I8 registran sus revisiones pendientes y
  la coordinación I4 consolida esas conformidades.

**Dictamen:** objetivo técnico de S4 cumplido y entregables listos para la
validación integral de S5. El acta conserva pendientes administrativos explícitos
y no declara una aceptación personal unánime que no está documentada.

## Registro individual consolidado · I2 Sebastian · cierre del 28/10/2026

- **Trabajo y trazabilidad:** integración del núcleo OpenMP de filas locales en
  `c_paralelo/src/matrix.c`, commit `dd5891d`, incluido en el PR #33. Las llamadas
  MPI se mantienen fuera de la región OpenMP y se usa `MPI_THREAD_FUNNELED`.
- **Distribución estimada:** 3,5 h de implementación, 2,5 h de verificación,
  1 h asignada a revisión de I3 y 1 h de coordinación con I1: **8 h**. Este
  desglose se reconstruye para el cierre y no acredita horas medidas.
- **Evidencia técnica:** revisión de I1 registrada y pruebas generales Debug y
  Release del híbrido conformes, con nueve comparaciones de fixtures por
  configuración, P=1, P>N y casos no divisibles.
- **Revisión pendiente:** no se encontró una conformidad personal de I2 sobre
  I3; la hora asignada a revisión no se toma como evidencia de su ejecución.

## Registro individual · I3 Giuliano · 19/10/2026

- **Participantes y horas reales:** Giuliano (I3). El plan contempla 3 h de implementación, 3 h de pruebas, 1 h de revisión y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s04-i03-go-paralelo-workers`; [PR #29](https://github.com/GiulianoMaPe/MatricesParalelas/pull/29) integrado en main. La creación de issues sigue pendiente.

- **Pruebas y evidencias:** implementé el núcleo Go paralelo y la distribución de bloques de filas en [workers.go](../../go_paralelo/workers.go), junto con las validaciones en [matrix.go](../../go_paralelo/matrix.go). Añadí pruebas en [matrix_test.go](../../go_paralelo/matrix_test.go) y [workers_core_test.go](../../go_paralelo/workers_core_test.go). Los cinco fixtures compartidos pasaron con 1, 2, 4 y 8 workers. Verifiqué que todas las filas se calculen una vez, que cada bloque respete sus límites y que A/B permanezcan intactas. También pasaron 720 productos repetidos con distintos tamaños y semillas, casos de entradas inválidas, resultados no finitos y llamadas simultáneas. `go test`, `go vet`, `go test -race` y el script `test_windows.ps1` en Debug y Release terminaron con código 0, usando Go 1.27.0 en Windows amd64.

- **Bloqueos y decisiones:** usé un pool acotado, un canal de bloques contiguos y `WaitGroup` para esperar a todos los workers. `Multiply` conserva su firma y `MultiplyParallel` permite elegir la cantidad de workers. Dejé en el [README](../../go_paralelo/README.md) las interfaces y la separación de tiempos. Eva (I4) ya conectó el núcleo con su CLI, integrada en main mediante el [PR #30](https://github.com/GiulianoMaPe/MatricesParalelas/pull/30). Al actualizar mi rama con main corregí restos del merge en `main.go` y `matrix.go` que impedían compilar.

- **Revision y criterio de aceptacion:** revisé la integración de Eva (I4) el 20/10/2026 y completé los ajustes de repetición y cronometraje: cada invocación ejecuta solo la repetición solicitada, emite una cabecera y una fila CSV, y configura `GOMAXPROCS` fuera de `total_s`, registrando su valor efectivo. Verifiqué los cinco fixtures con W=1,2,4,8, el cierre y espera de workers, los errores de entrada y las repeticiones 0 a 5. `go vet`, `go test -race` y los scripts Debug/Release terminaron con código 0, sin carreras reportadas. Mi revisión del ejecutable Go paralelo de I4 queda conforme al Sprint 4 en su estado actual.

#### Integrante 4

- **Participantes y horas reales:** Eva (I4). El plan contempla 3 h de integración de flags/canal/WaitGroup, 3 h de pruebas con workers=1, varios workers y workers>filas, 1 h de revisión cruzada y 1 h de coordinación (8 h total). Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s04-i04-ejecutable-go-paralelo`. La creación de issues y del pull request sigue pendiente.

- **Pruebas y evidencias:** implementé el ejecutable Go paralelo integrado en [main.go](../../go_paralelo/main.go) con parsing completo de flags (`--n`, `--seed`, `--input`, `--output`, `--workers`, `--repetition`, `--smoke-test`), medición separada de `kernel_s` (máximo de tiempos por worker) y `total_s` (incluye vaciado, creación de pool, despacho, `close(tasks)`, `wg.Wait()`), validación numérica contra producto de referencia (tolerancia $10^{-9} + 10^{-9}\cdot|esperado|$) y salida CSV de 20 campos conforme a `docs/protocolo_medicion.md`. Añadí [environment.go](../../go_paralelo/environment.go) y [environment_windows.go](../../go_paralelo/environment_windows.go) para recopilación de metadatos (commit, hostname, CPU, RAM, OS). Completé `matrix.go` con `matrixElementCount()` y moví allí `ErrInvalidDimension`/`ErrSizeOverflow`; agregué `WriteMatrix()` en `input.go`. Verificación ejecutada: workers=1 (equivalente secuencial), workers=2,4,8, workers>filas (N=4, W=8), fixtures compartidos (`producto2`, `escalar`, `identidad`, `cero`, `impar3`), repeticiones con warmup, `go test -race` sin advertencias, `go vet`, `go test` en Debug/Release con código 0 (Go 1.27.0, Windows amd64).

- **Bloqueos y decisiones:** dependí de `multiplyParallelKernel` de I3 (Giuliano) en `workers.go` para la orquestación del pool, canal y `WaitGroup`; mi `main.go` llama a esa función y mide los tiempos. Se usó `runtime.GOMAXPROCS(workers)` por ejecución y se restaura tras `wg.Wait()`. La validación de referencia usa orden de bucles i,j,k (independiente del kernel i,k,j). El CSV usa `configuration=go_paralelo_W{W}`, `version=go_paralelo`, `processes=threads=observed_threads=1`, `gomaxprocs=workers`.

- **Revision y criterio de aceptacion:** el ejecutable compila, acepta todos los flags requeridos, produce CSV válido con `validation_status=OK`, `kernel_s <= total_s`, tiempos finitos con 9 decimales, y pasa el detector de carreras. Casos probados: workers=1, múltiples workers, workers>filas. Queda pendiente revisión cruzada asignada a I1 (Yessly) y aceptación final del equipo.

- **Revisión cruzada a I5 (Fernando) · 22/10/2026:** revisé el [PR #34](https://github.com/GiulianoMaPe/MatricesParalelas/pull/34) (`feature/s04-i05-pruebas-particionado-c`, commit `96e192b`). `partition_test.c` comprueba los ejemplos (a), (b), (g), (h) e (i) de [partition.h](../../c_paralelo/include/partition.h) con los valores esperados del contrato: repartos no divisibles 10/4 y 7/3, procesos sin filas 3/5 y 4/8 y la frontera 46340/46341. Verifica además contigüidad, cobertura y counts/desplazamientos en elementos double (invariantes I2–I8), y el rechazo de N=0, P=0 y punteros nulos sin modificar buffers. La integración en `build_windows.ps1` y `test_windows.ps1` conserva `pending_test.exe` y solo añade `partition_test.exe` para `c_paralelo`. Compilé `partition.c` + `partition_test.c` con GCC 10.3.0 (TDM-GCC) en Debug (`-O0 -g`) y Release (`-O2 -DNDEBUG`) con `-std=c11 -Wall -Wextra -Werror -pedantic`; ambos ejecutables terminaron con código 0, sin advertencias adicionales con `-Wconversion -Wsign-conversion -Wshadow`. Para comprobar que la prueba detecta errores reales, inyecté cuatro fallos en `partition.c` (resto asignado con `<=`, límite `N >= 46340`, escritura en buffers antes de validar y desplazamientos en filas en lugar de elementos): la prueba falló en los cuatro casos. No reproduje la batería MPI/OpenMP con MSVC/MS-MPI porque mi equipo no tiene Windows SDK ni MS-MPI instalados; para esa parte me apoyo en la evidencia Debug/Release del [reporte de particionado C](../../c_paralelo/tests/reporte_particionado.md). Resolví el conflicto de este registro con main conservando la sección actualizada de I1 y la de I5. Revisión conforme para el alcance de I5.

## Registro individual · I6 Gerardo · 20/10/2026 · avance

- **Participantes y horas reales:** Gerardo (I6). La asignación estima 3 h de pruebas, 3 h de verificación, 1 h de revisión y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** pendientes de registrar.

- **Pruebas y evidencias:** organicé en [workers_test.go](../../go_paralelo/workers_test.go) las pruebas asignadas a I6: diez repeticiones por combinación de seis tamaños, tres semillas y cuatro cantidades de workers (720 productos comparados con una referencia secuencial); cobertura numérica de filas con 1, 2, 4, 8 y 32 workers para detectar trabajo perdido o acumulación duplicada; y ocho llamadas concurrentes con tamaños de pool distintos. La prueba concurrente comprueba terminación en un máximo de 10 s, estabilidad de los resultados, almacenamiento de salida independiente y que A/B no se modifiquen. `go test ./...` pasó en Windows. `go test -race ./...` no se pudo ejecutar porque CGO no está habilitado en el entorno (`-race requires cgo`). La prueba de instalación se conserva y repite el smoke test diez veces.

- **Bloqueos y decisiones:** el detector de carreras queda pendiente hasta disponer de CGO habilitado y un compilador C compatible. No se duplicaron las pruebas: se trasladaron desde [workers_core_test.go](../../go_paralelo/workers_core_test.go) a la ubicación del entregable de I6.

- **Revision y criterio de aceptacion:** el avance cubre repetición, tamaños variados, resultados estables, terminación y detección numérica de trabajo perdido o duplicado. Revisión cruzada por I7, horas reales, coordinación y cierre formal pendientes.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h documentación técnica de flujos de datos y sincronización de C híbrido MPI+OpenMP y Go concurrente CSP, 3 h mapeo a la rúbrica del curso, análisis de sobrecostes y prevención de fallos concurrentes, 1 h coordinación de acuerdos, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s04-i08-arquitectura-paralela`.
- Pruebas y evidencias: Entregable `docs/arquitectura.md` completado y actualizado como documento maestro de ambos paralelos. Incluye análisis de particionado 1D (`partition.h`, algoritmos de cociente y resto, soporte de $P > N$, límite $N \le 46340$), comunicación colectiva MPI (`Bcast`, `Scatterv`, `Gatherv`), multihilo OpenMP (`MPI_THREAD_FUNNELED`, variables privadas de bucle), modelo CSP de Go (`chan Task`, `sync.WaitGroup`, pool acotado, inmutabilidad y ausencia de data races con `go test -race`), diagramas de secuencia Mermaid y matriz de invariantes globales.
- Bloqueos y decisiones: Se unificó el criterio de cronometraje para que `kernel_s` aísle el cómputo puro del sobrecoste de comunicación en MPI y despacho en canales de Go, alineado con el protocolo de medición.
- Revision y criterio de aceptacion: Entregable de I8 finalizado; listo para revisión formal por Integrante 7 (Andrés). Revisión cruzada a I1 Yessly pendiente a la publicación de su PR de comunicación MPI.

## Registro individual - I1 Yessly - 20/10/2026

- **Participantes y horas reales:** Yessly (I1). El plan contempla 3 h de implementacion, 3 h de pruebas, 1 h de revision y 1 h de coordinacion. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s04-i01-mpi-scatterv-gatherv`. La creacion de issues y del pull request queda pendiente.

- **Pruebas y evidencias:** se implementaron `c_paralelo/src/partition.c` y el flujo MPI de `c_paralelo/src/main.c` (Bcast de B, Scatterv de A, Gatherv de C, validacion en el rango 0, CSV de 20 columnas y CLI). Se implemento tambien el nucleo local de `c_paralelo/src/matrix.c` como dependencia de integracion y se ampliaron `c_paralelo/tests/pending_test.c` y los scripts `run_hybrid_windows.ps1`/`test_windows.ps1`. La verificacion aritmetica del reparto (`scripts/verify_partition_design.ps1`) pasa: 8 ejemplos, 4480 pares N/P y fronteras 46340/46341. Las pruebas de runtime quedan pendientes porque el equipo de trabajo no tiene instalados MSVC, Windows SDK ni MS-MPI.

- **Bloqueos y decisiones:** `status.json` queda con `algorithm=implemented` y `validation=pending`. Se fijo `N <= 46340` para respetar los `count`/desplazamientos `int` de MPI y se exige `OMP_NUM_THREADS` positivo con `OMP_DYNAMIC=FALSE`. La revision formal de FUNNELED, variables privadas y ausencia de MPI en la region OpenMP corresponde a I2 (Sebastian).

- **Revision y criterio de aceptacion:** el reparto y la comunicacion cumplen el diseno de `partition.h` y las pruebas de particion pasan; falta compilar y ejecutar en un entorno con MSVC y MS-MPI para aceptar el entregable. La revision de I1 corresponde a I8 (Roberto) y la coordinacion de S4 a I4 (Eva). Queda pendiente tambien la revision de Giuliano (I3) por Sebastian (I2).

## Registro individual · I7 Andrés · 21/10/2026

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h ejecución y comparación exhaustiva de salidas en los 5 fixtures con las referencias y paralelos; 3 h investigación de discrepancias, punto flotante y redacción del reporte técnico `docs/equivalencia.md`; 1 h revisión cruzada formal a Roberto I8 sobre `docs/arquitectura.md`; 1 h coordinación de acuerdos del equipo).
- **Issues y pull requests:** rama de trabajo `feature/s04-i07-reporte-equivalencia`. Pull request listo para apertura.
- **Entregable principal:** [`docs/equivalencia.md`](../equivalencia.md) (Reporte de equivalencia de cuatro versiones).
- **Pruebas y evidencias:**
  - Se verificó celda por celda la equivalencia numérica entre `c_secuencial`, `go_secuencial` y `go_paralelo` ($W \in \{1, 2, 4, 8\}$ workers) frente a los 5 fixtures oficiales (`escalar`, `identidad`, `cero`, `producto2`, `impar3`) usando [`scripts/compare_results.ps1`](../../scripts/compare_results.ps1).
  - En todas las pruebas se obtuvo $max\_abs = 0.0$ y $max\_rel = 0.0$ con código de salida 0, satisfaciendo holgadamente la tolerancia acordada ($atol=10^{-9}, rtol=10^{-9}$).
  - Se evaluaron escenarios de sobre-concurrencia ($W=4, 8$ con $N=1, 2$) y particionado no divisible ($N=3$ con 2, 4 y 8 workers), confirmando que no se presentan carreras de datos, corrupciones ni desbordamientos de buffer.
  - Se contrastó el cálculo con el generador LCG ($N=2, \text{semilla}=42$), verificando idéntica salida de matrices ($A, B, C$) y cabecera/filas CSV conformes con `validation_status = OK`.
- **Bloqueos y decisiones:** Se determinó formalmente que la coincidencia exacta binaria ($max\_abs=0$) es consecuencia de la descomposición 1D por filas puras y del orden uniforme de acumulación secuencial sobre el índice interno $k$ (sin reducción paralela en $k$), asegurando que cada celda tenga un único escritor.
- **Revisión a I8 (Roberto):** Revisé exhaustivamente [`docs/arquitectura.md`](../arquitectura.md). La fundamentación de los paradigmas híbrido (MPI+OpenMP) y CSP (goroutines, canales, WaitGroup) es matemáticamente sólida y exhaustiva. Los invariantes de particionado $I1-I6$ en `partition.h`, el tratamiento de $P > N$, el orden canónico $i \to k \to j$ y la delimitación estricta de cronometraje entre `kernel_s` y `total_s` se alinean a la perfección con la rúbrica y el protocolo de medición. El entregable de I8 queda **CONFORME**.
- **Revisión y criterio de aceptación:** Mi entregable técnico (`docs/equivalencia.md`), las evidencias experimentales y la revisión cruzada quedan completadas y conformes al Sprint 4.

#### Integrante 1
- **Rama / PR:** `feature/s04-i01-comunicacion-mpi`
- **Horas declaradas:** 8 h (3 h comunicación/partición, 3 h pruebas P=1,2,4, P>N, no divisibles, 1 h revisión I2, 1 h coordinación)
- **Evidencia de ejecución:**  
  - `check_env_windows.ps1`: Entorno completo validado (MSVC, MS-MPI Runtime v10.1, Go 1.27.3).  
  - `build_windows.ps1 -Version all`: Compilación exitosa de las 4 versiones.  
  - `test_windows.ps1 -Version all` y `run_hybrid_windows.ps1`: Pasados con éxito.  
  - Validaciones de comunicación MPI: Ejecuciones con `mpiexec` (-n 1, -n 2, -n 4) en fixtures, caso $P > N$ ($N=3, P=8$) y no divisibles ($N=7, P=3$ y $N=33, P=4$) con coincidencia $10^{-9}$ celda a celda respecto a `c_secuencial`.
- **Revisión cruzada a I2:** Código de Sebastián validado. Llamadas MPI fuera de regiones OpenMP, uso de `MPI_THREAD_FUNNELED` y cálculo de desplazamientos/counts correcto en elementos double.

#### Integrante 5 (Fernando)

- **Trabajo y pruebas:** preparé `c_paralelo/tests/partition_test.c` para comprobar repartos no divisibles (`N=10/P=4`, `N=7/P=3`), procesos sin filas (`N=3/P=5`, `N=4/P=8`), el límite válido `N=46340`, el inválido `N=46341` y argumentos inválidos. Comprueba `rows`, `first_rows`, `counts`, `displacements`, continuidad y cobertura; ante entradas inválidas, verifica que los buffers no cambien.
- **Integración:** añadí `partition_test.exe` como prueba separada a `scripts/build_windows.ps1` y `scripts/test_windows.ps1` para `c_paralelo`; `pending_test.exe` se mantiene y sigue ejecutándose sin reemplazos. La prueba unitaria dedicada compila `partition.c` junto con `partition_test.c`.
- **Evidencia inicial:** `partition.c` + `partition_test.c` se compilaron y ejecutaron con GCC en Debug (`-O0 -g`) y Release (`-O2 -DNDEBUG`), con `-std=c11 -Wall -Wextra -Werror -pedantic`; ambos ejecutables terminaron con código 0. Esta evidencia se amplía con la validación oficial siguiente.
- **Validación oficial · 22/10/2026:** sobre el commit `3151e4be0b57f57f53ee695f9cded51420661e98`, `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_windows.ps1 -Version c_paralelo -Configuration Debug` y el mismo comando con `-Configuration Release` terminaron con código **0**, usando MSVC x64 19.51.36257.0, Windows SDK 10.0.26100.0 y MS-MPI Runtime 10.1.12498.52. Pasaron `pending_test.exe` (ocho ejemplos, 4480 pares N/P y núcleo local), `partition_test.exe`, el smoke test con dos procesos/dos hilos y `MPI_THREAD_FUNNELED`, los cinco fixtures en nueve configuraciones por compilación (incluidos P=1, P>N y reparto impar no divisible) y la comprobación automática del CSV. Las 18 comparaciones de matrices dieron `max_abs=0` y `max_rel=0`. También pasó `verify_partition_design.ps1` con código 0. El detalle, los comandos y la matriz de casos están en el [reporte de particionado C](../../c_paralelo/tests/reporte_particionado.md).
- **Bloqueo resuelto:** MSVC y MS-MPI ya están instalados. El intento dentro del entorno restringido fallaba al iniciar el binario mediante `mpiexec` con `Error (5) Acceso denegado` (código -4); las baterías completas pasaron al ejecutarse fuera de ese entorno, sin cambiar código ni permisos de archivos. La falta de herramientas registrada inicialmente deja de ser un bloqueo actual.
- **Revisión y aceptación:** validación técnica Debug/Release completada para el alcance de I5. Sigue pendiente la revisión cruzada de Eva (I4) a Fernando (I5), así como registrar la revisión de Fernando a Gerardo (I6), las horas reales y los enlaces de issue/PR. La aceptación final del equipo y el cierre del Sprint 4 continúan pendientes.
