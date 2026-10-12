# Sprint 3 Implementar las referencias secuenciales

Estado: en ejecución. Como integrante 3, completé y probé la multiplicación Go secuencial y revisé el ejecutable integrado de Eva. Sebastian aceptó mi entrega y el trabajo de I4 queda conforme en su estado actual. El cierre de las demás entregas del equipo sigue pendiente. Las asignaciones siguientes proceden de la [guía vigente](../Guia_Sprints.md); detallo mi avance en el registro individual.

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

## Registro individual · I5 Fernando · 12/10/2026

- **Rama y entregable:** preparé `feature/s03-i05-comparador-resultados`. El entregable es [`scripts/compare_results.ps1`](../../scripts/compare_results.ps1); el pull request permanece pendiente hasta revisar estos cambios.
- **Comparación implementada:** el script valida UTF-8 sin BOM, dimensión, número exacto de filas y columnas, gramática decimal y valores finitos. Compara todas las celdas con `atol = 1e-9` y `rtol = 1e-9`, informa la primera diferencia y los errores absoluto y relativo máximos, y devuelve código 1 ante formato o resultado inválido.
- **Pruebas automatizadas:** añadí [`tests/compare_results_test.ps1`](../../tests/compare_results_test.ps1) y lo integré en `scripts/test_windows.ps1`. Cubre los cinco fixtures, aceptación y rechazo alrededor de la tolerancia, dimensión distinta, `NaN` y cantidad incorrecta de valores por fila.
- **Evidencia Go secuencial:** ejecuté `scripts/test_windows.ps1 -Version go_secuencial -Configuration Debug`; compilación, `go fmt`, `go vet`, `go test`, producto real, CSV y cinco fixtures terminaron con código 0. Después comparé las cinco salidas generadas por Go; `producto2`, `escalar`, `identidad`, `cero` e `impar3` resultaron `OK`, todos con `max_abs=0` y `max_rel=0`.
- **Bloqueo de C secuencial:** la inspección de `c_secuencial/src/main.c` muestra que todavía no admite `--input`/`--output` y que su flujo actual devuelve código 2 aun cuando el núcleo ya está integrado. No pude confirmar ese comportamiento ejecutando C porque este equipo no encontró MSVC ni Build Tools. No es posible afirmar todavía la comparación ejecutable completa C-Go-referencia; el comparador queda preparado para recibir la salida C cuando I1/I2 completen esa integración.
- **Horas, coordinación y revisión:** Fernando debe confirmar las horas reales. Quedan pendientes la revisión cruzada de este entregable por Eva (I4), mi revisión del generador C de Gerardo (I6) y la apertura del pull request.

## Registro individual · I3 Giuliano · 05/10/2026

- **Distribución de horas:** organicé mis 8 h en 3 h para implementar la multiplicación, conservar las validaciones y documentar su uso; 3 h para añadir y ejecutar las pruebas matemáticas, de errores y de uso repetido; 1 h para revisar el ejecutable de Eva (I4); y 1 h para preparar el acuerdo de coordinación del sprint y definir las interfaces entre el núcleo y la integración.
- **Trabajo realizado:** completé mis dos tareas principales: implementar la multiplicación Go secuencial y añadir las pruebas del producto. Modifiqué [matrix.go](../../go_secuencial/matrix.go) y [matrix_test.go](../../go_secuencial/matrix_test.go), y actualicé el [README](../../go_secuencial/README.md) con el funcionamiento y la forma de comprobarlo.
- **Multiplicación:** completé `Multiply`, que antes indicaba que el cálculo estaba pendiente. Ahora calcula A por B con el orden de bucles acordado y guarda el resultado en una matriz nueva. Conservé las comprobaciones de tamaños, datos y errores del Sprint 2. Comprobé que A y B permanecen intactas y que modificar el resultado no cambia las entradas.
- **Preparación para la integración:** separé el cálculo de la preparación de las matrices. Dejé explicado en el README cómo Eva puede usar esa separación para medir el tiempo de cálculo y el tiempo total según el acuerdo del equipo.
- **Pruebas matemáticas:** ejecuté los cinco casos compartidos: producto conocido de 2×2, escalar negativo, identidad, matriz cero y matriz impar de 3×3. Comparé todas las posiciones con los resultados esperados y la tolerancia acordada; los cinco pasaron. También añadí un caso con decimales cuyo resultado calculé manualmente.
- **Pruebas de errores y uso repetido:** mantuve las pruebas de entradas inválidas y comprobé el orden en que se detectan sus errores. Añadí pruebas de una matriz multiplicada por sí misma y de varias llamadas seguidas, verificando que los resultados sean correctos e independientes. También comprobé que, si el cálculo produce valores fuera de lo admitido, se informa el error, se conservan las entradas y no se devuelve un resultado incompleto.
- **Comprobación final:** ejecuté `gofmt -w matrix.go matrix_test.go`, `go test -count=1 -timeout=30s -v ./...` y `go vet ./...` desde `go_secuencial`. Todas las comprobaciones terminaron correctamente, con código 0. Revisé los cambios con `git diff --check`, que también pasó. Utilicé Go 1.27.0 en Windows de 64 bits.
- **Incidencia resuelta:** al principio, Go no pudo escribir en su carpeta habitual de archivos temporales de compilación. Usé una carpeta local del proyecto y pude completar las pruebas. Apareció además un aviso de permisos de la telemetría de Go; las comprobaciones terminaron correctamente.
- **Revisión a I4 (Eva) · 11/10/2026:** revisé el ejecutable Go secuencial integrado. Comprobé los argumentos, la lectura y escritura de matrices, los tiempos y la salida CSV. Ejecuté las comprobaciones en Debug y Release y verifiqué los cinco casos compartidos. También comprobé 38 ejecuciones con entradas válidas e inválidas, archivos y calentamiento. Todas respondieron como correspondía. El entregable de I4 queda conforme al Sprint 3 en su estado actual.
- **Revisión y aceptación:** Sebastian (I2) revisó y aceptó mi entrega. Completé la multiplicación Go secuencial, sus pruebas y la revisión del trabajo de Eva. Mi parte del Sprint 3 queda conforme; el cierre del sprint depende de las demás entregas y revisiones del equipo.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h ejecución y auditoría de pruebas en referencias C y Go, 3 h ampliación de casos de regresión matemática y documentación de errores observados, 1 h coordinación de equipo según ACUERDO_SPRINT_3.md, 1 h revisión cruzada con evidencia a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s03-i08-validacion-secuencial`.
- Pruebas y evidencias: Entregable `docs/validacion_secuencial.md` completado y actualizado con auditoría empírica de `feature/s03-i03-go-secuencial-multiplicacion-y-pruebas` (I3 Giuliano, 5 fixtures compartidos PASS) y revisión cruzada reproducida de `feature/s03-i01-nucleo-c-secuencial` (I1 Yessly, `matrix_kernel_test.c` PASS, observación en `pending_test.c:185`).
- Bloqueos y decisiones: Se reportó a Yessly la corrección en `pending_test.c` línea 185 para evitar el fallo de retorno 1 en `test_windows.ps1`. Se mantiene la coordinación con I3 Giuliano e I4 Eva para la integración final del script general de pruebas cuando los ejecutables principales estén enlazados.
- Revision y criterio de aceptacion: Entregable de I8 finalizado con evidencia experimental rigurosa; listo para revisión cruzada formal por Integrante 7 (Andrés).


#### Integrante 4 (Eva)
- **Issues y pull requests**: Rama de trabajo feature/s03-i04-go-secuencial-integrado. El pull request se abrirá tras la revisión cruzada de Giuliano (I3) y la validación final del equipo.
- **Participantes y horas reales**: Dediqué 8 h: 3 h a implementar argumentos, lectura y escritura de matrices en Go (main.go, input.go), 3 h a integrar el timer (time.Now) y la salida CSV de 20 campos según el protocolo de medición v1.2, 1 h a revisar el comparador de Fernando (I5) y 1 h a coordinar los acuerdos con el equipo.
- **Entrega y trazabilidad**: Mi entregable es el ejecutable Go secuencial integrado en go_secuencial/main.go y go_secuencial/input.go. La multiplicación usa Multiply de matrix.go (implementada por Giuliano en S3). El código compila y pasa todas las pruebas de test_windows.ps1.
- **Pruebas y evidencias**:
- **Argumentos (main.go:21–109)**: Soporta --smoke-test, --n N --seed S (generación), --input archivo --output archivo (archivos). Rechaza combinaciones inválidas (--input con --n/--seed, duplicados, faltantes). Validación de N > 0 y semilla en [0, 4294967295].
- **Lectura de matrices (input.go:48–107)**: ReadMatrices exige N en línea propia, N filas de A y N de B, exactamente N valores por fila. Acepta LF/CRLF y espacios finales; rechaza filas fusionadas/divididas, blanco interno, BOM, NUL, CR aislado, valores no finitos (NaN, Infinity). Devuelve ErrInvalidFixture o ErrFixtureIO (mapeados a salida 1 en main.go).
- **Escritura de matriz (input.go:161–189)**: WriteMatrix valida la matriz antes de escribir, emite N en línea propia y N filas con N valores en formato %.17g (precisión completa round-trip), separador espacio, LF final.
- **Generación (input.go:20–38)**: Generate usa el LCG compartido (1664525*state + 1013904223), valores en [-1.000, 1.000] con 3 decimales. Valida dimensión con ValidateDimension (mismas reglas que C).
- **Timer y CSV (main.go:137–169, 219–260)**: Mide kernel_s (solo Multiply) y total_s (incluye validación y limpieza) con time.Now(). Emite CSV de 20 campos por stderr: timestamp, version, commit, hostname, cpu_model, ram_gb, os_version, configuration, n, seed, repetition, warmup, gomaxprocs, concurrency, is_warmup, kernel_s, total_s, validation_status. validation_status = "PENDING" mientras el contrato no exija validación post-cálculo en S3.
- **Ejecución verificada:** scripts/test_windows.ps1 -Version go_secuencial -Configuration Debug → código 0. Incluye: compilación, go fmt, go vet, go test ./..., --smoke-test, --n 2 --seed 42 (producto real + CSV validado), 5 fixtures con --input/--output comparados por compare_results.ps1 (todos OK, max_abs=0, max_rel=0). Giuliano (I3) replicó 38 ejecuciones (válidas e inválidas, archivos, calentamiento) en Debug y Release: todas respondieron como correspondía.
- **Bloqueos y decisiones:**
    - getCommitHash() devuelve "dev" (se completará en CI/CD futuro).
    - getCPUModel(), getRAMGB(), getOSVersion(), getHostname() son stubs funcionales en Windows; se completarán según capacidad del hardware.
    - validation_status = "PENDING" en el CSV: según docs/protocolo_medicion.md §3.3, la validación matemática post-cálculo (valores finitos en C) se integrará cuando el comparador y las referencias C estén listos. El ejecutable no debe autodeclararse "OK" sin validación cruzada.
    - Separación clara: Multiply (núcleo, medido en kernel_s) vs. main (argumentos, I/O, generación, validación, medido en total_s pero fuera de kernel_s). Coincide con el protocolo v1.2.
- **Criterio de aceptación:** Mi entregable técnico (ejecutable Go secuencial con argumentos, I/O, timer y CSV) queda conforme según la revisión de Giuliano (I3) registrada en su sección del 11/10/2026. La distribución de 8 h y los acuerdos están registrados en este cierre.
- **Coordinación:** Alineé la interfaz de argumentos (--input/--output), el formato de matriz en archivo (idéntico a fixtures), el CSV de 20 campos y los límites de timer con el protocolo de Andrés (I7) y el comparador de Fernando (I5). Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I5 (Fernando):** Revisé el comparador scripts/compare_results.ps1 y su suite de pruebas. Las validaciones de formato (UTF-8, BOM, NUL, CR, gramática decimal, dimensiones, valores finitos) y la comparación numérica (atol=1e-9, rtol=1e-9, reporte de primera diferencia y máximos) son correctas y completas. La integración en test_windows.ps1 funciona y la evidencia Go secuencial (5 fixtures OK, max_abs=0, max_rel=0) confirma que el comparador recibe y valida correctamente las salidas de Go. El entregable de I5 queda conforme. Queda pendiente mi firma formal en el PR.
- **Revisión y aceptación:** Giuliano (I3) revisó y aceptó mi entregable el 11/10/2026 (ver su registro). Completé la integración Go secuencial, sus argumentos, I/O, timer y CSV, y la revisión del comparador de Fernando. Mi parte del Sprint 3 queda conforme; el cierre del sprint depende de las demás entregas y revisiones del equipo.

## Registro individual · I6 Gerardo · 

- **Generador C:** revisé `c_secuencial/src/input.c` contra las secciones 4.4–4.5 de `docs/formato_datos.md`. La implementación existente actualiza un único estado `uint32_t`, genera primero A y luego B sin reiniciar el estado, y convierte el residuo a entero con signo antes de restar 1000. No fue necesario modificar el algoritmo.
- **Pruebas de semillas límite:** añadí a `c_secuencial/tests/pending_test.c` vectores de N=2 para `seed=0` y `seed=UINT32_MAX`; comprueban todos los valores de A y B, el rango [-1, 1] y que la generación sea repetible. Añadí los mismos vectores de control a `go_secuencial/input_test.go` para mantener una referencia común.
- **Evidencia ejecutada:** compilé y ejecuté las pruebas C en Debug y Release con `scripts/build_windows.ps1 -Version c_secuencial -Configuration <Debug|Release> -Tests`, y ejecuté `c_secuencial/build/<Configuration>/tests/pending_test.exe` desde la raíz. Ambas configuraciones terminaron con código 0; pasaron los vectores de seed 42, los casos límite 0/`UINT32_MAX` y las pruebas existentes de lectura de fixtures/formato. `go test -count=1 -timeout=30s ./...` y `go vet ./...` desde `go_secuencial` también terminaron con código 0.
- **Limitación del runner general:** `scripts/test_windows.ps1 -Version c_secuencial -Configuration Debug` se detuvo en `tests/compare_results_test.ps1` antes de compilar C: el mensaje de error de una fila vacía llegó con formato multilínea y no coincidió con la expresión esperada. La compilación y ejecución C enfocadas indicadas arriba sí pasaron; queda pendiente corregir o verificar ese runner general fuera de este entregable.
- **Pendiente administrativo:** confirmar horas reales, revisión cruzada, rama y pull request.
