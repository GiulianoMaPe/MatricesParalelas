# Sprint 1 Revisar la base y acordar requisitos

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 1 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Comprender lo que ya funciona, identificar funciones pendientes y definir el alcance matemático.

Cierre: Existe un diagnóstico por versión, una lista priorizada de pendientes y casos de referencia comprobados.

## Trabajo de cada integrante

Integrante 1  Leer el flujo funcional y los módulos de C secuencial (3 h). Identificar funciones pendientes, supuestos y puntos de validación (3 h). Entregable: Diagnóstico funcional C secuencial. Ubicación: docs/diagnostico_c_secuencial.md.

Integrante 2  Analizar el flujo MPI y OpenMP disponible en C paralelo (3 h). Distinguir demostraciones de hilos del producto real y enumerar faltantes (3 h). Entregable: Diagnóstico funcional C paralelo. Ubicación: docs/diagnostico_c_paralelo.md.

Integrante 3  Leer los módulos de Go secuencial y sus pruebas existentes (3 h). Identificar operaciones reales, funciones pendientes y errores no cubiertos (3 h). Entregable: Diagnóstico funcional Go secuencial. Ubicación: docs/diagnostico_go_secuencial.md.

Integrante 4  Leer workers, canales y sincronización de Go paralelo (3 h). Identificar propiedad de filas, riesgos de bloqueo y funciones pendientes (3 h). Entregable: Diagnóstico funcional Go paralelo. Ubicación: docs/diagnostico_go_paralelo.md.

Integrante 5  Resolver manualmente productos pequeños de matrices (3 h). Revisar los fixtures recibidos y corregir valores esperados incorrectos (3 h). Entregable: Casos matemáticos de referencia. Ubicación: tests/fixtures/.

Integrante 6  Revisar las entradas y salidas propuestas para C y Go (3 h). Registrar discrepancias de dimensiones, semilla, formato y errores (3 h). Entregable: Matriz de diferencias del contrato. Ubicación: docs/formato_datos.md.

Integrante 7  Relacionar las métricas solicitadas con preguntas de rendimiento (3 h). Proponer tamaños y presupuestos de trabajadores según recursos disponibles (3 h). Entregable: Preguntas experimentales y alcance de medición. Ubicación: docs/protocolo_medicion.md.

Integrante 8  Convertir los criterios académicos en entregables verificables (3 h). Priorizar pendientes y localizar los artículos científicos del curso (3 h). Entregable: Matriz de requisitos y pendientes priorizados. Ubicación: docs/requisitos.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-01.md.

## Registro de cierre

- **Participantes y horas reales:**
  - Integrante 7 (Andrés): 8 h registradas (3 h formulación de preguntas de rendimiento, 3 h diseño de tamaños $N$ y presupuestos de trabajadores, 1 h revisión cruzada de I8 Roberto, 1 h coordinación de acuerdos).
  - Integrantes 1 a 6 y 8: pendientes de registro individual.
- **Issues y pull requests:**
  - Rama: `feature/s01-i07-protocolo`
  - Pull Request: Pendiente de aprobación por revisor asignado (Integrante 6 · Gerardo).
- **Pruebas y evidencias:**
  - Entregable completado en [`docs/protocolo_medicion.md`](../protocolo_medicion.md): formulación de preguntas P1 a P5, análisis de viabilidad de memoria RAM, definición de fases (Piloto S7 vs. Oficial S8), matriz de configuraciones $P \times T$ y workers para $W \in \{1, 2, 4, 8\}$, protocolo de mitigación de sesgos (1 warmup + 5 repeticiones en round-robin) y delimitación de cronómetros.
- **Bloqueos y decisiones:**
  - Se ratifica no generar datos experimentales ficticios mientras los algoritmos estén pendientes de implementación (S3 y S4).
  - Se fija el uso de la mediana para mitigar variabilidad térmica y de sistema en Windows 11.
- **Revisión y criterio de aceptación:**
  - Revisor de este entregable: Integrante 6 (Gerardo).
  - Revisión asignada a realizar por I7: Integrante 8 (Roberto) sobre [`docs/requisitos.md`](../requisitos.md).

