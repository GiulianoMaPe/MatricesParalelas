package main

import (
	"fmt"
	"testing"
)

// Diagnóstico de S9 (I4). En la campaña oficial, go_paralelo con W=1 tarda
// unas 1,45 veces más que go_secuencial dentro de kernel_s, aunque ambos usan
// el mismo bucle i,k,j. La única diferencia es la firma: multiplyBlock recibe
// *Matrix y multiplyKernel de go_secuencial recibe Matrix por valor. Con
// punteros, el compilador recarga las cabeceras de b.Data y c.Data en cada
// iteración del bucle interno. multiplyBlockByValue es una copia de
// laboratorio que recibe las matrices por valor; no se usa en producción ni
// cambia el algoritmo congelado.
func multiplyBlockByValue(a, b, c Matrix, startRow, endRow int) {
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

func TestMultiplyBlockByValueBitwise(t *testing.T) {
	for _, n := range []int{1, 7, 64} {
		a, b, err := Generate(n, 42)
		if err != nil {
			t.Fatal(err)
		}
		pointer := Matrix{N: n, Data: make([]float64, n*n)}
		value := Matrix{N: n, Data: make([]float64, n*n)}
		multiplyBlock(&a, &b, &pointer, 0, n)
		multiplyBlockByValue(a, b, value, 0, n)
		assertBitwiseEqual(t, fmt.Sprintf("N=%d", n), value, pointer)
	}
}

// BenchmarkKernelPointerVsValue mide un producto completo en una sola
// goroutine con cada firma. Ejecutar con -cpu 1 para igualar GOMAXPROCS=1.
func BenchmarkKernelPointerVsValue(b *testing.B) {
	for _, n := range []int{512, 1024} {
		a, bm, err := Generate(n, 42)
		if err != nil {
			b.Fatal(err)
		}
		c := Matrix{N: n, Data: make([]float64, n*n)}
		flops := 2 * float64(n) * float64(n) * float64(n)
		b.Run(fmt.Sprintf("N%d/puntero", n), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				clear(c.Data)
				multiplyBlock(&a, &bm, &c, 0, n)
			}
			b.ReportMetric(flops*float64(b.N)/b.Elapsed().Seconds()/1e9, "GFLOPS")
		})
		b.Run(fmt.Sprintf("N%d/valor", n), func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				clear(c.Data)
				multiplyBlockByValue(a, bm, c, 0, n)
			}
			b.ReportMetric(flops*float64(b.N)/b.Elapsed().Seconds()/1e9, "GFLOPS")
		})
	}
}
