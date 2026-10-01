# Diagnóstico funcional: C secuencial

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)
**Sprint:** 1 · **Integrante:** 1 · **Versión analizada:** `c_secuencial`
**Estado:** completado por lectura de código y verificado por ejecución (30/09/2026); pendiente de revisión cruzada.
**Método:** lectura del código y de la documentación del repositorio, más la ejecución de los comandos de la sección 7.

---

## 1. Resumen

`c_secuencial` es un **esqueleto**: compila y responde a `--smoke-test`, pero no multiplica, no genera datos, no mide tiempo y no lee los argumentos `--n` y `--seed`. Los tres módulos de lógica (`matrix.c`, `input.c`, `timer.c`) devuelven `MATRIX_PENDING` (2) sin modificar los buffers. `status.json` declara `algorithm: pending` y `validation: pending`. El mayor riesgo es que faltan la reserva segura de memoria y los códigos de error, de los que dependen el resto de módulos.

## 2. Flujo actual de ejecución

1. `main` recibe `argc` y `argv`.
2. Si `argc == 2` y `argv[1]` es `--smoke-test`, imprime un mensaje de instalación y devuelve 0.
3. En cualquier otro caso (incluido `--n 2 --seed 42`) escribe "PENDIENTE" en stderr y devuelve 2.

`main.c` no incluye `input.h` ni `timer.h`: ningún módulo se usa desde el flujo real. Solo `tests/pending_test.c` llama a `matrix_multiply` e `input_generate`.

## 3. Inventario por módulo

| Archivo | Función o elemento | Estado | Observaciones |
| --- | --- | --- | --- |
| `src/main.c` | `main` | Parcial | Solo `--smoke-test`. Sin parseo de argumentos, memoria, generación, cronómetro, validación ni salida. |
| `src/matrix.c` | `matrix_multiply(a,b,c,n)` | Pendiente | Devuelve 2 y deja `c` intacto. |
| `src/input.c` | `input_generate(a,b,n,seed)` | Pendiente | Devuelve 2 y deja `a` y `b` intactos. |
| `src/timer.c` | `timer_seconds(&s)` | Pendiente | Devuelve 2. Incluye `matrix.h` solo para usar `MATRIX_PENDING`. |
| `include/matrix.h` | Prototipo de `matrix_multiply`, `MATRIX_PENDING` | Incompleto | El TODO menciona reserva de memoria y comprobación de desbordamiento que no existen. |
| `include/input.h` | Prototipo de `input_generate` | Incompleto | Faltan lector de `--input` y escritor de `--output`. |
| `include/timer.h` | Prototipo de `timer_seconds` | Incompleto | Un solo prototipo; la API de Windows se incluirá en `timer.c`. |
| `tests/pending_test.c` | Prueba de rechazo | Solo rechazo | Verifica que las funciones devuelven 2 y no modifican buffers (N=1). No prueba `timer_seconds`. |
| `status.json` | Estado | Pendiente | `algorithm: pending`, `validation: pending`. |

## 4. Funciones pendientes priorizadas

| Prioridad | Pendiente | Por qué bloquea o importa | Sprint sugerido |
| --- | --- | --- | --- |
| P0 | Códigos de retorno reales (`MATRIX_OK` y errores) | Hoy solo existe `MATRIX_PENDING`; sin códigos no se pueden reportar fallos. | S2 |
| P0 | Reserva segura de matrices | Calcular `n*n*sizeof(double)` con `size_t` comprobando desbordamiento y `malloc` nulo. | S2 |
| P0 | `matrix_multiply` (bucles i,k,j, `C` a cero) | Núcleo del programa. | S3 |
| P0 | `input_generate` (LCG del contrato) | Sin entradas reproducibles no hay comparación con Go. | S3 |
| P0 | `timer_seconds` con `QueryPerformanceCounter` | Sin cronómetro no hay `kernel_s` ni `total_s`. | S3 |
| P0 | `main`: parseo de `--n` y `--seed`, orquestación y salida | Une todos los módulos. | S3 |
| P1 | Lector `--input` y escritor `--output` | Necesarios para probar con fixtures. | S3 |
| P1 | Salida de métricas por stdout y errores por stderr | Contrato de salida. | S3 |
| P1 | Sustituir `pending_test.c` por pruebas de corrección | Las pruebas actuales solo comprueban el rechazo. | S3-S5 |
| P1 | Actualizar `status.json` | Solo después de validar. | S5 |

## 5. Supuestos del contrato

| Supuesto | Documento de origen | Cumplido hoy |
| --- | --- | --- |
| Matrices cuadradas N×N, N > 0, `double` | `docs/contrato.md` | No |
| Almacenamiento contiguo por filas, posición `i*N+j` | `docs/contrato.md` | No |
| Orden de bucles i,k,j y `C` inicializada a cero | `docs/contrato.md` | No |
| `--n` y `--seed` obligatorios; seed de 32 bits sin signo (0 a 4294967295) | `docs/contrato.md` | No |
| Generador: `state = (1664525*state + 1013904223) mod 2^32` antes de cada elemento; valor `(int64(state % 2001) - 1000) / 1000.0`; primero toda `A`, luego `B`, con el mismo estado | `docs/contrato.md` | No |
| Sin `rand()`, sin OpenMP, sin MPI | `docs/contrato.md` | Sí (no hay código que los use) |
| Errores por stderr, métricas por stdout, código distinto de cero al fallar | `docs/contrato.md` | Parcial (el rechazo usa stderr y código 2) |
| Comparación elemento a elemento con `abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)` | `docs/contrato.md` | No (no hay comparador) |
| `kernel_s` (triple bucle) separado de `total_s` (incluye vaciado de `C`) | `docs/protocolo_medicion.md` | No |

Comprobación a mano: con seed=42, `1664525*42 + 1013904223 = 1083814273`, igual al primer estado que indica el contrato.

## 6. Puntos de validación y riesgos

| # | Punto de validación | Riesgo o decisión pendiente | Cómo se comprobará |
| --- | --- | --- | --- |
| V1 | `n*n*sizeof(double)` | Desbordamiento de `size_t` antes del `malloc`. | Caso con N enorme que debe devolver error sin reservar. |
| V2 | Punteros nulos o `n == 0` en `matrix_multiply` | Falta definir el código de error. | Prueba negativa. |
| V3 | Solapamiento de `a`, `b` y `c` | Se supone que no se solapan; hay que documentarlo. | Revisión de la interfaz en S2. |
| V4 | Puesta a cero de `C` | Decidir si la hace `matrix_multiply` o `main`; afecta la frontera entre `kernel_s` y `total_s`. | Acuerdo en S2 y revisión del protocolo de medición. |
| V5 | Códigos de salida | `docs/contrato.md` define 0/1/2 con 1 = fallo de entorno; `docs/requisitos.md` asigna 1 también a argumentos inválidos. | Unificar en S2. |
| V6 | `scripts/test_windows.ps1` | Exige que `exe --n 2 --seed 42` devuelva 2; al implementar el cálculo esa comprobación fallará. | Reemplazarla (responsable de la batería: I6 en S5) y avisar al equipo. |
| V7 | Compilación con `/W4 /WX` | Cualquier advertencia (parámetro sin usar, conversiones `size_t`/`int`) rompe la compilación. | Compilar tras cada cambio. |
| V8 | Fixtures existentes | `escalar`, `identidad`, `cero` y `producto2` son correctos (comprobados a mano, p. ej. producto2 = 19 22 / 43 50). Faltan N impar mayor que 1 y casos de error. | Ampliar en S2 (responsable: I5). |
| V9 | `scripts/bench_windows.ps1` | Se niega a medir mientras `status.json` no diga `implemented` y `passed`. | Actualizar `status.json` solo tras validar. |

## 7. Comandos de verificación y evidencia

Comandos ejecutados desde la raíz del clon en Windows 11 (build 26200), por la Integrante 1.

| Comando | Resultado esperado | Resultado observado | Fecha |
| --- | --- | --- | --- |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1` (1.ª ejecución) | Dependencias detectadas | MSVC/Windows SDK no encontrados; faltan también MS-MPI y Go; Git 2.55.0 x64 correcto. Código 1. | 30/09/2026 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1` (2.ª ejecución, tras agregar la carga de trabajo de C++ a Visual Studio Community) | MSVC x64 y SDK detectados | MSVC 14.51.36231 x64 y Windows SDK 10.0.26100.0 detectados; Git correcto; faltan MS-MPI y Go (no requeridos por `c_secuencial`). Código 1. | 30/09/2026 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_secuencial -Configuration Debug` | Compila sin advertencias; código 0 | Compiló `input.c`, `main.c`, `matrix.c` y `timer.c` sin advertencias ni errores. Código 0. | 30/09/2026 |
| `.\c_secuencial\build\Debug\c_secuencial.exe --smoke-test` | Mensaje "OK..."; código 0 | "OK: prueba de instalacion C secuencial x64, sin MPI ni OpenMP. Algoritmo pendiente." Código 0. | 30/09/2026 |
| `.\c_secuencial\build\Debug\c_secuencial.exe --n 2 --seed 42` | Mensaje "PENDIENTE" en stderr; código 2 | "PENDIENTE: multiplicacion y argumentos --n/--seed. Use --smoke-test para probar la instalacion." Código 2. | 30/09/2026 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial` | "OK: c_secuencial (...)"; código 0 | Pasó la prueba de rechazo (`pending_test.exe`), el smoke test y el rechazo de `--n 2 --seed 42`; terminó con "OK: c_secuencial (entorno y rechazo de operaciones pendientes; no valida multiplicacion)". Código 0. | 30/09/2026 |

**Limitaciones de esta verificación:** solo se verificó `c_secuencial`. MS-MPI y Go no están instalados en este equipo, por lo que no se ejecutó nada de `c_paralelo`, `go_secuencial` ni `go_paralelo`. Las pruebas ejecutadas comprueban el entorno y el rechazo de operaciones pendientes; **no validan ninguna multiplicación**.

## 8. Trazabilidad con los sprints

| Pendiente | Sprint | Responsable |
| --- | --- | --- |
| Interfaces, contrato de memoria, validación de N | S2 | I1 (`c_secuencial/include/`) |
| Núcleo i,k,j | S3 | I1 (`matrix.c`) |
| Argumentos, reserva de memoria, errores, timer | S3 | I2 (`main.c`, `timer.c`) |
| Generador LCG | S3 | I6 (`input.c`) |
| Comparador y reporte de equivalencia | S3 | I5 |
| Robustez y casos negativos | S5 | I1 |
| Batería de pruebas matemáticas en `test_windows.ps1` | S5 | I6 |

---

## Registro de revisión

- Autor: Integrante 1.
- Revisión cruzada: pendiente (Integrante 8).
- Observaciones de la revisión: pendiente.
