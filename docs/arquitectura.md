# Arquitectura Go Paralelo: Diseño con Invariantes

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)
**Sprint:** 2 · **Integrante:** 4 Moreno Eva· **Versión:** `go_paralelo`
**Estado:** Diseño pendiente de aprobación para implementación en Sprint 4
**Ubicación del código:** `go_paralelo/` (`main.go`, `workers.go`, `matrix.go`, `input.go`)

---

## 1. Visión General

La versión `go_paralelo` implementa la multiplicación de matrices cuadradas densas $C = A \times B$ de dimensión $N \times N$ usando un **pool acotado de workers** (goroutines) que consumen **bloques de filas** desde un **canal de tareas tipado**. La sincronización usa `sync.WaitGroup`. Los argumentos CLI son `--n N --seed SEED --workers W`.

**Principios rectores (de `docs/contrato.md` y `docs/guia-extraida.txt`):**
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
│   ├── Rechazar si faltan, N < 1, seed > 2^32-1, workers < 1
│   └── runtime.GOMAXPROCS(workers); gomaxprocs = runtime.GOMAXPROCS(0)  // fija, consulta y registra valor efectivo
├── 2. Validar tamaño: comprobar que N*N cabe en memoria (size_t) y que N*N*3*8 bytes no excede límite razonable
├── 3. Asignar matrices A, B, C (heap, contiguas)
│   ├── A = make([]float64, N*N)
│   ├── B = make([]float64, N*N)
│   └── C = make([]float64, N*N)  // se inicializa en 0 en el kernel
├── 4. Generar A y B (input.Generate)  // PRNG determinista, mismo estado
├── 5. Medición total_s: time.Now()  // [T0] inicio total_s
├── 6. Crear canal de tareas: tasks := make(chan Task, workers)
├── 7. Iniciar WaitGroup: var wg sync.WaitGroup
├── 8. Lanzar workers fijos:
│   for w := 0; w < workers; w++ {
│       wg.Add(1)
│       go worker(w, tasks, &wg, A, B, C, N)
│   }
├── 9. Despachar bloques de filas al canal (productor único):
│   blockSize := ceil(N / workers)  // o fijo, ej. 64 filas
│   for start := 0; start < N; start += blockSize {
│       end := min(start + blockSize, N)
│       tasks <- Task{StartRow: start, EndRow: end}
│   }
│   close(tasks)  // señal de fin: no más tareas (tras enviar todas)
├── 10. wg.Wait()  // bloquea hasta que todos los workers terminen
├── 11. Medición total_s: total_s = time.Since(T0)  // [T1] fin total_s
├── 12. Validar C (elemento a elemento vs referencia, tolerancia 1e-9)
├── 13. Imprimir CSV en stdout: N,workers,total_s,kernel_s,checksum,status
└── 14. os.Exit(0)  // o código ≠ 0 si error
```

---

## 4. Worker (`workers.go`)

```go
func worker(id int, tasks <-chan Task, wg *sync.WaitGroup, A, B, C *Matrix, N int) {
    defer wg.Done()

    // [K0] kernel_s inicia con la primera iteración real de cálculo
    // (se mide en main con time.Now() antes del primer envío al canal
    //  y time.Since() tras wg.Wait(); ver sección 7)

    for task := range tasks {
        // Propiedad exclusiva: este worker es dueño de filas [task.StartRow, task.EndRow)
        multiplyBlock(A, B, C, task.StartRow, task.EndRow, N)
    }
    // Al salir del range, el canal está cerrado y no hay más trabajo
}

func multiplyBlock(A, B, C *Matrix, startRow, endRow, N int) {
    // Orden de bucles i, k, j (igual que referencia secuencial)
    for i := startRow; i < endRow; i++ {
        // Inicializar fila i de C en 0 (parte del kernel_s)
        base := i * N
        for j := 0; j < N; j++ {
            C.Data[base+j] = 0
        }
        // Acumular productos
        for k := 0; k < N; k++ {
            a := A.Data[i*N + k]
            bBase := k * N
            cBase := i * N
            for j := 0; j < N; j++ {
                C.Data[cBase+j] += a * B.Data[bBase+j]
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
| **I2** | **Sin *data races***: $A$ y $B$ solo lectura; $C$ escritura disjunta por fila | `A` y `B` pasados como `*Matrix` (no se modifican); `C` escrito solo en índices `i*N+j` con `i` en rango propio del worker | `go test -race ./go_paralelo/...` |
| **I3** | **Cierre ordenado del canal**: `close(tasks)` **solo** después de enviar todas las tareas, y **solo** desde `main` (productor único) | `main` envía todos los bloques en bucle `for`, luego `close(tasks)` | Test: `workers` > `N` no hace panic |
| **I4** | **Sincronización completa**: `wg.Wait()` retorna **solo después** de que todos los workers hayan salido del `range tasks` | `wg.Add(workers)` antes de lanzar; cada worker `defer wg.Done()` al salir de `for range` | Test: variar workers=1,2,4,8; verificar que termina |
| **I5** | **No *deadlock***: canal con buffer `workers` evita bloqueo del productor; `close` + `range` + `WaitGroup` patrón estándar | `make(chan Task, workers)`; `close` en productor; `range` en consumidores | Test: stress con N=1000, workers=8 |
| **I6** | **Inicialización de $C$ a cero dentro del kernel**: cada worker pone a 0 sus filas antes de acumular | `multiplyBlock` pone `C.Data[base+j] = 0` al inicio de cada fila | Validación numérica vs fixture |
| **I7** | **Generación determinista**: mismo `seed` → mismas matrices $A, B$ en C y Go | `input.Generate` usa LCG idéntico: `state = (1664525*state + 1013904223) % 2^32` | Vectores de control en `docs/formato_datos.md` |

---

## 6. Particionado de Filas (Distribución de Trabajo)

**Estrategia:** Bloques contiguos de tamaño fijo o calculado por división entera.

```go
func computeBlockSize(N, workers int) int {
    // Opción A: tamaño fijo (ej. 64 filas) → mejor balanceo dinámico
    // Opción B: división entera → ceil(N/workers)
    // Para S4: usar división entera simple
    blockSize := (N + workers - 1) / workers // ceil
    if blockSize < 1 {
        blockSize = 1
    }
    return blockSize
}
```

**Casos límite:**
- `workers >= N`: `blockSize = 1` → cada worker recibe 0 o 1 fila; workers extra salen del `range` sin trabajo (correcto)
- `N % workers != 0`: último bloque más pequeño; `min(start+blockSize, N)` lo maneja
- `workers = 1`: un solo bloque `[0, N)` → equivalente a secuencial (útil para medir sobrecoste)

---

## 7. Delimitación de Tiempos (`kernel_s` vs `total_s`)

Según `docs/protocolo_medicion.md` (sección 3, tabla para `go_paralelo`):

| Evento | Variable | Código en `main.go` |
|--------|----------|---------------------|
| Inicio `total_s` ($T_0$) | `totalStart` | `totalStart := time.Now()` **antes** de crear canal y lanzar workers |
| Inicio `kernel_s` ($K_0$) | `kernelStart` | `kernelStart := time.Now()` **justo antes** del primer `tasks <- Task{...}` (inicio despacho) |
| Fin `kernel_s` ($K_1$) | `kernelEnd` | `kernelEnd := time.Now()` **justo después** de `wg.Wait()` (último worker terminó) |
| Fin `total_s` ($T_1$) | `totalEnd` | `totalEnd := time.Now()` **tras** validación y antes de CSV |

**Implementación precisa:**

```go
totalStart := time.Now()                    // [T0] inicio total_s

tasks := make(chan Task, workers)
var wg sync.WaitGroup
for w := 0; w < workers; w++ {
    wg.Add(1)
    go worker(w, tasks, &wg, A, B, C, N)
}

kernelStart := time.Now()                   // [K0] inicio cómputo puro (primer envío)
// Despachar tareas
blockSize := computeBlockSize(N, workers)
for start := 0; start < N; start += blockSize {
    end := start + blockSize
    if end > N { end = N }
    tasks <- Task{StartRow: start, EndRow: end}
}
close(tasks)

wg.Wait()                                   // espera a que terminen TODOS los workers
kernelEnd := time.Now()                     // [K1] fin cómputo puro (último worker terminó)

kernel_s := kernelEnd.Sub(kernelStart).Seconds()
total_s  := kernelEnd.Sub(totalStart).Seconds()  // [T1] ≈ fin total_s (sin validación/CSV)
```

**Excluidos de `kernel_s` (cómputo puro):**
- Parseo/validación de argumentos
- Asignación de memoria (`make`)
- Generación PRNG (`input.Generate`)
- **Espera final `wg.Wait()` → NO, está INCLUIDA en `kernel_s` (es sincronización del cómputo)**
- Validación matemática elemento a elemento
- Formateo/escritura CSV

**Excluidos de `total_s` (según protocolo §3.2):**
- Lectura de disco / fixtures
- Generación de datos (PRNG)
- Validación matemática
- Reserva/liberación memoria matrices completas
- Generación de reportes (CSV)

---

## 8. Manejo de Errores

| Situación | Tipo | Acción | Código de salida |
|-----------|------|--------|------------------|
| Flags faltantes/inválidos | **Entrada inválida** | `fmt.Fprintln(os.Stderr, "uso: ...")` | 2 |
| `N < 1` o `workers < 1` | **Entrada inválida** | Error a `stderr` | 2 |
| `seed > 2^32-1` | **Entrada inválida** | Error a `stderr` | 2 |
| Fallo asignación memoria (`make`) | **Entorno** | `panic` o error controlado → `stderr` | 1 |
| Operación pendiente (algoritmo no implementado) | **Pendiente** | `fmt.Fprintln(os.Stderr, "PENDIENTE: ...")` | 2 |
| Validación numérica falla | **Cálculo** | `fmt.Fprintf(stderr, "validación falló: ...")` | 1 |
| *Data race* detectado (`-race`) | **Entorno** | Termina con error del runtime | ≠0 |

**Regla:** Errores de **entrada** y **operaciones pendientes** → `stderr`, código 2. Errores de **entorno/cálculo** → `stderr`, código 1. Cualquier error **antes** de medición válida no imprime CSV parcial.

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
- `gomaxprocs`: valor de `runtime.GOMAXPROCS(workers)`

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
        if math.IsNaN(got) || math.IsInf(got, 0) {
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
| `TestNoDataRaces` | I2: sin carreras en A/B/C | `go test -race ./go_paralelo/...` |
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
| Pool acotado, canal tareas, WaitGroup | `contrato.md` §31, `guia-extraida.txt` §70 | §3, §4 |
| Propiedad exclusiva de filas | `guia-extraida.txt` §70 | §5 (I1, I6) |
| No goroutine por celda | `guia-extraida.txt` §70 | §4 (bloques de filas) |
| A/B solo lectura | `guia-extraida.txt` §70 | §5 (I2) |
| Cierre canal + WaitGroup | `guia-extraida.txt` §70 | §5 (I3, I4) |
| GOMAXPROCS fijado y registrado | `contrato.md` §11 | §3 (paso 1), §9 |
| kernel_s / total_s delimitados | `protocolo_medicion.md` §3 | §7 |
| Generación determinista LCG | `contrato.md` §20, `formato_datos.md` | §10 |
| Validación atol/rtol 1e-9 | `contrato.md` §51-52 | §11 |
| CSV stdout con campos requeridos | `protocolo_medicion.md` §4 | §9 |

---

## 14. Pendientes para Sprints Posteriores

| Sprint | Tarea | Responsable |
|--------|-------|-------------|
| **S3** | Implementar `input.Generate` (PRNG LCG) | Integrante 4 / 7 |
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
| Buffer del canal = `workers` | Evita bloqueo productor si workers lentos al inicio; tamaño acotado | Sin buffer (bloquea productor) o buffer `N` (memoria innecesaria) |
| Bloques contiguos de filas | Localidad de caché: cada worker accede a filas contiguas de C y recorre A/B secuencialmente | Filas intercaladas (stride) → peor localidad |
| `GOMAXPROCS = workers` | Mapea workers a hilos OS; evita sobrecoste de scheduler Go | `GOMAXPROCS = NumCPU()` → ignora flag `--workers` |
| Inicializar C a 0 dentro del kernel | Parte del cómputo puro; exclusivo de cada worker | Inicializar en main antes de despachar → incluido en `total_s` pero no en `kernel_s` |
| Validación elemento a elemento | Contrato exige comparación completa; checksum no sustituye | Solo checksum → no detecta errores locales |

---

## 16. Referencias

- `docs/contrato.md` — Contrato de argumentos, generación, cálculo, corrección
- `docs/formato_datos.md` — Formato fixtures, vectores de control PRNG
- `docs/protocolo_medicion.md` — Delimitación tiempos, CSV, matriz experimentos
- `docs/guia-extraida.txt` §69-70 — Núcleo secuencial y Go paralelo
- `docs/diagnostico_go_paralelo.md` — Estado actual y pendientes priorizados

---

**Autor:** Integrante 4
**Revisión cruzada:** Pendiente (Integrante 3)
