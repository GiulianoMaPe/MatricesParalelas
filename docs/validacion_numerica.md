# Informe de validación numérica — Sprint 5, I5

**Responsable:** Fernando Saire (Integrante 5)  
**Rama:** `feature/s05-i05-validacion-numerica`  
**Comparador:** [`scripts/compare_results.ps1`](../scripts/compare_results.ps1)  
**Pruebas del comparador:** [`tests/compare_results_test.ps1`](../tests/compare_results_test.ps1)

## Alcance y procedencia de la evidencia

Este informe reúne la validación numérica disponible para las cuatro implementaciones. Las pruebas de Go y del comparador se reprodujeron en esta sesión. Los datos de C se toman de los reportes previos citados en la tabla y no se presentan como una reproducción local de Sprint 5: el entorno disponible no tiene MSVC configurado y no se instaló software.

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
| Go secuencial | Reproducido en esta sesión; 5 fixtures | 0 | 0 |
| Go paralelo | Reproducido en esta sesión; 5 fixtures | 0 | 0 |
| C secuencial | Evidencia previa: `docs/equivalencia.md`, tabla de fixtures | 0 | 0 |
| C paralelo (MPI/OpenMP) | Evidencia previa: `docs/equivalencia.md` y `c_paralelo/tests/reporte_particionado.md` | 0 | 0 |

La evidencia previa de `docs/equivalencia.md` registra los cinco fixtures para C secuencial y C paralelo, y casos adicionales de concurrencia. También registra comparaciones cruzadas del producto LCG de semilla 42. En los casos allí reportados los máximos fueron cero. Los resultados de los cuatro lenguajes/configuraciones no sustituyen una nueva ejecución conjunta en un mismo entorno.

## Casos negativos del comparador

La suite automatizada verifica aceptación dentro de tolerancia y rechazo fuera de tolerancia; dimensión distinta; `NaN` e infinito; cantidad incorrecta de valores; BOM, NUL, UTF-8 inválido y CR aislado; archivo vacío, fila vacía, fila sobrante y archivo inexistente. También verifica CRLF válido y espacios permitidos.

Se añadió una prueba específica para valor esperado cero: una diferencia de `5e-10` debe aceptarse por la tolerancia absoluta (`1e-9`) aunque el error relativo máximo se reporte como infinito. Esto hace explícita la distinción entre la métrica relativa y el criterio combinado de aceptación.

## Reproducción

Desde la raíz del repositorio, en Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\compare_results_test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo -Configuration Debug
```

## Pendiente para validación local de C

La ejecución conjunta solicitada con `scripts/test_windows.ps1 -Version all -Configuration Debug` no pudo completar C: el entorno informó que MSVC no está inicializado y `vswhere` no está disponible. La ejecución se detuvo mientras comenzaba Go secuencial. Se necesita que un integrante con Visual Studio Build Tools C++/MSVC configurado reproduzca al menos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_paralelo -Configuration Debug
```

Para C paralelo, confirmar además que MS-MPI SDK y Runtime estén disponibles. Registrar códigos de salida y `max_abs`/`max_rel` para los cinco fixtures; si difieren de cero, comprobar cada resultado contra la tolerancia, no exigir igualdad exacta.
