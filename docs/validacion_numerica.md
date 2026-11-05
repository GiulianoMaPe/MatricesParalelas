# Informe de validación numérica — Sprint 5, I5

**Responsable:** Fernando Saire (Integrante 5)
**Rama:** `feature/s05-i05-validacion-numerica`
**Comparador:** [`scripts/compare_results.ps1`](../scripts/compare_results.ps1)
**Pruebas del comparador:** [`tests/compare_results_test.ps1`](../tests/compare_results_test.ps1)

## Alcance y procedencia de la evidencia

Este informe reúne la validación numérica de las cuatro implementaciones. I5 reprodujo las pruebas de Go y del comparador; su entorno no tenía MSVC configurado y no se instaló software. El 04/11/2026, I4 (Eva) completó en otra PC la reproducción de C secuencial y C paralelo y la ejecución conjunta de las cuatro versiones sobre el commit `6c76be6` de esta rama (véase [Reproducción de C y ejecución conjunta](#reproducción-de-c-y-ejecución-conjunta)).

## Criterio numérico

Para cada celda se calculan:

- Error absoluto: `abs(obtenido - esperado)`.
- Error relativo: `abs(obtenido - esperado) / abs(esperado)` cuando el esperado es distinto de cero.
- Error máximo absoluto y relativo: máximo de esas medidas sobre todas las celdas de la matriz.

Una celda se acepta si cumple:

```text
abs(obtenido - esperado) <= atol + rtol * abs(esperado)
atol = 1e-9
rtol = 1e-9
```

Cuando el esperado es cero, el término relativo no aporta tolerancia y la aceptación depende de `atol`. Si la diferencia es distinta de cero, el comparador informa `max_rel=Infinity` porque no se puede dividir por cero; esto no implica por sí solo rechazo. El resultado de aceptación se decide con la desigualdad combinada. `NaN`, infinitos, formato inválido o dimensiones incompatibles se rechazan.

## Casos comprobados y resultados

En la sesión actual se ejecutaron `scripts/test_windows.ps1` para Go secuencial y paralelo en Debug. Ambas ejecuciones pasaron sus pruebas Go y compararon los cinco fixtures (`escalar`, `identidad`, `cero`, `producto2`, `impar3`) con código de salida 0. Para cada salida se observó `max_abs=0` y `max_rel=0`.

| Versión | Estado/evidencia | Error máximo absoluto | Error máximo relativo |
| --- | --- | ---: | ---: |
| Go secuencial | Reproducido por I5 (Debug) y por I4 en la ejecución conjunta (Debug y Release); 5 fixtures | 0 | 0 |
| Go paralelo | Reproducido por I5 (Debug) y por I4 en la ejecución conjunta (Debug y Release); 5 fixtures | 0 | 0 |
| C secuencial | Reproducido por I4 el 04/11/2026 en Debug y Release; 5 fixtures | 0 | 0 |
| C paralelo (MPI/OpenMP) | Reproducido por I4 el 04/11/2026 en Debug y Release; 9 configuraciones P/T por compilación, incluidos P=1, P>N y reparto no divisible | 0 | 0 |

La evidencia previa de `docs/equivalencia.md` registra los cinco fixtures para C secuencial y C paralelo, y casos adicionales de concurrencia. También registra comparaciones cruzadas del producto LCG de semilla 42. En los casos allí reportados los máximos fueron cero. La ejecución conjunta de las cuatro versiones en un mismo entorno, descrita al final de este informe, confirmó esos máximos.

## Casos negativos del comparador

La suite automatizada verifica aceptación dentro de tolerancia y rechazo fuera de tolerancia; dimensión distinta; `NaN` e infinito; cantidad incorrecta de valores; BOM, NUL, UTF-8 inválido y CR aislado; archivo vacío, fila vacía, fila sobrante y archivo inexistente. También verifica CRLF válido y espacios permitidos.

Se añadió una prueba específica para valor esperado cero: una diferencia de `5e-10` debe aceptarse por la tolerancia absoluta (`1e-9`) aunque el error relativo máximo se reporte como infinito. Esto hace explícita la distinción entre la métrica relativa y el criterio combinado de aceptación.

## Reproducción

Desde la raíz del repositorio, en Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\compare_results_test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_paralelo -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Release
```

C requiere MSVC x64, Windows SDK y, para C paralelo, MS-MPI Runtime y SDK; `scripts/check_env_windows.ps1` confirma las dependencias antes de compilar.

## Reproducción de C y ejecución conjunta

En el entorno de I5 la ejecución conjunta no pudo completar C porque MSVC no estaba configurado. I4 (Eva) la completó el 04/11/2026 sobre el commit `6c76be6` de esta rama, con Windows 11 Pro x64 (build 26200), MSVC x64 14.43.34808 (Visual Studio 2022 Community 17.13.5), Windows SDK 10.0.26100.0, MS-MPI Runtime y SDK 10.1.12498.52 y Go 1.27.1 windows/amd64. `check_env_windows.ps1` detectó todas las dependencias.

| Comando | Debug | Release |
| --- | --- | --- |
| `test_windows.ps1 -Version c_secuencial` | código 0; 5 fixtures | código 0; 5 fixtures |
| `test_windows.ps1 -Version c_paralelo` | código 0; 9 configuraciones | código 0; 9 configuraciones |
| `test_windows.ps1 -Version all` | código 0; 24 comparaciones | código 0; 24 comparaciones |

En C paralelo pasaron también `pending_test.exe` (8 ejemplos de reparto y 4480 pares N/P), `partition_test.exe`, el smoke test MPI/OpenMP y la comprobación del CSV. Las nueve configuraciones por compilación fueron los cinco fixtures con P=2 y T=2, más `impar3` con P=1/T=2, P=2/T=1 y P=5/T=1, y `producto2` con P=3/T=1. La ejecución conjunta compara 5 fixtures por cada versión secuencial y Go paralelo, más las 9 configuraciones de C paralelo: 24 comparaciones por compilación. Todas, en Debug y en Release, dieron `max_abs=0` y `max_rel=0`, y las cuatro baterías terminaron con su mensaje `OK`. No hubo diferencias que requirieran evaluar la tolerancia.
