# Sprint 5 Integrar y fortalecer la corrección

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 5 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Eliminar diferencias de formato, manejo de errores y validación entre las cuatro carpetas.

Cierre: La batería común pasa en las cuatro versiones, los fallos esperados terminan sin bloqueos y existe un reporte reproducible.

## Trabajo de cada integrante

Integrante 1  Revisar desbordamientos y errores de asignación en C secuencial (3 h). Corregir límites de dimensión y asegurar limpieza en cada error (3 h). Entregable: C secuencial robusto y casos negativos. Ubicación: c_secuencial/src/ y tests/.

Integrante 2  Revisar errores colectivos y finalización del híbrido (3 h). Probar procesos sin filas y fallos controlados sin esperas indefinidas (3 h). Entregable: C paralelo robusto y registro de fallos. Ubicación: c_paralelo/src/ y tests/.

Integrante 3  Revisar formatos, índices y errores en Go secuencial (3 h). Corregir compatibilidad de entrada y salida frente a C (3 h). Entregable: Go secuencial consistente. Ubicación: go_secuencial/input.go.

Integrante 4  Revisar límites de workers y propiedad de buffers Go (3 h). Probar repeticiones largas y corregir bloqueos o resultados variables (3 h). Entregable: Go paralelo estable. Ubicación: go_paralelo/workers.go.

Integrante 5  Completar casos negativos del comparador y tolerancias (3 h). Calcular error máximo por versión y documentar el criterio numérico (3 h). Entregable: Informe de validación numérica. Ubicación: docs/validacion_numerica.md.

Integrante 6  Ampliar test_windows.ps1 con las pruebas matemáticas completas (3 h). Detectar fallos mediante códigos de salida y reportar el caso exacto (3 h). Entregable: Batería integral automatizada. Ubicación: scripts/test_windows.ps1.

Integrante 7  Verificar que las cuatro mediciones usan límites equivalentes (3 h). Separar validación y escritura de los intervalos medidos (3 h). Entregable: Auditoría del protocolo de tiempo. Ubicación: docs/protocolo_medicion.md.

Integrante 8  Reproducir los casos de validación en una segunda PC preparada (3 h). Analizar diferencias funcionales y resolver errores del programa (3 h). Entregable: Acta de validación independiente. Ubicación: docs/validacion_independiente.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-05.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

## Registro individual · I4 Eva · 02/11/2026

- **Participantes y horas reales:** Eva (I4). El plan contempla 3 h de revisión de límites de workers y propiedad de buffers, 3 h de repeticiones largas y corrección de bloqueos o resultados variables, 1 h de revisión cruzada a I5 (Fernando) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s05-i04-go-paralelo-estable`. La creación del pull request queda pendiente; su revisión corresponde a I3 (Giuliano) según la rotación.

- **Revisión inicial:** el tope de 1024 workers solo existía como constante local de `parseArgs`. `MultiplyParallel` aceptaba cualquier valor positivo: con `workers=1e9` intentaba reservar el vector de tiempos (unos 8 GB) y lanzar mil millones de goroutines, en lugar de devolver un error. Además, las precondiciones de `multiplyParallelKernel` (un slot de tiempo por worker, N*N elementos en A, B y C, y C sin memoria compartida con A/B) solo estaban documentadas: al violarlas se producía un *panic* de índice o un C corrupto, no un error. El reparto ya era determinista (un escritor por fila, orden `i,k,j`), pero las pruebas comparaban solo con tolerancia y con 5 a 10 repeticiones.

- **Cambios:** en [workers.go](../../go_paralelo/workers.go) añadí `MaxWorkers` (1024) como tope único para la API y la CLI, `validateWorkers` y `validateKernelBuffers`, que comprueba en O(1) las precondiciones del kernel e incluye el solapamiento parcial entre subslices del mismo arreglo. `multiplyParallelKernel` no cambió. En [matrix.go](../../go_paralelo/matrix.go) añadí `ErrTooManyWorkers`, `ErrInvalidDurations` y `ErrBufferAlias`; `MultiplyParallel` rechaza `workers > MaxWorkers` antes de reservar memoria. En [main.go](../../go_paralelo/main.go), `parseArgs` usa `MaxWorkers` y `execute` llama a `validateKernelBuffers` antes de fijar `GOMAXPROCS` y de iniciar `total_s`, de modo que la medición no cambia. Documenté el tope, la propiedad de cada buffer y el determinismo en el [README](../../go_paralelo/README.md).

- **Pruebas y evidencias:** añadí [workers_stability_test.go](../../go_paralelo/workers_stability_test.go) sin modificar las pruebas de I3 ni de I6. Cubre repeticiones largas con igualdad bit a bit frente a W=1 (N=1, 2, 3, 17, 64, 129; tres semillas; W=1, 2, 3, 4, 8, 16, N+1 y 1024; unos 20 600 productos por corrida), ausencia de fugas de goroutines, terminación con plazo de 30 s bajo `GOMAXPROCS`=1 y 2, límites de workers en la API y la CLI, trece casos de buffers inválidos o con memoria compartida, y salidas idénticas byte a byte entre corridas del ejecutable. Resultados con Go 1.27.1 en Windows amd64, todos con código 0: `gofmt -l` sin archivos, `go vet ./...` sin avisos, `go test -count=1 ./...` (3,7 s), `go test -race -count=3 ./...` (122 s, sin carreras, con TDM-GCC 10.3.0) y la corrida larga `go test -run 'LongRepetitions|NoGoroutineLeak|Terminates|WorkerLimits|ValidateKernelBuffers|CLIRepeated' -count=5 -timeout 20m ./...` (18 s). `scripts/test_windows.ps1 -Version go_paralelo` pasó en Debug y Release, con los cinco fixtures en `max_abs=0` y `max_rel=0`. El ejecutable Release completó 250 corridas con `impar3` y 50 con N=129, seed 42 (W=1, 2, 4, 8 y 1024): todas con `validation_status=OK` y un único SHA-256 de salida por caso; `--workers 1025` terminó con código 1 en 52 ms.

- **Comprobación de las pruebas:** en una copia aparte inyecté cinco fallos en `workers.go`: no esperar a los workers, no cerrar el canal, aceptar 1025 workers, no detectar memoria compartida y no comprobar los slots de tiempo. Las pruebas nuevas fallaron en los cinco casos; el canal sin cerrar se reportó a los 30 s como "posible bloqueo".

- **Bloqueos y decisiones:** no se encontraron bloqueos ni resultados variables en el código actual; los cambios convierten precondiciones asumidas en errores verificados. El valor de workers solicitado no se reduce cuando supera N, para que el CSV conserve el valor pedido. La comprobación de solapamiento usa `unsafe.SliceData` solo para comparar direcciones y no recorre datos.

- **Revisión y criterio de aceptación:** el entregable cumple los criterios del sprint para Go paralelo: la batería pasa, los fallos esperados terminan con error y sin esperas indefinidas, y los resultados son reproducibles bit a bit. Quedan pendientes la revisión de I3 (Giuliano), mi revisión cruzada de `docs/validacion_numerica.md` de I5 (Fernando) cuando se publique, las horas reales y la aceptación del equipo.
