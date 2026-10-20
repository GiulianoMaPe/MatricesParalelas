package main

import (
	"fmt"
	"sync"
	"time"
)

// Task asigna un bloque no vacío de filas [StartRow, EndRow).
type Task struct {
	StartRow int
	EndRow   int
}

// computeBlockSize requiere n y workers positivos. La división con resto evita
// el posible desbordamiento de (n + workers - 1) / workers.
func computeBlockSize(n, workers int) int {
	size := n / workers
	if n%workers != 0 {
		size++
	}
	return size
}

// dispatchRowBlocks envía cada fila exactamente una vez. Requiere n y workers
// positivos y consumidores activos, o un buffer suficiente. El productor que
// llama a esta función conserva la responsabilidad de cerrar tasks.
func dispatchRowBlocks(n, workers int, tasks chan<- Task) {
	size := computeBlockSize(n, workers)
	for start := 0; start < n; {
		end := n
		if size < n-start {
			end = start + size
		}
		tasks <- Task{StartRow: start, EndRow: end}
		start = end
	}
}

// multiplyBlock solo acumula en las filas propias de C con orden i,k,j.
// Requiere matrices válidas de igual dimensión, C vaciada e independiente de
// A/B y 0 <= startRow <= endRow <= N. No reserva, valida ni modifica A/B.
func multiplyBlock(a, b, c *Matrix, startRow, endRow int) {
	n := a.N
	for i := startRow; i < endRow; i++ {
		row := i * n
		for k := 0; k < n; k++ {
			value := a.Data[row+k]
			bRow := k * n
			for j := 0; j < n; j++ {
				c.Data[row+j] += value * b.Data[bRow+j]
			}
		}
	}
}

// worker consume bloques hasta el cierre del canal. Sus tareas deben ser
// disjuntas de todas las demás. Solo escribe su slot de tiempo antes de Done;
// un worker sin tareas registra cero. La recepción no forma parte del kernel.
func worker(id int, tasks <-chan Task, wg *sync.WaitGroup,
	a, b, c *Matrix, kernelDurations []time.Duration) {
	defer wg.Done()
	var elapsed time.Duration
	for task := range tasks {
		start := time.Now()
		multiplyBlock(a, b, c, task.StartRow, task.EndRow)
		elapsed += time.Since(start)
	}
	kernelDurations[id] = elapsed
}

// multiplyParallelKernel coordina un pool acotado de exactamente workers
// goroutines y espera su terminación completa. Requiere workers > 0, matrices
// válidas de igual dimensión, C ya vaciada y sin alias con A/B, y un vector de
// tiempos independiente de longitud workers, reservado antes de total_s.
// El llamador valida antes de entrar, inicia total_s antes de vaciar C y lo
// detiene al volver; después toma el máximo de tiempos y valida C.
func multiplyParallelKernel(a, b, c Matrix, workers int, kernelDurations []time.Duration) {
	tasks := make(chan Task, workers)
	var wg sync.WaitGroup
	wg.Add(workers)
	for id := 0; id < workers; id++ {
		go worker(id, tasks, &wg, &a, &b, &c, kernelDurations)
	}
	dispatchRowBlocks(a.N, workers, tasks)
	close(tasks)
	wg.Wait()
}

// smokeTest demonstrates two goroutines, a channel and a joined shutdown.
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
