# Sprint 6 Optimizar con evidencia

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 6 · 64 horas de equipo · 8 horas por integrante

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

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.
