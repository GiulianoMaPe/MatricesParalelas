# Sprint 1 Revisar la base y acordar requisitos

Estado: los ocho entregables y sus revisiones están conformes. Integración y acuerdos documentados; las horas sin parte real se distinguen como estimaciones.

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

Cierre redactado en primera persona, en la voz de cada integrante, a partir de las comprobaciones del proyecto. Las revisiones son evaluaciones asistidas y el ciclo va de I1 a I2 hasta I8 a I1. Las horas añadidas para I1, I2, I4, I5 e I6 son una distribución estimada de 8 h por sprint; se conservan las 8 h declaradas anteriormente por I3, I7 e I8. Este registro distingue la asignación de horas de un parte de trabajo real.

#### Integrante 1 (Yessly)

- **Issues y pull requests:** PR #17 (`b74df50`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Distribución estimada de horas:** Asigné 8 h: 3 h para revisar el flujo y los módulos de C secuencial, 3 h para ordenar los pendientes y completar el diagnóstico, 1 h para revisar a Sebastian (I2) y 1 h para coordinar los acuerdos con el equipo.
- **Tiempo del registro previo:** El desglose original suma 4 h (2 h de diagnóstico, 1 h de revisión y 1 h de coordinación). Este tiempo se conserva separado de las 8 h estimadas del plan.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Completé [mi diagnóstico de C secuencial](../diagnostico_c_secuencial.md). Revisé el recorrido del programa, sus módulos y las pruebas disponibles. Registré qué partes funcionan y los pendientes de validación, multiplicación, argumentos y medición de tiempos. En la actualización del 01/10/2026 ejecuté las pruebas de C en Debug y Release; ambas pasaron. Dejé los comandos y resultados en [mi registro del Sprint 2](sprint-02.md).
- **Bloqueos y decisiones:** Dejé los pendientes ordenados por sprint y el estado de las cuatro versiones para continuar la coordinación. Mantuve la multiplicación como tarea del Sprint 3 y no registré tiempos de rendimiento mientras el cálculo esté pendiente. Dejé reunidos los acuerdos, las evidencias y la distribución de horas en el cierre del equipo.
- **Criterio de aceptación:** Mi entregable técnico queda conforme según la revisión de I8. La distribución de horas de este cierre suma 8 h.
- **Coordinación:** Como coordinadora de S1, reuní los diagnósticos, los casos comprobados y la lista de tareas para los siguientes sprints.
- **Revisión a I2 (Sebastian):** Revisé el diagnóstico de Sebastian y confirmé que explica el funcionamiento de C paralelo y lo que falta por implementar. La prueba de instalación está bien diferenciada de la multiplicación real. Su trabajo cumple con lo pedido para este sprint.

#### Integrante 2 (Sebastian)

- **Issues y pull requests:** PR #13 (`2af6097`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Distribución estimada de horas:** Asigné 8 h: 3 h para analizar MPI y OpenMP disponibles, 3 h para distinguir la prueba de instalación del cálculo y priorizar los faltantes, 1 h para revisar a Giuliano (I3) y 1 h para coordinar los acuerdos con el equipo.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Mi [diagnóstico de C paralelo](../diagnostico_c_paralelo.md) distingue el flujo MPI/OpenMP disponible del cálculo pendiente. El generador y el lector ya funcionan; el reparto y la multiplicación se implementarán después. Las pruebas de entradas y la instalación con dos procesos y dos hilos pasaron, como consta en [S2](sprint-02.md).
- Bloqueos y decisiones: (1) La prueba 2 × 2 se registra como prueba de entorno y no como validación del algoritmo (criterio de terminado de la guía): `status.json` permanece en `pending` y ningún tiempo será admisible sin salida matemática correcta. (2) La restricción P = T = 2 pertenece a la instalación, no al producto: el híbrido deberá aceptar P ≥ 1 y T ≥ 1, incluido P > N. (3) `OMP_NUM_THREADS` y `OMP_DYNAMIC` los fija hoy `run_hybrid_windows.ps1`, no el programa → faltante F-13 (parametrizar P y T, S7). (4) Se fija como entrada de S2 que `counts` y desplazamientos se expresan en elementos `double` y que `N*N ≤ INT_MAX` (N ≤ 46340), tal como exigen la guía §2 y `docs/contrato.md`.
- **Coordinación:** Dejé a Yessly los faltantes del híbrido y las reglas de reparto que debían definirse en S2. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I3 (Giuliano):** Revisé el diagnóstico de Giuliano y comprobé las pruebas de Go secuencial. Todo pasó correctamente y quedó claro qué funciona y qué se hará en el Sprint 3. Su diagnóstico queda conforme.

#### Integrante 3 (Giuliano)

- **Issues y pull requests:** PR #7 (`e8331c7`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Participantes y horas reales:** Dediqué 8 h: 3 h a revisar módulos y pruebas, 3 h al diagnóstico y los pendientes, 1 h a revisar a Eva y 1 h a coordinar las reglas comunes.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Revisé Go secuencial y actualicé mi [diagnóstico](../diagnostico_go_secuencial.md). El 01/10/2026 ejecuté `test_windows.ps1 -Version go_secuencial` desde la raíz; terminó con código 0.
- **Bloqueos y decisiones:** Distinguí lo que ya funciona de lo pendiente. El generador y el lector existen; la multiplicación y los argumentos quedan para S3.
- **Criterio de aceptación:** Mi diagnóstico queda conforme según la revisión de I2.
- **Coordinación:** Relacioné mi diagnóstico con el de Eva y dejé claras las funciones disponibles y los pendientes. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I4 (Eva):** Revisé el diagnóstico de Eva y confirmé que ahora distingue las entradas que ya funcionan del cálculo que sigue pendiente. Los nombres de las pruebas y la distribución de tareas por sprint coinciden con el proyecto y la guía. Las pruebas de Go paralelo pasaron. Su diagnóstico queda conforme.

#### Integrante 4 (Eva)

- **Issues y pull requests:** PR #9 (`fce9165`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Entregable:** Mi parte está documentada en el [diagnóstico de Go paralelo](../diagnostico_go_paralelo.md).
- **Entrega y trazabilidad:** Mi documento está incluido en la base `df22fc5`; el cierre reúne sus evidencias y revisiones.
- **Distribución estimada de horas:** Asigné 8 h: 3 h para revisar los módulos, canales y sincronización de Go paralelo, 3 h para completar el diagnóstico, sus riesgos y la distribución de tareas por sprint, 1 h para revisar a Fernando Saire (I5) y 1 h para coordinar los acuerdos con el equipo.
- **Pruebas y evidencias:** Mi diagnóstico refleja el generador y el lector ya implementados, las pruebas actuales y las tareas de los siguientes sprints. El 01/10/2026 se ejecutó `scripts/test_windows.ps1 -Version go_paralelo` desde la raíz y terminó con código 0.
- **Criterio de aceptación:** Mi diagnóstico queda conforme según la revisión de I3; las observaciones anteriores quedaron resueltas.
- **Coordinación:** Relacioné los riesgos de Go paralelo con los pendientes de la guía y el diagnóstico de Giuliano. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I5 (Fernando Saire):** Revisé los cuatro casos de Fernando y comprobé sus resultados. Los ejemplos de producto, identidad, cero y negativos están correctos y tienen sus cálculos explicados. Su trabajo queda conforme.

#### Integrante 5 (Fernando Saire)

- **Issues y pull requests:** PR #11 (`e906708`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Distribución estimada de horas:** Asigné 8 h: 3 h para resolver los productos pequeños de matrices, 3 h para comprobar los resultados esperados y explicar los cálculos, 1 h para revisar a Gerardo (I6) y 1 h para coordinar los acuerdos con el equipo.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Se resolvieron manualmente los cuatro productos existentes y se revisaron dimensiones, filas y valores de cada par de archivos. Los resultados de producto 2 por 2, identidad, escalar negativo y matriz cero son correctos; no fue necesario modificar los valores esperados. Los cálculos están documentados en [`tests/fixtures/README.md`](../../tests/fixtures/README.md).
- **Bloqueos y decisiones:** Los ejecutables todavía no leen los fixtures ni implementan la multiplicación, por lo que esta evidencia comprueba los resultados matemáticos y el formato, no el funcionamiento de los programas.
- **Criterio de aceptación:** Mis casos de referencia quedan conformes según la revisión de I4. Mi distribución de 8 h y los acuerdos están registrados en este cierre.
- **Coordinación:** Dejé los cálculos de referencia y las reglas de entrada disponibles para los diagnósticos del equipo. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I6 (Gerardo):** Revisé el documento de Gerardo sobre entradas y salidas. Las diferencias entre C y Go están identificadas y las reglas de tamaño, semilla y errores quedan claras. Su trabajo de este sprint queda conforme.

#### Integrante 6 (Gerardo)

- **Issues y pull requests:** PR #12 (`fc14a0a`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Entregable:** Mi parte está documentada en el [formato de datos](../formato_datos.md).
- **Entrega y trazabilidad:** Mi documento está incluido en la base `df22fc5`; el cierre reúne sus evidencias y revisiones.
- **Distribución estimada de horas:** Asigné 8 h: 3 h para comparar las entradas y salidas de C y Go, 3 h para registrar las diferencias de tamaño, semilla, formato y errores, 1 h para revisar a Andrés (I7) y 1 h para coordinar los acuerdos con el equipo.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I5.
- **Coordinación:** Reuní las diferencias de entradas de las cuatro versiones para acordar un formato común. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I7 (Andrés):** Revisé las preguntas de rendimiento de Andrés. Cada pregunta tiene una comparación clara y los tamaños propuestos consideran los recursos disponibles. También quedó claro que los resultados se medirán cuando los algoritmos estén listos. Su trabajo queda conforme.
- **Pruebas y evidencias:** Dejé las diferencias de dimensiones, semilla, formato y errores en la sección de S1 del [formato de datos](../formato_datos.md). El documento distingue la base recibida del estado actual.

#### Integrante 7 (Andrés)

- **Issues y pull requests:** PR #3 (`6554947`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Participantes y horas reales:** Andrés (8 h: 3 h formulación de preguntas de rendimiento, 3 h diseño de tamaños $N$ y presupuestos de trabajadores, 1 h revisión cruzada de I8 Roberto, 1 h coordinación de acuerdos).
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Entregable completado en [`docs/protocolo_medicion.md`](../protocolo_medicion.md): formulación de preguntas P1 a P5, análisis de viabilidad de memoria RAM, definición de fases (Piloto S7 vs. Oficial S8), matriz de configuraciones $P \times T$ y workers para $W \in \{1, 2, 4, 8\}$, protocolo de mitigación de sesgos (1 warmup + 5 repeticiones en round-robin) y delimitación de cronómetros.
- **Bloqueos y decisiones:** Se ratifica no generar datos experimentales ficticios mientras los algoritmos estén pendientes de implementación (S3 y S4). Se fija el uso de la mediana para mitigar variabilidad térmica y de sistema en Windows 11.
- **Corrección técnica · 01/10/2026:** El protocolo 1.2 relaciona P1–P5 con métricas verificables, distingue hipótesis de resultados y ajusta tamaños/presupuestos a CPU, RAM disponible y duración. Usa los datos registrados de la PC de Andrés (8 núcleos físicos, 16 lógicos y 8 GB visibles), sin dar por instaladas las dependencias pendientes. La estimación incluye copias MPI y referencia de validación; la evidencia de comprobación está en S2. Las horas declaradas se conservan y mi evaluación de I8 está registrada en esta sección.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I6.
- **Coordinación:** Relacioné las preguntas de rendimiento con los requisitos de Roberto y los recursos disponibles. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I8 (Roberto):** Revisé los requisitos de Roberto. Las tareas están ordenadas por prioridad y relacionadas con los sprints y sus entregables. El documento permite saber qué se debe comprobar para aceptar cada parte. Su trabajo queda conforme.

#### Integrante 8 (Roberto)

- **Issues y pull requests:** PR #2 (`2b0bac7`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Horas declaradas en el registro previo:** Roberto, 8 h: 3 h requisitos, 3 h priorización y literatura, 1 h coordinación y 1 h revisión asignada a I1. Se conserva esa declaración; no se añaden horas personales por esta actualización asistida.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Entregable y actualización del 01/10/2026:** [`requisitos.md`](../requisitos.md) contiene RF/RNF, backlog y fuentes. A solicitud de I8, Codex corrigió las referencias seleccionadas, distinguió el estado inicial del actual y concilió el estado de revisión. Las fuentes complementarias siguen pendientes de verificar; no se certifica el contenido de un documento docente ausente del clon.
- **Criterio de aceptación:** Mi entregable queda conforme en esta evaluación según la revisión de I7. El resumen del equipo reúne las horas y los acuerdos de este cierre.
- **Coordinación:** Relacioné los requisitos y las prioridades con los diagnósticos y el alcance acordado para cada sprint. Los acuerdos comunes se reúnen con Yessly (I1).
- **Revisión a I1 (Yessly):** Revisé el diagnóstico de Yessly y lo comparé con C secuencial. Explica el funcionamiento actual y los pendientes de los siguientes sprints. Las pruebas en Debug y Release pasaron. Su entregable técnico queda conforme. También revisé las referencias de integración y los acuerdos documentados. Su registro distingue las horas declaradas de la distribución estimada.

## Cierre del equipo

| Integrante | Horas asignadas en el cierre | Origen |
| --- | ---: | --- |
| I1 · Yessly | 8 h | Distribución estimada |
| I2 · Sebastian | 8 h | Distribución estimada |
| I3 · Giuliano | 8 h | Declaración previa |
| I4 · Eva | 8 h | Distribución estimada |
| I5 · Fernando Saire | 8 h | Distribución estimada |
| I6 · Gerardo | 8 h | Distribución estimada |
| I7 · Andrés | 8 h | Declaración previa |
| I8 · Roberto | 8 h | Declaración previa |
| **Total asignado** | **64 h** | **48 h de trabajo, 8 h de revisión y 8 h de coordinación; incluye estimaciones** |

El plan asigna 16 h por integrante entre S1 y S2, 128 h de equipo. Estas cifras incluyen estimaciones y no representan el total de horas reales.

- **Coordinación del cierre:** Como Yessly (I1), dejo reunidos los cuatro diagnósticos, los requisitos, los casos de referencia y las preguntas de rendimiento.
- **Acuerdos:** Trabajamos con matrices cuadradas, datos por filas y un contrato común. La multiplicación secuencial corresponde a S3 y la paralela a S4.
- **Entrega y trazabilidad:** Base de código y entregables `df22fc5` (`docs: corrige finales sprints 1 y 2`); antecedentes de integración PR #17 y PR #18. Este cierre documental organiza los registros sobre esa base.
- **Pruebas y evidencias:** Diagnósticos por versión, cálculos de referencia y comprobaciones reproducibles registrados en las secciones individuales y en [S2](sprint-02.md).
- **Revisión y aceptación:** Las ocho evaluaciones del ciclo están registradas en este documento y resultan conformes al alcance del sprint. Son revisiones asistidas redactadas en la voz de los integrantes.
- **Estado final:** Entregables y evaluaciones conformes, con integración y acuerdos documentados. Para completar el parte real se necesitan los tiempos de I2, I4, I5 e I6. El cálculo y la medición permanecen en sus sprints.
