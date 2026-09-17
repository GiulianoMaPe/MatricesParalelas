# c_paralelo

C híbrido MSVC x64 con /openmp y MS-MPI. La prueba --smoke-test inicializa MPI_THREAD_FUNNELED, verifica el nivel y exige dos procesos y dos hilos por proceso. Las llamadas MPI están fuera de OpenMP. matrix.c, input.c y partition.c están pendientes. No existe aún distribución ni multiplicación.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_paralelo
```

Ejecutar con `scripts/run_hybrid_windows.ps1`; fija OMP_NUM_THREADS=2 y OMP_DYNAMIC=FALSE y lanza mpiexec -n 2. La tarea VS Code `MPI 2 procesos x 2 hilos` compila antes de ejecutar. No es una sesión de depuración de todos los ranks.

Debug y Release se generan en build/Debug y build/Release; build se ignora en Git.

La única ejecución exitosa actual es --smoke-test. Intentar calcular con --n/--seed devuelve 2 y no imprime resultados. Las pruebas no validan aún productos matemáticos.

Ver [instalación](../docs/instalacion-windows.md), [contrato pendiente](../docs/contrato.md) y [fixtures](../docs/formato-datos.md). status.json declara el estado pendiente; al implementar, reemplazar las pruebas de rechazo por pruebas de corrección y actualizar el estado solamente después de validar.
