# Sprint 1 Revisar la base y acordar requisitos

Estado: los ocho entregables técnicos están conformes. El cierre administrativo sigue pendiente.

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

Evaluación redactada en primera persona, en la voz de cada revisor, a partir de las comprobaciones del proyecto. El ciclo va de I1 a I2 hasta I8 a I1.

#### Integrante 1 (Yessly)

- **Participantes y horas reales:** Soy Yessly y dediqué 3 h a este sprint: 2 h a revisar C secuencial y preparar el diagnóstico, 1 h a revisar el trabajo de I2 y 1 h a coordinar los pendientes.
- **Issues y pull requests:** Mi diagnóstico original se integró en el PR #17. Dejé esta actualización en los archivos del proyecto; todavía no tiene un nuevo commit ni pull request.
- **Pruebas y evidencias:** Completé [mi diagnóstico de C secuencial](../diagnostico_c_secuencial.md). Revisé el recorrido del programa, sus módulos y las pruebas disponibles. Registré qué partes funcionan y los pendientes de validación, multiplicación, argumentos y medición de tiempos. En la actualización del 01/10/2026 ejecuté las pruebas de C en Debug y Release; ambas pasaron. Dejé los comandos y resultados en [mi registro del Sprint 2](sprint-02.md).
- **Bloqueos y decisiones:** Dejé los pendientes ordenados por sprint y el estado de las cuatro versiones para continuar la coordinación. Mantuve la multiplicación como tarea del Sprint 3 y no registré tiempos de rendimiento mientras el cálculo esté pendiente. El cierre administrativo sigue pendiente de completar los registros del equipo.
- **Criterio de aceptación:** Mi entregable técnico queda conforme según la revisión de I8. El total de horas declarado todavía debe aclararse.
- **Revisión a I2 (Sebastian):** Revisé el diagnóstico de Sebastian y confirmé que explica el funcionamiento de C paralelo y lo que falta por implementar. La prueba de instalación está bien diferenciada de la multiplicación real. Su trabajo cumple con lo pedido para este sprint.

#### Integrante 2 (Sebastian)

- Participantes y horas reales: Sebastian (8 h planificadas: 3 h análisis del flujo MPI y OpenMP disponible en `c_paralelo`, 3 h distinción entre la demostración de hilos y el producto real más enumeración de faltantes, 1 h de coordinación de equipo con I1 como coordinador de S1, 1 h de revisión cruzada asignada a I3). Las horas reales se anotan con el integrante al cierre del sprint.
- Issues y pull requests: Rama de trabajo `feature/integrante-2-sebastian`.
- Pruebas y evidencias: Entregable `docs/diagnostico_c_paralelo.md` finalizado el 30/09/2026. Contiene: (i) el flujo real de `--smoke-test` paso a paso (`MPI_Init_thread` con `MPI_THREAD_FUNNELED` y comprobación del nivel entregado, conteo de hilos con `reduction`, consenso global con `MPI_Allreduce`, `MPI_Finalize`, códigos 0/1/2) y sus invariantes a conservar en S4; (ii) inventario por archivo de `c_paralelo/` (6 fuentes, 3 cabeceras, `pending_test.c`, `status.json`, scripts y tarea de VS Code); (iii) la distinción demostración/producto real con siete pruebas textuales del repositorio (`matrix.c`, `input.c` y `partition.c` no escriben salida; `main.c` rechaza `--n/--seed` con código 2; `pending_test.c` verifica que no haya matrices falsas; `status.json` en `pending`; sin ninguna `MPI_Scatterv`/`Gatherv`/`Bcast` en el módulo); (iv) 14 faltantes priorizados F-01..F-14 con prioridad, sprint y responsables; (v) los 8 supuestos y los puntos de validación futuros. Análisis estático: este equipo no tiene MSVC, MS-MPI ni Go instalados (comprobado el 30/09/2026), por lo que no se repitieron compilaciones ni ejecuciones aquí; la ejecución híbrida 2 × 2 sigue respaldada por `docs/verificacion-inicial.md` (17/09/2026) y las órdenes de reproducción quedan en la §7 del diagnóstico.
- Bloqueos y decisiones: (1) La prueba 2 × 2 se registra como prueba de entorno y no como validación del algoritmo (criterio de terminado de la guía): `status.json` permanece en `pending` y ningún tiempo será admisible sin salida matemática correcta. (2) La restricción P = T = 2 pertenece a la instalación, no al producto: el híbrido deberá aceptar P ≥ 1 y T ≥ 1, incluido P > N. (3) `OMP_NUM_THREADS` y `OMP_DYNAMIC` los fija hoy `run_hybrid_windows.ps1`, no el programa → faltante F-13 (parametrizar P y T, S7). (4) Se fija como entrada de S2 que `counts` y desplazamientos se expresan en elementos `double` y que `N*N ≤ INT_MAX` (N ≤ 46340), tal como exigen la guía §2 y `docs/contrato.md`.
- **Revisión a I3 (Giuliano):** Revisé el diagnóstico de Giuliano y comprobé las pruebas de Go secuencial. Todo pasó correctamente y quedó claro qué funciona y qué se hará en el Sprint 3. Su diagnóstico queda conforme.

#### Integrante 3 (Giuliano)

- **Participantes y horas reales:** Dediqué 8 h: 3 h a revisar módulos y pruebas, 3 h al diagnóstico y los pendientes, 1 h a revisar a Eva y 1 h a coordinar las reglas comunes.
- **Issues y pull requests:** Trabajé en `feature/s01-i03-diagnostico-go-secuencial`.
- **Pruebas y evidencias:** Revisé Go secuencial y actualicé mi [diagnóstico](../diagnostico_go_secuencial.md). El 01/10/2026 ejecuté `test_windows.ps1 -Version go_secuencial` desde la raíz; terminó con código 0.
- **Bloqueos y decisiones:** Distinguí lo que ya funciona de lo pendiente. El generador y el lector existen; la multiplicación y los argumentos quedan para S3.
- **Criterio de aceptación:** Mi diagnóstico queda conforme según la revisión de I2.
- **Revisión a I4 (Eva):** Revisé el diagnóstico de Eva y confirmé que ahora distingue las entradas que ya funcionan del cálculo que sigue pendiente. Los nombres de las pruebas y la distribución de tareas por sprint coinciden con el proyecto y la guía. Las pruebas de Go paralelo pasaron. Su diagnóstico queda conforme.

#### Integrante 4 (Eva)

- **Entregable:** Mi parte está documentada en el [diagnóstico de Go paralelo](../diagnostico_go_paralelo.md).
- **Participantes y horas reales:** Las horas reales y los datos de coordinación siguen pendientes de registro.
- **Pruebas y evidencias:** Mi diagnóstico refleja el generador y el lector ya implementados, las pruebas actuales y las tareas de los siguientes sprints. El 01/10/2026 se ejecutó `scripts/test_windows.ps1 -Version go_paralelo` desde la raíz y terminó con código 0.
- **Criterio de aceptación:** Mi diagnóstico queda conforme según la revisión de I3; las observaciones anteriores quedaron resueltas.
- **Revisión a I5 (Fernando Saire):** Revisé los cuatro casos de Fernando y comprobé sus resultados. Los ejemplos de producto, identidad, cero y negativos están correctos y tienen sus cálculos explicados. Su trabajo queda conforme.

#### Integrante 5 (Fernando Saire)

- **Participantes y horas reales:** Fernando Saire. Falta registrar las horas reales; la estimación del sprint es de 8 h.
- **Issues y pull requests:** Rama de trabajo `feature/s01-i05-validacion-fixtures`; issue y pull request pendientes.
- **Pruebas y evidencias:** Se resolvieron manualmente los cuatro productos existentes y se revisaron dimensiones, filas y valores de cada par de archivos. Los resultados de producto 2 por 2, identidad, escalar negativo y matriz cero son correctos; no fue necesario modificar los valores esperados. Los cálculos están documentados en [`tests/fixtures/README.md`](../../tests/fixtures/README.md).
- **Bloqueos y decisiones:** Los ejecutables todavía no leen los fixtures ni implementan la multiplicación, por lo que esta evidencia comprueba los resultados matemáticos y el formato, no el funcionamiento de los programas.
- **Criterio de aceptación:** Mis casos de referencia quedan conformes según la revisión de I4. Las horas reales y los datos de coordinación todavía deben completarse.
- **Revisión a I6 (Gerardo):** Revisé el documento de Gerardo sobre entradas y salidas. Las diferencias entre C y Go están identificadas y las reglas de tamaño, semilla y errores quedan claras. Su trabajo de este sprint queda conforme.

#### Integrante 6 (Gerardo)

- **Entregable:** Mi parte está documentada en el [formato de datos](../formato_datos.md).
- **Participantes y horas reales:** Las horas reales y los datos de coordinación siguen pendientes de registro.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I5.
- **Revisión a I7 (Andrés):** Revisé las preguntas de rendimiento de Andrés. Cada pregunta tiene una comparación clara y los tamaños propuestos consideran los recursos disponibles. También quedó claro que los resultados se medirán cuando los algoritmos estén listos. Su trabajo queda conforme.

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (8 h: 3 h formulación de preguntas de rendimiento, 3 h diseño de tamaños $N$ y presupuestos de trabajadores, 1 h revisión cruzada de I8 Roberto, 1 h coordinación de acuerdos).
- **Issues y pull requests:** Rama de trabajo `feature/s01-i07-protocolo`.
- **Pruebas y evidencias:** Entregable completado en [`docs/protocolo_medicion.md`](../protocolo_medicion.md): formulación de preguntas P1 a P5, análisis de viabilidad de memoria RAM, definición de fases (Piloto S7 vs. Oficial S8), matriz de configuraciones $P \times T$ y workers para $W \in \{1, 2, 4, 8\}$, protocolo de mitigación de sesgos (1 warmup + 5 repeticiones en round-robin) y delimitación de cronómetros.
- **Bloqueos y decisiones:** Se ratifica no generar datos experimentales ficticios mientras los algoritmos estén pendientes de implementación (S3 y S4). Se fija el uso de la mediana para mitigar variabilidad térmica y de sistema en Windows 11.
- **Corrección técnica · 01/10/2026:** El protocolo 1.2 relaciona P1–P5 con métricas verificables, distingue hipótesis de resultados y ajusta tamaños/presupuestos a CPU, RAM disponible y duración. Usa los datos registrados de la PC de Andrés (8 núcleos físicos, 16 lógicos y 8 GB visibles), sin dar por instaladas las dependencias pendientes. La estimación incluye copias MPI y referencia de validación; la evidencia de comprobación está en S2. No se añaden horas ni aprobaciones de personas.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I6.
- **Revisión a I8 (Roberto):** Revisé los requisitos de Roberto. Las tareas están ordenadas por prioridad y relacionadas con los sprints y sus entregables. El documento permite saber qué se debe comprobar para aceptar cada parte. Su trabajo queda conforme.

#### Integrante 8 (Roberto)

- **Horas declaradas en el registro previo:** Roberto, 8 h: 3 h requisitos, 3 h priorización y literatura, 1 h coordinación y 1 h revisión asignada a I1. Se conserva esa declaración; no se añaden horas personales por esta actualización asistida.
- **Issues y pull requests:** Rama de trabajo `feature/integrante-8-roberto`.
- **Entregable y actualización del 01/10/2026:** [`requisitos.md`](../requisitos.md) contiene RF/RNF, backlog y fuentes. A solicitud de I8, Codex corrigió las referencias seleccionadas, distinguió el estado inicial del actual y concilió el estado de revisión. Las fuentes complementarias siguen pendientes de verificar; no se certifica el contenido de un documento docente ausente del clon.
- **Criterio de aceptación:** Mi entregable queda conforme en esta evaluación según la revisión de I7. El cierre administrativo del equipo sigue pendiente.
- **Revisión a I1 (Yessly):** Revisé el diagnóstico de Yessly y lo comparé con C secuencial. Explica el funcionamiento actual y los pendientes de los siguientes sprints. Las pruebas en Debug y Release pasaron. Su entregable técnico queda conforme.

**Registro global del equipo (separado del cierre individual de I1):**

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: resultados y documentos registrados en las secciones individuales.
- Bloqueos y decisiones: los entregables técnicos de S1 están conformes; falta completar los registros administrativos.
- Revisión y criterio de aceptación: las evaluaciones técnicas quedan registradas en las secciones de cada integrante; falta completar el cierre administrativo.
