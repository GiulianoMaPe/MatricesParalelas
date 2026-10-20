# Sprint 4 Construir las versiones paralelas

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 4 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Implementar el híbrido C y el conjunto de trabajadores Go usando las referencias existentes.

Cierre: Las cuatro versiones coinciden en los fixtures. C usa MPI y OpenMP y Go espera correctamente a todos sus trabajadores.

## Trabajo de cada integrante

Integrante 1  Implementar Scatterv y Gatherv con el reparto acordado (3 h). Probar P igual a uno y particiones no divisibles con el núcleo secuencial (3 h). Entregable: Comunicación MPI funcional. Ubicación: c_paralelo/src/main.c y partition.c.

Integrante 2  Integrar OpenMP en las filas locales del híbrido (3 h). Verificar FUNNELED, variables privadas y ausencia de llamadas MPI en hilos secundarios (3 h). Entregable: Híbrido MPI y OpenMP funcional. Ubicación: c_paralelo/src/matrix.c.

Integrante 3  Implementar workers Go y distribución de bloques de filas (3 h). Comprobar que cada fila tiene un solo escritor y todas son calculadas (3 h). Entregable: Núcleo Go paralelo funcional. Ubicación: go_paralelo/workers.go.

Integrante 4  Integrar flags, cierre del canal y WaitGroup en Go paralelo (3 h). Probar workers igual a uno, varios workers y más workers que filas (3 h). Entregable: Ejecutable Go paralelo integrado. Ubicación: go_paralelo/main.go.

Integrante 5  Crear pruebas del reparto MPI y bloques vacíos (3 h). Ejecutar casos impares y revisar errores de counts y desplazamientos (3 h). Entregable: Reporte de particionado C. Ubicación: c_paralelo/tests/.

Integrante 6  Crear pruebas de concurrencia Go por repetición y tamaños variados (3 h). Verificar terminación, resultados estables y no pérdida de tareas (3 h). Entregable: Reporte de concurrencia Go. Ubicación: go_paralelo/workers_test.go.

Integrante 7  Comparar salidas de las cuatro versiones con los fixtures (3 h). Investigar discrepancias y ampliar casos de equivalencia cruzada (3 h). Entregable: Reporte de equivalencia de cuatro versiones. Ubicación: docs/equivalencia.md.

Integrante 8  Documentar los flujos de datos y sincronización de ambos paralelos (3 h). Relacionar los mecanismos reales con el diseño y la rúbrica (3 h). Entregable: Descripción de arquitectura actualizada. Ubicación: docs/arquitectura.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-04.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h documentación técnica de flujos de datos y sincronización de C híbrido MPI+OpenMP y Go concurrente CSP, 3 h mapeo a la rúbrica del curso, análisis de sobrecostes y prevención de fallos concurrentes, 1 h coordinación de acuerdos, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s04-i08-arquitectura-paralela`.
- Pruebas y evidencias: Entregable `docs/arquitectura.md` completado y actualizado como documento maestro de ambos paralelos. Incluye análisis de particionado 1D (`partition.h`, algoritmos de cociente y resto, soporte de $P > N$, límite $N \le 46340$), comunicación colectiva MPI (`Bcast`, `Scatterv`, `Gatherv`), multihilo OpenMP (`MPI_THREAD_FUNNELED`, variables privadas de bucle), modelo CSP de Go (`chan Task`, `sync.WaitGroup`, pool acotado, inmutabilidad y ausencia de data races con `go test -race`), diagramas de secuencia Mermaid y matriz de invariantes globales.
- Bloqueos y decisiones: Se unificó el criterio de cronometraje para que `kernel_s` aísle el cómputo puro del sobrecoste de comunicación en MPI y despacho en canales de Go, alineado con el protocolo de medición.
- Revision y criterio de aceptacion: Entregable de I8 finalizado; listo para revisión formal por Integrante 7 (Andrés). Revisión cruzada a I1 Yessly pendiente a la publicación de su PR de comunicación MPI.

