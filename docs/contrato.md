# Contrato inicial para implementar

Estado: especificación; los esqueletos solo aceptan `--smoke-test`. Código 0 indica
éxito de esa prueba, 1 fallo de entorno y 2 operación pendiente. Los futuros errores
de argumentos deben terminar sin medición válida y escribir en stderr.

- Matrices densas cuadradas N × N, N > 0, `double` en C y `float64` en Go.
- Almacenamiento contiguo por filas: posición `i*N+j`.
- `--n N` y `--seed SEED` obligatorios para generación; semilla entera sin signo de
  32 bits, incluidos 0 y 4294967295. Rechazar valores fuera de rango.
- Go paralelo añade `--workers W`, entero positivo. `GOMAXPROCS` se fija y registra
  aparte; no equivale al número de goroutines.
- MPI obtiene P desde `mpiexec -n P`; OpenMP usa `OMP_NUM_THREADS=T` explícito y
  `OMP_DYNAMIC=FALSE`. Comprobar hilos observados. La prueba actual exige P=T=2.
- Futuros `--input archivo` y `--output archivo` para fixtures: la dimensión procede
  del archivo y no se combinan `--input` con `--n`/`--seed`.
- Comprobar N*N, bytes, asignaciones, índices y límites de counts MPI antes de usar
  memoria. Rechazar NaN, infinitos y archivos malformados.

## Generación equivalente (propuesta precisa para S2)

No usar `rand()` de C ni `math/rand` de Go. Un solo estado `uint32` inicializado con
seed. Antes de cada elemento actualizar `state = (1664525*state + 1013904223) mod 2^32`.
Llenar A completa por filas y después B, continuando el mismo estado. Cada valor
será `float64(int64(state % 2001) - 1000) / 1000.0`; usar conversión con signo antes
de restar para evitar underflow. C usa la operación equivalente con `uint32_t`.
Para seed=42, los primeros estados son 1083814273, 378494188, 2479403867,
955863294. Estos vectores y las matrices pequeñas deberán probarse en ambos lenguajes
antes de declarar implementado el generador. El generador aún devuelve pendiente.

## Cálculo y concurrencia

La referencia C secuencial será un programa independiente, sin `/openmp` ni MPI.
Empezar con bucles i,k,j y C inicializada en cero. Ejecutar el híbrido con P=T=1
sirve para estudiar sobrecoste, no reemplaza esa referencia.

En MPI: rank 0 prepara entradas; Bcast de B, Scatterv de filas de A, OpenMP
`parallel for schedule(static)` sobre filas locales, Gatherv de C. Repartir q=N/P
y r=N%P, con una fila extra para los primeros r ranks. Probar P>N y resto distinto
de cero. Counts y desplazamientos se expresan en elementos, con límites comprobados.
Pedir `MPI_THREAD_FUNNELED`, verificar el nivel recibido y hacer llamadas MPI
en el hilo inicial fuera de las regiones OpenMP. Los errores deben coordinarse o
abortar para evitar ranks esperando indefinidamente.

En Go: pool acotado, canal de bloques de filas, un escritor por fila, A/B de solo
lectura, cierre de canales y WaitGroup. La prueba existente sincroniza goroutines,
pero todavía no reparte ni calcula filas.

## Corrección y tiempos

Comparación completa elemento a elemento:
`abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`.
Rechazar NaN e infinitos; un checksum no sustituye esta comparación.
Ver [formato de datos](formato-datos.md) y [mediciones](mediciones.md).
Separar `kernel_s` de `total_s` que incluye comunicación/coordinación; todavía
no se implementan ni se imprimen tiempos.
