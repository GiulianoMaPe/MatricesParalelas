# Comparativa de granularidad Go — Sprint 6, I4

> Revisión de integración del 12/11/2026: se conserva la entrega y sus datos
> originales. La auditoría encontró 189/720 filas históricas con kernel mayor
> que total por la mezcla de relojes; no son observaciones contractuales válidas.
> La comparación original de total QPC es exploratoria. El arnés corregido usa
> el mismo reloj monotónico para total/kernel, conserva QPC como columna auxiliar
> y aborta ante tiempos inválidos. La resolución de Go se mide de nuevo por
> equipo/toolchain. Las recomendaciones W=8/16 corresponden al equipo de I4;
> no habilitan esos presupuestos en la PC de seis núcleos del cierre.
> Véanse [revisión](revision_s06.md) y [aceptación Windows](cierre_s06_windows.md).

**Responsable:** Eva Moreno (Integrante 4)
**Rama:** `feature/s06-i04-granularidad-go`
**Código:** [`go_paralelo/workers.go`](../go_paralelo/workers.go) y [`go_paralelo/granularity_test.go`](../go_paralelo/granularity_test.go)
**Datos:** [`resultados/experimentos/granularidad_go/`](../resultados/experimentos/granularidad_go/)

## Resumen

- **El canal no es un cuello de botella.** Una tarea cuesta 0,15–0,25 µs y crear el pool, 0,75–10 µs por corrida. Con la granularidad más fina medida (una fila por tarea, 2048 tareas) eso suma menos del 0,05 % de `total_s`.
- **Los bloques más finos sí mejoran algunos casos.** Con W=4 y W=8 y N ≥ 1024, bajan `total_s` entre un 4 y un 12 %. Con W=1, W=16 y N=512, el efecto es nulo o irregular. La causa es el balance de carga dinámico que da el canal, no un menor coste de coordinación.
- **Decisión: conservar el bloque canónico** `ceil(N/W)`, un bloque por worker, para la campaña. La mejora no es consistente en todas las configuraciones (regla de modificación justificada, [arquitectura §11](arquitectura.md)). Además, darle balance dinámico solo a Go sería una comparación injusta, porque C paralelo reparte de forma estática. La variante fina queda como experimento aislado (regla 3).
- **Cantidad de workers:** se recomienda la serie W ∈ {1, 2, 4, 8, 16}. W=16 usa los 16 hilos lógicos (SMT) y, con N ≥ 1024, rinde entre 1,6 y 1,7 veces más que W=8.
- **Hallazgo colateral sobre el reloj:** en este Windows, `time.Now()` de Go avanza a saltos de unos 0,5 ms, mientras que C mide con `QueryPerformanceCounter` o `MPI_Wtime` (100 ns). Ver [Resolución del reloj](#resolución-del-reloj).

## Pregunta y alternativas

El kernel envía por un canal bloques contiguos de filas; cada worker toma bloques hasta que el canal se cierra. La pregunta es si el tamaño de bloque o el coste del canal limitan el rendimiento, sin crear tareas por celda. Todas las alternativas conservan el orden `i,k,j`, las 2N³ operaciones y un escritor por fila, como exige el congelamiento algorítmico:

| Nombre | Filas por tarea | Tareas | Comentario |
| --- | --- | --- | --- |
| **W** (canónica) | `ceil(N/W)` | ≤ W | Un bloque por worker; equivale al reparto estático de C. |
| 2W, 4W, 8W | `ceil(N/(kW))` | ≤ kW | Varios bloques por worker. |
| fijo16 | 16 | `ceil(N/16)` | Tamaño fijo, independiente de W. |
| fila | 1 | N | La más fina posible sin bajar a tareas por celda. |

Para medir sin duplicar el kernel, `workers.go` expone `multiplyParallelKernelBlocks` y `dispatchRowBlocksOfSize`, que reciben el tamaño de bloque explícito. `multiplyParallelKernel` las llama con `computeBlockSize(N, W)`, así que el ejecutable de la campaña no cambia.

## Método

- **Entorno:** AMD Ryzen 7 3700X (8 núcleos, 16 hilos), 15,9 GB de RAM, Windows 11 Pro build 26200, plan de energía "AMD Ryzen Balanced" y Go 1.27.1 windows/amd64. Las mediciones se hicieron el 11/11/2026 sobre `dd008f7` más los cambios de esta rama, con el equipo conectado a la corriente.
- **Diseño:**
  - N ∈ {256, 512, 1024, 2048}, que son los tamaños del piloto y de la campaña oficial, y semilla 42.
  - W ∈ {1, 2, 4, 8, 16}.
  - Seis granularidades.
  - Una ronda de calentamiento y cinco medidas, según el [protocolo](protocolo_medicion.md).
  - En cada ronda se rota el orden de las granularidades, para no favorecer a ninguna por su posición.
  - Total: 720 corridas en 14 minutos.
- **Fronteras de tiempo:** las mismas de `execute`. La reserva de memoria, `validateKernelBuffers` y `GOMAXPROCS(W)` quedan fuera. Dentro de `total_s` entran el vaciado de C, el canal, el pool, el despacho, el cierre y la espera. Antes de cada corrida se llama a `runtime.GC()`, fuera de la medición, para que cada corrida empiece con el heap limpio, como un proceso nuevo.
- **Reloj:** `total_s` se mide con `QueryPerformanceCounter` (paso de 100 ns). `kernel_s` sale del reloj de producción de cada worker (`time.Now`). Como ese reloj redondea cada tarea, `kernel_s` no es comparable entre granularidades, y por eso la comparativa usa `total_s`.
- **Corrección:** cada corrida se compara bit a bit con el producto de W=1, y todas coincidieron.
- **Métricas:** mediana de `total_s` sobre las cinco rondas medidas, el IQR y la diferencia porcentual frente a la mediana canónica. También se cuentan las rondas en que la alternativa fue más rápida que la canónica medida en esa misma ronda ("emparejadas", sobre 5).

## Resultados

Diferencia de la mediana de `total_s` frente a la granularidad canónica. Un valor negativo significa más rápido. Entre paréntesis, las rondas emparejadas que fueron más rápidas.

| N | W | W canónico (ms) | 2W | 4W | 8W | fijo16 | fila |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 256 | 1 | 20,5 | -2,4 % (3/5) | +0,0 % (1/5) | -0,5 % (2/5) | -10,6 % (5/5) | -7,4 % (4/5) |
| 256 | 2 | 15,0 | -21,6 % (3/5) | -21,0 % (3/5) | -36,3 % (3/5) | -36,4 % (4/5) | -37,0 % (4/5) |
| 256 | 4 | 5,6 | -3,5 % (3/5) | -3,9 % (4/5) | -13,1 % (4/5) | -4,8 % (4/5) | -21,9 % (4/5) |
| 256 | 8 | 3,9 | -0,3 % (4/5) | -21,2 % (5/5) | -25,3 % (5/5) | -0,1 % (3/5) | -20,6 % (5/5) |
| 256 | 16 | 3,0 | -8,2 % (4/5) | -17,9 % (4/5) | -23,1 % (4/5) | +0,3 % (2/5) | -19,3 % (4/5) |
| 512 | 1 | 131,4 | +6,6 % (0/5) | +1,9 % (0/5) | +0,7 % (0/5) | +1,2 % (2/5) | +2,2 % (1/5) |
| 512 | 2 | 73,3 | -4,5 % (2/5) | -10,9 % (5/5) | -9,0 % (4/5) | -7,3 % (4/5) | -7,1 % (3/5) |
| 512 | 4 | 35,3 | -1,0 % (3/5) | -4,9 % (5/5) | -1,8 % (3/5) | +9,2 % (2/5) | -2,8 % (3/5) |
| 512 | 8 | 22,2 | +10,3 % (2/5) | +2,9 % (2/5) | -6,8 % (4/5) | -4,7 % (5/5) | -12,8 % (3/5) |
| 512 | 16 | 18,2 | +2,6 % (1/5) | +2,7 % (2/5) | -6,3 % (3/5) | +3,0 % (3/5) | +2,8 % (1/5) |
| 1024 | 1 | 1089,4 | +0,3 % (3/5) | +3,1 % (2/5) | -0,2 % (3/5) | +3,3 % (1/5) | +2,7 % (1/5) |
| 1024 | 2 | 630,0 | +4,2 % (2/5) | -5,4 % (3/5) | +0,1 % (2/5) | -6,9 % (4/5) | -1,6 % (2/5) |
| 1024 | 4 | 418,4 | +2,9 % (2/5) | -6,8 % (4/5) | -7,4 % (5/5) | -11,9 % (5/5) | -9,9 % (5/5) |
| 1024 | 8 | 239,7 | -0,1 % (3/5) | -3,5 % (4/5) | -6,2 % (5/5) | -8,1 % (5/5) | -8,5 % (5/5) |
| 1024 | 16 | 137,5 | -0,5 % (2/5) | -1,0 % (3/5) | -0,5 % (3/5) | -1,6 % (4/5) | +3,2 % (0/5) |
| 2048 | 1 | 8933,5 | +0,5 % (2/5) | -0,4 % (2/5) | -1,2 % (4/5) | -0,3 % (2/5) | -0,6 % (2/5) |
| 2048 | 2 | 4719,5 | -1,5 % (3/5) | +0,3 % (3/5) | 0,0 % (2/5) | -1,1 % (3/5) | +2,1 % (1/5) |
| 2048 | 4 | 3296,5 | -0,4 % (2/5) | -3,0 % (3/5) | -7,6 % (4/5) | -8,7 % (4/5) | -7,5 % (5/5) |
| 2048 | 8 | 1886,3 | +1,2 % (2/5) | +0,5 % (3/5) | -2,2 % (4/5) | -4,2 % (5/5) | -4,0 % (5/5) |
| 2048 | 16 | 1162,2 | -1,0 % (3/5) | +0,7 % (3/5) | +0,7 % (2/5) | +0,2 % (2/5) | +1,9 % (0/5) |

Las medianas, IQR, mínimos, máximos y medianas de `kernel_s` completas están en [`granularidad_go_resumen.csv`](../resultados/experimentos/granularidad_go/granularidad_go_resumen.csv), y las 720 observaciones, en [`granularidad_go.csv`](../resultados/experimentos/granularidad_go/granularidad_go.csv).

### Lectura

- **W=1:** variar el tamaño de bloque no cambia nada medible con N ≥ 1024 (±3 %). Con un solo worker no hay nada que balancear, y la diferencia que queda es el coste del canal, que resulta despreciable.
- **N=256:** las diferencias relativas son grandes, pero se trata de corridas de 3 a 20 ms, con IQR de hasta 7 ms en la canónica con W=2. Son sensibles al ruido del sistema y no sirven para decidir nada para la campaña.
- **W=4 y W=8 con N ≥ 1024:** las variantes finas (8W, fijo16, fila) bajan `total_s` entre un 4 y un 12 %, con 4/5 o 5/5 rondas emparejadas a favor. La hipótesis, no verificada, es que con el reparto estático todos esperan al worker más lento, por ejemplo uno que el planificador de Windows pone en un hilo hermano SMT o en el otro CCX del Ryzen. Con bloques finos, los workers rápidos toman más tareas. Esa hipótesis también explica el bajo speedup canónico con W=4 (2,6–2,7 veces con N ≥ 1024).
- **W=16:** no hay efecto consistente (±2 %). Con todos los hilos lógicos ocupados, los workers avanzan a ritmos parecidos.
- **N=512:** los resultados son mixtos y cambian de signo según W; por ejemplo, fijo16 da +9,2 % con W=4 y 2W da +10,3 % con W=8.

### Coste del canal y de la coordinación

Benchmarks de Go (`-benchtime 2s -count 3`); la salida completa está en [`benchmarks_canal.txt`](../resultados/experimentos/granularidad_go/benchmarks_canal.txt):

| W | Envío y recepción de una tarea vacía (`BenchmarkTaskChannel`) | Canal, pool, una tarea 1x1, cierre y espera (`BenchmarkKernelCoordination`) |
| ---: | ---: | ---: |
| 1 | 143–148 ns | 753–760 ns, 6 asignaciones |
| 2 | 253–262 ns | 2,6–2,7 µs, 7 asignaciones |
| 4 | 246–269 ns | 4,4–4,5 µs, 9 asignaciones |
| 8 | 244–253 ns | 5,8–6,1 µs, 13 asignaciones |
| 16 | 237–244 ns | 8,9–9,8 µs, 21 asignaciones |

En el peor caso medido (fila, N=2048) son 2048 tareas de unos 0,25 µs: unos 0,5 ms frente a 1,1–8,9 s de `total_s`, es decir, menos del 0,05 %. La coordinación fija por corrida (menos de 10 µs) es despreciable incluso con N=256.

### Cantidad de workers

Speedup de la granularidad canónica frente a W=1, calculado con medianas de `total_s`:

| N | W=2 | W=4 | W=8 | W=16 |
| ---: | ---: | ---: | ---: | ---: |
| 256 | 1,36 | 3,64 | 5,33 | 6,82 |
| 512 | 1,79 | 3,72 | 5,93 | 7,22 |
| 1024 | 1,73 | 2,60 | 4,54 | 7,92 |
| 2048 | 1,89 | 2,71 | 4,74 | 7,69 |

W=16 aprovecha el SMT: con N ≥ 1024 rinde entre 1,6 y 1,7 veces más que W=8. No se midió W > 16, porque supera los hilos lógicos del equipo. W > N está permitido, pero no aporta nada: los workers sobrantes terminan sin tareas.

## Decisión

1. **Se conserva la granularidad canónica `ceil(N/W)` en el ejecutable de la campaña.** No hay cambios en `computeBlockSize` ni en `multiplyParallelKernel`. Dos razones:
   - **No es una mejora consistente.** La regla de modificación justificada pide más del 5 % de forma consistente. Las variantes finas solo lo cumplen con W=4 y W=8 y N ≥ 1024; con W=1, W=16 y N=512 el efecto es nulo, irregular o en contra.
   - **Equidad.** C paralelo reparte de forma estática (`MPI_Scatterv` en bloques contiguos y `#pragma omp for schedule(static)` en [`c_paralelo/src/matrix.c`](../c_paralelo/src/matrix.c)). Darle balance dinámico solo a Go mezclaría el efecto del lenguaje con el de la política de reparto. Si el equipo quiere estudiarlo, debe hacerse de forma simétrica, por ejemplo `schedule(dynamic)` en C frente a bloques finos en Go, y como experimento separado.
2. **La variante fina queda como experimento aislado** (regla 3 de [arquitectura §11](arquitectura.md)). Vive en `granularity_test.go` y solo se ejecuta si se define `GO_GRANULARITY_CSV`.
3. **Serie de workers recomendada para la campaña:** W ∈ {1, 2, 4, 8, 16}. Se recomienda registrar en el análisis (S9) que el reparto estático deja entre un 4 y un 12 % de desbalance con W=4 y W=8 en este equipo; probablemente afecta también a C.

Este documento aporta la evidencia que pide I7 para su [registro de decisiones](optimizaciones.md), y la confirma de forma experimental para la decisión de I8 en [arquitectura §10.3](arquitectura.md).

## Resolución del reloj

`TestPreciseClockResolution` mide el menor avance positivo de cada reloj en esta PC: **100 ns** para `QueryPerformanceCounter` y **502 µs** para `time.Now()`. La resolución de `time.Now()` en Windows depende de la del temporizador del sistema, que otras aplicaciones pueden modificar, así que no es estable entre equipos.

En cambio, C secuencial usa `QueryPerformanceCounter` ([`c_secuencial/src/timer.c`](../c_secuencial/src/timer.c)) y C paralelo, `MPI_Wtime`. Por eso los tiempos cortos de las dos versiones Go en la campaña tendrán una resolución unas 5000 veces más gruesa que los de C:
- con N=256 y W=16, `total_s` ronda los 3 ms y el error de cuantización puede llegar al 15–30 %;
- con N ≥ 1024 baja del 1 %.

Este informe no cambia el reloj de los ejecutables, porque afecta a `go_secuencial` (I3) y al [protocolo de medición](protocolo_medicion.md) (I7). Se propone tratarlo antes del piloto del S7. Hay dos opciones:
- que los ejecutables Go midan con un reloj de alta resolución (en Windows, `QueryPerformanceCounter`, como hace esta comparativa);
- o, como mínimo, documentar la resolución y excluir del análisis los tiempos menores de unos 50 ms.

## Reproducción

Desde `go_paralelo/`, con el equipo conectado a la corriente y sin cargas pesadas en paralelo:

```powershell
$env:GO_GRANULARITY_CSV = (Resolve-Path ..\resultados\experimentos\granularidad_go).Path + '\granularidad_go.csv'
go test -count=1 -timeout 90m -v -run TestGranularityExperiment ./...
Remove-Item env:GO_GRANULARITY_CSV
go test -run '^$' -bench 'TaskChannel|KernelCoordination' -benchtime 2s -count 3 ./...
go test -count=1 -v -run 'PreciseClock|BlockSizes|DispatchRowBlocksOfSize' ./...
```

`GO_GRANULARITY_N`, `GO_GRANULARITY_W` y `GO_GRANULARITY_REPETITIONS` aceptan listas separadas por comas para ensayos más cortos. Las pruebas de equivalencia comprueban que todas las granularidades producen C idéntico bit a bit; corren siempre con `go test`.
