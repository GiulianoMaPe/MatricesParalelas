# Sprint 3 Implementar las referencias secuenciales

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 3 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Obtener C secuencial y Go secuencial correctos y comparables con las mismas entradas.

Cierre: Ambos programas pasan todos los fixtures pequeños y producen mediciones con el contrato acordado.

## Trabajo de cada integrante

Integrante 1  Implementar el núcleo C con almacenamiento contiguo y bucles i k j (3 h). Comprobar identidad, ceros y producto conocido con salidas completas (3 h). Entregable: Núcleo C secuencial probado. Ubicación: c_secuencial/src/matrix.c.

Integrante 2  Implementar argumentos, reserva de memoria y errores de C (3 h). Integrar el timer y el flujo principal sin incluir impresión en el tiempo (3 h). Entregable: C secuencial integrado. Ubicación: c_secuencial/src/main.c y timer.c.

Integrante 3  Implementar el núcleo Go con float64 y almacenamiento por filas (3 h). Añadir pruebas unitarias del producto con los fixtures (3 h). Entregable: Núcleo Go secuencial probado. Ubicación: go_secuencial/matrix.go.

Integrante 4  Implementar argumentos, lectura y escritura en Go (3 h). Integrar timer y salida CSV sin incluir generación ni validación (3 h). Entregable: Ejecutable Go secuencial integrado. Ubicación: go_secuencial/main.go e input.go.

Integrante 5  Construir comparador de salidas y errores numéricos (3 h). Ejecutar comparación completa entre C, Go y resultados esperados (3 h). Entregable: Comparador y reporte de equivalencia. Ubicación: scripts/compare_results.ps1.

Integrante 6  Implementar el generador determinista en C (3 h). Verificar sus primeras entradas y archivos frente al contrato (3 h). Entregable: Generador C con vectores de prueba. Ubicación: c_secuencial/src/input.c.

Integrante 7  Implementar el mismo generador en Go (3 h). Comparar con C para varias semillas y dimensiones pequeñas (3 h). Entregable: Generador Go y evidencia cruzada. Ubicación: go_secuencial/input.go.

Integrante 8  Ejecutar las pruebas disponibles contra ambas referencias reales (3 h). Ampliar regresiones y documentar comportamiento y errores observados (3 h). Entregable: Reporte funcional de las referencias. Ubicación: docs/validacion_secuencial.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-03.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.
