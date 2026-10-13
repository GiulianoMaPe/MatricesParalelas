# c_paralelo

C híbrido MSVC x64 con /openmp y MS-MPI. La prueba --smoke-test inicializa MPI_THREAD_FUNNELED, verifica el nivel y exige dos procesos y dos hilos por proceso. Las llamadas MPI están fuera de OpenMP. input.c ya genera entradas LCG y lee fixtures; matrix.c y partition.c siguen pendientes. No existe aún distribución ni multiplicación.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_paralelo
```

Ejecutar con `scripts/run_hybrid_windows.ps1`; fija OMP_NUM_THREADS=2 y OMP_DYNAMIC=FALSE y lanza mpiexec -n 2. La tarea VS Code `MPI 2 procesos x 2 hilos` compila antes de ejecutar. No es una sesión de depuración de todos los ranks.

Debug y Release se generan en build/Debug y build/Release; build se ignora en Git.

La única ejecución exitosa actual es --smoke-test. Intentar calcular con --n/--seed devuelve 2 y no imprime resultados. Las pruebas no validan aún productos matemáticos.

Ver [instalación](../docs/instalacion-windows.md), [contrato común](../docs/contrato.md) y [fixtures](../docs/formato_datos.md). status.json declara el estado del algoritmo pendiente; actualizarlo solamente después de validar el cálculo.

El lector requiere N en su propia línea, seguido de N filas de A y N de B con N valores por fila; acepta LF/CRLF y blanco al final. Los buffers devueltos pertenecen al llamador. INPUT_INVALID, INPUT_IO_ERROR e INPUT_NO_MEMORY son estados internos: la futura CLI los convierte a salida 1, aunque INPUT_IO_ERROR valga 2. La salida 2 queda reservada a operaciones pendientes; éxito devuelve 0.

El [protocolo](../docs/protocolo_medicion.md) fija total_s entre Bcast y Gatherv, incluyendo reparto, vaciado y cálculo; kernel_s cronometra la región OpenMP con C ya vaciada. Los máximos de tiempos por proceso se reducen después de detener los relojes. La instrumentación se implementará con el algoritmo.
