package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"
)

// Comparativa de granularidad de S6 (I4). Las pruebas de equivalencia y los
// benchmarks del canal corren con go test; la medición de tiempos solo corre
// cuando GO_GRANULARITY_CSV indica dónde escribir las observaciones.

type granularity struct {
	name      string
	blockRows func(n, workers int) int
}

// granularities ordena las alternativas de más gruesa a más fina. "W" es la
// canónica (un bloque por worker); "fila" es la más fina sin tareas por celda.
var granularities = []granularity{
	{"W", func(n, workers int) int { return computeBlockSize(n, workers) }},
	{"2W", func(n, workers int) int { return computeBlockSize(n, 2*workers) }},
	{"4W", func(n, workers int) int { return computeBlockSize(n, 4*workers) }},
	{"8W", func(n, workers int) int { return computeBlockSize(n, 8*workers) }},
	{"fijo16", func(n, workers int) int { return 16 }},
	{"fila", func(n, workers int) int { return 1 }},
}

func TestDispatchRowBlocksOfSizeCoverage(t *testing.T) {
	for _, n := range []int{1, 5, 17, 129} {
		for _, size := range []int{1, 2, 3, 16, n, n + 1} {
			tasks := make(chan Task, n)
			dispatchRowBlocksOfSize(n, size, tasks)
			close(tasks)
			next, count := 0, 0
			for task := range tasks {
				if task.StartRow != next || task.EndRow <= task.StartRow || task.EndRow-task.StartRow > size || task.EndRow > n {
					t.Fatalf("N=%d size=%d: bloque inválido %+v tras %d", n, size, task, next)
				}
				next = task.EndRow
				count++
			}
			if next != n || count != computeBlockSize(n, size) {
				t.Fatalf("N=%d size=%d: cubrió %d filas con %d tareas", n, size, next, count)
			}
		}
	}
}

func TestBlockSizesBitwiseEquivalent(t *testing.T) {
	for _, n := range []int{1, 2, 7, 17, 64, 129} {
		a, b, err := Generate(n, 42)
		if err != nil {
			t.Fatal(err)
		}
		baseline, err := MultiplyParallel(a, b, 1)
		if err != nil {
			t.Fatal(err)
		}
		for _, workers := range []int{1, 3, 8, 16} {
			sizes := []int{n, n + 5}
			for _, g := range granularities {
				sizes = append(sizes, g.blockRows(n, workers))
			}
			for _, blockRows := range sizes {
				c := Matrix{N: n, Data: make([]float64, n*n)}
				durations := make([]time.Duration, workers)
				multiplyParallelKernelBlocks(a, b, c, workers, blockRows, durations)
				assertBitwiseEqual(t, fmt.Sprintf("N=%d W=%d bloque=%d", n, workers, blockRows), c, baseline)
			}
		}
	}
}

// minClockStep devuelve el menor avance positivo observado de un reloj.
func minClockStep(now func() time.Duration) time.Duration {
	smallest := time.Duration(1<<63 - 1)
	last := now()
	for steps, deadline := 0, time.Now().Add(time.Second); steps < 200 && time.Now().Before(deadline); {
		if current := now(); current > last {
			smallest = min(smallest, current-last)
			last = current
			steps++
		}
	}
	return smallest
}

func TestPreciseClockResolution(t *testing.T) {
	origin := preciseNow()
	precise := minClockStep(func() time.Duration { return preciseSince(origin) })
	wall := time.Now()
	production := minClockStep(func() time.Duration { return time.Since(wall) })
	t.Logf("%s: paso mínimo %v; time.Now: paso mínimo %v", preciseClockName, precise, production)
	if precise > 10*time.Microsecond {
		t.Fatalf("%s avanza a saltos de %v; la comparativa necesita < 10µs", preciseClockName, precise)
	}
}

// BenchmarkTaskChannel mide el envío y la recepción de una tarea vacía por el
// canal del pool (ns/op = coste por tarea), sin cómputo.
func BenchmarkTaskChannel(b *testing.B) {
	for _, workers := range []int{1, 2, 4, 8, 16} {
		b.Run(fmt.Sprintf("W%d", workers), func(b *testing.B) {
			previous := runtime.GOMAXPROCS(workers)
			defer runtime.GOMAXPROCS(previous)
			tasks := make(chan Task, workers)
			var wg sync.WaitGroup
			wg.Add(workers)
			for id := 0; id < workers; id++ {
				go func() {
					defer wg.Done()
					for range tasks {
					}
				}()
			}
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				tasks <- Task{StartRow: i, EndRow: i + 1}
			}
			close(tasks)
			wg.Wait()
		})
	}
}

// BenchmarkKernelCoordination mide crear el canal y el pool, despachar una
// tarea de 1x1, cerrar y esperar: el coste fijo de coordinación por corrida.
func BenchmarkKernelCoordination(b *testing.B) {
	a := Matrix{N: 1, Data: []float64{1}}
	for _, workers := range []int{1, 2, 4, 8, 16} {
		b.Run(fmt.Sprintf("W%d", workers), func(b *testing.B) {
			previous := runtime.GOMAXPROCS(workers)
			defer runtime.GOMAXPROCS(previous)
			c := Matrix{N: 1, Data: []float64{0}}
			durations := make([]time.Duration, workers)
			b.ReportAllocs()
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				c.Data[0] = 0
				multiplyParallelKernel(a, a, c, workers, durations)
			}
		})
	}
}

type granularitySample struct {
	n, workers, blockRows, tasks, repetition int
	name                                     string
	kernel, total, qpcTotal                  time.Duration
}

func envInts(t *testing.T, name string, fallback []int) []int {
	value := os.Getenv(name)
	if value == "" {
		return fallback
	}
	var values []int
	for _, field := range strings.Split(value, ",") {
		number, err := strconv.Atoi(strings.TrimSpace(field))
		if err != nil || number <= 0 {
			t.Fatalf("%s: valor inválido %q", name, field)
		}
		values = append(values, number)
	}
	return values
}

// quantile interpola linealmente entre observaciones ordenadas (tipo 7).
func quantile(sorted []float64, p float64) float64 {
	position := p * float64(len(sorted)-1)
	lower := int(position)
	if lower+1 >= len(sorted) {
		return sorted[len(sorted)-1]
	}
	return sorted[lower] + (position-float64(lower))*(sorted[lower+1]-sorted[lower])
}

func formatSeconds(d time.Duration) string {
	return strconv.FormatFloat(d.Seconds(), 'f', 9, 64)
}

// TestGranularityExperiment mide total_s y kernel_s con las mismas fronteras
// que execute: reservas, validación y GOMAXPROCS fuera; vaciado de C, canal,
// pool, despacho, cierre y espera dentro de total_s. total_s usa el mismo
// reloj monotono que worker; QPC queda como diagnostico auxiliar independiente.
// Cada ronda alterna el orden de las granularidades y la repetición 0 es
// calentamiento.
func TestGranularityExperiment(t *testing.T) {
	path := os.Getenv("GO_GRANULARITY_CSV")
	if path == "" {
		t.Skip("defina GO_GRANULARITY_CSV para medir la granularidad")
	}
	sizes := envInts(t, "GO_GRANULARITY_N", []int{256, 512, 1024, 2048})
	workersList := envInts(t, "GO_GRANULARITY_W", []int{1, 2, 4, 8, 16})
	repetitions := envInts(t, "GO_GRANULARITY_REPETITIONS", []int{5})[0]
	previous := runtime.GOMAXPROCS(0)
	defer runtime.GOMAXPROCS(previous)

	var samples []granularitySample
	for _, n := range sizes {
		a, b, err := Generate(n, 42)
		if err != nil {
			t.Fatal(err)
		}
		baseline, err := MultiplyParallel(a, b, 1)
		if err != nil {
			t.Fatal(err)
		}
		c := Matrix{N: n, Data: make([]float64, n*n)}
		for repetition := 0; repetition <= repetitions; repetition++ {
			for _, workers := range workersList {
				durations := make([]time.Duration, workers)
				if err := validateKernelBuffers(a, b, c, workers, durations); err != nil {
					t.Fatal(err)
				}
				for offset := range granularities {
					g := granularities[(offset+repetition)%len(granularities)]
					blockRows := g.blockRows(n, workers)
					runtime.GOMAXPROCS(workers)
					runtime.GC()
					qpcStart := preciseNow()
					start := time.Now()
					clear(c.Data)
					multiplyParallelKernelBlocks(a, b, c, workers, blockRows, durations)
					total := time.Since(start)
					qpcTotal := preciseSince(qpcStart)
					// kernel sale del reloj de producción de cada worker
					// (time.Now); con muchas tareas acumula su redondeo.
					var kernel time.Duration
					for _, d := range durations {
						kernel = max(kernel, d)
					}
					if kernel < 0 || total < kernel {
						t.Fatalf("tiempos invalidos N=%d W=%d %s: kernel=%v total=%v", n, workers, g.name, kernel, total)
					}
					assertBitwiseEqual(t, fmt.Sprintf("N=%d W=%d %s", n, workers, g.name), c, baseline)
					samples = append(samples, granularitySample{n, workers, blockRows,
						computeBlockSize(n, blockRows), repetition, g.name, kernel, total, qpcTotal})
				}
			}
			t.Logf("N=%d repetición %d completada", n, repetition)
		}
	}
	writeGranularityRaw(t, path, samples)
	writeGranularitySummary(t, strings.TrimSuffix(path, ".csv")+"_resumen.csv", samples)
}

func writeGranularityRaw(t *testing.T, path string, samples []granularitySample) {
	f, err := os.Create(path)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	w := csv.NewWriter(f)
	w.Write([]string{"n", "workers", "gomaxprocs", "granularity", "block_rows", "tasks",
		"repetition", "is_warmup", "kernel_s", "total_s", "overhead_s", "total_clock", "go_version", "qpc_total_s"})
	for _, s := range samples {
		w.Write([]string{strconv.Itoa(s.n), strconv.Itoa(s.workers), strconv.Itoa(s.workers), s.name,
			strconv.Itoa(s.blockRows), strconv.Itoa(s.tasks), strconv.Itoa(s.repetition),
			strconv.FormatBool(s.repetition == 0), formatSeconds(s.kernel), formatSeconds(s.total),
			formatSeconds(s.total - s.kernel), "time.Now monotonic", runtime.Version(), formatSeconds(s.qpcTotal)})
	}
	w.Flush()
	if err := w.Error(); err != nil {
		t.Fatal(err)
	}
}

// writeGranularitySummary resume las repeticiones medidas (sin calentamiento)
// por N, W y granularidad. delta_total_pct compara medianas de total_s con la
// granularidad canónica; paired_faster cuenta las rondas en que la alternativa
// fue más rápida que la canónica medida en la misma ronda.
func writeGranularitySummary(t *testing.T, path string, samples []granularitySample) {
	type key struct {
		n, workers int
		name       string
	}
	groups := make(map[key][]granularitySample)
	var order []key
	canonical := make(map[[3]int]time.Duration) // n, workers, repetition
	for _, s := range samples {
		if s.repetition == 0 {
			continue
		}
		k := key{s.n, s.workers, s.name}
		if _, ok := groups[k]; !ok {
			order = append(order, k)
		}
		groups[k] = append(groups[k], s)
		if s.name == "W" {
			canonical[[3]int{s.n, s.workers, s.repetition}] = s.total
		}
	}
	medians := make(map[key]float64)
	for k, group := range groups {
		var totals []float64
		for _, s := range group {
			totals = append(totals, s.total.Seconds())
		}
		sort.Float64s(totals)
		medians[k] = quantile(totals, 0.5)
	}
	f, err := os.Create(path)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	w := csv.NewWriter(f)
	w.Write([]string{"n", "workers", "granularity", "block_rows", "tasks", "measured",
		"median_total_s", "iqr_total_s", "min_total_s", "max_total_s",
		"median_kernel_s", "median_overhead_s", "delta_total_pct", "paired_faster"})
	sort.SliceStable(order, func(i, j int) bool {
		if order[i].n != order[j].n {
			return order[i].n < order[j].n
		}
		return order[i].workers < order[j].workers
	})
	for _, k := range order {
		group := groups[k]
		var totals, kernels, overheads []float64
		faster := 0
		for _, s := range group {
			totals = append(totals, s.total.Seconds())
			kernels = append(kernels, s.kernel.Seconds())
			overheads = append(overheads, (s.total - s.kernel).Seconds())
			if s.total < canonical[[3]int{s.n, s.workers, s.repetition}] {
				faster++
			}
		}
		sort.Float64s(totals)
		sort.Float64s(kernels)
		sort.Float64s(overheads)
		delta := 100 * (medians[k]/medians[key{k.n, k.workers, "W"}] - 1)
		format := func(v float64) string { return strconv.FormatFloat(v, 'f', 9, 64) }
		w.Write([]string{strconv.Itoa(k.n), strconv.Itoa(k.workers), k.name,
			strconv.Itoa(group[0].blockRows), strconv.Itoa(group[0].tasks), strconv.Itoa(len(group)),
			format(medians[k]), format(quantile(totals, 0.75) - quantile(totals, 0.25)),
			format(totals[0]), format(totals[len(totals)-1]),
			format(quantile(kernels, 0.5)), format(quantile(overheads, 0.5)),
			strconv.FormatFloat(delta, 'f', 2, 64), fmt.Sprintf("%d/%d", faster, len(group))})
	}
	w.Flush()
	if err := w.Error(); err != nil {
		t.Fatal(err)
	}
}
