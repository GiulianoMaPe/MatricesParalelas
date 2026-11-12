# Sprint 7 · Integrante 2 (Sebastian) — Plan de trabajo y entrega

**Estado:** implementación entregada en el PR; validación a cargo del revisor I1.
**Objetivo del sprint:** dejar preparada una campaña ejecutable sin editar comandos a mano.
**Asignación oficial:** `docs/sprints/sprint-07.md`, Integrante 2.
**Entregable oficial:** Medición C paralelo validada · `scripts/bench_windows.ps1`.

Este documento describe el alcance, diseño, pruebas y criterios de cierre de I2.
La implementación y las pruebas unitarias están en el PR; la ejecución real del
piloto y la validación oficial corresponden al revisor (I1) y a I6.

---

## 1. Resumen ejecutivo

El trabajo de I2 en S7 tiene dos mitades:

1. **Completar el caso híbrido C** dentro de `scripts/bench_windows.ps1` para que
   ejecute combinaciones **P × T** (procesos MPI × hilos OpenMP) con la misma
   campaña, orden y metadatos que el resto de versiones.
2. **Registrar y verificar** los procesos e hilos realmente observados y todos
   los parámetros de cada ejecución, sin inventar ceros ni filas válidas cuando
   una corrida falla.

El script hoy es un esqueleto: valida `status.json` y termina con código 2
(`scripts/bench_windows.ps1`, línea 20). Los cuatro ejecutables ya emiten la fila
CSV de 20 campos por `stdout`; el trabajo de I2 es orquestarlos, capturarlos,
validarlos y conservar la trazabilidad.

**Resultado esperado:** un piloto parcial de `c_paralelo` con `plan.csv`,
`mediciones.csv`, `entorno.json`, `bitacora.txt` y logs por corrida, más las
pruebas que demuestren que el caso rechaza filas inválidas y conserva los fallos.

**Horas (8 h):**

| Bloque | Horas | Resultado |
| --- | ---: | --- |
| Caso híbrido P × T en el script | 3 h | Combinaciones, comandos, entorno OMP/MPI, timeout y captura |
| Registro de procesos/hilos y parámetros | 3 h | Validación de `processes`, `threads`, `observed_threads`, `configuration`, plan y bitácora |
| Revisión cruzada de I3 | 1 h | Caso Go secuencial revisado y observaciones registradas |
| Coordinación | 1 h | Acuerdos con I5 (integración), I4 (concurrencia), I6 (piloto), I7 (resumen) e I8 (congelación) |

---

## 2. Punto de partida verificado en el repositorio

| Elemento | Estado actual | Implicación para I2 |
| --- | --- | --- |
| `scripts/bench_windows.ps1` | Esqueleto de 21 líneas; solo valida `status.json` y sale con 2 | I2 añade el caso `c_paralelo`; I5 integra después |
| `scripts/common_windows.ps1` | Helpers de Windows, MSVC, MPI y Go; sin helpers de campaña | Reutilizar; no duplicar detección de MPI |
| `scripts/run_hybrid_windows.ps1` | Ejecuta una sola combinación P/T con `mpiexec -n P`, `OMP_NUM_THREADS` y `OMP_DYNAMIC=FALSE` | Sirve de referencia para construir el comando |
| `c_paralelo/status.json` | `algorithm=implemented`, `validation=passed` | El gate del script puede habilitar la versión |
| CLI de `c_paralelo` | `--n`, `--seed`, `--input`, `--output`, `--repetition 0..5` | El script debe pasar `--n`, `--seed` y `--repetition` |
| Salida de `c_paralelo` | Cabecera + una fila CSV de 20 campos por `stdout`; solo rank 0 | El script captura y valida; no debe reconstruir tiempos |
| CSV de `c_paralelo` | Incluye `configuration=c_paralelo_P{P}_T{T}`, `processes`, `threads`, `observed_threads`, `workers=1`, `gomaxprocs` vacío | Base para verificar parámetros y participación |
| `docs/protocolo_medicion.md` | v1.3: esquema, fronteras, `plan.csv`, 1 warmup + 5 repeticiones, orden alternado, carpetas | Contrato que el script debe cumplir |
| `docs/plantillas/entorno_medicion.json` | Plantilla con campos de campaña | Completar sin inventar valores |
| `resultados/piloto/` | Vacío (solo `.gitkeep`) | Aquí va el piloto parcial de I2, con ID propio |
| Entregables de S6 | No se localizaron en `main` `docs/memoria.md`, `docs/optimizaciones.md` ni `docs/equidad_algoritmica.md` | **Confirmar rama/commit de S6 antes de medir**; no mezclar versiones |

> **Base de medición (resuelto):** el commit exacto no se fija a mano. El script
> ejecuta `git rev-parse HEAD` al iniciar la campaña y lo registra en
> `entorno.json`, `mediciones.csv` y `bitacora.txt`; si el árbol tiene cambios
> locales, guarda `git_status.txt` y `diff_codigo.patch`. Así la campaña es
> reproducible sobre cualquier commit que el equipo decida congelar, sin editar
> el script. Si S6 cambia durante S7, las mediciones dejan de ser comparables y
> hay que repetir el lote sobre el nuevo commit.

---

## 3. Alcance y no alcance

### Dentro del alcance de I2

- Caso `c_paralelo` del script: combinaciones P × T, construcción del comando,
  variables de entorno, timeout, captura de `stdout`/`stderr` y código de salida.
- Generación y consumo de `plan.csv` para las combinaciones habilitadas de
  `c_paralelo` (1 warmup + 5 repeticiones, orden alternado).
- Validación de las 20 columnas, configuración, P, T, `observed_threads`,
  repetición, `is_warmup`, tiempos finitos y `kernel_s <= total_s`.
- Registro por corrida en `bitacora.txt`: parámetros solicitados, procesos
  observados (`MPI_Comm_size`), hilos observados (`omp_get_num_threads`), estado,
  código de salida, duración y rutas de logs.
- Filas sintéticas de fallo con tiempos vacíos y estado `PENDING`, `MISMATCH`,
  `OOM`, `TIMEOUT` o `ERROR`, sin inventar observaciones.
- Piloto parcial de `c_paralelo` en `resultados/piloto/<campaign_id>/`.
- Pruebas del parser/validador y de los casos negativos.
- Evidencia y revisión cruzada en `docs/sprints/sprint-07.md`.

### Fuera del alcance de I2

- Casos `c_secuencial` (I1), `go_secuencial` (I3) y `go_paralelo` (I4).
- Integración final y aceptación de la campaña completa (I5).
- Piloto completo de las cuatro versiones en la PC oficial (I6).
- `scripts/summarize_results.ps1` (I7).
- `docs/campana.md` y acta de congelación (I8).
- Campaña oficial en `resultados/raw/` (S8).

I2 puede implementar el **motor compartido mínimo** (plan, lock, captura,
validación) siempre que lo acuerde con I5 y no invada los casos de otros
integrantes. La prioridad es que el caso `c_paralelo` sea mergeable por separado.

---

## 4. Entregables y criterios de aceptación

| ID | Entregable | Ruta | Criterio de aceptación | Evidencia |
| --- | --- | --- | --- | --- |
| D1 | Caso híbrido C en el script | `scripts/bench_windows.ps1` | Ejecuta las combinaciones P × T habilitadas con `mpiexec`, OMP correcto, timeout y sin campañas simultáneas | Diff del PR + ejecución de prueba |
| D2 | Validador de filas CSV | `scripts/bench_windows.ps1` | Rechaza columnas faltantes/extra, versión/configuración incorrecta, P/T distintos, `observed_threads != T`, tiempos no finitos o `kernel_s > total_s` | Pruebas unitarias del parser |
| D3 | Registro de parámetros y observaciones | `bitacora.txt` del piloto | Cada corrida tiene P, T, `observed_threads`, repetición, estado, código, duración y logs | Bitácora del piloto |
| D4 | Piloto parcial C paralelo | `resultados/piloto/<campaign_id>/` | `entorno.json`, `plan.csv`, `mediciones.csv`, `bitacora.txt` y logs; 1 warmup + 5 OK por combinación o exclusión justificada | Carpeta del piloto |
| D5 | Pruebas del caso | `tests/bench_c_paralelo_test.ps1` | Cubre fila válida, fila corrupta, fallo/timeout, orden del plan y bloqueo de campaña simultánea | Salida de la prueba |
| D6 | Evidencia y revisión | `docs/sprints/sprint-07.md` | Registra horas, comandos, resultados, fallos, revisión de I1 y revisión de I3 por I2 | Acta del sprint |

**Criterio de cierre de I2:** D1–D6 cumplen, el piloto parcial no contiene filas
inventadas ni tiempos de fallos, y I1 (revisor asignado) confirma que el caso
respeta el protocolo.

---

## 5. Diseño técnico propuesto

### 5.1 Interfaz del script compartido (acuerdo con I5)

Para que I1–I4 trabajen en paralelo sin pisarse, `bench_windows.ps1` debe tener
un registro de casos y funciones separadas por versión. I2 propone:

```powershell
# Descriptor de caso devuelto por el registro.
[pscustomobject]@{
    Version         = 'c_paralelo'
    Enabled         = $true
    Configurations  = @('P1_T1','P1_T2','P2_T1','P1_T4','P2_T2','P4_T1')
    BuildArguments  = @{ Configuration = 'Release' }
    Invoke          = { param($Run) Invoke-CParallelRun @Run }
}
```

Funciones mínimas (nombres a acordar con I5):

| Función | Responsabilidad | Dueño propuesto |
| --- | --- | --- |
| `Get-BenchCase` | Devuelve el descriptor de una versión | I5 |
| `New-CampaignPlan` | Genera `plan.csv` desde los casos habilitados | I5, con aporte de I2 |
| `Invoke-Campaign` | Recorre el plan, alterna rondas y escribe la bitácora | I5 |
| `Invoke-CParallelRun` | Ejecuta una corrida P/T y devuelve el resultado | **I2** |
| `Test-MeasurementRow` | Valida las 20 columnas y las reglas del protocolo | **I2** (reutilizable por I1/I3/I4) |
| `Write-FailureRow` | Emite fila sintética con tiempos vacíos | **I2** (reutilizable) |
| `Enter-CampaignLock` / `Exit-CampaignLock` | Evita campañas simultáneas | I4, consumido por I2 |
| `New-CampaignEnvironment` | Completa `entorno.json` y SHA-256 | I5/I8, consumido por I2 |

**Parámetros nuevos propuestos para `bench_windows.ps1`:**

```powershell
-Version        c_paralelo | all | ...
-NList          256,512,1024
-Configurations P1_T1,P1_T2,P2_T1,P1_T4,P2_T2,P4_T1
-Seed           42
-Warmups        1
-Repetitions    5
-TimeoutSeconds 120
-OutputRoot     resultados/piloto
-CampaignId     20261112T090000Z_PC-SEBASTIAN_<commit>_i02
-DryRun         # genera plan y metadatos, no ejecuta
-FailFast       # opcional; por defecto continuar y reportar al final
```

Mantener compatibilidad con `-N`, `-Processes`, `-Threads`, `-Workers` y
`-Repetitions` actuales para no romper ejemplos existentes. Si se usa un único
`-Processes/-Threads`, equivale a una configuración `P{P}_T{T}`.

**Sintaxis canónica de configuración:**

- C paralelo: `P1_T1`, `P1_T2`, `P2_T1`, `P1_T4`, `P2_T2`, `P4_T1` y, si hay
  núcleos físicos, `P1_T8`, `P2_T4`, `P4_T2`, `P8_T1`.
- Go paralelo (I4): `W1`, `W2`, `W4`, `W8`.
- Secuenciales: `BASE`.

El parser debe rechazar `P0`, `T0`, `P2_T3` no habilitada, `W` fuera de rango y
presupuestos `P*T` que excedan los núcleos físicos disponibles.

### 5.2 Flujo de una corrida `c_paralelo`

```text
1. Validar P, T, N, seed, repetición y timeout.
2. Verificar que el ejecutable Release existe y que su SHA-256 está registrado.
3. Comprobar capacidad de memoria para (P, N) según protocolo §5.4.
4. Adquirir el lock de campaña.
5. Guardar OMP_NUM_THREADS=T y OMP_DYNAMIC=FALSE en el proceso.
6. Ejecutar:
      mpiexec -n P <root>\c_paralelo\build\Release\c_paralelo.exe \
          --n N --seed SEED --repetition REP
7. Capturar stdout, stderr, código de salida y duración de pared.
8. Restaurar OMP_NUM_THREADS/OMP_DYNAMIC en finally.
9. Parsear y validar la fila CSV.
10. Escribir la fila en mediciones.csv y la línea en bitacora.txt.
11. Liberar el lock.
```

Detalles obligatorios:

- `mpiexec.exe` se obtiene con `Get-MPILauncher` de `common_windows.ps1`; no
  duplicar rutas ni detección.
- `OMP_DYNAMIC=FALSE` es obligatorio. Si el programa detecta hilos distintos de
  `T`, termina con error; el script debe registrar `ERROR`, no reintentar en
  silencio.
- No usar `--output`: la escritura de matrices queda fuera de la medición y solo
  añade I/O.
- Timeout por corrida con terminación del árbol MPI:
  `taskkill /PID <mpiexec_pid> /T /F`. Nunca dejar procesos huérfanos.
- Un timeout no produce fila `OK`; produce `TIMEOUT` con tiempos vacíos.
- No ejecutar dos benchmarks a la vez. El lock debe ser exclusivo y liberarse en
  `finally`.

### 5.3 Parseo y validación de la fila

El programa imprime **cabecera + una fila**. El script debe:

1. Leer `stdout` como texto UTF-8 sin BOM y localizar las dos líneas CSV.
2. Rechazar cualquier línea adicional no vacía (ruido de MPI, avisos, etc.).
3. Verificar que la cabecera sea exactamente la lista de 20 campos y en orden:

```text
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,
n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,
is_warmup,kernel_s,total_s,validation_status
```

4. Validar la fila:

| Regla | Condición |
| --- | --- |
| `version` | `c_paralelo` |
| `configuration` | `c_paralelo_P{P}_T{T}` |
| `n`, `seed` | Coinciden con el plan |
| `processes` | `P` solicitado (observado por `MPI_Comm_size`) |
| `threads` | `T` solicitado |
| `observed_threads` | `T`; si difiere, `ERROR` |
| `workers`, `gomaxprocs` | `1` y vacío |
| `repetition` | Índice del plan (0–5) |
| `is_warmup` | `true` si y solo si `repetition=0` |
| `kernel_s`, `total_s` | Finitos, `>= 0`, `kernel_s <= total_s` |
| `validation_status` | `OK` |
| `commit`, `hostname` | Coinciden con `entorno.json` |

5. Parsear números con `[Globalization.CultureInfo]::InvariantCulture` para no
   depender de la configuración regional de Windows (coma decimal).
6. Si la fila es inválida, **no** corregirla: registrar `ERROR` con el motivo y
   conservar el `stdout`/`stderr` originales.

**Clasificación de fallos:**

| Situación | Estado | Tiempos |
| --- | --- | --- |
| Salida 0 y fila válida | `OK` | Del CSV |
| Salida 2 | `PENDING` | Vacíos |
| Timeout | `TIMEOUT` | Vacíos |
| Salida 1 con `resultado incorrecto` en stderr | `MISMATCH` | Vacíos |
| Salida 1 con error de memoria/recursos | `OOM` | Vacíos |
| Cualquier otra salida 1 o fila inválida | `ERROR` | Vacíos |

Las filas de fallo conservan los metadatos de la corrida (timestamp, versión,
commit, hostname, configuración, N, seed, P, T, repetición, `is_warmup`) y dejan
`kernel_s` y `total_s` vacíos. No se incluyen en medianas ni speedup.

### 5.4 `plan.csv`

Cabecera exacta:

```text
execution_order,n,configuration,seed,repetition,is_warmup
```

Reglas:

- Lista `L`: N ascendente y, dentro de cada N, orden de la tabla §5.2 del
  protocolo para `c_paralelo`:
  `P1_T1`, `P1_T2`, `P2_T1`, `P1_T4`, `P2_T2`, `P4_T1` (y W=8 si se habilita).
- Primero un warmup por combinación (`repetition=0`, `is_warmup=true`).
- Después cinco rondas completas (`repetition=1..5`, `is_warmup=false`),
  alternando orden directo en rondas impares e inverso en pares.
- `execution_order` consecutivo desde 1.
- `plan.csv` se escribe antes de la primera corrida y no se modifica después.
  El orden real se conserva en `bitacora.txt`.

Ejemplo con 2 configuraciones y N=256 (solo ilustrativo):

```csv
execution_order,n,configuration,seed,repetition,is_warmup
1,256,c_paralelo_P1_T1,42,0,true
2,256,c_paralelo_P1_T2,42,0,true
3,256,c_paralelo_P1_T1,42,1,false
4,256,c_paralelo_P1_T2,42,1,false
5,256,c_paralelo_P1_T2,42,2,false
6,256,c_paralelo_P1_T1,42,2,false
...
```

### 5.5 `bitacora.txt`

Una línea por corrida, con formato estable y legible:

```text
order=12 planned=N256/P2_T2/rep=3 actual=N256/P2_T2/rep=3 start=2026-11-12T15:04:05Z
  end=2026-11-12T15:04:07Z wall_s=1.842 exit=0 status=OK
  processes=2 threads=2 observed_threads=2 kernel_s=0.512345678 total_s=0.530123456
  stdout=logs/order-012.stdout.txt stderr=logs/order-012.stderr.txt
```

La cabecera de la bitácora registra: `campaign_id`, commit, árbol limpio o diff,
hostname, operador, línea de comando, configuraciones habilitadas, timeout,
versión del protocolo y cualquier exclusión.

### 5.6 `entorno.json`

Copiar `docs/plantillas/entorno_medicion.json` y completar **sin `null`** para la
campaña habilitada:

- `campaign_id`, `phase`, `started_at_utc`, `operator`, `hostname`.
- `git.commit_full`, `git.dirty`, `git.diff_file` (si hay cambios locales).
- CPU, núcleos físicos/lógicos, RAM visible y disponible al inicio, edición/build
  de Windows, alimentación y plan de energía.
- MSVC, Windows SDK, MS-MPI Runtime/SDK, Go, GOOS/GOARCH, Release y opciones
  efectivas.
- `executable_sha256_by_version.c_paralelo`.
- `matrix_sizes`, `seed`, `enabled_budgets`, `ordered_configurations`,
  `warmups_per_combination=1`, `measured_repetitions=5`, timeout y presupuesto
  de tiempo de máquina.
- `omp_dynamic="FALSE"` y `omp_num_threads_by_configuration` para las
  configuraciones C habilitadas.
- `estimated_matrix_peak_bytes` con la fórmula conservadora del protocolo:
  `(P+5)*8*N*N` para el híbrido.

Si un dato no se puede obtener, la campaña **no se habilita**; no se completa por
suposición.

### 5.7 Bloqueo de campaña simultánea

- Archivo de lock en `.cache/bench.lock` con PID, hostname, campaign_id y hora.
- Adquisición exclusiva (`CreateNew`); si existe, comprobar si el PID sigue vivo.
- Si el lock es huérfano, registrar la incidencia y permitir retirarlo solo con
  confirmación explícita (`-ForceUnlock`), nunca automáticamente.
- Liberar en `finally` incluso si hay excepción o timeout.
- I4 es dueño del diseño de concurrencia; I2 lo consume y, si aún no existe,
  implementa una versión mínima acordada con I4/I5.

### 5.8 Carpetas y nombres

```text
resultados/piloto/<campaign_id>/
    entorno.json
    plan.csv
    mediciones.csv
    bitacora.txt
    logs/
        order-001.stdout.txt
        order-001.stderr.txt
        ...
```

`campaign_id` sugerido:
`20261112T090000Z_PC-SEBASTIAN_<commit7>_i02`.

No sobrescribir intentos: si el ID existe, añadir `_intento02`, `_intento03`, etc.
El piloto parcial de I2 se etiqueta como validación de `c_paralelo` en la
bitácora; no se presenta como el piloto oficial de las cuatro versiones.

---

## 6. Plan experimental de I2

### 6.1 Combinaciones

| Presupuesto | Configuraciones C paralelo | Condición |
| --- | --- | --- |
| W=1 | `P1_T1` | Siempre |
| W=2 | `P1_T2`, `P2_T1` | Siempre |
| W=4 | `P1_T4`, `P2_T2`, `P4_T1` | Siempre |
| W=8 | `P1_T8`, `P2_T4`, `P4_T2`, `P8_T1` | Solo si hay ≥ 8 núcleos físicos |

No habilitar `P*T` mayor que los núcleos físicos. `P*T` es presupuesto nominal,
no afinidad de CPU.

### 6.2 Tamaños y volumen

- Piloto: `N ∈ {256, 512, 1024}`.
- Semilla: `42`.
- 1 warmup + 5 repeticiones por combinación.
- Con W ≤ 4: 6 configuraciones × 3 N = 18 pares; 18 warmups + 90 medidas =
  **108 corridas**.
- Con W=8: 10 configuraciones × 3 N = 30 pares; 30 + 150 = **180 corridas**.

### 6.3 Memoria estimada

`S = 8*N*N` bytes por matriz. Para C híbrido, estimación conservadora
`(P+5)*S`:

| N | S (MiB) | P=2 | P=4 | P=8 |
| ---: | ---: | ---: | ---: | ---: |
| 256 | 0.5 | 3.5 MiB | 4.5 MiB | 6.5 MiB |
| 512 | 2 | 14 MiB | 18 MiB | 26 MiB |
| 1024 | 8 | 56 MiB | 72 MiB | 104 MiB |

No habilitar una configuración si la estimación supera el 50 % de la RAM
disponible al inicio. El piloto debe confirmar el pico real.

### 6.4 Timeout y duración

- Timeout inicial propuesto: **120 s por corrida**. Ajustarlo con el primer lote
  y registrarlo en `entorno.json`.
- Estimar la duración total del piloto parcial con la primera pasada y reservar
  tiempo de máquina. No ejecutar mientras haya actualizaciones, sincronización
  en la nube, navegadores o antivirus activos.
- Si una corrida agota el timeout, no reducir N ni cambiar P/T a mitad de
  campaña: registrar `TIMEOUT`, investigar y repetir el lote completo en una
  carpeta nueva si corresponde.

---

## 7. Pruebas y evidencias

### 7.1 Pruebas unitarias del parser/validador

Archivo propuesto: `tests/bench_c_paralelo_test.ps1`. Debe cubrir, como mínimo:

| Caso | Resultado esperado |
| --- | --- |
| Fila válida `P2_T2`, `observed_threads=2` | Aceptada |
| Falta una columna | Rechazada (`ERROR`) |
| Columna extra | Rechazada |
| `version` distinta de `c_paralelo` | Rechazada |
| `configuration` no coincide con P/T | Rechazada |
| `processes` distinto de P | Rechazada |
| `observed_threads` distinto de T | Rechazada |
| `is_warmup` incoherente con `repetition` | Rechazada |
| `kernel_s > total_s` | Rechazada |
| `kernel_s` vacío con estado `OK` | Rechazada |
| `NaN` o `Inf` | Rechazada |
| Salida 2 | Fila `PENDING` con tiempos vacíos |
| Timeout simulado | Fila `TIMEOUT` con tiempos vacíos |
| Salida 1 con `resultado incorrecto` | Fila `MISMATCH` |
| Lock ya tomado | Segunda campaña rechazada |

Las pruebas deben usar cadenas CSV de fixture, no ejecutar MPI, salvo los casos
de integración marcados aparte.

### 7.2 Pruebas de integración

1. **Dry-run:** genera `plan.csv` y `entorno.json` sin ejecutar; verificar orden,
   conteos y ausencia de `null`.
2. **Humo real:** `N=64`, `P1_T1`, 1 warmup + 1 repetición; verificar fila,
   `observed_threads=1`, `processes=1`.
3. **Hilos:** `N=64`, `P2_T2` y `P1_T4`; verificar `observed_threads=T` y
   `processes=P`.
4. **Procesos sin filas:** `P4_T1` con `N=2`; el programa ya soporta ranks sin
   filas; verificar que no hay bloqueo y que `observed_threads=T`.
5. **Fallo controlado:** `OMP_DYNAMIC=TRUE` o `OMP_NUM_THREADS` inválido; debe
   registrar `ERROR` sin fila `OK`.
6. **Timeout:** `N=1024` con `-TimeoutSeconds 1`; verificar `TIMEOUT` y que no
   quedan procesos `mpiexec`/`c_paralelo` vivos.
7. **Lock:** lanzar dos campañas; la segunda debe rechazarse y la primera debe
   liberar el lock al terminar.
8. **Repetición:** ejecutar dos veces el humo y confirmar que no se sobrescribe
   la carpeta; se crea un intento nuevo.

### 7.3 Piloto parcial

- Ejecutar las 6 configuraciones W ≤ 4 en N=256, 512 y 1024 (108 corridas) si el
  tiempo de máquina lo permite. Si no, priorizar N=256 completo y una pasada de
  humo en 512/1024, dejando constancia de la exclusión.
- Verificar que cada combinación tenga 1 warmup + 5 filas `OK`.
- Comprobar que `plan.csv` y el orden real de `bitacora.txt` coinciden en
  contenido y alternancia.
- Revisar dispersión: si una configuración tiene un valor atípico, conservarlo y
  documentarlo; no borrarlo ni sustituirlo por el mejor.
- Confirmar que `mediciones.csv` no contiene filas de fallo mezcladas como `OK`.

### 7.4 Evidencia para el acta

En `docs/sprints/sprint-07.md`, sección de I2:

- Comandos exactos ejecutados y commit.
- Rutas de `entorno.json`, `plan.csv`, `mediciones.csv`, `bitacora.txt`.
- Tabla de combinaciones con número de filas `OK`/fallos.
- Confirmación de `observed_threads=T` y `processes=P` en todas las filas `OK`.
- Incidencias, decisiones y horas reales.
- Revisión de I1 (conformidad o hallazgos).
- Revisión de I3 por I2 (1 h).

---

## 8. Dependencias y coordinación

| Persona | Dependencia | Acuerdo necesario |
| --- | --- | --- |
| Compañero de S6 | Rama/commit con las optimizaciones y estabilidad | Confirmar qué se mide y congelarlo antes del piloto |
| I5 (Fernando) | Integración de los cuatro casos | I2 entrega funciones y registro; I5 no reescribe el caso C |
| I1 (Yessly) | Revisión de I2 | Checklist de §4 y §7; revisión antes del cierre |
| I3 (Giuliano) | I2 revisa su caso Go secuencial (1 h) | Revisar comandos, CSV, parámetros y manejo de fallos |
| I4 (Eva) | Lock y no simultaneidad | I2 consume el lock; si no existe, acordar versión mínima |
| I6 (Gerardo) | Piloto completo en PC oficial | I2 entrega el caso validado y el timeout inicial |
| I7 (Andrés) | `summarize_results.ps1` | Confirmar que `mediciones.csv` conserva el esquema de 20 campos |
| I8 (Roberto) | `docs/campana.md` y congelación | I2 aporta commit, configuraciones, timeout y exclusiones |

**Estrategia de rama/PR:** `feature/s07-i02-c-paralelo-bench`. Cambios acotados a:

- `scripts/bench_windows.ps1` (funciones del caso C y registro).
- `tests/bench_c_paralelo_test.ps1` (nuevo).
- `docs/sprints/sprint-07.md` (evidencia).
- `resultados/piloto/<campaign_id>/` (solo si el equipo decide versionar el
  piloto; en caso contrario, conservar localmente y enlazar el acta).

Evitar reformatear todo el script o mover funciones de otros integrantes: eso
genera conflictos con I1/I3/I4/I5.

---

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| S6 no está integrado en `main` | Mediciones no comparables | Confirmar rama/commit y medir sobre una base única; registrar `commit` |
| Ediciones simultáneas de `bench_windows.ps1` | Conflictos y pérdida de trabajo | Funciones separadas por versión; PR pequeño; coordinar con I5 |
| `mpiexec` sin permisos | El caso no ejecuta | Probar `mpiexec -n 2` antes; reportar restricción como fallo, no omitir |
| `observed_threads != T` | Fila inválida | `OMP_DYNAMIC=FALSE`; validar y registrar `ERROR` |
| `P*T` sobreasigna núcleos | Resultados injustos | Limitar a núcleos físicos; no confundir lógicos con físicos |
| Memoria insuficiente | `OOM` o swap | Estimar `(P+5)*S`; excluir configuraciones con justificación |
| Timeout deja procesos vivos | Contamina corridas siguientes | `taskkill /T /F` y verificación posterior |
| Cultura regional con coma decimal | Parseo erróneo | `InvariantCulture` en todas las conversiones |
| Ruido en `stdout` de MPI | Fila no parseable | Exigir exactamente cabecera + fila; conservar logs |
| Campaña simultánea | Tiempos contaminados | Lock exclusivo y bitácora con hora de inicio/fin |
| ID de campaña repetido | Sobrescritura | Validar existencia y crear `_intentoNN` |
| Optimizaciones de S6 cambian durante S7 | Se invalida el lote | Congelar commit y SHA-256 antes del piloto |

---

## 10. Cronograma sugerido (5 días)

| Día | Actividad | Salida |
| --- | --- | --- |
| 1 | Preflight: confirmar S6, MS-MPI, MSVC, Go, núcleos/RAM; acordar interfaz con I5; esqueleto del caso y `plan.csv` | Notas de acuerdo + dry-run |
| 2 | `Invoke-CParallelRun`: comando, OMP, timeout, captura y parseo | Humo `N=64` |
| 3 | Validación de 20 campos, `observed_threads`, fallos, lock y bitácora | Pruebas unitarias + negativas |
| 4 | Piloto parcial 108 corridas; revisar plan/bitácora/dispersión | `resultados/piloto/<id>/` |
| 5 | Evidencia, revisión de I1, revisión de I3 y cierre en `sprint-07.md` | Acta actualizada |

---

## 11. Comandos de referencia

```powershell
# Compilar Release de la versión híbrida
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Release

# Prueba manual de una combinación (referencia)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1 -Configuration Release -Processes 2 -Threads 2 -N 256 -Seed 42

# Prueba de instalación de MS-MPI
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1 -Configuration Release -SmokeTest

# Dry-run del caso c_paralelo (no ejecuta MPI)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -NList 256,512,1024 `
    -Configurations P1_T1,P1_T2,P2_T1,P1_T4,P2_T2,P4_T1 `
    -Seed 42 -Warmups 1 -Repetitions 5 -TimeoutSeconds 120 `
    -OutputRoot resultados/piloto -DryRun
```

---

## 12. Decisiones resueltas

1. **Base de S6 / commit a entregar:** no se fija un hash en el plan. El script
   deriva `HEAD` en tiempo de ejecución y lo registra junto al estado limpio o
   sucio y el diff. El equipo congela el commit al abrir la campaña; I2 no
   inventa ni adelanta el hash.
2. **PC de validación de I2:** la campaña se ejecuta en la PC de quien valida
   (I1) o en la PC oficial (I6). La evidencia de I2 es el script, las pruebas y
   el dry-run, no un piloto ejecutado en una máquina distinta.
3. **W=8:** se habilita automáticamente solo si `Win32_Processor` informa ≥ 8
   núcleos físicos; con menos, esas configuraciones se excluyen y queda
   constancia en `entorno.json`/`bitacora.txt`. La máquina de I2 tiene 6
   núcleos físicos, por lo que su dry-run usa W ≤ 4.
4. **Alcance del piloto parcial:** lo decide el revisor/I6 con el tiempo de
   máquina disponible. El script soporta tanto las 108 corridas completas como
   un subconjunto con `-NList` y `-Configurations`.
5. **Lock:** I2 implementa una versión mínima (archivo exclusivo con PID y
   `-ForceUnlock` explícito) que I4/I5 pueden reemplazar al integrar.
6. **Versionado del piloto:** el PR no incluye `resultados/piloto/<id>/`; la
   carpeta se genera al ejecutar y queda fuera de control de versiones salvo
   decisión del equipo.
7. **Continuar o abortar:** por defecto el script continúa tras un fallo y
   resume el conteo al final; `-FailFast` detiene la campaña en el primer fallo.

---

## 13. Estado de implementación (PR de I2)

Implementado en `scripts/bench_windows.ps1`:

- Caso `c_paralelo` con combinaciones P × T, `mpiexec -n P`,
  `OMP_NUM_THREADS=T` y `OMP_DYNAMIC=FALSE` aplicados y restaurados en `finally`.
- Resolución de configuraciones por núcleos físicos y exclusiones por memoria
  (`(P+5)*8*N*N` frente al 50 % de la RAM disponible).
- `plan.csv` (1 warmup + 5 rondas alternadas), `entorno.json`, `bitacora.txt`,
  `mediciones.csv` y logs `stdout`/`stderr` por corrida.
- Parser CSV de 20 campos, validador de configuración/P/T/`observed_threads`/
  repetición/tiempos, y filas de fallo (`PENDING`, `MISMATCH`, `OOM`, `TIMEOUT`,
  `ERROR`) con `kernel_s` y `total_s` vacíos.
- Timeout con `taskkill /T /F`, lock de campaña, `-DryRun`, `-FailFast` y
  `-ForceUnlock`.
- `-Version all` falla de forma explícita: esta rama solo implementa
  `c_paralelo`; la integración de los cuatro casos es de I5.

Pruebas: `tests/bench_c_paralelo_test.ps1` (23 pruebas, sin MSVC ni MS-MPI).

```powershell
# Pruebas unitarias del caso
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_c_paralelo_test.ps1

# Dry-run sin ejecutar MPI
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -NList 256,512,1024 `
    -Configurations P1_T1,P1_T2,P2_T1,P1_T4,P2_T2,P4_T1 `
    -Seed 42 -Warmups 1 -Repetitions 5 -TimeoutSeconds 120 -DryRun

# Campaña real (requiere MSVC, MS-MPI y el ejecutable Release compilado)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version c_paralelo -Configuration Release -Seed 42 -Warmups 1 -Repetitions 5
```

**Límite conocido:** la máquina de I2 no tiene `cl.exe`, `mpiexec.exe` ni un
`c_paralelo.exe` Release, por lo que no se ejecutó una campaña real. El revisor
debe compilar, ejecutar el dry-run, correr el piloto que corresponda y validar
las filas antes de marcar el entregable como validado.

---

## 14. Checklist de cierre

- [x] Commit derivado en tiempo de ejecución y registrado con estado/diff.
- [x] `scripts/bench_windows.ps1` ejecuta `c_paralelo` con P × T.
- [x] `OMP_NUM_THREADS=T` y `OMP_DYNAMIC=FALSE` se aplican y restauran.
- [x] `mpiexec -n P` usa el lanzador de `common_windows.ps1`.
- [x] Timeout y `taskkill /T /F` implementados.
- [x] `plan.csv` tiene cabecera, orden, warmups y 5 rondas alternadas.
- [x] `mediciones.csv` valida 20 campos, configuración, P, T y `observed_threads`.
- [x] Filas de fallo tienen tiempos vacíos y estado correcto.
- [x] `entorno.json` incluye commit y SHA-256.
- [x] `bitacora.txt` registra parámetros, observaciones y logs por corrida.
- [x] Lock impide campañas simultáneas y se libera en `finally`.
- [x] Pruebas unitarias del parser/validador pasan (23/23).
- [ ] Dry-run y campaña real ejecutados por el revisor (requiere MSVC + MS-MPI).
- [ ] Piloto parcial con 1 warmup + 5 OK por combinación (o exclusión justificada).
- [ ] Evidencia y horas registradas en `docs/sprints/sprint-07.md`.
- [ ] Revisión de I1 registrada.
- [ ] Revisión de I3 por I2 registrada (1 h).
- [x] PR abierto y coordinado con I5 para la integración.


