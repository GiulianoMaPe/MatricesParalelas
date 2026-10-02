# Contrato común de C y Go

Versión unificada: 2026-10-01. Este documento define las reglas comunes; no declara
cerrado S2 ni sustituye la revisión cruzada del equipo. Los generadores y lectores
están implementados como funciones; los ejecutables aún solo integran
`--smoke-test`, y la multiplicación y las mediciones siguen pendientes.

## Códigos de salida y errores

| Código del ejecutable | Significado |
| --- | --- |
| `0` | Operación completada. En `--smoke-test` solo confirma la instalación. |
| `1` | Argumentos o datos inválidos, desbordamiento, fallo de archivo/memoria/entorno o resultado matemático incorrecto. |
| `2` | Operación pendiente de implementación. |

Los errores se escriben en `stderr`. Una ejecución fallida no emite una matriz
parcial ni una fila de medición válida. Los resultados y métricas usan `stdout`
o el archivo explícito de salida. El lanzador puede devolver otros códigos por
fallos de MPI/sistema; el script informa el fallo y termina con 1.

Los estados internos de funciones **no son códigos de salida del ejecutable**:

| API interna | Conversión que debe realizar `main` |
| --- | --- |
| C: `MATRIX_OK`, `PARTITION_OK`, entrada con retorno 0 | Éxito: 0. |
| C: `MATRIX_PENDING`, `PARTITION_PENDING` | Pendiente: 2. |
| C: cualquier otro error matricial/de reparto, `INPUT_INVALID`, `INPUT_IO_ERROR`, `INPUT_NO_MEMORY` | Error: 1. `INPUT_IO_ERROR` vale 2 internamente y nunca significa operación pendiente. |
| Go: sin error | Éxito: 0. |
| Go: `errors.Is(err, ErrPending)` | Pendiente: 2. |
| Go: cualquier otro error | Error: 1. |

Los dos generadores Go distinguen `ErrInvalidDimension` y `ErrSizeOverflow`.
Los lectores Go devuelven `ErrInvalidFixture` para datos incorrectos y
`ErrFixtureIO` para errores de lectura. C conserva sus estados simbólicos
equivalentes. Con una dimensión válida los generadores entregan datos; no
devuelven pendiente. La CLI de S3 aplicará estas conversiones; el esqueleto
actual responde 2 a solicitudes de cálculo porque aún no integra los argumentos.

## Matrices, argumentos y memoria

- Matrices densas cuadradas N × N, N > 0, `double` en C y `float64` en Go.
- Almacenamiento contiguo por filas: posición `i*N+j`; A y B son de solo lectura.
- `--n N --seed SEED` son obligatorios para generación; semilla decimal de 32
  bits sin signo, incluidos 0 y 4294967295. Rechazar negativos y fuera de rango.
- `--input archivo` obtiene N del archivo y no se combina con `--n`/`--seed`.
  `--output archivo` guarda C en el formato común para los casos pequeños.
- Go paralelo añade `--workers W`, entero positivo. Fijar y consultar el valor
  efectivo de `GOMAXPROCS`, que no equivale al número de goroutines.
- MPI obtiene P de `mpiexec -n P`; OpenMP usa `OMP_NUM_THREADS=T` explícito y
  `OMP_DYNAMIC=FALSE`. Comprobar hilos observados. Solo el smoke test exige P=T=2.
- Comprobar N*N y sus bytes antes de multiplicar o reservar. El tamaño de cada
  matriz cabe en el entero con signo de la plataforma: `PTRDIFF_MAX` en C e
  `int` en Go, ambos de 64 bits en Windows x64. Validar además capacidad y fallos
  de reserva; el límite aritmético no garantiza RAM. MPI tiene el límite adicional
  de counts/desplazamientos `int`, definido en `partition.h`.
- El lector C devuelve dos buffers propios reservados en heap; el llamador libera
  ambos. El stream sigue siendo propiedad del llamador. Las salidas no deben
  contener reservas anteriores; con punteros de salida válidos, un error deja
  A/B en NULL y N en 0. En Go, un error devuelve matrices vacías.

## Formato de archivos

La especificación detallada está en [formato_datos.md](formato_datos.md).
UTF-8 sin BOM ni comentarios, punto decimal, LF o CRLF. La primera línea contiene
solo N; siguen exactamente N filas de A y N filas de B, con N valores por fila.
Una fila no puede repartirse ni fusionarse con otra línea. Se permiten espacios
o tabuladores dentro de la línea, espacios finales, líneas de blanco al final y
ausencia de salto final. No se permiten líneas vacías dentro de los datos.
La salida contiene N y N filas de C con las mismas reglas.

Aceptar números decimales finitos, incluidos subnormales y valores que se redondeen
a cero al convertirlos a doble precisión. Rechazar desbordamiento a infinito,
NaN, formato hexadecimal, valores faltantes/extra y errores de lectura. Ninguna
función acepta tokens después de la última fila, aunque haya suficientes valores.

## Generación equivalente

No usar `rand()` ni `math/rand`. Inicializar un solo estado `uint32` con seed.
Antes de cada elemento: `state = (1664525*state + 1013904223) mod 2^32`.
Generar A por filas y después B continuando el estado. Cada valor es
`float64(int64(state % 2001) - 1000) / 1000.0`; C usa la operación equivalente
con `uint32_t`, convirtiendo con signo antes de restar. Los vectores y matrices
de control están en `formato_datos.md` y se prueban en ambos lenguajes.

## Cálculo y concurrencia

La referencia C es independiente de MPI/OpenMP. Empezar con bucles i,k,j.
Vaciar C antes del cálculo en cada ejecución, incluido el calentamiento.

En MPI, rank 0 prepara entradas; Bcast de B, Scatterv de filas de A, OpenMP
`parallel for schedule(static)` sobre filas locales y Gatherv de C. Repartir
q=N/P y r=N%P; los primeros r ranks reciben una fila extra. P>N es válido.
Counts/desplazamientos son elementos double. Pedir y comprobar
`MPI_THREAD_FUNNELED`; cada proceso llama a MPI desde su hilo inicial, fuera de
OpenMP. Coordinar errores o abortar para evitar procesos esperando.

En Go, usar un pool fijo y canal de bloques de filas. Cada fila tiene un solo
escritor; un trabajador puede consumir varias tareas. El productor envía todas
las tareas, cierra el canal y espera con WaitGroup. Los consumidores ya deben
estar activos antes del envío; el buffer no garantiza por sí solo ausencia de
bloqueos. La implementación del cálculo corresponde a los sprints posteriores.

## Corrección y límites de medición

Comparar cada celda: `abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`.
Rechazar NaN/Inf tanto en resultado como en referencia. Un checksum no sustituye
la comparación. Los límites exactos están en [protocolo_medicion.md](protocolo_medicion.md),
sección 3, y la arquitectura debe seguirlos:

- `total_s`: entradas y buffers matriciales preparados; comienza antes de vaciar
  C y del trabajo de reparto/coordinación. Incluye creación de workers/canales,
  despacho, cálculo, cierre/espera y reunión de C. Termina antes de validación/I/O.
- `kernel_s`: solo acumulación i,k,j con C ya vaciada. Excluye vaciado, envío y
  recepción de tareas, MPI, espera del coordinador, validación e I/O. Go paralelo
  acumula los intervalos de cálculo por worker y toma el máximo; C híbrido toma
  el máximo de los tiempos locales de la región de cálculo OpenMP.
- Lectura, generación, argumentos, reserva/liberación de buffers matriciales y
  escritura de matrices/CSV quedan fuera de ambos. Go usa time.Now/Since,
  C secuencial QueryPerformanceCounter/Frequency y MPI MPI_Wtime.
- Las métricas deben ser finitas y no negativas; una ejecución fallida o pendiente
  no produce una medición aceptada. Arranque del lanzador se mide aparte.
