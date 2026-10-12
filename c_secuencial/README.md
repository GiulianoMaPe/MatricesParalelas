# C secuencial

Completé las interfaces de S2: validación de matrices, errores y reserva y liberación de memoria. El módulo ya genera entradas y lee archivos de prueba.

En S3 dejé integrados los argumentos (`--n`, `--seed`) y el cronómetro en `src/main.c` y `src/timer.c`. La multiplicación sigue pendiente del PR #19.

## Cómo probarlo

Desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Release
```

Ejecuté ambos comandos el 01/10/2026 y pasaron. `--smoke-test` comprueba la instalación y ahora además comprueba que `timer_seconds` avance de forma monótona; `--n` y `--seed` todavía devuelven pendiente (código 2) porque el núcleo del PR #19 aún no está en `main`.

## Lo que hace `src/main.c`

- Parsea `--n <N>` y `--seed <SEED>`; `--smoke-test` solo se acepta como único argumento.
- Rechaza argumento faltante, desconocido, duplicado, mal formado, valor no numérico, fuera de rango, `n <= 0` y el desbordamiento de `n*n` o de bytes (los mismos códigos `MATRIX_*` de `matrix.h`, sin números mágicos).
- Reserva A, B y C con `matrix_allocate` y libera todo en cada ruta de salida, incluida la falla de reserva (`MATRIX_NO_MEMORY`).
- Genera A y B fuera de los cronómetros, valida antes de cualquier temporización y no escribe en C durante la validación.
- Códigos de salida: 0 éxito, 1 error, 2 pendiente. Los errores internos `INPUT_*` se traducen a 1.

## Lo que falta (dependencia del PR #19)

`matrix.h` en esta rama no declara `matrix_multiply_validate`, `matrix_clear` ni `matrix_accumulate`, así que `kernel_s` y `total_s` todavía no se pueden medir. No dupliqué ni inventé el núcleo: el flujo exacto a cablear (límites de `total_s` y `kernel_s` de `docs/protocolo_medicion.md` §3.1–3.3, comprobación de `kernel_s <= total_s` y salida de resultados) está documentado en el comentario del paso de multiplicación de `src/main.c`.

## Evidencia de S3 (05/10/2026)

Mi equipo no tiene MSVC instalado, así que `build_windows.ps1`/`test_windows.ps1` no pudieron ejecutarse aquí; compilé con GCC 16.2 (w64devkit portátil, fuera del repositorio) usando los mismos avisos estrictos: `-std=c11 -Wall -Wextra -Wpedantic -Wconversion -Wshadow -Werror -O2`, sin un solo aviso. Queda pendiente repetir la compilación con MSVC x64 en una máquina con el toolchain del proyecto.

- `pending_test.exe`: pasa (contratos de dimensión, datos, memoria, LCG y fixtures).
- `--smoke-test`: salida 0, con autocomprobación del cronómetro.
- 23 casos de argumentos: `--n 0`, `--n -5`, no numérico, fuera de rango, `--seed` inválido y fuera de rango, desconocido, faltante, duplicado, sin argumentos, `overflow n*n` (`1073741824` y `4294967296`), reserva de memoria fallida (`1073741823`) y los casos válidos. Todos con el código esperado (1 ó 2).
- Fugas de memoria: binario auxiliar con `--wrap=malloc/calloc/realloc/free`. En todas las rutas `outstanding = 1 + argc`, que es la copia de argv del arranque del CRT; nuestras tres matrices suman 3 allocs y 3 frees, incluida la ruta de reserva fallida.
- Cronómetro (test auxiliar fuera del repo): `NULL` rechazado, lecturas monótonas, resolución ≈100 ns y una espera de 200 ms medida en 0.206954 s.

## Reglas que dejé

- Cada matriz tiene tamaño positivo, exactamente N*N valores y ningún NaN o infinito.
- Compruebo el tamaño antes de reservar memoria, con el mismo límite de Go en Windows x64.
- `matrix_allocate` requiere una matriz vacía. `matrix_release` libera sus datos y la deja vacía otra vez. Solo libero memoria propia, nunca datos prestados ni dos copias del mismo puntero.
- `matrix_multiply_checked` comprueba las entradas y la capacidad de salida. Todavía devuelve pendiente y conserva los datos.
- Los códigos de salida acordados son 0 para éxito, 1 para error y 2 para pendiente. Los códigos internos de las funciones se traducirán al integrar el programa.

Dejé los detalles de las funciones en [matrix.h](include/matrix.h) y los acuerdos en la [propuesta C/Go](../docs/especificaciones_c_go_secuencial.md). Mis evidencias están en [S2](../docs/sprints/sprint-02.md). La [revisión técnica asistida para I8](../docs/revision_i08_sprints_01_02.md), realizada el 01/10/2026, registra resultado técnico conforme y una observación pendiente sobre horas declaradas.

El [contrato común](../docs/contrato.md) y el [formato de datos](../docs/formato_datos.md) fijan N en una línea propia, N filas de A y N de B, con N valores por fila y LF/CRLF. Los errores internos INPUT_* siempre se convierten a salida 1. Según el [protocolo](../docs/protocolo_medicion.md), el vaciado de C pertenece a total_s; kernel_s solo medirá la acumulación i,k,j. El cronómetro ya está implementado con `QueryPerformanceCounter`/`QueryPerformanceFrequency` en `src/timer.c` y no imprime por sí mismo.
