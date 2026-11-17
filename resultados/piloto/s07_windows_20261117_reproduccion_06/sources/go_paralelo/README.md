# Go paralelo

El núcleo paralelo de I3 está implementado: multiplica matrices `float64` con
almacenamiento contiguo por filas, un pool acotado de goroutines y bloques
contiguos enviados por canal. El ejecutable integra argumentos, archivos, validación
contra referencia y CSV (I4, [PR #30](https://github.com/GiulianoMaPe/MatricesParalelas/pull/30)
y [PR #32](https://github.com/GiulianoMaPe/MatricesParalelas/pull/32)). `--smoke-test`
conserva la prueba de instalación; por sí sola no verifica el producto.

## Interfaces del núcleo

| Función | Contrato |
| --- | --- |
| `Multiply(a, b)` | Conserva la firma previa y calcula con un worker. |
| `MultiplyParallel(a, b, workers)` | Valida workers, A, B y dimensiones; reserva C y los tiempos, comprueba los buffers, vacía C, ejecuta el pool, espera y valida C. Devuelve `(Matrix, error)`. |
| `ValidateDimension(n)` / `Matrix.Validate()` | Comprueban tamaño representable, longitud y valores finitos antes de lanzar goroutines. |
| `MaxWorkers` | Tope único de workers (1024) para la API y la CLI. |
| `validateKernelBuffers(a, b, c, workers, durations)` | Comprueba en O(1), fuera de `total_s`, las precondiciones del kernel: `0 < workers <= MaxWorkers`, un slot de tiempo por worker, N*N elementos en A, B y C, y C sin memoria compartida con A ni con B. |
| `multiplyParallelKernel(a, b, c, workers, durations)` | Coordina canal, workers, reparto, cierre y espera sobre matrices preparadas. Permite medir sin incluir reservas y validaciones. |
| `dispatchRowBlocks(n, workers, tasks)` | Envía los bloques canónicos de `ceil(N/workers)` filas; no cierra el canal. Requiere consumidores activos o buffer suficiente. |
| `multiplyParallelKernelBlocks` / `dispatchRowBlocksOfSize` | Igual que las anteriores, pero con un tamaño de bloque explícito. Solo las usa la [comparativa de granularidad](../docs/granularidad_go.md); el ejecutable usa siempre el bloque canónico. |
| `worker` / `multiplyBlock` | Consumen tareas y acumulan solo en sus filas de C usando bucles `i,k,j`. |

`MultiplyParallel` rechaza workers no positivos (`ErrInvalidWorkers`) o mayores
que `MaxWorkers` (`ErrTooManyWorkers`), dimensiones no positivas o con
desbordamiento, longitudes incorrectas, NaN/Inf y dimensiones distintas. Valida
en ese orden, antes de reservar el vector de tiempos o lanzar goroutines, y
devuelve una matriz vacía ante cualquier error, incluido un resultado no finito.
Los errores admiten `errors.Is`. Los errores de dimensión son los ya definidos
en `input.go`; no se duplican.

A/B son de solo lectura durante toda la llamada; el llamador tampoco debe
modificarlas concurrentemente. C tiene memoria propia. Se permite A×A, llamadas
simultáneas con las mismas entradas y llamadas repetidas con distintos workers.
La API no cambia `GOMAXPROCS`; fijarlo y registrar su valor efectivo corresponde
a la integración del ejecutable. Un tamaño representable no garantiza RAM para
las matrices, el canal o todas las goroutines. El número de workers se acota con
`MaxWorkers` (1024), el mismo tope de `--workers`, pero no se ajusta al hardware
ni se reduce silenciosamente: con workers>N los sobrantes terminan sin tareas y el
CSV registra el valor solicitado.

## Propiedad de buffers

| Buffer | Propietario | Quién escribe |
| --- | --- | --- |
| A, B | Llamador | Nadie durante la llamada; los workers solo leen. Pueden ser la misma matriz. |
| C | Llamador (`MultiplyParallel` o `execute` la reservan) | Cada worker, solo en las filas de sus bloques; nunca comparte memoria con A/B. |
| `durations` | Llamador, con exactamente workers slots | Cada worker, solo su slot y antes de `Done`; se lee tras `Wait`. |
| Canal `tasks` | `multiplyParallelKernel` | El coordinador envía y cierra una vez; los workers solo reciben. |

`validateKernelBuffers` convierte estas condiciones en errores en lugar de
*panics* de índice o resultados corruptos. Se detecta el solapamiento parcial
entre subslices del mismo arreglo, no solo la igualdad de punteros.

## Determinismo

Cada celda de C la calcula un único worker con el mismo orden `i,k,j` sea cual
sea W, así que el resultado es idéntico bit a bit para cualquier número de
workers y en cada repetición. Las pruebas de estabilidad lo comprueban con
`math.Float64bits`, no solo con tolerancia.

## Reparto y sincronización

`Task` contiene `StartRow` inclusiva y `EndRow` exclusiva. El bloque tiene tamaño
`ceil(N/workers)`, calculado mediante división y resto para evitar desbordamiento.
El extremo final se limita a N mediante la diferencia `N-start`, sin sumar fuera
del rango de `int`. La partición cubre `[0,N)` exactamente una vez.

El coordinador crea un canal de capacidad workers, registra todos los workers
con `Add`, los lanza, envía los bloques, cierra el canal una vez y llama a `Wait`.
Cada consumidor usa `defer Done`. Cada fila tiene un único escritor; A/B no se
copian por worker y no hay mutex por celda. Con workers>N se envían tareas de una
fila; un worker puede consumir varias y otros pueden no recibir ninguna. Todos
terminan al cerrarse el canal.

## Medición desde el ejecutable

La CLI valida sus opciones y prepara entradas válidas de igual dimensión antes
de invocar el núcleo. `MultiplyParallel` sirve para obtener un producto completo,
pero incluye reservas y validaciones y no debe cronometrarse como si fuera solo
el kernel.

Para instrumentar según el [protocolo](../docs/protocolo_medicion.md), validar
A/B y su igualdad de dimensiones y calcular la referencia; después reservar C y
el vector de tiempos y llamar a `validateKernelBuffers`, todo antes de fijar
`GOMAXPROCS` y de iniciar `total_s`. `execute` en `main.go` sigue este orden.

```go
c := Matrix{N: a.N, Data: make([]float64, len(a.Data))}
durations := make([]time.Duration, workers)
if err := validateKernelBuffers(a, b, c, workers, durations); err != nil {
    return err
}

totalStart := time.Now()
clear(c.Data)
multiplyParallelKernel(a, b, c, workers, durations)
total := time.Since(totalStart)

var kernel time.Duration
for _, elapsed := range durations {
    if elapsed > kernel {
        kernel = elapsed
    }
}
// Después de detener total: validar C contra la referencia, escribir matriz/CSV.
```

El kernel local mide solo `multiplyBlock`, acumulado por worker. Cada slot tiene
un único escritor y se publica antes de `Done`; se consulta tras `Wait`.
Un worker sin tareas escribe cero, incluso al reutilizar el vector. El máximo
se calcula después de detener `total_s`. Canal, goroutines, despacho, cierre y
espera pertenecen a `total_s`; la recepción de tareas queda fuera del kernel.
El llamador vacía C explícitamente antes de cada ejecución. La CLI devuelve
éxito=0, error=1 y operación pendiente=2.

## Cómo verificar el núcleo

Desde `go_paralelo`:

```powershell
go test -count=1 -timeout=60s ./...
go vet ./...
go test -race -count=1 -timeout=120s ./...
```

Las pruebas de equivalencia y del núcleo están en `matrix_test.go` y
`workers_core_test.go`; las pruebas asignadas a I6 están en `workers_test.go`.
Cubren los cinco fixtures con W=1,2,4,8, conteo de asignaciones por fila,
límites de escritura de los bloques, entradas preservadas, errores, resultados
no finitos, workers sin tareas, varias tareas por worker y reutilización de
buffers. I6 añade verificación de filas calculadas una sola vez, llamadas
concurrentes terminadas y productos repetidos para seis tamaños, tres semillas
y cuatro cantidades de workers: 720 productos comparados con una referencia
`i,j,k`, diez repeticiones por combinación. La tolerancia es
`abs(got-want) <= 1e-9 + 1e-9*abs(want)`; NaN/Inf se rechazan.

`workers_stability_test.go` (I4, S5) añade:
- repeticiones largas con igualdad bit a bit frente a W=1, para N=1..129, tres
  semillas y W=1,2,3,4,8,16,N+1,1024;
- ausencia de fugas de goroutines tras cientos de llamadas;
- terminación con plazo de 30 s bajo `GOMAXPROCS`=1 y 2, de modo que un bloqueo
  se reporta como fallo y no como cuelgue;
- límites de workers en la API y la CLI;
- rechazo de buffers inválidos o con memoria compartida;
- archivos de salida idénticos byte a byte entre corridas del ejecutable.

`-short` divide las repeticiones entre 10. Para la corrida larga:

```powershell
go test -run 'LongRepetitions|NoGoroutineLeak|Terminates' -count=5 -timeout 20m ./...
```

En Windows, `-race` requiere un compilador C compatible disponible para Go.
Los scripts del repositorio fijan cachés locales; si la carpeta temporal habitual
no permite escrituras, definir `GOTMPDIR` hacia una carpeta existente en `.cache/`.

Desde la raíz, comprobar también Debug y Release:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo -Configuration Release
```

El script ejecuta las pruebas Go, el smoke test, los cinco fixtures con el
ejecutable (incluido workers>filas) y la validación del CSV. Debug y Release se
generan en `build/`, ignorado por Git.

`status.json` distingue algoritmo implementado de validación integral pendiente;
no habilita campañas. La evidencia real y las revisiones pendientes se registran
en [Sprint 4](../docs/sprints/sprint-04.md). Ver también el
[contrato](../docs/contrato.md), [formato](../docs/formato_datos.md),
[arquitectura S2](../docs/arquitectura.md) e
[instalación Windows](../docs/instalacion-windows.md).
