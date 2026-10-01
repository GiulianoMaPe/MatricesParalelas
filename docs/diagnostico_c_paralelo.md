# Diagnóstico funcional C paralelo

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)
**Curso:** Programación Concurrente y Paralela — UNMSM
**Sprint:** 1 (Semana 1) · **Autor:** Integrante 2 — Sebastian · **Módulo:** `c_paralelo`
**Fecha de redacción:** 30/09/2026
**Estado:** Entregable de Sprint 1 finalizado. Pendiente de revisión cruzada formal por Integrante 1 (Yessly), que registra su visto bueno en `docs/sprints/sprint-01.md`.

---

## 1. Alcance y método

Esta es la primera de las dos subtareas de Sprint 1 del Integrante 2: *analizar el flujo MPI y OpenMP disponible en C paralelo* y *distinguir demostraciones de hilos del producto real, enumerando faltantes*.

Método empleado:

| Paso | Acción | Fuente |
| --- | --- | --- |
| 1 | Lectura completa del módulo (6 fuentes + cabeceras + pruebas + `status.json` + `README.md`) | `c_paralelo/**` |
| 2 | Lectura del flujo de compilación, prueba y ejecución | `scripts/build_windows.ps1`, `scripts/test_windows.ps1`, `scripts/run_hybrid_windows.ps1`, `scripts/common_windows.ps1` |
| 3 | Lectura de la tarea de VS Code de ejecución híbrida | `.vscode/tasks.json` (tarea `MPI 2 procesos x 2 hilos`) |
| 4 | Contraste con el contrato y la guía vigentes | `docs/contrato.md`, `docs/guia-extraida.txt` (§2), `docs/requisitos.md` (RNF-03, RNF-04, backlog) |
| 5 | Contraste con la verificación previa del equipo | `docs/verificacion-inicial.md` (17/09/2026) |

**Naturaleza de la evidencia.** Este diagnóstico es un *análisis estático del código fuente y de los scripts*, ejecutado el 30/09/2026 en un equipo sin MSVC, MS-MPI ni Go instalados, por lo que aquí no se repitieron las ejecuciones. Las ejecuciones previas del híbrido 2 × 2 están registradas por el equipo en `docs/verificacion-inicial.md`; las instrucciones para reproducirlas están en la §7. La guía es explícita: *una prueba del entorno se registra como tal y no como validación del algoritmo*, y ese criterio se respeta a lo largo de este documento.

---

## 2. Flujo funcional disponible hoy

### 2.1 Camino único de ejecución: `--smoke-test`

`c_paralelo/src/main.c` sólo acepta un argumento exacto: `--smoke-test`. Cualquier otra forma de invocación (incluido `--n/--seed`) termina antes de inicializar MPI, escribiendo en `stderr` y devolviendo `MATRIX_PENDING` (2).

Secuencia real de la prueba, en orden:

| # | Operación | Tipo | Observación |
| --- | --- | --- | --- |
| 1 | Validación de `argv`: sólo `--smoke-test` | proceso | Devuelve 2 y escribe en `stderr` si no coincide |
| 2 | `MPI_Init_thread(..., MPI_THREAD_FUNNELED, &provided)` | MPI | Fallo → retorno 1 sin `Finalize` (camino de aborto temprano) |
| 3 | `provided < MPI_THREAD_FUNNELED` → `MPI_Abort` | MPI | Verifica el nivel realmente ofrecido, no el pedido |
| 4 | `MPI_Comm_rank` / `MPI_Comm_size` | MPI | Fallo → `MPI_Abort` |
| 5 | `#pragma omp parallel reduction(+:threads) { threads += 1; }` | OpenMP | Cada hilo de la región aporta 1: el resultado es el número de hilos que entraron |
| 6 | `failed = (size != 2 \|\| threads != 2)` | proceso | Decisión local por rank |
| 7 | `MPI_Allreduce(&failed, &any_failed, MPI_MAX)` | MPI | Consenso global sin esperas indefinidas: si un rank falla, todos lo saben |
| 8 | `printf(...)` por rank | stdout | Imprime rango, tamaño, hilos y nivel MPI |
| 9 | `any_failed` → mensaje en `stderr` | proceso | Aviso conjunto: exige exactamente 2 procesos y 2 hilos |
| 10 | `MPI_Finalize` | MPI | Camino normal de terminación |
| 11 | `return any_failed ? 1 : 0` | proceso | Códigos del contrato: 0 entorno correcto, 1 fallo |

Invariantes ya cumplidas y que **deben conservarse** en la implementación de S4:

- Todas las llamadas MPI se ejecutan en el hilo que inicializó MPI, fuera de regiones OpenMP (comentario explícito en `main.c` y verificado en el código: no hay ninguna llamada MPI dentro de la región paralela).
- Ninguna ruta deja procesos esperando: los fallos se coordinan con `MPI_Allreduce` o se terminan con `MPI_Abort`.
- El nivel de hilos pedido (`FUNNELED`) se comprueba con el valor entregado por la librería.
- Los códigos de retorno respetan el contrato (0 / 1 / 2).

### 2.2 Flujo de compilación y prueba

| Etapa | Qué hace | Qué demuestra |
| --- | --- | --- |
| `build_windows.ps1 -Version c_paralelo [-Tests]` | `cl /TC /std:c11 /W4 /WX /fp:precise /I include /openmp /I <MPI include>` + `/Od /Zi /MDd` (Debug) o `/O2 /MD` (Release), enlaza `/MACHINE:X64` con `msmpi.lib`. Compila **todos** los `src/*.c`. Con `-Tests` excluye `main.c` y añade `tests/pending_test.c` | Que el código compila estricto (`/W4 /WX`) y enlaza contra MS-MPI x64 |
| `test_windows.ps1 -Version c_paralelo` | Compila con pruebas → ejecuta `pending_test.exe` → ejecuta `run_hybrid_windows.ps1` → exige que `--n 2 --seed 42` devuelva **2** | Que los módulos siguen pendientes y **no** producen matrices falsas; no valida ninguna multiplicación |
| `run_hybrid_windows.ps1` | Exige el ejecutable compilado; fija `OMP_NUM_THREADS=2` y `OMP_DYNAMIC=FALSE`; lanza `mpiexec -n 2 c_paralelo.exe --smoke-test`; restaura las variables | Que existen 2 procesos × 2 hilos con el entorno forzado desde el script |
| Tarea VS Code `MPI 2 procesos x 2 hilos` | Compila (`Build c_paralelo Debug`) y luego ejecuta el lanzador | Atajo de ejecución; **no** es una sesión de depuración de todos los ranks (advertencia del propio `README.md`) |

Detalle relevante: `OMP_NUM_THREADS` y `OMP_DYNAMIC` los fija el **script**, no el programa. Ejecutado directamente con `mpiexec`, `main.c` contaría los hilos que el runtime decida y probablemente terminaría con código 1. La prueba no verifica por sí sola que el producto controle su nivel de paralelismo.

---

## 3. Demostración de hilos frente a producto real

La salida `Proceso 1/2, hilos 2, nivel MPI 1` es una **demostración de instalación**, no una ejecución del producto. La distinción es la siguiente:

| Dimensión | Demostración de hilos (hoy) | Producto real (requerido por la guía) |
| --- | --- | --- |
| Propósito | Comprobar que MPI + OpenMP arrancan en esta máquina | Calcular `C = A × B` con reparto por filas |
| Procesos y hilos | Exige **exactamente** P = 2 y T = 2; si no, código 1 | Acepta cualquier P ≥ 1 y T ≥ 1, incluido **P > N** (procesos sin filas) |
| Datos de entrada | Ninguno | `--n`/`--seed` (generador LCG común) o `--input <archivo>` |
| Paralelismo real | Conteo de hilos con `reduction`; **cero** cálculo | `MPI_Bcast` de B, `MPI_Scatterv` de filas de A, `parallel for schedule(static)` sobre filas locales, `MPI_Gatherv` de C |
| Salida | Mensaje informativo por rank en `stdout` | Matriz C (validada) y fila CSV de tiempos; diagnóstico en `stderr` |
| Códigos | 0 = entorno correcto, 1 = entorno incorrecto | 0 = ejecución validada, 1 = error de entorno/argumentos/memoria, 2 = pendiente |
| Qué prueba | Que el entorno de ejecución funciona | Que la salida matemática pasa la tolerancia `1e-9 + 1e-9·|esperado|` |

**Pruebas textuales de que aún no hay producto:**

1. `src/matrix.c`: `matrix_multiply` devuelve `MATRIX_PENDING` y el comentario declara *«Deliberately leave output untouched: this is NOT a multiplication»*; el búfer `c` no se modifica.
2. `src/input.c` y `src/partition.c`: devuelven `MATRIX_PENDING` sin escribir en sus parámetros.
3. `src/main.c`: rechaza cualquier invocación que no sea `--smoke-test` con código 2.
4. `tests/pending_test.c`: verifica precisamente que `matrix_multiply(&a,&b,&c,1)` **no** altera `c` (queda en `-123.0`) y que `input_generate` no altera `a` ni `b`; imprime *«OK: operaciones pendientes no producen matrices falsas»*. Es una prueba anti-falsos-positivos, no una prueba matemática.
5. `c_paralelo/status.json` declara `"algorithm": "pending"` y `"validation": "pending"`.
6. `c_paralelo/README.md`: *«No existe aún distribución ni multiplicación»* y *«Las pruebas no validan aún productos matemáticos»*.
7. No existe ninguna llamada a `MPI_Scatterv`, `MPI_Gatherv` ni `MPI_Bcast` en el módulo; las únicas colectivas presentes son `MPI_Allreduce` (consenso de la prueba) y `MPI_Abort`.

**Conclusión del apartado:** el híbrido tiene un *esqueleto de arranque correcto* (nivel de hilos, conciencia de rango, terminación ordenada), pero ningún componente del algoritmo paralelo está implementado. El número «hilos 2» mide el runtime, no la corrección ni el rendimiento.

---

## 4. Inventario funcional por archivo

| Archivo | Símbolo / contenido | Estado | Observación |
| --- | --- | --- | --- |
| `include/matrix.h` | `MATRIX_PENDING` (2), `matrix_multiply` | Parcial | Falta contrato de memoria, desbordes y multiplicación independiente |
| `include/input.h` | `input_generate` | Parcial | El TODO remite al generador y al parser de fixtures de `docs/contrato.md` |
| `include/partition.h` | `partition_rows` | **Esqueleto** | TODO: filas por cociente/resto y counts/desplazamientos MPI comprobados → entregable de Sprint 2 de I2 |
| `src/main.c` | Arranque + prueba 2 × 2 | Funcional (sólo prueba) | Sin CLI, sin timers, sin flujo colectivo de datos |
| `src/matrix.c` | `matrix_multiply` | Pendiente | No escribe salida |
| `src/input.c` | `input_generate` | Pendiente | No escribe salida |
| `src/partition.c` | `partition_rows` | Pendiente | No rellena `counts`/`displacements` |
| `tests/pending_test.c` | Verificación de pendencia | Funcional | Comprueba que no hay matrices falsas; **no** valida productos |
| `status.json` | `algorithm`, `validation` | `pending` | Sólo debe cambiarse después de validar (regla del `README.md`) |
| `README.md` | Instrucciones y límites | Completo | Declara con exactitud el alcance actual |
| `scripts/*` | Build, test, híbrido, entorno | Funcionales | `run_hybrid` y `bench` asumen P = T = 2 fijos |
| `.vscode/tasks.json` | Tarea híbrida | Funcional | Depende de `Build c_paralelo Debug` |

---

## 5. Faltantes priorizados

Prioridad tomada de `docs/requisitos.md` (P0/P1/P2) y responsable/sprint de la guía vigente.

| ID | Faltante | Evidencia en el código | Prioridad | Sprint previsto | Responsables |
| --- | --- | --- | --- | --- | --- |
| F-01 | CLI `--n`/`--seed` con validación y errores en `stderr` | `main.c` sólo acepta `--smoke-test` | P0 | S3 | I2 |
| F-02 | Generador LCG determinista portable (mismo que C secuencial y Go) | `input.c` devuelve 2 sin escribir | P0 | S3 | I6, I7 (con I2 en C) |
| F-03 | Reserva de memoria con `size_t` y comprobación de `N*N` y bytes | No hay ningún `malloc` en el módulo | P0 | S3 | I1, I2 |
| F-04 | **Reparto de filas: `counts` y desplazamientos en elementos** | `partition.c` devuelve 2 sin rellenar nada | P0 | Diseño en **S2 (este módulo)**; implementación en S4 | I2 (diseño), I1 e I2 (implementación) |
| F-05 | Flujo colectivo: `MPI_Bcast` de B, `MPI_Scatterv` de A, `MPI_Gatherv` de C | Ausentes en todo el módulo | P0 | S4 | I1 |
| F-06 | `#pragma omp parallel for schedule(static)` sobre filas locales, variables privadas e índice con signo | Sólo existe la región `reduction` de conteo | P0 | S4 | I2 |
| F-07 | Comprobación de límites de los enteros MPI (counts/desplazamientos) y de `N*N` antes de usar memoria | No hay comprobaciones; contrato §«Cálculo y concurrencia» | P0 | S3–S4 | I1, I2 |
| F-08 | Soporte de fixtures `--input`/`--output` y tolerancias | Inexistente; `tests/fixtures/` aún no se consume | P1 | S2–S3 (fixtures en S2: I5, I6) | I5, I6, I2 |
| F-09 | Pruebas que validen productos matemáticos | `pending_test.c` sólo verifica pendencia | P1 | S3 (núcleos), S5 (validación integral) | I1 a I8 |
| F-10 | Relojes `kernel_s` y `total_s` con `MPI_Wtime` + `MPI_Reduce(MAX)` | No hay cronómetro ni `MPI_Wtime` | P1 | S6–S7 | I2, I7 |
| F-11 | Prueba de procesos sin filas (P > N) y errores colectivos controlados | Imposible hoy: no hay reparto ni CLI | P1 | S5 | I2 |
| F-12 | Salida CSV de métricas con campos del protocolo | No hay escritura de resultados | P2 | S7–S8 | I2, I7 |
| F-13 | Parametrizar P y T (hoy fijos a 2 en `run_hybrid`/`bench`) | `run_hybrid_windows.ps1` endurece `2` y `2` | P2 | S7 | I2 |
| F-14 | Actualizar `status.json` sólo tras validación | Sigue en `pending` (correcto hasta S3–S5) | P2 | S5 | Todo el equipo |

---

## 6. Supuestos que el diseño de reparto debe respetar

Puntos que este diagnóstico fija como entrada para el entregable de Sprint 2 (`c_paralelo/include/partition.h`):

1. **Unidades.** `counts` y desplazamientos se expresan en **elementos `double`** (filas locales × N), no en filas, y los desplazamientos son la suma acumulada de los `counts` (guía §2 y `docs/contrato.md`).
2. **Límite entero MPI.** `counts` y desplazamientos son `int` en las colectivas variables: exige `N*N ≤ INT_MAX`, es decir `N ≤ 46340`; para `N = 46341` el diseño debe rechazar con error, no truncar.
3. **Puede haber procesos sin filas.** P > N es un caso válido que debe producir `count = 0` (y desplazamiento definido) sin provocar error ni esperas.
4. **Reparto determinista y sin comunicación.** Todos los ranks calculan la misma partición con aritmética entera; no hace falta reducirla por MPI, pero sí comprobar que `processes == MPI_Comm_size`.
5. **Concurrencia.** El reparto se calcula una vez, en el hilo principal, antes de cualquier región OpenMP; los arreglos pertenecen al rank.
6. **MSVC.** Sin arreglos de tamaño variable (VLA) — MSVC no los soporta en C11 —, uso de `malloc` con `size_t` e índice **entero con signo** en el `parallel for`.
7. **Errores.** Decisión colectiva o `MPI_Abort`; nunca un rank fallando en silencio mientras los demás esperan.
8. **Equivalencia.** El híbrido con P = T = 1 debe reproducir la salida de `c_secuencial`; eso estudia sobrecoste, pero **no** sustituye a la referencia secuencial.

### Puntos de validación futuros asociados

| Punto de validación | Cuándo | Cómo se comprobará |
| --- | --- | --- |
| Reparto con N divisible y no divisible entre P | S4 | Comparar tabla de `counts`/desplazamientos contra los ejemplos de `partition.h` |
| P = 1 y P > N | S4–S5 | Ejecutar el híbrido y verificar salida idéntica a la referencia |
| Límite `N*N ≤ INT_MAX` | S5 | Caso límite `N = 46340` / `N = 46341` esperando éxito / rechazo con código 1 |
| FUNNELED y ausencia de MPI en hilos secundarios | S4, S5 | Revisión de código + comprobación del nivel entregado en tiempo de ejecución |
| Corrección matemática completa | S5 | Comparación elemento a elemento con `1e-9` sobre todos los fixtures |
| Rendimiento P × T | S7–S8 | `scripts/bench_windows.ps1` con combinaciones 1×4, 2×2, 4×1 |

---

## 7. Evidencia y cómo reproducirla

Comandos desde la raíz del clon, en PowerShell heredado de la consola x64, en un equipo con MSVC, MS-MPI y Go instalados (requisitos en `docs/instalacion-windows.md`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Debug -Tests
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_paralelo
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1
.\c_paralelo\build\Debug\c_paralelo.exe --n 2 --seed 42   # debe devolver 2
```

Qué demuestra y qué **no** demuestra cada uno:

- Demuestra: compilación estricta, enlace MPI x64, ejecución 2 × 2 con nivel FUNNELED, y que el módulo sigue rechazando el cálculo pendiente con código 2.
- **No** demuestra corrección matemática, reparto de filas ni rendimiento: todavía no existen.

Evidencia previa del equipo (no ejecutada por el autor de este documento): `docs/verificacion-inicial.md`, 17/09/2026 — compilación de las cuatro versiones en Debug y Release, `test_windows.ps1 -Version all` correcto, híbrido 2 × 2 observando dos procesos, dos hilos por proceso y nivel MPI 1 (= `MPI_THREAD_FUNNELED`).

Reproducción de este diagnóstico: leer los seis ficheros de `c_paralelo/src` y `c_paralelo/include`, `tests/pending_test.c`, `status.json` y los tres scripts citados en la §1; el documento sólo contiene afirmaciones verificables en esas fuentes.

---

## 8. Criterio de aceptación de Sprint 1 para Integrante 2

- [x] Existe un diagnóstico funcional de la versión `c_paralelo` con evidencia por archivo (§4).
- [x] El flujo MPI y OpenMP disponible está descrito paso a paso con sus invariantes (§2.1).
- [x] La demostración de hilos queda diferenciada del producto real, con pruebas textuales del repositorio (§3).
- [x] Los faltantes están enumerados y priorizados, con sprint y responsables (§5).
- [x] Los supuestos y puntos de validación que condicionan el diseño de reparto quedan fijados (§6).
- [x] Instrucciones de reproducción publicadas y límites de la evidencia declarados (§7).
- [ ] Revisión cruzada por Integrante 1 (Yessly) registrada en `docs/sprints/sprint-01.md`.
