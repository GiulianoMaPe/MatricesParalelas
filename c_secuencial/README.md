# c_secuencial

C secuencial independiente, sin MPI ni OpenMP. src/matrix.c e input.c devuelven MATRIX_PENDING sin modificar los buffers. timer.c deja pendiente QueryPerformanceCounter. include/ contiene las interfaces; tests/pending_test.c verifica el rechazo explícito.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_secuencial -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial
```

Ejecutar `c_secuencial/build/Debug/c_secuencial.exe --smoke-test`. F5 ofrece una configuración específica en VS Code.

Debug y Release se generan en build/Debug y build/Release; build se ignora en Git.

La única ejecución exitosa actual es --smoke-test. Intentar calcular con --n/--seed devuelve 2 y no imprime resultados. Las pruebas no validan aún productos matemáticos.

Ver [instalación](../docs/instalacion-windows.md), [contrato pendiente](../docs/contrato.md) y [fixtures](../docs/formato-datos.md). status.json declara el estado pendiente; al implementar, reemplazar las pruebas de rechazo por pruebas de corrección y actualizar el estado solamente después de validar.
