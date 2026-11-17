# C secuencial

Completé las interfaces de S2: validación de matrices, errores y reserva y liberación de memoria. El módulo ya genera entradas y lee archivos de prueba.

En S3 quedó integrado el ejecutable C secuencial: genera o lee matrices, multiplica, valida el resultado, guarda una matriz opcional y emite el CSV de métricas.

## Cómo probarlo

Desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Release
```

La validación más reciente pasó en Debug y Release. `--smoke-test` comprueba la instalación y que `timer_seconds` avance de forma monótona; `--n`/`--seed` y los cinco fixtures completan el producto y producen CSV válido.

## Lo que hace `src/main.c`

- Parsea `--n <N>` y `--seed <SEED>`; `--smoke-test` solo se acepta como único argumento.
- Acepta `--input <archivo>` en lugar de generación y `--output <archivo>` para guardar C; `--repetition 0..5` registra calentamiento y repetición.
- Rechaza argumento faltante, desconocido, duplicado, mal formado, valor no numérico, fuera de rango, `n <= 0` y el desbordamiento de `n*n` o de bytes (los mismos códigos `MATRIX_*` de `matrix.h`, sin números mágicos).
- Reserva A, B y C con `matrix_allocate` y libera todo en cada ruta de salida, incluida la falla de reserva (`MATRIX_NO_MEMORY`).
- Generación, lectura, preparación y validación independiente del producto quedan fuera de los cronómetros.
- `total_s` incluye vaciar C y calcular; `kernel_s` mide solo la acumulación i,k,j. Solo se emite `validation_status=OK` tras validar el resultado.
- Códigos de salida: 0 éxito, 1 error y 2 solo si la operación solicitada estuviera pendiente. Los errores internos `INPUT_*` se traducen a 1.

## Integración del núcleo y las métricas

`main.c` conecta `matrix_multiply_validate`, `matrix_clear` y `matrix_accumulate` de `matrix.c`. Compara el resultado con una referencia independiente antes de guardarlo o emitir la fila de métricas. La salida matricial se escribe en un temporal y se renombra solo cuando terminó correctamente.

## Evidencia de S3 (05/10/2026)

La evidencia original de esta sección corresponde al entorno registrado por el integrante. Validación posterior en este checkout: `scripts/test_windows.ps1 -Version c_secuencial` terminó con código 0 tanto en Debug como en Release con MSVC x64; pasaron las pruebas de contrato, el smoke test, el cálculo generado, la validación del CSV y los cinco fixtures comparados.

- `pending_test.exe`: pasa (contratos de dimensión, datos, memoria, LCG y fixtures).
- `--smoke-test`: salida 0, con autocomprobación del cronómetro.
- 23 casos de argumentos: `--n 0`, `--n -5`, no numérico, fuera de rango, `--seed` inválido y fuera de rango, desconocido, faltante, duplicado, sin argumentos, `overflow n*n` (`1073741824` y `4294967296`), reserva de memoria fallida (`1073741823`) y los casos válidos. Todos con el código esperado (1 ó 2).
- Fugas de memoria: binario auxiliar con `--wrap=malloc/calloc/realloc/free`. En todas las rutas `outstanding = 1 + argc`, que es la copia de argv del arranque del CRT; nuestras tres matrices suman 3 allocs y 3 frees, incluida la ruta de reserva fallida.
- Cronómetro (test auxiliar fuera del repo): `NULL` rechazado, lecturas monótonas, resolución ≈100 ns y una espera de 200 ms medida en 0.206954 s.

## Reglas que dejé

- Cada matriz tiene tamaño positivo, exactamente N*N valores y ningún NaN o infinito.
- Compruebo el tamaño antes de reservar memoria, con el mismo límite de Go en Windows x64.
- `matrix_allocate` requiere una matriz vacía. `matrix_release` libera sus datos y la deja vacía otra vez. Solo libero memoria propia, nunca datos prestados ni dos copias del mismo puntero.
- `matrix_multiply_checked` comprueba las entradas, calcula el producto y rechaza resultados no finitos. El ejecutable usa las funciones separadas para medir los límites definidos en el protocolo.
- Los códigos de salida acordados son 0 para éxito, 1 para error y 2 para una operación aún no implementada.

Dejé los detalles de las funciones en [matrix.h](include/matrix.h) y los acuerdos en la [propuesta C/Go](../docs/especificaciones_c_go_secuencial.md). Mis evidencias están en [S2](../docs/sprints/sprint-02.md). La [revisión técnica asistida para I8](../docs/revision_i08_sprints_01_02.md), realizada el 01/10/2026, registra resultado técnico conforme y una observación pendiente sobre horas declaradas.

El [contrato común](../docs/contrato.md) y el [formato de datos](../docs/formato_datos.md) fijan N en una línea propia, N filas de A y N de B, con N valores por fila y LF/CRLF. Los errores internos INPUT_* siempre se convierten a salida 1. Según el [protocolo](../docs/protocolo_medicion.md), el vaciado de C pertenece a total_s; kernel_s solo medirá la acumulación i,k,j. El cronómetro ya está implementado con `QueryPerformanceCounter`/`QueryPerformanceFrequency` en `src/timer.c` y no imprime por sí mismo.
