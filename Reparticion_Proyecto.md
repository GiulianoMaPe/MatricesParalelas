# Canva 2 — Avance del proyecto "Multiplicación de matrices en paralelo"
**Sprints 1, 2 y 3** · Repositorio: github.com/GiulianoMaPe/MatricesParalelas

> Exponen los **8 integrantes**; cada uno explica lo que hizo en los sprints 1 a 3.
> El orden sigue el hilo del proyecto: introducción → requisitos y literatura → contrato de datos y casos de prueba → código (C secuencial, C paralelo, Go paralelo) → medición y cierre.
> Los integrantes **5, 6, 7 y 8** también exponen el Canva del libro, así que sus partes son más cortas.
> Tiempos sugeridos, ajustables: total ≈ 21 min.
> Fuentes: registros de `docs/sprints/sprint-01.md` a `sprint-03.md`, README, `docs/validacion_secuencial.md`, contrato, protocolo, código y pruebas presentes en `main`.

---

## Estado confirmado y verificaciones para exponer

1. **PR de S3:** según el estado actualizado de `main` y lo confirmado por el equipo, las entregas de S3 están integradas. La guía toma sus detalles de los entregables y registros locales, no de descripciones de PR pendientes.
2. **Registros de S3:** `docs/sprints/sprint-03.md` ya contiene las entregas de los integrantes 4 a 8 y `docs/validacion_secuencial.md` documenta la auditoría de las referencias. La ruta `docs/plan_generador_go.md` citada en el registro de I7 no existe en este checkout; para el generador, usen `go_secuencial/input.go`, sus pruebas y `docs/contrato.md`.
3. **Integrantes 5 y 6:** sus entregables de S3 sí están documentados: el comparador y sus pruebas (I5), y los vectores de control del generador C/Go (I6). Usen las diapositivas actualizadas abajo.
4. **README principal:** C y Go secuenciales tienen núcleo, CLI, validación y métricas integrados. C paralelo y Go paralelo siguen en desarrollo; la integración secuencial no equivale a las campañas oficiales de rendimiento.
5. **Pruebas secuenciales:** `docs/validacion_secuencial.md` registra las pruebas del núcleo C y las referencias C/Go. Las ejecuciones de Sprint 3 validan los cinco fixtures en ambas versiones secuenciales; pueden usar esa evidencia al preparar capturas.
6. **Integración de C secuencial:** `c_secuencial/src/main.c` conecta `matrix_multiply_validate`, `matrix_clear` y `matrix_accumulate`, acepta generación o archivos de entrada/salida, valida el resultado y emite `kernel_s`/`total_s` en el CSV. El runner pasó en Debug y Release.
7. **Mediciones:** el protocolo describe el diseño, pero no hay resultados experimentales en `resultados/`. No muestren tiempos ni speedups.
8. **Horas y revisiones:** los registros dicen que las revisiones de S1 y S2 son evaluaciones asistidas y que varias horas son estimadas. Si preguntan, respondan eso.
9. **Comparación de generadores:** las pruebas de C y Go comparten vectores de control N=2 para `seed=42`, `seed=0` y `seed=UINT32_MAX`. No presenten una campaña comparativa amplia para otras dimensiones y semillas como concluida.

---

## Reparto y orden

| Orden | Integrante | Lo que expone | Diapositivas | Tiempo |
|---|---|---|---|---|
| 1 | **3** | Introducción, organización y Go secuencial | 1–4 | 4 min |
| 2 | **8** | Requisitos, bibliografía y validación secuencial | 5–6 | 2,5 min |
| 3 | **6** | Formato y contrato de datos | 7 | 1,5 min |
| 4 | **5** | Casos de referencia (fixtures) | 8 | 1,5 min |
| 5 | **1** | C secuencial | 9–10 | 3 min |
| 6 | **2** | C paralelo | 11–12 | 3–4 min |
| 7 | **4** | Go paralelo y Go secuencial integrado | 13–14 | 3 min |
| 8 | **7** | Protocolo de medición, generador Go, estado y hoja de ruta (cierre) | 15–17 | 2,5 min |

---

## Integrante 3 — Introducción y Go secuencial

**Diapositiva 1 · Portada y objetivo**
- Título del proyecto, materia, equipo (8 integrantes), fecha.
- Objetivo: multiplicar matrices cuadradas en 4 versiones y compararlas con mediciones reproducibles.
- Las 4 versiones: C secuencial, C paralelo (MS-MPI + OpenMP), Go secuencial, Go paralelo (goroutines y canales).
- Entorno: Windows 11, MSVC x64, Go; automatización con scripts PowerShell.

**Diapositiva 2 · Cómo trabajamos**
- 10 sprints, 8 integrantes, 640 horas de equipo (8 h por persona y sprint: 2 tareas de 3 h, 1 h de revisión, 1 h de coordinación).
- Rama por tarea (`feature/sNN-iNN-...`), pull request con plantilla y revisión cruzada en anillo (1 revisa a 2, 2 a 3, … 8 a 1).
- Coordinador rotativo por sprint; cada tarea con objetivo, entregable y criterio de aceptación.
- Resultado esperado: S1 diagnóstico y requisitos · S2 interfaces y casos de prueba · S3 referencias secuenciales correctas.
- Regla del equipo: una prueba de instalación no valida un algoritmo; no se aceptan tiempos con salidas matemáticas incorrectas.
- Capturas sugeridas: árbol del repo (`c_secuencial/`, `c_paralelo/`, `go_secuencial/`, `go_paralelo/`, `tests/fixtures/`, `scripts/`, `docs/`), plantilla de PR, lista de PR cerrados.

**Diapositiva 3 · Go secuencial: S1 y S2**
- S1 (`docs/diagnostico_go_secuencial.md`): el generador y el lector existían; multiplicación y argumentos, pendientes.
- S2 (`go_secuencial/matrix.go`): contrato de errores y argumentos equivalente al de C.
- Corregí los errores de tamaño de `Generate` y cinco pruebas que fallaban.
- Acuerdo C/Go documentado junto con el integrante 1; integrado en el PR #18.
- `test_windows.ps1 -Version go_secuencial` termina con código 0.

**Diapositiva 4 · Go secuencial: S3**
- Núcleo de multiplicación y pruebas (rama `feature/s03-i03-go-secuencial-multiplicacion-y-pruebas`).
- Verificación (según el informe de validación del integrante 8): pruebas unitarias y los 5 fixtures compartidos pasan con tolerancia 1e-9.
- La multiplicación usa el mismo orden i, k, j que C para que ambas referencias sean comparables.
- Completar con detalles propios de tu código (nombre de funciones, errores que devuelve).

---

## Integrante 8 — Requisitos, bibliografía y validación secuencial

**Diapositiva 5 · Requisitos y bibliografía (S1 y S2)**
- `docs/requisitos.md`: criterios académicos convertidos en entregables verificables, requisitos funcionales y no funcionales, backlog priorizado.
- `docs/bibliografia.md`: dos artículos IEEE analizados (Quintin et al., 2013; Hérault et al., 2019).
- Decisión de diseño: **reparto 1D por bloques de filas** por su continuidad y simplicidad; la variante jerárquica de Hérault usa una malla 2D y no equivale a nuestra combinación MPI/OpenMP.
- Se separa lo que dicen los artículos de lo que decidió el equipo.

**Diapositiva 6 · Validación secuencial (S3, PR #20)**
- `docs/validacion_secuencial.md`: auditoría de las referencias secuenciales de C y Go.
- Matriz de regresión de 8 escenarios (REG-01 a REG-08): escalares, identidad, matriz nula, dimensiones impares, generador determinista y prevención de aliasing destructivo.
- Resultado: el núcleo de C (producto 2×2 = 19 22 / 43 50) y el de Go pasan sus pruebas.
- Esta validación se explica mejor después de ver el código; di "lo retomamos al ver C secuencial y Go secuencial".

---

## Integrante 6 — Formato y contrato de datos

**Diapositiva 7 · Un formato común para las 4 versiones**
- S1: matriz de diferencias entre C y Go (dimensiones, semilla, formato y errores), en `docs/formato_datos.md`.
- S2: formato definitivo: N en línea propia, N filas de A y N de B, exactamente N valores por fila; acepta LF/CRLF; rechaza BOM, NUL, CR aislado, filas fusionadas y valores no finitos.
- Generador determinista con semilla y vectores de control que C y Go deben reproducir.
- 22 casos de gramática por lector, con resultados equivalentes en C y Go.
- Códigos de salida (`docs/contrato.md`): 0 éxito, 1 error, 2 solo operación pendiente.
- S3: I6 verificó el generador C existente y añadió vectores de N=2 para `seed=0` y `seed=UINT32_MAX`; añadió los mismos vectores a las pruebas Go. El generador conserva un estado LCG y genera B después de A sin reiniciar la semilla.

---

## Integrante 5 — Casos de referencia (fixtures)

**Diapositiva 8 · Fixtures y criterio de comparación**
- S1: resolví a mano los 4 casos recibidos (producto 2×2, escalar negativo, identidad, matriz cero); no fue necesario corregir valores. Cálculos en `tests/fixtures/README.md`.
- S2: añadí el caso 3×3 impar (`impar3`) con ceros y negativos; son 5 casos en total.
- Criterio de comparación: `atol = 1e-9`, `rtol = 1e-9`, celda por celda, rechazo de NaN e infinitos.
- Idea clave: un tiempo solo vale si la salida matemática es correcta.
- S3: I5 implementó `scripts/compare_results.ps1` y `tests/compare_results_test.ps1`. Valida el formato de ambas matrices, compara todas las celdas con `atol = rtol = 1e-9`, reporta la primera diferencia y los errores máximos. El runner de Sprint 3 comparó los cinco fixtures con las salidas de C y Go; todos pasaron con `max_abs=0` y `max_rel=0`.

---

## Integrante 1 — C secuencial

**Diapositiva 9 · C secuencial: S1 y S2**
- S1 (`docs/diagnostico_c_secuencial.md`): diagnóstico con 8 secciones, adoptado como formato común por el equipo. Al inicio compilaba y respondía a `--smoke-test`, pero no multiplicaba ni aceptaba `--n/--seed`. Detectó una inconsistencia entre `contrato.md` y `requisitos.md` sobre el código de salida 1.
- S2 (`c_secuencial/include/matrix.h`): reglas de memoria, validación de N, reserva y liberación de buffers.
- Pruebas con tamaños inválidos, datos incompletos, NaN e infinitos; Debug y Release con código 0.
- Acuerdo C/Go documentado en `docs/especificaciones_c_go_secuencial.md`.

**Diapositiva 10 · C secuencial: S3 (PR #19)**
- Núcleo con orden **i → k → j** sobre almacenamiento contiguo por filas.
- Tres funciones separadas: validar (no escribe), vaciar C y acumular. Así se puede cronometrar `total_s` (vaciado + acumulación) y `kernel_s` (solo acumulación).
- Pruebas nuevas (`matrix_kernel_test.c`): producto 2×2 conocido (19 22 / 43 50), escalar, identidad, cero, 3×3 impar, A y B intactas, argumentos inválidos, NaN y desbordamiento.
- Revisión cruzada: el integrante 8 detectó una comprobación residual en `pending_test.c` y se corrigió.
- Integración de S3: `c_secuencial/src/main.c` conecta el núcleo con la CLI, la validación del resultado y el CSV de métricas. El runner general pasó en Debug y Release, incluidos los cinco fixtures.

---

## Integrante 2 — C paralelo

**Diapositiva 11 · C paralelo: S1 y S2**
- S1 (`docs/diagnostico_c_paralelo.md`): el generador y el lector funcionan. La prueba de 2 procesos × 2 hilos es de **instalación**, no valida el algoritmo. Faltaban reparto, multiplicación y parametrizar P y T.
- S2 (`c_paralelo/include/partition.h`): reparto 1D por bloques de filas con cociente y resto, `primera[i] = i·q + min(i, r)`.
- Invariantes I1–I8 (suma de filas = N, bloques contiguos, suma de `counts` = N·N, etc.).
- `counts` y desplazamientos en elementos `double`; límite N·N ≤ INT_MAX (N ≤ 46340).
- Casos con **más procesos que filas** resueltos (N=3, P=5 y N=4, P=8).
- Verificación aritmética: 4480 pares (N, P) sin fallos.
- Esquema de uso previsto: `MPI_Bcast`, `MPI_Scatterv`, `parallel for`, `MPI_Gatherv`.
- Aclaración honesta: el reparto está **diseñado**; la implementación es del Sprint 4.

**Diapositiva 12 · Argumentos y temporizador: S3 (PR #21)**
- `main.c` interpreta y valida `--n` y `--seed`: faltantes, desconocidos, duplicados, mal formados, fuera de rango, desbordamiento de n·n y fallos de memoria.
- Reserva A, B y C y libera la memoria en cada ruta de salida; conserva los códigos 0, 1 y 2.
- `timer.c` con `QueryPerformanceCounter`; `--smoke-test` comprueba que el reloj avanza de forma monótona.
- Generación y validación quedan fuera de los cronómetros.
- Estado de C secuencial: el flujo principal ya calcula el producto, valida su salida y emite `kernel_s` y `total_s`; el runner pasó en Debug y Release. Esta actualización describe el cierre técnico del Sprint 3, sin atribuir ni modificar avances individuales.

---

## Integrante 4 — Go paralelo

**Diapositiva 13 · Go paralelo: S1 y S2**
- S1 (`docs/diagnostico_go_paralelo.md`): solo funcionaba la prueba de sincronización (goroutines, canal y `WaitGroup`). Riesgos de sincronización identificados; `go test -race` sin detecciones en la base.
- S2 (`docs/arquitectura.md`): bloques de filas, canal de tareas, **propiedad de filas** (nadie escribe en filas ajenas), cierre del canal y espera sin bloqueos ni escritura compartida.
- Definición de tiempos: cálculo acumulado por worker y máximo entre workers.
- Implementación de los workers: Sprint 4.

**Diapositiva 14 · Go secuencial integrado: S3 (PR #22)**
- Ejecutable de Go secuencial con argumentos de línea de comandos, multiplicación i, k, j, temporizador y salida CSV.
- Conecta el núcleo y el generador de Go con el flujo completo del programa.
- El registro de S3 confirma `--n/--seed`, `--input/--output`, lectura/escritura, producto, timer y CSV de 20 campos. Las salidas Go de los cinco fixtures se compararon con los resultados esperados y pasaron.

---

## Integrante 7 — Medición, generador Go y cierre

**Diapositiva 15 · Protocolo de medición (S1 y S2)**
- `docs/protocolo_medicion.md` versión 1.2: preguntas de rendimiento P1–P5 ligadas a métricas concretas.
- Fronteras de tiempo: `kernel_s` (solo cálculo) frente a `total_s` (incluye vaciado, reparto y coordinación).
- CSV de 20 campos, metadatos reproducibles, 1 warmup + 5 repeticiones, mediana e IQR.
- Plan completo: 16 configuraciones por N y **288 corridas** para tres tamaños; planes de 72, 126, 198 o 288 corridas según la capacidad de cada PC.
- Es un diseño: **todavía no se ejecutó ninguna medición**.

**Diapositiva 16 · Generador determinista en Go (S3, PR #23)**
- Generador congruencial lineal de 32 bits (a = 1664525, c = 1013904223, m = 2^32), con valores `float64` en [-1, 1].
- La matriz B continúa la secuencia de A sin reiniciar la semilla.
- Validaciones: N > 0 y protección contra desbordamiento.
- Pruebas: estados de control para semilla 42, vectores para N = 2, rango, continuidad de estado y semillas extremas; todas pasaron.
- I6 añadió también los vectores de control para semillas 0 y `UINT32_MAX` a las pruebas Go. El registro de I7 no documenta una campaña amplia de comparación C-Go para varias semillas; limiten la afirmación a los vectores compartidos y sus pruebas.

**Diapositiva 17 · Estado actual y hoja de ruta (cierre)**
- Go secuencial y C secuencial: núcleo, generador, CLI, validación y comparación de fixtures integrados. Las pruebas de cierre pasaron; todavía no se ejecutaron las campañas oficiales de rendimiento.
- Paralelo C y Go: diseño listo, implementación en S4.
- Mediciones: protocolo listo, ejecución en S7 y S8.
- Ruta: S4 núcleos paralelos · S5 validación integral y errores · S6 optimización · S7 mediciones y piloto · S8 campaña oficial · S9 análisis e informe · S10 reproducción y entrega.
- Frase de cierre: "Tenemos una base verificada y un contrato común; lo que sigue es paralelizar y medir con rigor."
- Abrir a preguntas.

---

## Consejos para armar el Canva
- Una captura por tema: árbol del repo, un PR con revisión, salida de pruebas con código 0.
- No mostrar tiempos ni gráficos de rendimiento.
- Ensayar el pase: 3 → 8 → 6 → 5 → 1 → 2 → 4 → 7.
- Si preguntan por C, indicar que el ejecutable secuencial está integrado y validado en Debug y Release; las mediciones oficiales de rendimiento quedan para S7/S8.
