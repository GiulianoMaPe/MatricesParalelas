package main

import (
	"fmt"
	"sync"
)

// smokeTest demonstrates two goroutines, a channel and a joined shutdown.
// TODO: a bounded pool that owns disjoint row blocks; no multiplication yet.
func smokeTest() error {
	results := make(chan int)
	var wg sync.WaitGroup
	for id := 0; id < 2; id++ {
		wg.Add(1)
		go func(worker int) {
			defer wg.Done()
			results <- worker
		}(id)
	}
	go func() {
		wg.Wait()
		close(results)
	}()
	seen := [2]bool{}
	for id := range results {
		if id < 0 || id >= len(seen) || seen[id] {
			return fmt.Errorf("resultado inesperado de goroutine: %d", id)
		}
		seen[id] = true
	}
	if !seen[0] || !seen[1] {
		return fmt.Errorf("faltan goroutines")
	}
	fmt.Println("Prueba de instalacion: 2 goroutines completadas mediante canal y WaitGroup.")
	return nil
}
