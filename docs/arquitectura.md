# Arquitectura Go Paralelo: Diseño con Invariantes

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)
**Sprint:** 2 · **Integrante:** 4 Moreno Eva· **Versión:** `go_paralelo`
**Estado:** Diseño pendiente de aprobación para implementación en Sprint 4
**Ubicación del código:** `go_paralelo/` (`main.go`, `workers.go`, `matrix.go`, `input.go`)

---

## 1. Visión General

La implementación futura de `go_paralelo` multiplicará matrices cuadradas densas $C = A \times B$ de dimensión $N \times N$ usando un **pool acotado de workers** (goroutines) que consumen **bloques de filas** desde un **canal de tareas tipado**. La sincronización usa `sync.WaitGroup`. Los argumentos CLI son `--n N --seed SEED --workers W`.

**Principios rectores (de `docs/contrato.md` y `docs/Guia_Sprints.md`):**
- Almacenamiento contiguo por filas (`float64`, row-major: índice `i*N + j`)
- Pool acotado: `W` workers fijos, **no** una goroutine por celda
- Canal de tareas: reparte intervalos de filas (bloques), no celdas individuales; **un worker puede recibir varias tareas**; lo obligatorio es que **cada fila se calcule exactamente una vez**
- Propiedad exclusiva: **un único worker escribe cada fila de $C$**
- $A$ y $B$ son de **solo lectura** para todos los workers
- Cierre ordenado: **primero se envían todas las tareas al canal, luego se cierra el canal (`close(tasks)`), y finalmente se espera a los workers con `wg.Wait()`**
- `GOMAXPROCS` se fija y registra aparte; no equivale al número de workers; **tras `runtime.GOMAXPROCS(workers)`, consultar `runtime.GOMAXPROCS(0)` para guardar el valor efectivo**

---

## 2. Estructura de Datos

```go
// Matrix: representación contigua por filas (row-major)
type Matrix struct {
    N    int       // dimensión N x N
    Data []float64 // len == N*N, fila i en Data[i*N : (i+1)*N]
}

// Task: bloque de filas asignado a un worker
type Task struct {
    StartRow int // fila inicial (inclusive), 0 <= StartRow < N
    EndRow   int // fila final (exclusive), StartRow < EndRow <= N
}

// Result: resultado parcial por bloque (opcional, para validación interna)
type Result struct {
    StartRow int
    EndRow   int
    // No se copian datos; el worker escribe directamente en C.Data
}
```

---

## 3. Flujo Principal (`main.go`)

```text
main()
├── 1. Parsear y validar flags: --n, --seed, --workers
│   ├── Rechazar si faltan, N < 1, seed fuera de [0, 2^32-1], workers < 1
│   └── runtime.GOMAXPROCS(workers); gomaxprocs = runtime.GOMAXPROCS(0)  // fija, consulta y registra valor efectivo
├── 2. Validar tamaño: comprobar N*N y N*N*8 antes de multiplicar; considerar RAM para A/B/C
├── 3. Asignar matrices A, B, C (heap, contiguas)
│   ├── A = make([]float64, N*N)
│   ├── B = make([]float64, N*N)
│   └── C = make([]float64, N*N)  // reserva fuera de total_s; vaciado explícito dentro
├── 4. Generar A y B; reservar kernelDurations  // PRNG determinista, instrumentación fuera de total_s
├── 5. Medición total_s: time.Now()  // [T0] inicio total_s
├── 6. Vaciar C; crear canal de tareas: tasks := make(chan Task, workers)
├── 7. Iniciar WaitGroup: var wg sync.WaitGroup
├── 8. Lanzar workers fijos:
│   for w := 0; w < workers; w++ {
│       wg.Add(1)
│       go worker(w, tasks, &wg, &A, &B, &C, kernelDurations)
│   }
├── 9. Despachar bloques de filas al canal (productor único):
│   blockSize := computeBlockSize(N, workers)
│   for start := 0; start < N; {
│       end := N
│       if blockSize < N-start { end = start + blockSize }
│       tasks <- Task{StartRow: start, EndRow: end}
│       start = end
│   }
│   close(tasks)  // señal de fin: no más tareas (tras enviar todas)
├── 10. wg.Wait()  // bloquea hasta que todos los workers terminen
├── 11. Medición total_s: total_s = time.Since(T0)  // [T1] fin total_s
├── 12. Obtener máximo de tiempos locales; validar C (elemento a elemento vs referencia, tolerancia 1e-9)
├── 13. Imprimir CSV en stdout con las 20 columnas del protocolo
└── 14. os.Exit(0)  // o código ≠ 0 si error
```

---

## 4. Worker (`workers.go`)

Pseudocódigo de la implementación futura. A/B/C y el vector de tiempos se
reservan antes de total_s; C se vacía dentro de total_s antes de lanzar workers.
Cada slot de tiempo pertenece a un solo worker y se consulta después de WaitGroup.

```go
func worker(id int, tasks <-chan Task, wg *sync.WaitGroup,
    A, B, C *Matrix, kernelDurations []time.Duration) {
    defer wg.Done()
    var elapsed time.Duration
    for task := range tasks {             // recepción fuera del kernel
        start := time.Now()
        multiplyBlock(A, B, C, task.StartRow, task.EndRow)
        elapsed += time.Since(start)      // solo cálculo de esta tarea
    }
    kernelDurations[id] = elapsed          // antes de Done; sin escritor compartido
}

func multiplyBlock(A, B, C *Matrix, startRow, endRow int) {
    N := A.N
    // C ya está vaciada. Aquí solo se acumula el producto i,k,j.
    for i := startRow; i < endRow; i++ {
        for k := 0; k < N; k++ {
            a := A.Data[i*N + k]
            for j := 0; j < N; j++ {
                C.Data[i*N+j] += a * B.Data[k*N+j]
            }
        }
    }
}
```

---

## 5. Invariantes de Correctitud

| # | Invariante | Dónde se garantiza | Verificación |
|---|------------|-------------------|--------------|
| **I1** | **Propiedad exclusiva de filas**: cada fila de $C$ es escrita por **exactamente un** worker | `multiplyBlock` recibe rango disjunto `[StartRow, EndRow)`; partición cubre `[0, N)` sin solapamientos ni huecos | Test: `go test -race` + fixture N=2, workers=4 |
| **I2** | **Sin *data races***: $A$ y $B$ solo lectura; $C$ escritura disjunta por fila | `A` y `B` pasados como `*Matrix` (no se modifican); `C` escrito solo en índices `i*N+j` con `i` en rango propio del worker | `go test -race ./...` |
| **I3** | **Cierre ordenado del canal**: `close(tasks)` **solo** después de enviar todas las tareas, y **solo** desde `main` (productor único) | `main` envía todos los bloques en bucle `for`, luego `close(tasks)` | Test: `workers` > `N` no hace panic |
| **I4** | **Sincronización completa**: `wg.Wait()` retorna **solo después** de que todos los workers hayan salido del `range tasks` | `wg.Add(workers)` antes de lanzar; cada worker `defer wg.Done()` al salir de `for range` | Test: variar workers=1,2,4,8; verificar que termina |
| **I5** | **Cierre sin bloqueo permanente**: consumidores activos, productor único, envío antes de close y WaitGroup después de close | Consumidores lanzados antes del primer envío; productor cierra; consumidores terminan y llaman a Done | Test: stress con N=1000, workers=8 |
| **I6** | **Inicialización de C dentro de total_s y fuera del kernel**: el coordinador vacía C antes de lanzar workers | El coordinador vacía toda C antes del despacho; multiplyBlock solo acumula | Validación numérica vs fixture |
| **I7** | **Generación determinista**: mismo `seed` → mismas matrices $A, B$ en C y Go | `input.Generate` usa LCG idéntico: `state = (1664525*state + 1013904223) % 2^32` | Vectores de control en `docs/formato_datos.md` |

---

## 6. Particionado de Filas (Distribución de Trabajo)

**Estrategia:** Bloques contiguos de tamaño fijo o calculado por división entera.

```go
func computeBlockSize(N, workers int) int {
    // Opción A: tamaño fijo (ej. 64 filas) → mejor balanceo dinámico
    // Opción B: división entera → ceil(N/workers)
    // Para S4: usar división entera simple
    blockSize := N / workers
    if N % workers != 0 { blockSize++ } // ceil sin suma que pueda desbordar
    if blockSize < 1 {
        blockSize = 1
    }
    return blockSize
}
```

**Precondiciones:** N y workers positivos y tamaño matricial válido.

**Casos límite:**
- `workers >= N`: `blockSize = 1` → cada tarea tiene una fila; un worker puede consumir varias tareas y los que no reciben ninguna salen tras close
- `N % workers != 0`: último bloque más pequeño; `min(start+blockSize, N)` lo maneja
- `workers = 1`: un solo bloque `[0, N)` → equivalente a secuencial (útil para medir sobrecoste)

---

## 7. Delimitación de tiempos (`kernel_s` vs `total_s`)

Aplicar `protocolo_medicion.md`, sección 3. El kernel es el máximo de los
intervalos de cálculo acumulados por cada worker, no el tiempo desde el primer
envío de tareas hasta WaitGroup. Despacho, espera y vaciado solo cuentan en total_s.

| Evento | Frontera |
| --- | --- |
| Antes de T0 | A/B/C preparados y reservados; validación de entradas, referencia y vector de tiempos listos. |
| T0 | Antes de vaciar C y de crear canal/workers. |
| Kernel local | Dentro de cada worker, justo antes y después de multiplyBlock; acumular por worker. |
| T1 | Inmediatamente después de wg.Wait(), antes de validar o escribir. |
| Después de T1 | Calcular máximo de tiempos, validar C, escribir CSV y liberar buffers. |

Pseudocódigo futuro; no supone que el multiplicador ya existe:

```go
kernelDurations := make([]time.Duration, workers) // instrumentación fuera de total_s
totalStart := time.Now()
for i := range C.Data { C.Data[i] = 0 }
tasks := make(chan Task, workers)
var wg sync.WaitGroup
for w := 0; w < workers; w++ {
    wg.Add(1)
    go worker(w, tasks, &wg, &A, &B, &C, kernelDurations)
}
blockSize := computeBlockSize(N, workers)
for start := 0; start < N; {
    end := N
    if blockSize < N-start { end = start + blockSize }
    tasks <- Task{StartRow: start, EndRow: end}
    start = end
}
close(tasks)
wg.Wait()
total_s := time.Since(totalStart).Seconds()  // detener antes de validación/I/O
var kernelDuration time.Duration
for _, duration := range kernelDurations {
    if duration > kernelDuration { kernelDuration = duration }
}
kernel_s := kernelDuration.Seconds()
// Validar y escribir solo después de detener total_s.
```

Un worker sin tareas aporta cero. No se cronometra el range/recepción del canal.
Lectura/generación, reserva/liberación de matrices, argumentos, validación y salida
quedan fuera de ambos intervalos. La creación del canal y las goroutines sí es
coordinación dentro de total_s. Los tiempos deben ser finitos y no negativos;
solo se aceptan mediciones con resultado matemático válido.

---

## 8. Manejo de Errores

| Situación | Tipo | Acción | Código de salida |
|-----------|------|--------|------------------|
| Flags faltantes/inválidos | **Entrada inválida** | `fmt.Fprintln(os.Stderr, "uso: ...")` | 1 |
| `N < 1` o `workers < 1` | **Entrada inválida** | Error a `stderr` | 1 |
| `seed > 2^32-1` | **Entrada inválida** | Error a `stderr` | 1 |
| Fallo controlado de asignación memoria | **Entorno** | Error a `stderr` | 1 |
| Operación pendiente (algoritmo no implementado) | **Pendiente** | `fmt.Fprintln(os.Stderr, "PENDIENTE: ...")` | 2 |
| Validación numérica falla | **Cálculo** | `fmt.Fprintf(stderr, "validación falló: ...")` | 1 |
| *Data race* detectado (`-race`) | **Entorno** | Termina con error del runtime | ≠0 |

**Regla común:** éxito → 0; cualquier error de entrada, archivo, memoria, entorno o cálculo → stderr y 1; únicamente operación pendiente → stderr y 2. Son códigos del ejecutable, no los estados internos de C. Un fallo no imprime una medición válida ni una matriz parcial. La CLI completa se integrará en S4; la prueba actual de cálculo sigue devolviendo pendiente.

---

## 9. Salida CSV (stdout)

Formato según `docs/protocolo_medicion.md` §4:

```text
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status
2026-10-15T14:32:05Z,go_paralelo,abc1234,PC-USER,AMD Ryzen 7 8845HS,16.0,Win11_26200,go_paralelo_W4,1024,42,1,1,1,4,4,1,false,0.485123901,0.521894210,OK
```

Campos específicos de Go paralelo:
- `version`: `go_paralelo`
- `configuration`: `go_paralelo_W{workers}`
- `processes`: `1` (no usa MPI)
- `threads`: `1` (no usa OpenMP)
- `workers`: valor de `--workers`
- `gomaxprocs`: valor efectivo consultado con `runtime.GOMAXPROCS(0)` tras fijarlo

---

## 10. Generación Determinista (PRNG)

Según `docs/contrato.md` §20:

```go
// LCG: state = (1664525 * state + 1013904223) mod 2^32
// Valor ∈ [-1000, 1000] / 1000.0
func generateMatrix(N int, state *uint32) []float64 {
    data := make([]float64, N*N)
    for i := 0; i < N*N; i++ {
        *state = 1664525*(*state) + 1013904223
        val := int64(*state % 2001) - 1000  // [-1000, 1000]
        data[i] = float64(val) / 1000.0
    }
    return data
}
```

**Vectores de control (seed=42):**
- Estados iniciales: 1083814273, 378494188, 2479403867, 955863294
- Llenar A completa por filas, luego B continuando el mismo estado

---

## 11. Validación Numérica

Según `docs/contrato.md` §49-53:

```go
const atol = 1e-9
const rtol = 1e-9

func validate(C, Cref *Matrix) error {
    if C.N != Cref.N { return fmt.Errorf("dimensión distinta") }
    for i := 0; i < C.N*C.N; i++ {
        got := C.Data[i]
        exp := Cref.Data[i]
        if math.IsNaN(got) || math.IsInf(got, 0) || math.IsNaN(exp) || math.IsInf(exp, 0) {
            return fmt.Errorf("NaN/Inf en C[%d]", i)
        }
        diff := math.Abs(got - exp)
        tol := atol + rtol*math.Abs(exp)
        if diff > tol {
            return fmt.Errorf("mismatch C[%d]: got=%v exp=%v diff=%v tol=%v", i, got, exp, diff, tol)
        }
    }
    return nil
}
```

---

## 12. Pruebas de Arquitectura (Para Sprint 4)

**Ejecución:** Todas las pruebas se ejecutan desde dentro del módulo `go_paralelo/`:
```powershell
cd go_paralelo
go test -race -run TestWorkerRowOwnership
go test -race ./...
go test -run TestChannelClose
# etc.
```

| Test | Qué verifica | Comando |
|------|--------------|---------|
| `TestWorkerRowOwnership` | I1: cada fila escrita una vez | `go test -race -run TestWorkerRowOwnership` |
| `TestNoDataRaces` | I2: sin carreras en A/B/C | `go test -race ./...` |
| `TestChannelClose` | I3: close tras enviar todas | `go test -run TestChannelClose` |
| `TestWaitGroupSync` | I4: wg.Wait retorna tras todos | `go test -run TestWaitGroupSync` |
| `TestWorkersGTN` | I5: workers > N no deadlock | `go test -run TestWorkersGTN` |
| `TestStress` | I5: N=1000, workers=8 estable | `go test -run TestStress -count=10` |
| `TestValidateFixtures` | I6+I7: equivalencia numérica | `go test -run TestValidateFixtures` |
| `TestEdgeCases` | N=1, impar, workers=1, workers>N | `go test -run TestEdgeCases` |

---

## 13. Trazabilidad con Contrato y Guía

| Requisito | Documento | Sección arquitectura |
|-----------|-----------|---------------------|
| Pool acotado, canal tareas, WaitGroup | `contrato.md` §31, `Guia_Sprints.md` §70 | §3, §4 |
| Propiedad exclusiva de filas | `Guia_Sprints.md` §70 | §5 (I1, I6) |
| No goroutine por celda | `Guia_Sprints.md` §70 | §4 (bloques de filas) |
| A/B solo lectura | `Guia_Sprints.md` §70 | §5 (I2) |
| Cierre canal + WaitGroup | `Guia_Sprints.md` §70 | §5 (I3, I4) |
| GOMAXPROCS fijado y registrado | `contrato.md` §11 | §3 (paso 1), §9 |
| kernel_s / total_s delimitados | `protocolo_medicion.md` §3 | §7 |
| Generación determinista LCG | `contrato.md` §20, `formato_datos.md` | §10 |
| Validación atol/rtol 1e-9 | `contrato.md` §51-52 | §11 |
| CSV stdout con campos requeridos | `protocolo_medicion.md` §4 | §9 |

---

## 14. Pendientes para Sprints Posteriores

| Sprint | Tarea | Responsable |
|--------|-------|-------------|
| **S3** | Integrar y conservar pruebas de `input.Generate` y lector ya implementados | Integrante 4 / 7 |
| **S3** | Implementar `Multiply` secuencial en `matrix.go` (referencia) | Integrante 3 |
| **S4** | Implementar `worker` y `multiplyBlock` en `workers.go` | Integrante 3 / 4 |
| **S4** | Integrar flags, canal, WaitGroup, tiempos en `main.go` | Integrante 4 |
| **S4** | Salida CSV completa | Integrante 4 |
| **S5** | Revisar límites workers, estabilidad, repeticiones largas | Integrante 4 |
| **S6** | Sintonizar `blockSize` (granularidad) con mediciones | Integrante 4 |
| **S7** | Completar caso Go paralelo en `bench_windows.ps1` | Integrante 4 |

---

## 15. Registro de Decisiones de Diseño

| Decisión | Justificación | Alternativa descartada |
|----------|---------------|------------------------|
| Buffer del canal = `workers` | Tamaño acotado; el envío puede esperar consumidores sin constituir un deadlock | Sin buffer (bloquea productor) o buffer `N` (memoria innecesaria) |
| Bloques contiguos de filas | Localidad de caché: cada worker accede a filas contiguas de C y recorre A/B secuencialmente | Filas intercaladas (stride) → peor localidad |
| `GOMAXPROCS = workers` | Limita ejecución simultánea de código Go; consultar y registrar el valor efectivo | `GOMAXPROCS = NumCPU()` → ignora flag `--workers` |
| Vaciar C antes de lanzar workers, dentro de total_s | Mismo límite que las referencias; kernel mide solo acumulación | Vaciar dentro de multiplyBlock mezclaría inicialización y cálculo |
| Validación elemento a elemento | Contrato exige comparación completa; checksum no sustituye | Solo checksum → no detecta errores locales |

---

## 16. Referencias

- `docs/contrato.md` — Contrato de argumentos, generación, cálculo, corrección
- `docs/formato_datos.md` — Formato fixtures, vectores de control PRNG
- `docs/protocolo_medicion.md` — Delimitación tiempos, CSV, matriz experimentos
- `docs/Guia_Sprints.md` §69-70 — Núcleo secuencial y Go paralelo
- `docs/diagnostico_go_paralelo.md` — Estado actual y pendientes priorizados

---

**Autor:** Integrante 4
**Revisión cruzada:** Pendiente (Integrante 3)
