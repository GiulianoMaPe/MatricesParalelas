# Sprint 4 Construir las versiones paralelas

Estado: pendiente de ejecucion y revision por el equipo. Plan extraido de la guia original; no es evidencia de tareas realizadas.

Semana 4 · 64 horas de equipo · 8 horas por integrante

Objetivo y cierre

Implementar el híbrido C y el conjunto de trabajadores Go usando las referencias existentes.

Aceptación: Las cuatro versiones coinciden en los fixtures. C usa MPI y OpenMP y Go espera correctamente a todos sus trabajadores.

Asignaciones individuales

Integrante 1  Implementar Scatterv y Gatherv con el reparto acordado (3 h). Probar P igual a uno y particiones no divisibles con el núcleo secuencial (3 h). Entregable: Comunicación MPI funcional.

Integrante 2  Integrar OpenMP en las filas locales del híbrido (3 h). Verificar FUNNELED, variables privadas y ausencia de llamadas MPI en hilos secundarios (3 h). Entregable: Híbrido MPI y OpenMP funcional.

Integrante 3  Implementar workers Go y distribución de bloques de filas (3 h). Comprobar que cada fila tiene un solo escritor y todas son calculadas (3 h). Entregable: Núcleo Go paralelo funcional.

Integrante 4  Integrar flags, cierre del canal y WaitGroup en Go paralelo (3 h). Probar workers igual a uno, varios workers y más workers que filas (3 h). Entregable: Ejecutable Go paralelo integrado.

Integrante 5  Crear pruebas del reparto MPI y bloques vacíos (3 h). Ejecutar casos impares y revisar errores de counts y desplazamientos (3 h). Entregable: Reporte de particionado C.

Integrante 6  Crear pruebas de concurrencia Go por repetición y tamaños variados (3 h). Verificar terminación, resultados estables y no pérdida de tareas (3 h). Entregable: Reporte de concurrencia Go.

Integrante 7  Incorporar las versiones paralelas al script de compilación (3 h). Crear lanzamientos de prueba con variables de entorno explícitas (3 h). Entregable: Script para las cuatro versiones.

Integrante 8  Documentar los flujos de datos y sincronización de ambos paralelos (3 h). Relacionar los mecanismos reales con el diseño y la rúbrica (3 h). Entregable: Descripción de arquitectura actualizada.

Carga adicional de cada integrante: 1 h para revisar al siguiente integrante del ciclo I1 a I8 y 1 h de coordinación. Total individual: 8 h. Registrar el resultado de la revisión en el pull request o en docs/sprints/.



## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.
