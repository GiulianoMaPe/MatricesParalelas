package main

import (
	"bytes"
	"encoding/csv"
	"errors"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"testing"
	"time"
)

// Pruebas de estabilidad de S5 (I4): límites de workers, propiedad de buffers,
// repeticiones largas, terminación y ausencia de fugas de goroutines.

const kernelDeadline = 30 * time.Second

// stabilityRepetitions escala las repeticiones con N para acotar la duración;
// -short divide entre 10 para las corridas con -race.
func stabilityRepetitions(n int) int {
	repetitions := 200
	switch {
	case n >= 129:
		repetitions = 10
	case n >= 64:
		repetitions = 50
	}
	if testing.Short() {
		repetitions /= 10
		if repetitions < 2 {
			repetitions = 2
		}
	}
	return repetitions
}

// runWithDeadline falla en lugar de colgarse si f no termina a tiempo.
func runWithDeadline(t *testing.T, name string, f func()) {
	t.Helper()
	done := make(chan struct{})
	go func() {
		defer close(done)
		f()
	}()
	timer := time.NewTimer(kernelDeadline)
	defer timer.Stop()
	select {
	case <-done:
	case <-timer.C:
		t.Fatalf("%s no terminó en %v: posible bloqueo", name, kernelDeadline)
	}
}

func assertBitwiseEqual(t *testing.T, label string, got, want Matrix) {
	t.Helper()
	if got.N != want.N || len(got.Data) != len(want.Data) {
		t.Fatalf("%s: dimensión %d/%d, esperada %d/%d", label, got.N, len(got.Data), want.N, len(want.Data))
	}
	for i := range want.Data {
		if math.Float64bits(got.Data[i]) != math.Float64bits(want.Data[i]) {
			t.Fatalf("%s: C[%d,%d] = %.17g; W=1 dio %.17g", label, i/got.N, i%got.N, got.Data[i], want.Data[i])
		}
	}
}

func TestLongRepetitionsBitwiseStable(t *testing.T) {
	for _, n := range []int{1, 2, 3, 17, 64, 129} {
		for _, seed := range []uint32{0, 42, ^uint32(0)} {
			a, b, err := Generate(n, seed)
			if err != nil {
				t.Fatal(err)
			}
			baseline, err := MultiplyParallel(a, b, 1)
			if err != nil {
				t.Fatal(err)
			}
			assertMatrixClose(t, baseline, referenceProduct(a, b))
			for _, workers := range []int{1, 2, 3, 4, 8, 16, n + 1, MaxWorkers} {
				t.Run(fmt.Sprintf("N%d/seed%d/W%d", n, seed, workers), func(t *testing.T) {
					for repetition := 0; repetition < stabilityRepetitions(n); repetition++ {
						got, err := MultiplyParallel(a, b, workers)
						if err != nil {
							t.Fatal(err)
						}
						assertBitwiseEqual(t, fmt.Sprintf("repetición %d", repetition), got, baseline)
					}
				})
			}
		}
	}
}

func TestKernelNoGoroutineLeak(t *testing.T) {
	a, b, err := Generate(17, 42)
	if err != nil {
		t.Fatal(err)
	}
	before := runtime.NumGoroutine()
	for call := 0; call < 300; call++ {
		workers := []int{1, 2, 8, 17, 18, 64}[call%6]
		if _, err := MultiplyParallel(a, b, workers); err != nil {
			t.Fatal(err)
		}
	}
	after := runtime.NumGoroutine()
	for deadline := time.Now().Add(2 * time.Second); after > before && time.Now().Before(deadline); {
		time.Sleep(10 * time.Millisecond)
		after = runtime.NumGoroutine()
	}
	if after > before {
		t.Fatalf("goroutines antes=%d, después=%d: el pool no terminó", before, after)
	}
}

func TestKernelTerminatesUnderDeadline(t *testing.T) {
	const n = 17
	a, b, err := Generate(n, 7)
	if err != nil {
		t.Fatal(err)
	}
	want := referenceProduct(a, b)
	for _, procs := range []int{1, 2} {
		for _, workers := range []int{1, n, n + 1, MaxWorkers} {
			t.Run(fmt.Sprintf("GOMAXPROCS%d/W%d", procs, workers), func(t *testing.T) {
				previous := runtime.GOMAXPROCS(procs)
				t.Cleanup(func() { runtime.GOMAXPROCS(previous) })
				c := Matrix{N: n, Data: make([]float64, n*n)}
				durations := make([]time.Duration, workers)
				for repetition := 0; repetition < stabilityRepetitions(n)/4+1; repetition++ {
					clear(c.Data)
					runWithDeadline(t, "multiplyParallelKernel", func() {
						multiplyParallelKernel(a, b, c, workers, durations)
					})
					assertMatrixClose(t, c, want)
				}
			})
		}
	}
}

func TestWorkerLimits(t *testing.T) {
	a, b, err := Generate(3, 42)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := MultiplyParallel(a, b, MaxWorkers); err != nil {
		t.Fatalf("W=MaxWorkers rechazado: %v", err)
	}
	for _, workers := range []int{MaxWorkers + 1, 1 << 30} {
		if _, err := MultiplyParallel(a, b, workers); !errors.Is(err, ErrTooManyWorkers) {
			t.Fatalf("W=%d: error %v; esperado ErrTooManyWorkers", workers, err)
		}
	}
	// Workers se valida antes que las matrices, igual que los valores no positivos.
	if _, err := MultiplyParallel(Matrix{}, Matrix{}, MaxWorkers+1); !errors.Is(err, ErrTooManyWorkers) {
		t.Fatalf("W>MaxWorkers con matrices vacías: %v", err)
	}
	for workers, wantCode := range map[int]int{MaxWorkers: 0, MaxWorkers + 1: 1} {
		var stdout, stderr bytes.Buffer
		args := []string{"--n", "2", "--seed", "42", "--workers", strconv.Itoa(workers)}
		if code := runWithMetadata(args, &stdout, &stderr, cliTestEnvironment); code != wantCode {
			t.Fatalf("CLI W=%d: exit=%d, esperado %d; stderr=%s", workers, code, wantCode, stderr.String())
		}
		if wantCode != 0 && (stdout.Len() != 0 || stderr.Len() == 0) {
			t.Fatalf("CLI W=%d: stdout=%q stderr=%q", workers, stdout.String(), stderr.String())
		}
	}
}

func TestValidateKernelBuffers(t *testing.T) {
	const n = 4
	elements := n * n
	backing := make([]float64, 3*elements)
	a := Matrix{N: n, Data: backing[:elements]}
	b := Matrix{N: n, Data: backing[elements : 2*elements]}
	c := Matrix{N: n, Data: backing[2*elements:]}
	durations := make([]time.Duration, 2)

	// Subslices contiguos sin solapamiento y A==B (solo lectura) son válidos.
	if err := validateKernelBuffers(a, b, c, 2, durations); err != nil {
		t.Fatalf("buffers adyacentes rechazados: %v", err)
	}
	if err := validateKernelBuffers(a, a, c, 2, durations); err != nil {
		t.Fatalf("A==B rechazado: %v", err)
	}

	short := Matrix{N: n, Data: make([]float64, elements-1)}
	cases := []struct {
		name      string
		a, b, c   Matrix
		workers   int
		durations []time.Duration
		want      error
	}{
		{"workers_cero", a, b, c, 0, nil, ErrInvalidWorkers},
		{"workers_excesivos", a, b, c, MaxWorkers + 1, make([]time.Duration, MaxWorkers+1), ErrTooManyWorkers},
		{"tiempos_cortos", a, b, c, 2, durations[:1], ErrInvalidDurations},
		{"tiempos_largos", a, b, c, 1, durations, ErrInvalidDurations},
		{"dimension_invalida", Matrix{}, b, c, 2, durations, ErrInvalidDimension},
		{"dimensiones_distintas", a, b, Matrix{N: n + 1, Data: make([]float64, (n+1)*(n+1))}, 2, durations, ErrDimensionMismatch},
		{"A_corta", short, b, c, 2, durations, ErrInvalidDataLength},
		{"B_corta", a, short, c, 2, durations, ErrInvalidDataLength},
		{"C_corta", a, b, short, 2, durations, ErrInvalidDataLength},
		{"C_es_A", a, b, a, 2, durations, ErrBufferAlias},
		{"C_es_B", a, b, b, 2, durations, ErrBufferAlias},
		{"C_solapa_A_un_elemento", a, b, Matrix{N: n, Data: backing[elements-1 : 2*elements-1]}, 2, durations, ErrBufferAlias},
		{"C_solapa_B_un_elemento", a, b, Matrix{N: n, Data: backing[elements+1 : 2*elements+1]}, 2, durations, ErrBufferAlias},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := validateKernelBuffers(tc.a, tc.b, tc.c, tc.workers, tc.durations); !errors.Is(err, tc.want) {
				t.Fatalf("error %v; esperado %v", err, tc.want)
			}
		})
	}
}

func TestCLIRepeatedRunsIdenticalOutput(t *testing.T) {
	previous := runtime.GOMAXPROCS(0)
	dir := t.TempDir()
	var baseline []byte
	repetitions := stabilityRepetitions(17) / 10
	for _, workers := range []int{1, 2, 3, 8, 17, 18, MaxWorkers} {
		for repetition := 0; repetition < repetitions; repetition++ {
			output := filepath.Join(dir, fmt.Sprintf("W%d_r%d.txt", workers, repetition))
			var stdout, stderr bytes.Buffer
			args := []string{"--n", "17", "--seed", "42", "--workers", strconv.Itoa(workers), "--output", output}
			var code int
			runWithDeadline(t, "go_paralelo", func() {
				code = runWithMetadata(args, &stdout, &stderr, cliTestEnvironment)
			})
			if code != 0 || stderr.Len() != 0 {
				t.Fatalf("W=%d rep=%d: exit=%d stderr=%s", workers, repetition, code, stderr.String())
			}
			records, err := csv.NewReader(&stdout).ReadAll()
			if err != nil || len(records) != 2 || records[1][len(records[1])-1] != "OK" {
				t.Fatalf("W=%d rep=%d: CSV inválido %v (%v)", workers, repetition, records, err)
			}
			data, err := os.ReadFile(output)
			if err != nil {
				t.Fatal(err)
			}
			if baseline == nil {
				baseline = data
			} else if !bytes.Equal(data, baseline) {
				t.Fatalf("W=%d rep=%d: el archivo de salida difiere del de W=1", workers, repetition)
			}
			if got := runtime.GOMAXPROCS(0); got != previous {
				t.Fatalf("GOMAXPROCS no restaurado: %d, esperado %d", got, previous)
			}
		}
	}
}
