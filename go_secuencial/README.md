# go_secuencial

Módulo Go independiente. `Multiply` comprueba sus matrices y `Generate` comprueba el tamaño. Ambas funciones devuelven un error si la entrada no es válida y `ErrPending` si es válida. `smoke.go` únicamente comprueba ejecución. El cálculo todavía está pendiente.

## Uso desde la raíz

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version go_secuencial -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial
```

Ejecutar `go_secuencial/build/Debug/go_secuencial.exe --smoke-test`. F5 ofrece una configuración específica en VS Code.

Debug y Release se generan en build/Debug y build/Release; build se ignora en Git.

La única ejecución exitosa actual es --smoke-test. Intentar calcular con --n/--seed devuelve 2 y no imprime resultados. Las pruebas no validan aún productos matemáticos.

Ver [instalación](../docs/instalacion-windows.md), [contrato pendiente](../docs/contrato.md) y [fixtures](../docs/formato_datos.md). status.json declara el estado pendiente; al implementar, reemplazar las pruebas de rechazo por pruebas de corrección y actualizar el estado solamente después de validar.

## Interfaces de Sprint 2

- `ValidateDimension(n)` revisa que el tamaño sea positivo y que la cantidad de elementos y sus bytes quepan en un entero. No reserva memoria ni garantiza que haya suficiente RAM.
- `Matrix.Validate()` revisa el tamaño, la cantidad exacta de datos y que no haya NaN ni infinitos. Acepta ceros y negativos. Los valores se guardan fila por fila.
- `Multiply(a, b)` revisa A, luego B y después que ambas tengan el mismo tamaño. No modifica sus entradas. Ante un error devuelve una matriz vacía; con entradas válidas sigue devolviendo `ErrPending` hasta implementar el cálculo en Sprint 3.
- `Generate(n, seed)` revisa N con la misma regla. La semilla es `uint32`, por lo que acepta 0 y 4294967295. Con un tamaño válido sigue devolviendo `ErrPending` y dos matrices vacías.

Los errores pueden comprobarse con `errors.Is`:

| Error | Qué indica |
| --- | --- |
| `ErrInvalidDimension` | El tamaño es cero o negativo. |
| `ErrSizeOverflow` | La cantidad de elementos o sus bytes excede los límites del entero. |
| `ErrInvalidDataLength` | Faltan o sobran datos para el tamaño indicado. |
| `ErrNonFiniteValue` | Hay NaN o infinito. |
| `ErrDimensionMismatch` | A y B tienen tamaños diferentes. |
| `ErrPending` | Las entradas son válidas, pero la operación sigue pendiente. |

### Contrato de argumentos para la integración

Estas reglas proceden de `docs/contrato.md`; el ejecutable aún solo acepta `--smoke-test`:

- Generación: `--n N` y `--seed SEED` obligatorios. N debe pasar `ValidateDimension`; la semilla debe ser un entero entre 0 y 4294967295. La función `Generate` recibe la semilla como `uint32`; comprobar el rango del texto corresponde al futuro procesamiento de argumentos.
- Archivo: `--input archivo` obtiene N del archivo y no se combina con `--n` ni `--seed`. `--output archivo` permite guardar una matriz pequeña.
- Para la futura integración, la propuesta de I3 fija: código 0 para éxito, 1 para entrada incorrecta o fallo de archivos, memoria o entorno, y 2 para una operación pendiente. Los errores van a `stderr` y no producen mediciones válidas.

La propuesta completa para I1 está en [especificaciones C/Go secuencial](../docs/especificaciones_c_go_secuencial.md), incluidos los límites y los casos de control. Falta la confirmación de I1 y la revisión de I2; estas reglas todavía no declaran una implementación terminada de C ni del procesamiento de argumentos.
