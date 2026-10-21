package main

import (
	"errors"
	"fmt"
	"math"
	"time"
)

// ErrPending se conserva para operaciones todavía no integradas en el ejecutable.
var ErrPending = errors.New("pendiente: algoritmo no implementado")

var (
	ErrInvalidDimension  = errors.New("la dimension debe ser positiva")
	ErrSizeOverflow      = errors.New("el tamaño de la matriz excede los limites")
	ErrInvalidWorkers    = errors.New("la cantidad de workers debe ser positiva")
	ErrInvalidDataLength = errors.New("la cantidad de datos no coincide con la dimension")
	ErrNonFiniteValue    = errors.New("la matriz contiene NaN o infinito")
	ErrDimensionMismatch = errors.New("las matrices deben tener la misma dimension")
)

// Matrix contiene N*N valores float64 contiguos, en orden por filas.
type Matrix struct {
	N    int
	Data []float64
}

func matrixElementCount(n int) (int, error) {
	if n <= 0 {
		return 0, fmt.Errorf("%w: N=%d", ErrInvalidDimension, n)
	}
	maxInt := int(^uint(0) >> 1)
	if n > maxInt/n {
		return 0, fmt.Errorf("%w: N=%d", ErrSizeOverflow, n)
	}
	elements := n * n
	if elements > maxInt/8 {
		return 0, fmt.Errorf("%w: N=%d", ErrSizeOverflow, n)
	}
	return elements, nil
}

// ValidateDimension comprueba N*N elementos y N*N*8 bytes antes de multiplicar.
// No reserva memoria ni garantiza que haya suficiente RAM disponible.
func ValidateDimension(n int) error {
	_, err := matrixElementCount(n)
	return err
}

// Validate comprueba dimensión, longitud y valores finitos, en ese orden.
func (m Matrix) Validate() error {
	elements, err := matrixElementCount(m.N)
	if err != nil {
		return err
	}
	if len(m.Data) != elements {
		return fmt.Errorf("%w: esperados %d, recibidos %d", ErrInvalidDataLength, elements, len(m.Data))
	}
	for index, value := range m.Data {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return fmt.Errorf("%w: posicion %d", ErrNonFiniteValue, index)
		}
	}
	return nil
}

// Multiply mantiene la firma existente y usa un worker. Para elegir el tamaño
// del pool, usar MultiplyParallel. Ninguna de las dos cambia GOMAXPROCS.
func Multiply(a, b Matrix) (Matrix, error) {
	return MultiplyParallel(a, b, 1)
}

// MultiplyParallel valida workers, A, B y dimensiones antes de lanzar goroutines.
// Devuelve C independiente y finita; ante error devuelve una matriz vacía.
// A/B son de solo lectura; el llamador no debe modificarlas durante la operación.
// Esta función incluye reservas y validaciones: no es la frontera del kernel.
func MultiplyParallel(a, b Matrix, workers int) (Matrix, error) {
	if workers <= 0 {
		return Matrix{}, fmt.Errorf("%w: workers=%d", ErrInvalidWorkers, workers)
	}
	if err := a.Validate(); err != nil {
		return Matrix{}, fmt.Errorf("matriz A: %w", err)
	}
	if err := b.Validate(); err != nil {
		return Matrix{}, fmt.Errorf("matriz B: %w", err)
	}
	if a.N != b.N {
		return Matrix{}, fmt.Errorf("%w: A=%d, B=%d", ErrDimensionMismatch, a.N, b.N)
	}
	c := Matrix{N: a.N, Data: make([]float64, len(a.Data))}
	durations := make([]time.Duration, workers)
	clear(c.Data)
	multiplyParallelKernel(a, b, c, workers, durations)
	if err := c.Validate(); err != nil {
		return Matrix{}, fmt.Errorf("matriz C: %w", err)
	}
	return c, nil
}
