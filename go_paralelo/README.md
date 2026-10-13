# go_paralelo

Módulo Go independiente. workers.go prueba dos goroutines sincronizadas mediante canal y WaitGroup, sin cálculos de matrices. La multiplicación sigue devolviendo ErrPending; input.go ya genera entradas LCG y lee fixtures con el contrato común. Falta integrar el pool de bloques de filas y los argumentos.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version go_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo
```

Ejecutar `go_paralelo/build/Debug/go_paralelo.exe --smoke-test`. F5 ofrece una configuración específica en VS Code.

Debug y Release se generan en build/Debug y build/Release; build se ignora en Git.

La única ejecución exitosa actual es --smoke-test. Intentar calcular con --n/--seed devuelve 2 y no imprime resultados. Las pruebas no validan aún productos matemáticos.

Ver [instalación](../docs/instalacion-windows.md), [contrato común](../docs/contrato.md) y [fixtures](../docs/formato_datos.md). status.json declara el estado del algoritmo pendiente; actualizarlo solamente después de validar el cálculo.

Generate distingue ErrInvalidDimension y ErrSizeOverflow, igual que Go secuencial. ReadMatrices requiere N en una línea propia y N filas de A y de B, con N valores por fila; acepta LF/CRLF y blanco al final. Un error devuelve matrices vacías. La futura CLI convierte éxito a 0, cualquier error a 1 y únicamente ErrPending a 2.

El [protocolo](../docs/protocolo_medicion.md) define total_s desde el vaciado de C hasta WaitGroup, incluyendo canal, workers y reparto; kernel_s será el máximo de los tiempos de cálculo acumulados por worker. Validación y escritura quedan fuera. El diseño aún debe implementarse.
