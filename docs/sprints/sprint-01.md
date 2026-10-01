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

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (8 h: 3 h formulación de preguntas de rendimiento, 3 h diseño de tamaños $N$ y presupuestos de trabajadores, 1 h revisión cruzada de I8 Roberto, 1 h coordinación de acuerdos).
- **Issues y pull requests:** Rama de trabajo `feature/s01-i07-protocolo`.
- **Pruebas y evidencias:** Entregable completado en [`docs/protocolo_medicion.md`](../protocolo_medicion.md): formulación de preguntas P1 a P5, análisis de viabilidad de memoria RAM, definición de fases (Piloto S7 vs. Oficial S8), matriz de configuraciones $P \times T$ y workers para $W \in \{1, 2, 4, 8\}$, protocolo de mitigación de sesgos (1 warmup + 5 repeticiones en round-robin) y delimitación de cronómetros.
- **Bloqueos y decisiones:** Se ratifica no generar datos experimentales ficticios mientras los algoritmos estén pendientes de implementación (S3 y S4). Se fija el uso de la mediana para mitigar variabilidad térmica y de sistema en Windows 11.
- **Revisión y criterio de aceptación:** Entregable de I7 finalizado; revisión cruzada realizada a I8 (Roberto) sobre [`docs/requisitos.md`](../requisitos.md) con aprobación de criterios académicos. Revisor asignado de I7: Integrante 6 (Gerardo).

#### Integrante 8 (Roberto)

- **Participantes y horas reales:** Roberto (8 h: 3 h especificación de requisitos y criterios académicos, 3 h priorización de backlog y mapeo de literatura IEEE, 1 h coordinación de equipo, 1 h revisión cruzada asignada a I1).
- **Issues y pull requests:** Rama de trabajo `feature/integrante-8-roberto`.
- **Pruebas y evidencias:** Entregable [`docs/requisitos.md`](../requisitos.md) finalizado con matriz de criterios verificables, RF-01..05, RNF-01..07, backlog P0..P2 y localización de fuentes IEEE.
- **Bloqueos y decisiones:** Se ratifica que ningún tiempo de ejecución es admisible si la salida matemática no pasa la tolerancia elemento a elemento (1e-9). Los programas devuelven código 2 como estado pendiente.
- **Revisión y criterio de aceptación:** Entregable de I8 revisado y verificado conforme por Integrante 7 (Andrés).

#### Integrante 3 (Giuliano)

- **Participantes y horas:** Giuliano. Falta anotar las horas reales; la estimación era de 8 h.
- **Issues y pull requests:** Rama de trabajo `feature/s01-i03-diagnostico-go-secuencial`.
- **Qué hice:** Revisé el programa Go secuencial y anoté qué funciona y qué falta en [`docs/diagnostico_go_secuencial.md`](../diagnostico_go_secuencial.md).
- **Verificación:** El 2026-09-30 ejecuté `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial`. Terminó correctamente. Confirmó que el programa compila, pasa sus pruebas actuales y reconoce que el cálculo sigue pendiente. Aparecieron avisos de acceso a telemetría, pero no detuvieron la verificación. Esta prueba no comprueba que la multiplicación funcione.
- **Revisión a I4 (Eva):** Revisé `docs/diagnostico_go_paralelo.md` sin cambiar de rama. El documento existe, pero necesita correcciones antes de aceptarlo: dice que el programa procesa `--n`, `--seed` y `--workers`, mide tiempos y escribe CSV, aunque `main.go` solo acepta `--smoke-test`; menciona `NewMatrix` y `MultiplyParallel`, que no existen; y marca argumentos, formato y salida como implementados cuando siguen pendientes. También debe aclarar desde qué carpeta se ejecutaron los comandos y aportar evidencia de los resultados anotados. El código actual solo prueba que dos goroutines se comuniquen y terminen; no reparte filas ni multiplica matrices. **Resultado:** revisión realizada; aceptación pendiente de corregir el diagnóstico.
- **Revisión de mi diagnóstico:** Pendiente.

#### Integrante 5 (Fernando Saire)

- **Participantes y horas reales:** Fernando Saire. Falta registrar las horas reales; la estimación del sprint es de 8 h.
- **Issues y pull requests:** Rama de trabajo `feature/s01-i05-validacion-fixtures`; issue y pull request pendientes.
- **Pruebas y evidencias:** Se resolvieron manualmente los cuatro productos existentes y se revisaron dimensiones, filas y valores de cada par de archivos. Los resultados de producto 2 por 2, identidad, escalar negativo y matriz cero son correctos; no fue necesario modificar los valores esperados. Los cálculos están documentados en [`tests/fixtures/README.md`](../../tests/fixtures/README.md).
- **Revisión cruzada a I6 (Gerardo):** Pendiente hasta que Gerardo publique su entregable. Solo se consultó el estado inicial de [`docs/formato_datos.md`](../formato_datos.md) como referencia para validar los fixtures; esta consulta no constituye una revisión de trabajo realizado por I6.
- **Bloqueos y decisiones:** Los ejecutables todavía no leen los fixtures ni implementan la multiplicación, por lo que esta evidencia comprueba los resultados matemáticos y el formato, no el funcionamiento de los programas.
- **Coordinación y criterio de aceptación:** La coordinación con I1 (Yessly) y la revisión asignada a I4 (Eva) quedan pendientes. El entregable técnico de fixtures queda preparado para esa revisión.
