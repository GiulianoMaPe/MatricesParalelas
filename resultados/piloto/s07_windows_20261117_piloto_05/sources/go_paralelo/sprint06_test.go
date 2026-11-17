package main

import (
	"encoding/json"
	"math"
	"os"
	"runtime"
	"strconv"
	"sync"
	"testing"
	"time"
)

// Experimental dispatch policy. Uses the production worker and arithmetic;
// only block size and channel capacity change. Never called by the CLI.
func sprint06Pool(a, b, c Matrix, workers, block, capacity int, durations []time.Duration) {
	tasks := make(chan Task, capacity)
	var wg sync.WaitGroup
	wg.Add(workers)
	for id := 0; id < workers; id++ {
		go worker(id, tasks, &wg, &a, &b, &c, durations)
	}
	for first := 0; first < a.N; {
		last := a.N
		if block < a.N-first {
			last = first + block
		}
		tasks <- Task{StartRow: first, EndRow: last}
		first = last
	}
	close(tasks)
	wg.Wait()
}

func TestSprint06PoolCandidates(t *testing.T) {
	for _, n := range []int{1, 3, 7, 17, 65} {
		for _, w := range []int{1, 2, 4, 8} {
			a, b, err := Generate(n, 42)
			if err != nil {
				t.Fatal(err)
			}
			want := referenceProduct(a, b)
			beforeA, beforeB := append([]float64(nil), a.Data...), append([]float64(nil), b.Data...)
			c := Matrix{N: n, Data: make([]float64, n*n)}
			for _, policy := range [][2]int{{16, w}, {computeBlockSize(n, w), 0}} {
				for rep := 0; rep < 3; rep++ {
					clear(c.Data)
					durations := make([]time.Duration, w)
					sprint06Pool(a, b, c, w, policy[0], policy[1], durations)
					assertMatrixClose(t, c, want)
					for _, duration := range durations {
						if duration < 0 {
							t.Fatal("negative duration")
						}
					}
				}
			}
			for i := range a.Data {
				if a.Data[i] != beforeA[i] || b.Data[i] != beforeB[i] {
					t.Fatal("candidate modified inputs")
				}
			}
		}
	}
}

func TestSprint06Observation(t *testing.T) {
	path := os.Getenv("S06_OUTPUT")
	if path == "" {
		t.Skip("laboratory observation requires S06_OUTPUT")
	}
	n, err := strconv.Atoi(os.Getenv("S06_N"))
	if err != nil || n < 1 || n > 4096 {
		t.Fatal("S06_N must be in 1..4096")
	}
	w, err := strconv.Atoi(os.Getenv("S06_WORKERS"))
	if err != nil || validateWorkers(w) != nil {
		t.Fatal("invalid workers")
	}
	previous := runtime.GOMAXPROCS(w)
	defer runtime.GOMAXPROCS(previous)
	variant := os.Getenv("S06_VARIANT")
	block, capacity := computeBlockSize(n, w), w
	switch variant {
	case "baseline":
	case "block16":
		block = 16
	case "unbuffered":
		capacity = 0
	default:
		t.Fatal("unknown variant")
	}
	a, b, err := Generate(n, 42)
	if err != nil {
		t.Fatal(err)
	}
	want := referenceProduct(a, b)
	c := Matrix{N: n, Data: make([]float64, n*n)}
	durations := make([]time.Duration, w)
	start := time.Now()
	clear(c.Data)
	if variant == "baseline" {
		multiplyParallelKernel(a, b, c, w, durations)
	} else {
		sprint06Pool(a, b, c, w, block, capacity, durations)
	}
	totalS := time.Since(start).Seconds()
	var maximum time.Duration
	for _, duration := range durations {
		if duration > maximum {
			maximum = duration
		}
	}
	kernelS := maximum.Seconds()
	assertMatrixClose(t, c, want)
	if math.IsNaN(totalS) || math.IsInf(totalS, 0) || kernelS < 0 || totalS < kernelS {
		t.Fatal("invalid durations")
	}
	x, y, _ := Generate(17, 42)
	z := Matrix{N: 17, Data: make([]float64, 17*17)}
	slots := make([]time.Duration, w)
	allocs := testing.AllocsPerRun(3, func() {
		clear(z.Data)
		if variant == "baseline" {
			multiplyParallelKernel(x, y, z, w, slots)
		} else {
			smallBlock := computeBlockSize(17, w)
			if variant == "block16" {
				smallBlock = 16
			}
			sprint06Pool(x, y, z, w, smallBlock, capacity, slots)
		}
	})
	data, err := json.Marshal(map[string]any{
		"schema": "s06-laboratory-v1", "version": "go_paralelo", "variant": variant,
		"n": n, "seed": 42, "workers": w, "gomaxprocs": w, "block_rows": block,
		"channel_capacity": capacity, "tasks": (n-1)/block + 1,
		"kernel_s": kernelS, "total_s": totalS, "coordination_allocs_n17": allocs,
		"validation_status": "OK",
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}
}
