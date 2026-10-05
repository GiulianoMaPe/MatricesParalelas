# Sprint 3 Implementar las referencias secuenciales

Estado: en ejecución. Como integrante 3, completé y probé la multiplicación Go secuencial. La revisión de mi trabajo y los demás entregables del equipo siguen pendientes. Las asignaciones siguientes proceden de la [guía vigente](../Guia_Sprints.md); detallo mi avance en el registro individual.

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

## Registro individual · I3 Giuliano · 05/10/2026

- **Trabajo realizado:** completé mis dos tareas principales: implementar la multiplicación Go secuencial y añadir las pruebas del producto. Modifiqué [matrix.go](../../go_secuencial/matrix.go) y [matrix_test.go](../../go_secuencial/matrix_test.go), y actualicé el [README](../../go_secuencial/README.md) con el funcionamiento y la forma de comprobarlo.
- **Multiplicación:** completé `Multiply`, que antes indicaba que el cálculo estaba pendiente. Ahora calcula A por B con el orden de bucles acordado y guarda el resultado en una matriz nueva. Conservé las comprobaciones de tamaños, datos y errores del Sprint 2. Comprobé que A y B permanecen intactas y que modificar el resultado no cambia las entradas.
- **Preparación para la integración:** separé el cálculo de la preparación de las matrices. Dejé explicado en el README cómo Eva puede usar esa separación para medir el tiempo de cálculo y el tiempo total según el acuerdo del equipo.
- **Pruebas matemáticas:** ejecuté los cinco casos compartidos: producto conocido de 2×2, escalar negativo, identidad, matriz cero y matriz impar de 3×3. Comparé todas las posiciones con los resultados esperados y la tolerancia acordada; los cinco pasaron. También añadí un caso con decimales cuyo resultado calculé manualmente.
- **Pruebas de errores y uso repetido:** mantuve las pruebas de entradas inválidas y comprobé el orden en que se detectan sus errores. Añadí pruebas de una matriz multiplicada por sí misma y de varias llamadas seguidas, verificando que los resultados sean correctos e independientes. También comprobé que, si el cálculo produce valores fuera de lo admitido, se informa el error, se conservan las entradas y no se devuelve un resultado incompleto.
- **Comprobación final:** ejecuté `gofmt -w matrix.go matrix_test.go`, `go test -count=1 -timeout=30s -v ./...` y `go vet ./...` desde `go_secuencial`. Todas las comprobaciones terminaron correctamente, con código 0. Revisé los cambios con `git diff --check`, que también pasó. Utilicé Go 1.27.0 en Windows de 64 bits.
- **Incidencia resuelta:** al principio, Go no pudo escribir en su carpeta habitual de archivos temporales de compilación. Usé una carpeta local del proyecto y pude completar las pruebas. Apareció además un aviso de permisos de la telemetría de Go; las comprobaciones terminaron correctamente.
- **Estado de mi entrega:** dejé la multiplicación y sus pruebas listas para la revisión de Sebastian (I2). La integración de argumentos, archivos, tiempos y CSV sigue a cargo de Eva (I4); el ejecutable todavía responde que el cálculo está pendiente. La actualización del script general de pruebas debe coordinarse con Roberto (I8). Mi entrega completa el núcleo y sus pruebas; el cierre del sprint depende de las demás entregas y revisiones.
- **Pendientes personales:** me falta recibir la revisión de Sebastian y revisar el trabajo de Eva. También debo registrar mis horas reales y la issue y el PR de la entrega.
