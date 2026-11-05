# Registro de fallos controlados · c_paralelo (Integrante 2 · Sebastian · Sprint 5)

Este documento registra los modos de fallo del híbrido C (MPI + OpenMP) y cómo el
programa los controla sin esperas indefinidas, sin salidas silenciosas y sin
bloqueos. Corresponde a la entrega del Sprint 5: "revisar errores colectivos y
finalización del híbrido" y "probar procesos sin filas y fallos controlados sin
esperas indefinidas".

## Alcance probado

Todas las comprobaciones se agregan a `tests/pending_test.c` y se ejecutan con
`scripts/test_windows.ps1 -Version c_paralelo` (compila `pending_test.c` y
`partition_test.c` sin MPI).

### 1. Partición con procesos sin filas (P > N)

**Archivo:** `tests/pending_test.c` → `check_partition_empty_rows()`

- `partition_split(3, 5, ...)` y `partition_rows(3, 5, ...)` devuelven `PARTITION_OK`.
- Los primeros 3 ranks reciben 1 fila cada uno; los ranks 3 y 4 reciben 0 filas.
- Invariante: suma de `rows[]` == N y suma de `counts[]` == N*N.
- El último desplazamiento + su `count` cubre exactamente N*N.

**Riesgo controlado:** un rank sin filas llama a `MPI_Scatterv`/`MPI_Gatherv`
con `count=0` y punteros válidos (al menos 1 elemento asignado), por lo que no
espera indefinidamente ni participa en colectivos con buffers inválidos.

### 2. Partición P = N

**Archivo:** `tests/pending_test.c` → `check_partition_p_equals_n()`

- `partition_split(4, 4, ...)` asigna exactamente 1 fila por rango,
  `first_rows[rank] == rank`, `counts[rank] == N` y
  `displacements[rank] == rank * N`.

### 3. Límites de dimensión (N > PARTITION_MAX_N)

**Archivo:** `tests/pending_test.c` → `check_partition_errors_extended()`

- `partition_split` y `partition_rows` rechazan `N = 46341` con
  `PARTITION_INVALID` y **no modifican los buffers de salida** (los valores
  centinela se conservan).
- `N = 1, P = 1` es válido y cubre la única fila.

### 4. Núcleo local con local_rows = 0

**Archivo:** `tests/pending_test.c` → `check_matrix_zero_rows()`

- `matrix_accumulate_rows(..., 0, n, ...)` no modifica el bloque de C y
  reporta `observed_threads == 1` (sin entrar en la región OpenMP).

## Fallos de tiempo de ejecución (run_hybrid, main.c)

Los siguientes fallos se detectan **antes de la barrera T0** y se comunican a
todos los rangos mediante `MPI_Allreduce(..., MPI_MIN)`, por lo que ningún
rango se queda esperando en un colectivo que otro nunca alcanza:

| Fallo | Detección | Comportamiento |
|-------|-----------|----------------|
| Entrada inválida / no legible | `load_inputs` en rango 0 | `MPI_Bcast(load_status)` → todos salen con código 1 |
| N fuera de rango (N <= 0 o N > 46340) | `matrix_multiply_rows_validate` | `local_ok = 0` → `MPI_Allreduce(partition)` → salida 1 |
| Reparto de filas inválido | `partition_split` / `partition_rows` | `local_ok = 0` → `MPI_Allreduce(partition)` → salida 1 |
| Falta de memoria (A, B, C, referencia, metadatos) | `malloc` / `collect_metadata` | `local_ok = 0` → `MPI_Allreduce(memory)` → salida 1 |
| MPI call falla | `mpi_check` en cada colectivo | `MPI_Abort(MPI_COMM_WORLD, 1)` |
| Tiempos no válidos (kernel_s/total_s) | comprobación de finitud y orden | `local_ok = 0` → `MPI_Bcast(timer_status)` → salida 1 |
| Hilos observados != OMP_NUM_THREADS | `MPI_Reduce(observed_min/max)` | `local_ok = 0` → salida 1 |
| Validación numérica falla | `validate_result` en rango 0 | `local_ok = 0` → `MPI_Bcast(validation)` → salida 1 |

## Salidas de proceso

- `0` (EXIT_OK): cálculo correcto, CSV emitido, validación OK.
- `1` (EXIT_ERROR): error controlado, mensaje en stderr, sin CSV válido.
- `2` (EXIT_PENDING): reservado, no usado para el cálculo.

## Revisión cruzada pendiente

- Revisado por: Integrante 3 (Giuliano) — revisar formal y ejecutar en equipo con MSVC, Windows SDK y MS-MPI x64.
- Ejecución: `scripts/test_windows.ps1 -Version c_paralelo` (unitarias sin MPI) y ejecución híbrida con `mpiexec` (requiere MS-MPI Runtime).