package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"strconv"
	"testing"
	"time"
)

// Laboratory candidate only. The production kernel remains unchanged until
// the Windows before/after comparison and common regression are available.
func sprint06RowSlices(a, b, c Matrix) {
	n := a.N
	for i := 0; i < n; i++ {
		ar := a.Data[i*n : (i+1)*n]
		cr := c.Data[i*n : (i+1)*n]
		for k, value := range ar {
			br := b.Data[k*n : (k+1)*n]
			for j := range cr {
				cr[j] += value * br[j]
			}
		}
	}
}

func TestSprint06RowSlices(t *testing.T) {
	for _, n := range []int{1, 3, 7, 17, 65} {
		for _, seed := range []uint32{0, 42, 101, 2024, 4294967295} {
			a, b, err := Generate(n, seed)
			if err != nil {
				t.Fatal(err)
			}
			want, err := referenceProduct(a, b)
			if err != nil {
				t.Fatal(err)
			}
			c := Matrix{N: n, Data: make([]float64, n*n)}
			beforeA, beforeB := append([]float64(nil), a.Data...), append([]float64(nil), b.Data...)
			for repetition := 0; repetition < 3; repetition++ {
				clear(c.Data)
				sprint06RowSlices(a, b, c)
				assertMatrixClose(t, c, want)
			}
			for i := range a.Data {
				if a.Data[i] != beforeA[i] || b.Data[i] != beforeB[i] {
					t.Fatal("candidate modified its inputs")
				}
			}
		}
	}
}

// One explicitly requested laboratory observation; never a campaign CSV.
// The driver launches a new process per repetition and alternates variants.
func TestSprint06Observation(t *testing.T) {
	path := os.Getenv("S06_OUTPUT")
	if path == "" {
		t.Skip("laboratory observation requires S06_OUTPUT")
	}
	n, err := strconv.Atoi(os.Getenv("S06_N"))
	if err != nil || n < 1 || n > 4096 {
		t.Fatal("S06_N must be in 1..4096")
	}
	variant := os.Getenv("S06_VARIANT")
	kernel := multiplyKernel
	if variant == "row_slices" {
		kernel = sprint06RowSlices
	} else if variant != "baseline" {
		t.Fatal("unknown variant")
	}
	a, b, err := Generate(n, 42)
	if err != nil {
		t.Fatal(err)
	}
	want, err := referenceProduct(a, b)
	if err != nil {
		t.Fatal(err)
	}
	c := Matrix{N: n, Data: make([]float64, n*n)}
	start := time.Now()
	clear(c.Data)
	k0 := time.Now()
	kernel(a, b, c)
	kernelS := time.Since(k0).Seconds()
	totalS := time.Since(start).Seconds()
	assertMatrixClose(t, c, want)
	if !isFiniteSprint06(kernelS) || !isFiniteSprint06(totalS) || totalS < kernelS {
		t.Fatal("invalid durations")
	}
	// Allocation diagnostics are outside both timers and use a small matrix:
	// kernel O(N^3) work must not be repeated 100 times at the pilot dimension.
	x, y, _ := Generate(17, 42)
	z := Matrix{N: 17, Data: make([]float64, 17*17)}
	allocs := testing.AllocsPerRun(3, func() { clear(z.Data); kernel(x, y, z) })
	apiAllocs := testing.AllocsPerRun(3, func() {
		if _, err := Multiply(x, y); err != nil {
			panic(err)
		}
	})
	data, err := json.Marshal(map[string]any{
		"schema": "s06-laboratory-v1", "version": "go_secuencial", "variant": variant,
		"n": n, "seed": 42, "workers": 1, "kernel_s": kernelS, "total_s": totalS,
		"kernel_allocs_n17": allocs, "api_allocs_n17": apiAllocs, "validation_status": "OK",
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}
	fmt.Println("S06 laboratory observation validated")
}

func isFiniteSprint06(value float64) bool {
	return value >= 0 && !math.IsNaN(value) && !math.IsInf(value, 0)
}
