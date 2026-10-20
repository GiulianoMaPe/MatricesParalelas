# c_paralelo

Híbrido C con MSVC x64, MS-MPI y OpenMP. El ejecutable ya implementa el reparto de filas con `MPI_Scatterv`, la difusión de B con `MPI_Bcast`, el cálculo local con OpenMP y la recolección de C con `MPI_Gatherv`. La validación se hace en el rango 0 contra una referencia secuencial antes de imprimir el CSV.

La integración se apoya en `MPI_THREAD_FUNNELED`: todas las llamadas MPI ocurren en el hilo que inicializó MPI y fuera de la región OpenMP. El núcleo local usa orden `i,k,j`, variables de fila privadas y una escritura disjunta por fila.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_paralelo
```

Para una ejecución manual, `scripts/run_hybrid_windows.ps1` fija `OMP_NUM_THREADS`, exige `OMP_DYNAMIC=FALSE` y lanza `mpiexec`:

```powershell
# Producto generado con LCG
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1 `
    -Configuration Debug -Processes 2 -Threads 2 -N 512 -Seed 42 -OutputPath .\producto.txt

# Fixture compartido
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1 `
    -Configuration Debug -Processes 3 -Threads 1 `
    -InputPath .\tests\fixtures\producto2.input.txt -OutputPath .\producto2.output.txt

# Prueba de instalación: exige exactamente P=2 y T=2
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1 -Configuration Debug -SmokeTest
```

También se puede invocar directamente, siempre con las dos variables de OpenMP:

```powershell
$env:OMP_NUM_THREADS = '2'
$env:OMP_DYNAMIC = 'FALSE'
mpiexec -n 2 .\c_paralelo\build\Debug\c_paralelo.exe --n 512 --seed 42 --output .\producto.txt
```

La CLI acepta `--n N --seed S`, `--input archivo`, `--output archivo`, `--repetition 0..5` y `--smoke-test`. `--input` no se combina con `--n/--seed`. En éxito devuelve 0 e imprime las 20 columnas del protocolo en `stdout` desde el rango 0; cualquier error devuelve 1 y no imprime una medición válida. La salida 2 sigue reservada a operaciones pendientes y ya no se usa para el cálculo.

## Flujo híbrido

1. El rango 0 lee el fixture o genera A y B con el LCG, prepara la referencia `i,j,k` y difunde N y B.
2. Todos los rangos calculan el mismo reparto con `partition_split` y `partition_rows`; el rango 0 envía bloques de filas de A con `MPI_Scatterv`.
3. Cada rango vacía su bloque local de C dentro de `total_s`, ejecuta la región OpenMP y mide `kernel_s` solo alrededor de esa región.
4. `MPI_Gatherv` reúne C en el rango 0; después se reducen los máximos de `kernel_s`/`total_s` y se comprueba que los hilos observados coincidan con `OMP_NUM_THREADS`.
5. El rango 0 valida C contra una referencia `i,j,k`, escribe la matriz si se pidió `--output` y emite el CSV.

`total_s` empieza después de la barrera inicial, antes de `MPI_Bcast`, y termina después de `MPI_Gatherv`. La referencia de validación se calcula antes de esa barrera. `kernel_s` no incluye lectura, generación, validación, E/S ni el vaciado de C.

## Límites y estado

- `N <= 46340` para que `N*N` y los `counts`/desplazamientos de MPI quepan en `int`.
- El cálculo exige `OMP_NUM_THREADS` positivo y `OMP_DYNAMIC=FALSE`; el runner los fija.
- `--smoke-test` exige 2 procesos y 2 hilos por proceso.
- `partition.c` implementa la división documentada en `include/partition.h`: los primeros `N % P` rangos reciben una fila extra y los rangos sin filas usan `count=0`.
- `matrix.c` implementa el núcleo local; `main.c` implementa la CLI, la comunicación MPI, los tiempos, la validación y el CSV.
- `status.json` marca `algorithm=implemented` y `validation=pending`: la compilación y las pruebas de runtime deben repetirse en un equipo con MSVC, Windows SDK y MS-MPI instalados. En el equipo donde se escribió esta integración no estaban disponibles esas herramientas.

## Pruebas

`scripts/test_windows.ps1 -Version c_paralelo` compila el módulo, ejecuta `tests/pending_test.c` y luego:

- `--smoke-test` con 2 procesos y 2 hilos;
- los cinco fixtures con P=2/T=2;
- P=1, P=2 con N=3 (partición no divisible) y P>N con N=1, 2 y 3;
- un CSV con N=2, seed=42, comprobando procesos, hilos solicitados/observados, configuración, commit, estado y tiempos.

El test unitario cubre los ocho ejemplos de partición, 4480 pares N/P, las fronteras 46340/46341, la generación LCG, los fixtures y el núcleo local por filas. La comprobación independiente del diseño se puede repetir con `scripts/verify_partition_design.ps1`.

Ver [instalación](../docs/instalacion-windows.md), [contrato común](../docs/contrato.md), [formato de datos](../docs/formato_datos.md) y [protocolo](../docs/protocolo_medicion.md). El lector exige N en su propia línea, seguido de N filas de A y N de B; acepta LF/CRLF y blanco al final. `INPUT_INVALID`, `INPUT_IO_ERROR` e `INPUT_NO_MEMORY` son estados internos y la CLI los convierte a salida 1.

## Reparto de responsabilidades

- I1 (Yessly): `partition.c` y la comunicación `Scatterv`/`Gatherv` en `main.c`, con las pruebas de P=1, P>N y particiones no divisibles.
- I2 (Sebastian): integración OpenMP en `matrix.c`, verificación de `MPI_THREAD_FUNNELED`, variables privadas y ausencia de MPI dentro de la región paralela. La base ya está integrada; falta la revisión formal y la ejecución en el entorno MSVC/MS-MPI.

## Checklist de revisión de I2

- [ ] `MPI_Init_thread` pide `MPI_THREAD_FUNNELED` y `provided >= MPI_THREAD_FUNNELED`.
- [ ] No hay ninguna llamada MPI dentro de `matrix_accumulate_rows` ni de la región OpenMP.
- [ ] `i` es la variable del bucle `omp for`; `k`, `j`, `a_row`, `b_row` y `c_row` se declaran dentro del cuerpo y son privados.
- [ ] `observed_threads` se obtiene con `omp_get_num_threads()` y coincide con `OMP_NUM_THREADS` en todos los rangos.
- [ ] `kernel_s` es el máximo de las duraciones locales; un rango sin filas reporta `0`.
- [ ] Repetir `scripts/test_windows.ps1 -Version c_paralelo` en un equipo con MSVC, Windows SDK y MS-MPI x64.
