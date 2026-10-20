package main

import (
	"fmt"
	"reflect"
	"testing"
	"time"
)

func TestGoroutinesSynchronize(t *testing.T) {
	for i := 0; i < 10; i++ {
		if err := smokeTest(); err != nil {
			t.Fatal(err)
		}
	}
}

func TestWorkerRowOwnership(t *testing.T) {
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
	timeout := time.NewTimer(10 * time.Second)
	defer timeout.Stop()
	var previous Matrix
	for call := 0; call < 8; call++ {
		var r result
		select {
		case r = <-results:
		case <-timeout.C:
			t.Fatalf("concurrent multiplication did not finish: received %d of 8 results", call)
		}
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
