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

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (3 h desarrollo generador Go y plan técnico; pendiente 3 h comparación cruzada con C, 1 h revisión de I8 y 1 h coordinación).
- **Issues y pull requests:** Rama de trabajo `feature/s03-i07-generador-go`.
- **Pruebas y evidencias:** 
  - Entregable [`go_secuencial/input.go`](../../go_secuencial/input.go) implementado con LCG determinista ($a=1664525, c=1013904223$), validación de dimensiones ($N > 0$), desbordamiento protegido y continuidad estricta de estado entre matrices $A$ y $B$.
  - Informe técnico de diseño disponible en [`docs/plan_generador_go.md`](../plan_generador_go.md).
  - Batería de pruebas unitarias implementada en [`go_secuencial/input_test.go`](../../go_secuencial/input_test.go) cubriendo: validación de dimensiones, verificación de los 4 estados canónicos para `seed = 42` (`1083814273`, `378494188`, `2479403867`, `955863294`), vectores de control $2 \times 2$ ($A = [-0.363, 0.036, -0.215, 0.602]$, $B = [0.941, -0.453, -0.554, 0.579]$), rango numérico $[-1.0, 1.0]$, continuidad de estado y semillas extremas.
- **Bloqueos y decisiones:** Se confirma que Go aprovecha la aritmética modular natural de `uint32` para el paso del LCG y la conversión explícita a `int64` para neutralizar riesgos de underflow al centrar en cero.
- **Revisión y criterio de aceptación:** Subtarea 1 completada. Pendiente comparación de evidencia cruzada con la implementación de C (I6 Gerardo) y revisión cruzada de I8 Roberto.

