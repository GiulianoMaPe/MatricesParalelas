# Bibliografía verificada y decisiones de diseño

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)

**Responsable:** Integrante 8 · Roberto · Sprint 2

**Actualización:** 2026-10-01, preparada con asistencia de Codex a solicitud de I8.

**Estado:** Contenido técnico conforme. La evaluación asistida de esta versión, en la voz de Andrés (I7), está registrada en [Sprint 2](sprints/sprint-02.md).

## 1. Alcance y fuentes

Se revisaron los dos PDF conservados en `docs/referencias/`. Las páginas citadas abajo son las posiciones del PDF local, contando la primera como página 1. Pueden diferir de la paginación de las actas publicadas.

Los metadatos de publicación se contrastaron el 2026-10-01 con fuentes de los autores: [publicación alojada en University College Dublin](https://hcl.ucd.ie/system/files/06687414.pdf), [lista de publicaciones de Thomas Hérault](https://icl.utk.edu/~herault/) y [registro institucional de Inria, entrada 19](https://rex-radar.inria.fr/report/2019/roma/bibliography.html). Se corrigieron el DOI de Quintin y el DOI y las páginas de Hérault.

La literatura proporciona hallazgos sobre comunicación y reutilización de datos. La elección de filas, MPI/OpenMP y workers es una adaptación propia al contrato del proyecto. Las mejoras de rendimiento se comprobarán durante las campañas; este documento no presenta resultados experimentales del equipo.

## 2. Resumen de los candidatos

### 2.1. Quintin, Hasanov y Lastovetsky: HSUMMA

**Referencia [1]:** “Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms”, ICPP 2013, pp. 754–762. DOI: [10.1109/ICPP.2013.89](https://doi.org/10.1109/ICPP.2013.89).

**PDF local:** [Hierarchical Parallel Matrix Multiplication…](referencias/Hierarchical%20Parallel%20Matrix%20Multiplication%20on%20Large-Scale%20Distributed%20Memory%20Platforms.pdf).

El trabajo reorganiza las comunicaciones de SUMMA mediante una jerarquía virtual de dos niveles sobre una malla bidimensional de procesos. Se difunden bloques entre grupos y después dentro de cada grupo. Los autores modelan costes de latencia y transferencia y evalúan el efecto de la agrupación en Grid5000 y BlueGene/P. El algoritmo es una organización de comunicación a nivel de aplicación, independiente de una correspondencia fija entre grupos y hardware.

**Ubicación verificable:** resumen e introducción, p. 1; sección II.C, pp. 2–3; algoritmo 1 y análisis de costes, pp. 4–6; evaluación, sección IV, pp. 7–8.

**Límite de la adaptación:** los dos niveles de HSUMMA no equivalen automáticamente a procesos MPI y hilos OpenMP. Nuestro reparto 1D no implementa HSUMMA. Tomamos como motivación estudiar cómo la comunicación afecta al tiempo total.

### 2.2. Hérault, Robert, Bosilca y Dongarra: producto sobre PaRSEC

**Referencia [2]:** “Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC”, ScalA 2019, pp. 33–41. DOI: [10.1109/ScalA49573.2019.00010](https://doi.org/10.1109/ScalA49573.2019.00010).

**PDF local:** [Generic Matrix Multiplication…](referencias/Generic%20Matrix%20Multiplication%20for%20Multi-GPU%20Accelerated%20Distributed-Memory%20Platforms%20over%20PaRSEC.pdf).

El artículo desarrolla un producto matricial para plataformas distribuidas con varias GPU por nodo, incluso cuando las matrices exceden la memoria de los aceleradores. Organiza teselas de C en bloques, divide el cálculo en fragmentos y controla dependencias y anticipación de transferencias mediante PaRSEC. Estas decisiones equilibran reutilización de datos, memoria y comunicación; pueden volver a transmitir datos para controlar el conjunto activo. A y B se usan como entradas de lectura y cada proceso actualiza las teselas de C que le corresponden.

**Ubicación verificable:** resumen e introducción, p. 1; sección II y algoritmos 1–2, pp. 1–3; análisis de comunicación, sección III, pp. 3–4; implementación, sección IV, pp. 4–5; evaluación y conclusiones, pp. 5–8.

**Límite de la adaptación:** este proyecto trabaja con CPU, sin GPU ni PaRSEC. La propiedad de filas y el recorrido contiguo son decisiones del equipo inspiradas en esos principios; el artículo no mide nuestro pool Go ni demuestra equivalencia de rendimiento con OpenMP.

## 3. Selección y relación con el proyecto

Se mantiene [1] como referencia principal para discutir costes de comunicación y [2] como complemento sobre reutilización, memoria y dependencias. El propósito es fundamentar preguntas y decisiones verificables dentro del alcance de la guía.

| Tema | Hallazgo de la fuente | Adaptación propia | Cómo se verificará |
| --- | --- | --- | --- |
| Comunicación | [1], II.C y III: jerarquía virtual y análisis de costes. | Comparar combinaciones P×T con igual presupuesto y separar cálculo de trabajo total. | Protocolo y campaña S7/S8. |
| Reutilización y memoria | [2], II–III: teselas, bloques y control del conjunto activo. | Almacenamiento por filas, recorrido i,k,j y estimación de matrices completas y locales. | Revisión de código y mediciones posteriores. |
| Propiedad del resultado | [2], II: cada proceso actualiza sus teselas de C. | Un trabajador escribe cada fila; A/B se comparten para lectura. | Diseño de S2; pruebas de cálculo y carreras en S4/S5. |

## 4. Decisiones propuestas para implementar

### 4.1. Reparto 1D por bloques de filas

Se eligen filas porque cada bloque es un segmento contiguo en la representación `i*N+j`. Esto facilita definir `counts` y desplazamientos en elementos `double`, y emplear `MPI_Scatterv`/`MPI_Gatherv`. El diseño está en `c_paralelo/include/partition.h`:

```text
q = N / P; r = N % P
filas[p] = q + (p < r ? 1 : 0)
primera[p] = p*q + min(p, r)
counts[p] = filas[p]*N
displs[p] = primera[p]*N
```

Es una simplificación propia para el curso. Las distribuciones 2D son alternativas válidas y pueden emplear almacenamiento local empaquetado o tipos MPI. No se afirma que 1D sea siempre más rápido ni se atribuye esa conclusión a [1]. La implementación del reparto corresponde a S4.

### 4.2. Difusión de B y memoria

Cada proceso necesita B completa para calcular su bloque de filas: se propone difundir B antes del cálculo. Una matriz ocupa `8*N*N` bytes; para N=512/1024/2048 son 2/8/32 MiB. Con P=4 y N=2048, las cuatro copias de B suman 128 MiB, sin contar A, C, bloques locales, referencia de validación y runtime. La viabilidad depende de la memoria disponible de cada PC; la estimación completa está en `docs/protocolo_medicion.md`.

Esta elección simplifica el flujo de datos. Su coste se incluirá en `total_s`; no se presupone un ancho de banda local ni una superioridad de rendimiento sin medirlos.

### 4.3. Orden i,k,j

El contrato comienza con el mismo orden en las cuatro versiones. En el bucle interno j, B y C se recorren con paso unitario; el acceso a A[i,k] se reutiliza durante esa fila de B. Esta explicación se deriva de la disposición por filas y es una decisión del proyecto. No garantiza un porcentaje de aprovechamiento de caché ni que el compilador mantenga un valor en un registro.

C se vacía antes de acumular. Según el protocolo común, ese vaciado pertenece a `total_s`; `kernel_s` registra el cálculo acordado. Los multiplicadores se implementarán en S3/S4.

### 4.4. MPI y OpenMP

El diseño requerido por la guía combina procesos MPI y cálculo local con `parallel for schedule(static)`. Cada proceso llama a MPI desde su hilo inicial, fuera de OpenMP, y comprueba `MPI_THREAD_FUNNELED`. Las filas locales tienen un único escritor. El reparto estático no garantiza por sí solo afinidad de CPU/caché ni ausencia de costes de sincronización.

El smoke test actual verifica el arranque de MPI/OpenMP. El flujo Bcast/Scatterv/cálculo/Gatherv todavía es una tarea de S4.

### 4.5. Workers Go

Se propone un pool acotado que recibe intervalos `[inicio, fin)` por un canal; el productor cierra el canal después de enviar las tareas y espera con `WaitGroup`. Cada fila de C pertenece a un trabajador y A/B son de solo lectura. Estos invariantes evitan escrituras simultáneas sobre las mismas celdas si se cumplen en la implementación.

La ausencia de carreras se comprobará con pruebas reales y `go test -race`. La eficiencia frente a OpenMP se evaluará experimentalmente. El pool de cálculo corresponde a S4; el código de instalación no valida todavía esa arquitectura matemática.

## 5. Referencias IEEE verificadas

[1] J.-N. Quintin, K. Hasanov y A. Lastovetsky, “Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms”, en *2013 42nd International Conference on Parallel Processing (ICPP)*, Lyon, Francia, 2013, pp. 754–762, doi: [10.1109/ICPP.2013.89](https://doi.org/10.1109/ICPP.2013.89).

[2] T. Hérault, Y. Robert, G. Bosilca y J. Dongarra, “Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC”, en *2019 IEEE/ACM 10th Workshop on Latest Advances in Scalable Algorithms for Large-Scale Systems (ScalA)*, Denver, EE. UU., 2019, pp. 33–41, doi: [10.1109/ScalA49573.2019.00010](https://doi.org/10.1109/ScalA49573.2019.00010).

Solo estas dos referencias se usan para los resúmenes anteriores. Las fuentes complementarias identificadas en `docs/requisitos.md` tienen su verificación pendiente y no fundamentan afirmaciones de este documento.

## 6. Evidencia y aceptación

- [x] Dos artículos resumidos con ubicación en los PDF locales.
- [x] Una referencia principal seleccionada y una complementaria.
- [x] Hallazgos separados de decisiones e hipótesis del proyecto.
- [x] Metadatos corregidos con fuentes de los autores e instituciones.
- [x] Reparto por filas justificado por el contrato y la representación contigua.
- [x] Aprobación de la versión anterior por I7 conservada en `docs/sprints/sprint-02.md`.
- [x] Evaluación asistida de esta actualización, en la voz de I7, conforme y registrada en el sprint.

Las evaluaciones de I7 a I8 y de I8 a I1 están registradas en [Sprint 2](sprints/sprint-02.md). El cierre reúne la evidencia y conserva las horas declaradas anteriormente por ambos integrantes.
