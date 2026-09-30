# Sprint 2 Completar interfaces y casos de prueba

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 2 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Revisar los contratos recibidos y completar interfaces, formatos y casos antes de desarrollar el núcleo.

Cierre: Hay un contrato único aprobado, fixtures con resultados conocidos y diseños que otros integrantes pueden explicar.

## Trabajo de cada integrante

Integrante 1  Revisar estructuras y funciones iniciales de C secuencial (3 h). Completar contrato de memoria, validación de N y liberación de buffers (3 h). Entregable: Interfaces C secuencial revisadas. Ubicación: c_secuencial/include/.

Integrante 2  Diseñar reparto de filas y counts y desplazamientos MPI (3 h). Resolver en papel N no divisible entre P y procesos sin filas (3 h). Entregable: Diseño MPI con ejemplos verificables. Ubicación: c_paralelo/include/partition.h.

Integrante 3  Revisar los datos y funciones iniciales de Go secuencial (3 h). Completar contrato de errores y argumentos equivalente al de C (3 h). Entregable: Interfaces Go secuencial revisadas. Ubicación: go_secuencial/matrix.go.

Integrante 4  Diseñar workers, canal de tareas y propiedad de las filas (3 h). Definir cierre del canal y espera sin bloqueos ni escritura compartida (3 h). Entregable: Diseño Go paralelo con invariantes. Ubicación: docs/arquitectura.md.

Integrante 5  Ampliar los fixtures recibidos con identidad, cero y negativos (3 h). Definir tolerancias y política para NaN e infinitos (3 h). Entregable: Fixtures ampliados y criterio de comparación. Ubicación: tests/fixtures/.

Integrante 6  Completar el formato y generador determinista propuestos (3 h). Preparar vectores de control que C y Go deberán reproducir (3 h). Entregable: Contrato de entradas definitivo. Ubicación: docs/formato_datos.md.

Integrante 7  Definir límites de kernel_s y total_s y campos del CSV (3 h). Diseñar matriz de experimentos y criterios de repetición (3 h). Entregable: Protocolo de medición versión inicial. Ubicación: docs/protocolo_medicion.md.

Integrante 8  Leer y resumir dos candidatos de literatura científica (3 h). Seleccionar al menos uno y asociar sus hallazgos al reparto por filas (3 h). Entregable: Bibliografía verificada y decisión de diseño. Ubicación: docs/bibliografia.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-02.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.
