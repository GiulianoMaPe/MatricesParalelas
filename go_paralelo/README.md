# Go paralelo

El núcleo paralelo de I3 está implementado: multiplica matrices `float64` con
almacenamiento contiguo por filas, un pool acotado de goroutines y bloques
contiguos enviados por canal. La integración de argumentos, archivos y CSV en el
ejecutable corresponde a I4 y sigue pendiente. `--smoke-test` conserva la prueba
de instalación; por sí sola no verifica el producto.

## Interfaces del núcleo

| Función | Contrato |
| --- | --- |
| `Multiply(a, b)` | Conserva la firma previa y calcula con un worker. |
| `MultiplyParallel(a, b, workers)` | Valida workers, A, B y dimensiones; reserva y vacía C, ejecuta el pool, espera y valida C. Devuelve `(Matrix, error)`. |
| `ValidateDimension(n)` / `Matrix.Validate()` | Comprueban tamaño representable, longitud y valores finitos antes de lanzar goroutines. |
| `multiplyParallelKernel(a, b, c, workers, durations)` | Coordina canal, workers, reparto, cierre y espera sobre matrices preparadas. Permite medir sin incluir reservas y validaciones. |
| `dispatchRowBlocks(n, workers, tasks)` | Envía los bloques; no cierra el canal. Requiere consumidores activos o buffer suficiente. |
| `worker` / `multiplyBlock` | Consumen tareas y acumulan solo en sus filas de C usando bucles `i,k,j`. |

`MultiplyParallel` rechaza workers no positivos, dimensiones no positivas o con
desbordamiento, longitudes incorrectas, NaN/Inf y dimensiones distintas. Valida
en ese orden y devuelve una matriz vacía ante cualquier error, incluido un
resultado no finito. Los errores admiten `errors.Is`. Los errores de dimensión
son los ya definidos en `input.go`; no se duplican.

A/B son de solo lectura durante toda la llamada; el llamador tampoco debe
modificarlas concurrentemente. C tiene memoria propia. Se permite A×A, llamadas
simultáneas con las mismas entradas y llamadas repetidas con distintos workers.
La API no cambia `GOMAXPROCS`; fijarlo y registrar su valor efectivo corresponde
a la integración del ejecutable. Un tamaño representable no garantiza RAM para
las matrices, el canal o todas las goroutines; no se impone todavía un límite de
workers según el hardware ni se reduce silenciosamente el valor solicitado.

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

## Integración que queda para I4

La CLI debe validar sus opciones y preparar entradas válidas de igual dimensión
antes de invocar el núcleo. `MultiplyParallel` sirve para obtener un producto
completo, pero incluye reservas y validaciones y no debe cronometrarse como si
fuera solo el kernel.

Para instrumentar según el [protocolo](../docs/protocolo_medicion.md), reservar
C y el vector de tiempos antes de `total_s`, comprobar workers positivos, validar
A/B y su igualdad de dimensiones y reservar/calcular la referencia antes de este
fragmento. C no debe compartir almacenamiento con A/B y `durations` debe tener
exactamente workers posiciones. Las funciones internas asumen estas condiciones.

```go
c := Matrix{N: a.N, Data: make([]float64, len(a.Data))}
durations := make([]time.Duration, workers)

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
El llamador vacía C explícitamente antes de cada ejecución.

I4 puede delegar en este coordinador en lugar de duplicar la gestión del pool.
Falta integrar `--workers`, entrada generada/archivo, escritura, metadatos,
validación contra referencia y CSV. La CLI actual solo acepta `--smoke-test`;
intentar calcular con `--n/--seed` devuelve 2 y no imprime una matriz ni métricas.
La futura CLI aplica éxito=0, error=1 y operación pendiente=2.

## Cómo verificar el núcleo

Desde `go_paralelo`:

```powershell
go test -count=1 -timeout=60s ./...
go vet ./...
go test -race -count=1 -timeout=120s ./...
```

Las pruebas de I3 están en `matrix_test.go` y `workers_core_test.go`, dejando
`workers_test.go` disponible para la ampliación de I6. Cubren los cinco fixtures
con W=1,2,4,8, conteo de asignaciones por fila, límites de escritura de los
bloques, entradas preservadas, errores, resultados no finitos, workers sin
tareas, varias tareas por worker, reutilización de buffers y llamadas
simultáneas. Se repiten 720 productos para N=1,2,3,5,17,64, semillas 0,42 y
UINT32_MAX, W=1,2,4,8 y diez repeticiones, comparados con una referencia `i,j,k`.
La tolerancia es `abs(got-want) <= 1e-9 + 1e-9*abs(want)`; NaN/Inf se rechazan.

En Windows, `-race` requiere un compilador C compatible disponible para Go.
Los scripts del repositorio fijan cachés locales; si la carpeta temporal habitual
no permite escrituras, definir `GOTMPDIR` hacia una carpeta existente en `.cache/`.

Desde la raíz, comprobar también Debug y Release:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo -Configuration Release
```

El script ejecuta las pruebas Go del núcleo, además del smoke test y del rechazo
de cálculo pendiente en la CLI. La comparación de archivos y CSV del ejecutable
paralelo requiere la integración de I4 y la actualización de esas expectativas.
Debug y Release se generan en `build/`, ignorado por Git.

`status.json` distingue algoritmo implementado de validación integral pendiente;
no habilita campañas. La evidencia real y las revisiones pendientes se registran
en [Sprint 4](../docs/sprints/sprint-04.md). Ver también el
[contrato](../docs/contrato.md), [formato](../docs/formato_datos.md),
[arquitectura S2](../docs/arquitectura.md) e
[instalación Windows](../docs/instalacion-windows.md).
