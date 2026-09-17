# go_paralelo

Módulo Go independiente. workers.go prueba dos goroutines sincronizadas mediante canal y WaitGroup, sin cálculos de matrices. matrix.go e input.go devuelven ErrPending. Falta el pool de bloques de filas y el argumento --workers.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version go_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo
```

Ejecutar `go_paralelo/build/Debug/go_paralelo.exe --smoke-test`. F5 ofrece una configuración específica en VS Code.

Debug y Release se generan en build/Debug y build/Release; build se ignora en Git.

La única ejecución exitosa actual es --smoke-test. Intentar calcular con --n/--seed devuelve 2 y no imprime resultados. Las pruebas no validan aún productos matemáticos.

Ver [instalación](../docs/instalacion-windows.md), [contrato pendiente](../docs/contrato.md) y [fixtures](../docs/formato-datos.md). status.json declara el estado pendiente; al implementar, reemplazar las pruebas de rechazo por pruebas de corrección y actualizar el estado solamente después de validar.
