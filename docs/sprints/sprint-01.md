# Sprint 1 Revisar la base y acordar requisitos

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 1 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Comprender lo que ya funciona, identificar funciones pendientes y definir el alcance matemático.

Cierre: Existe un diagnóstico por versión, una lista priorizada de pendientes y casos de referencia comprobados.

## Trabajo de cada integrante

Integrante 1 Leer el flujo funcional y los módulos de C secuencial (3 h). Identificar funciones pendientes, supuestos y puntos de validación (3 h). Entregable: Diagnóstico funcional C secuencial. Ubicación: docs/diagnostico_c_secuencial.md.

Integrante 2 Analizar el flujo MPI y OpenMP disponible en C paralelo (3 h). Distinguir demostraciones de hilos del producto real y enumerar faltantes (3 h). Entregable: Diagnóstico funcional C paralelo. Ubicación: docs/diagnostico_c_paralelo.md.

Integrante 3 Leer los módulos de Go secuencial y sus pruebas existentes (3 h). Identificar operaciones reales, funciones pendientes y errores no cubiertos (3 h). Entregable: Diagnóstico funcional Go secuencial. Ubicación: docs/diagnostico_go_secuencial.md.

Integrante 4 Leer workers, canales y sincronización de Go paralelo (3 h). Identificar propiedad de filas, riesgos de bloqueo y funciones pendientes (3 h). Entregable: Diagnóstico funcional Go paralelo. Ubicación: docs/diagnostico_go_paralelo.md.

Integrante 5 Resolver manualmente productos pequeños de matrices (3 h). Revisar los fixtures recibidos y corregir valores esperados incorrectos (3 h). Entregable: Casos matemáticos de referencia. Ubicación: tests/fixtures/.

Integrante 6 Revisar las entradas y salidas propuestas para C y Go (3 h). Registrar discrepancias de dimensiones, semilla, formato y errores (3 h). Entregable: Matriz de diferencias del contrato. Ubicación: docs/formato_datos.md.

Integrante 7 Relacionar las métricas solicitadas con preguntas de rendimiento (3 h). Proponer tamaños y presupuestos de trabajadores según recursos disponibles (3 h). Entregable: Preguntas experimentales y alcance de medición. Ubicación: docs/protocolo_medicion.md.

Integrante 8 Convertir los criterios académicos en entregables verificables (3 h). Priorizar pendientes y localizar los artículos científicos del curso (3 h). Entregable: Matriz de requisitos y pendientes priorizados. Ubicación: docs/requisitos.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-01.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h especificación de requisitos y criterios académicos, 3 h priorización de backlog y mapeo de literatura IEEE, 1 h coordinación de equipo, 1 h revisión cruzada asignada a I1).
- Issues y pull requests: Rama de trabajo `feature/integrante-8-roberto`.
- Pruebas y evidencias: Entregable `docs/requisitos.md` finalizado con matriz de criterios verificables, RF-01..05, RNF-01..07, backlog P0..P2 y localización de fuentes IEEE.
- Bloqueos y decisiones: Se ratifica que ningún tiempo de ejecución es admisible si la salida matemática no pasa la tolerancia elemento a elemento (1e-9). Los programas devuelven código 2 como estado pendiente.
- Revision y criterio de aceptacion: Entregable de I8 finalizado; pendiente revisión cruzada formal por Integrante 7 (Andres).

#### Integrante 2

- Participantes y horas reales: Sebastian (8 h planificadas: 3 h análisis del flujo MPI y OpenMP disponible en `c_paralelo`, 3 h distinción entre la demostración de hilos y el producto real más enumeración de faltantes, 1 h de coordinación de equipo con I1 como coordinador de S1, 1 h de revisión cruzada asignada a I3). Las horas reales se anotan con el integrante al cierre del sprint.
- Issues y pull requests: Rama de trabajo `feature/integrante-2-sebastian`.
- Pruebas y evidencias: Entregable `docs/diagnostico_c_paralelo.md` finalizado el 30/09/2026. Contiene: (i) el flujo real de `--smoke-test` paso a paso (`MPI_Init_thread` con `MPI_THREAD_FUNNELED` y comprobación del nivel entregado, conteo de hilos con `reduction`, consenso global con `MPI_Allreduce`, `MPI_Finalize`, códigos 0/1/2) y sus invariantes a conservar en S4; (ii) inventario por archivo de `c_paralelo/` (6 fuentes, 3 cabeceras, `pending_test.c`, `status.json`, scripts y tarea de VS Code); (iii) la distinción demostración/producto real con siete pruebas textuales del repositorio (`matrix.c`, `input.c` y `partition.c` no escriben salida; `main.c` rechaza `--n/--seed` con código 2; `pending_test.c` verifica que no haya matrices falsas; `status.json` en `pending`; sin ninguna `MPI_Scatterv`/`Gatherv`/`Bcast` en el módulo); (iv) 14 faltantes priorizados F-01..F-14 con prioridad, sprint y responsables; (v) los 8 supuestos y los puntos de validación futuros. Análisis estático: este equipo no tiene MSVC, MS-MPI ni Go instalados (comprobado el 30/09/2026), por lo que no se repitieron compilaciones ni ejecuciones aquí; la ejecución híbrida 2 × 2 sigue respaldada por `docs/verificacion-inicial.md` (17/09/2026) y las órdenes de reproducción quedan en la §7 del diagnóstico.
- Bloqueos y decisiones: (1) La prueba 2 × 2 se registra como prueba de entorno y no como validación del algoritmo (criterio de terminado de la guía): `status.json` permanece en `pending` y ningún tiempo será admisible sin salida matemática correcta. (2) La restricción P = T = 2 pertenece a la instalación, no al producto: el híbrido deberá aceptar P ≥ 1 y T ≥ 1, incluido P > N. (3) `OMP_NUM_THREADS` y `OMP_DYNAMIC` los fija hoy `run_hybrid_windows.ps1`, no el programa → faltante F-13 (parametrizar P y T, S7). (4) Se fija como entrada de S2 que `counts` y desplazamientos se expresan en elementos `double` y que `N*N ≤ INT_MAX` (N ≤ 46340), tal como exigen la guía §2 y `docs/contrato.md`.
- Revision y criterio de aceptacion: Criterio de cierre de S1 para I2 cumplido en las seis casillas de la §8 del diagnóstico; pendiente la revisión cruzada formal por Integrante 1 (Yessly). Como revisor asignado de I3, se revisó con evidencia lo publicado hasta la fecha por Giuliano (`docs/entorno/3-giuliano.md`, 17/09/2026): es consistente con `docs/verificacion-inicial.md` y con la corrección de rutas con espacios (`f0d69f3`); el entregable S1 de I3, `docs/diagnostico_go_secuencial.md`, aún no existe en el repositorio, por lo que su revisión formal queda pendiente de que I3 lo publique.
