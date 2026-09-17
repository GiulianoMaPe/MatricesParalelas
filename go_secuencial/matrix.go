package main

import "errors"

var ErrPending = errors.New("pendiente: algoritmo no implementado")

// Matrix will hold N*N float64 values in row-major order.
type Matrix struct {
	N    int
	Data []float64
}

// Multiply is a placeholder. A nil result must never be reported as a product.
func Multiply(a, b Matrix) (Matrix, error) {
	return Matrix{}, ErrPending
}
