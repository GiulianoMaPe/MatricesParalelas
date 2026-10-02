# C secuencial

Completé las interfaces de S2: validación de matrices, errores y reserva y liberación de memoria. El módulo ya genera entradas y lee archivos de prueba. La multiplicación y el cronómetro quedan para S3.

## Cómo probarlo

Desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Release
```

Ejecuté ambos comandos el 01/10/2026 y pasaron. `--smoke-test` comprueba la instalación; `--n` y `--seed` todavía devuelven pendiente.

## Reglas que dejé

- Cada matriz tiene tamaño positivo, exactamente N*N valores y ningún NaN o infinito.
- Compruebo el tamaño antes de reservar memoria, con el mismo límite de Go en Windows x64.
- `matrix_allocate` requiere una matriz vacía. `matrix_release` libera sus datos y la deja vacía otra vez. Solo libero memoria propia, nunca datos prestados ni dos copias del mismo puntero.
- `matrix_multiply_checked` comprueba las entradas y la capacidad de salida. Todavía devuelve pendiente y conserva los datos.
- Los códigos de salida acordados son 0 para éxito, 1 para error y 2 para pendiente. Los códigos internos de las funciones se traducirán al integrar el programa.

Dejé los detalles de las funciones en [matrix.h](include/matrix.h) y los acuerdos en la [propuesta C/Go](../docs/especificaciones_c_go_secuencial.md). Mis evidencias están en [S2](../docs/sprints/sprint-02.md). La [revisión técnica asistida para I8](../docs/revision_i08_sprints_01_02.md), realizada el 01/10/2026, registra resultado técnico conforme y una observación pendiente sobre horas declaradas.

El [contrato común](../docs/contrato.md) y el [formato de datos](../docs/formato_datos.md) fijan N en una línea propia, N filas de A y N de B, con N valores por fila y LF/CRLF. Los errores internos INPUT_* siempre se convierten a salida 1. Según el [protocolo](../docs/protocolo_medicion.md), el vaciado de C pertenece a total_s; kernel_s solo medirá la acumulación i,k,j. Los cronómetros se implementarán en S3.
