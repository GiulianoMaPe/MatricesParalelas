package main

import (
	"fmt"
	"math"
	"reflect"
	"sync"
	"testing"
	"time"
)

func TestRowBlockCoverage(t *testing.T) {
	for _, n := range []int{1, 2, 3, 5, 7, 8, 17, 64, 129} {
		for _, workers := range []int{1, 2, 3, 4, 8, 16, 130} {
			t.Run(fmt.Sprintf("N%d/W%d", n, workers), func(t *testing.T) {
				tasks := make(chan Task, n)
				dispatchRowBlocks(n, workers, tasks)
				close(tasks)
				counts := make([]int, n)
				next := 0
				for task := range tasks {
					if task.StartRow != next || task.EndRow <= task.StartRow || task.EndRow > n {
						t.Fatalf("invalid partition: %+v, next=%d, n=%d", task, next, n)
					}
					for row := task.StartRow; row < task.EndRow; row++ {
						counts[row]++
					}
					next = task.EndRow
				}
				for row, count := range counts {
					if count != 1 {
						t.Fatalf("row %d assigned %d times", row, count)
					}
				}
			})
		}
	}
}

func TestRowBlocksAvoidIntegerOverflow(t *testing.T) {
	maxInt := int(^uint(0) >> 1)
	for _, workers := range []int{1, 2, 3, 4, 8} {
		// No matrices or per-row buffers: exercise arithmetic near maxInt.
		tasks := make(chan Task, workers)
		dispatchRowBlocks(maxInt, workers, tasks)
		close(tasks)
		next, count := 0, 0
		for task := range tasks {
			if task.StartRow != next || task.EndRow <= next || task.EndRow > maxInt {
				t.Fatalf("W=%d: overflow or gap: %+v after %d", workers, task, next)
			}
			next = task.EndRow
			count++
		}
		if next != maxInt || count > workers {
			t.Fatalf("W=%d: reached %d with %d tasks", workers, next, count)
		}
	}
	if got := computeBlockSize(1, maxInt); got != 1 {
		t.Fatalf("block size for W>N = %d; want 1", got)
	}
}

func TestMultiplyBlockWritesOnlyOwnedRows(t *testing.T) {
	a, b, err := Generate(5, 42)
	if err != nil {
		t.Fatal(err)
	}
	want := referenceProduct(a, b)
	for _, bounds := range [][2]int{{0, 1}, {1, 4}, {4, 5}, {2, 2}} {
		t.Run(fmt.Sprint(bounds), func(t *testing.T) {
			c := Matrix{N: a.N, Data: make([]float64, len(a.Data))}
			for i := range c.Data {
				if row := i / c.N; row < bounds[0] || row >= bounds[1] {
					c.Data[i] = 12345
				}
			}
			multiplyBlock(&a, &b, &c, bounds[0], bounds[1])
			for i, value := range c.Data {
				expected := 12345.0
				if row := i / c.N; row >= bounds[0] && row < bounds[1] {
					expected = want.Data[i]
				}
				if math.IsNaN(value) || math.IsInf(value, 0) || math.Abs(value-expected) > 1e-9+1e-9*math.Abs(expected) {
					t.Fatalf("C[%d] = %.17g; want %.17g", i, value, expected)
				}
			}
		})
	}
}

func TestWorkerConsumesMultipleTasks(t *testing.T) {
	a, b, err := Generate(5, 42)
	if err != nil {
		t.Fatal(err)
	}
	c := Matrix{N: 5, Data: make([]float64, 25)}
	tasks := make(chan Task) // Verify consumers run before the first send.
	durations := []time.Duration{-1}
	var wg sync.WaitGroup
	wg.Add(1)
	go worker(0, tasks, &wg, &a, &b, &c, durations)
	for row := 0; row < a.N; row++ {
		tasks <- Task{StartRow: row, EndRow: row + 1}
	}
	close(tasks)
	wg.Wait()
	assertMatrixClose(t, c, referenceProduct(a, b))
	if durations[0] < 0 {
		t.Fatal("worker did not publish its duration before Done")
	}
}

func TestWorkersWithoutTasksFinishAndResetDurations(t *testing.T) {
	a := Matrix{N: 1, Data: []float64{2}}
	c := Matrix{N: 1, Data: []float64{123}}
	tasks := make(chan Task)
	close(tasks)
	durations := []time.Duration{-1, -1, -1, -1}
	var wg sync.WaitGroup
	wg.Add(len(durations))
	for id := range durations {
		go worker(id, tasks, &wg, &a, &a, &c, durations)
	}
	wg.Wait()
	for id, duration := range durations {
		if duration != 0 {
			t.Fatalf("idle worker %d duration = %v; want zero", id, duration)
		}
	}
	if c.Data[0] != 123 {
		t.Fatal("an idle worker wrote C")
	}
}

func TestWorkerRowOwnership(t *testing.T) {
	// Nonzero rows expose missing work and double accumulation. Partition
	// counts above check assignments independently of the numerical product.
	for _, n := range []int{1, 2, 3, 5, 8, 17} {
		a := Matrix{N: n, Data: make([]float64, n*n)}
		for i := range a.Data {
			a.Data[i] = 1
		}
		for _, workers := range []int{1, 2, 4, 8, 32} {
			got, err := MultiplyParallel(a, a, workers)
			if err != nil {
				t.Fatal(err)
			}
			for i, value := range got.Data {
				if value != float64(n) {
					t.Fatalf("N=%d W=%d C[%d]=%v, want %d", n, workers, i, value, n)
				}
			}
		}
	}
}

func TestParallelKernelReusesPreparedBuffers(t *testing.T) {
	a, b, err := Generate(7, 0)
	if err != nil {
		t.Fatal(err)
	}
	c := Matrix{N: 7, Data: make([]float64, 49)}
	durations := make([]time.Duration, 8)
	want := referenceProduct(a, b)
	for repetition := 0; repetition < 5; repetition++ {
		for i := range c.Data {
			c.Data[i] = 12345
		}
		for id := range durations {
			durations[id] = -1
		}
		start := time.Now()
		clear(c.Data)
		multiplyParallelKernel(a, b, c, 8, durations)
		total := time.Since(start)
		for id, duration := range durations {
			if duration < 0 || duration > total {
				t.Fatalf("worker %d duration %v outside [0,%v]", id, duration, total)
			}
		}
		assertMatrixClose(t, c, want)
	}
}

func TestMultiplyParallelRepeatedSizes(t *testing.T) {
	for _, n := range []int{1, 2, 3, 5, 17, 64} {
		for _, seed := range []uint32{0, 42, ^uint32(0)} {
			a, b, err := Generate(n, seed)
			if err != nil {
				t.Fatal(err)
			}
			want := referenceProduct(a, b)
			for _, workers := range []int{1, 2, 4, 8} {
				t.Run(fmt.Sprintf("N%d/seed%d/W%d", n, seed, workers), func(t *testing.T) {
					for repeat := 0; repeat < 10; repeat++ {
						got, err := MultiplyParallel(a, b, workers)
						if err != nil {
							t.Fatal(err)
						}
						assertMatrixClose(t, got, want)
					}
				})
			}
		}
	}
}

func TestConcurrentCallsShareReadOnlyInputs(t *testing.T) {
	a, b, err := Generate(17, 42)
	if err != nil {
		t.Fatal(err)
	}
	aBefore := append([]float64(nil), a.Data...)
	bBefore := append([]float64(nil), b.Data...)
	want := referenceProduct(a, b)
	type result struct {
		matrix Matrix
		err    error
	}
	results := make(chan result, 8)
	for workers := 1; workers <= 8; workers++ {
		go func(w int) {
			got, err := MultiplyParallel(a, b, w)
			results <- result{got, err}
		}(workers)
	}
	var previous Matrix
	for call := 0; call < 8; call++ {
		r := <-results
		if r.err != nil {
			t.Fatal(r.err)
		}
		assertMatrixClose(t, r.matrix, want)
		if previous.Data != nil && previous.Data[0] != 12345 {
			t.Fatal("concurrent calls share output storage")
		}
		r.matrix.Data[0] = 12345
		previous = r.matrix
	}
	if !reflect.DeepEqual(a.Data, aBefore) || !reflect.DeepEqual(b.Data, bBefore) {
		t.Fatal("concurrent calls modified A/B")
	}
}
