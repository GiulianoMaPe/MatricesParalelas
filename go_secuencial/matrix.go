package main

import (
	"errors"
	"fmt"
	"math"
)

// Los errores se pueden comprobar con errors.Is, aunque incluyan más detalles.
var (
	ErrPending           = errors.New("pendiente: algoritmo no implementado")
	ErrInvalidDimension  = errors.New("la dimension debe ser positiva")
	ErrSizeOverflow      = errors.New("el tamaño de la matriz excede los limites")
	ErrInvalidDataLength = errors.New("la cantidad de datos no coincide con la dimension")
	ErrNonFiniteValue    = errors.New("la matriz contiene NaN o infinito")
	ErrDimensionMismatch = errors.New("las matrices deben tener la misma dimension")
)

// Matrix guarda una matriz cuadrada: N > 0 y exactamente N*N valores finitos.
// Data se guarda por filas; el elemento (i, j) ocupa la posición i*N+j.
// Los ceros y los valores negativos son válidos. Validate comprueba estas reglas.
type Matrix struct {
	N    int
	Data []float64
}

// ValidateDimension comprueba N y que N*N elementos de 8 bytes quepan en int.
// No reserva memoria ni garantiza que la computadora tenga memoria disponible.
// Puede reutilizarse al procesar --n y al generar matrices.
func ValidateDimension(n int) error {
	_, err := matrixElementCount(n)
	return err
}

func matrixElementCount(n int) (int, error) {
	if n <= 0 {
		return 0, fmt.Errorf("%w: N=%d", ErrInvalidDimension, n)
	}
	maxInt := int(^uint(0) >> 1)
	// Comprobar antes de multiplicar evita que N*N desborde y cambie de valor.
	if n > maxInt/n {
		return 0, fmt.Errorf("%w: N=%d", ErrSizeOverflow, n)
	}
	elements := n * n
	if elements > maxInt/8 {
		return 0, fmt.Errorf("%w: N=%d", ErrSizeOverflow, n)
	}
	return elements, nil
}

// Validate revisa el tamaño, la cantidad de datos y luego cada valor, en ese orden.
// No modifica la matriz ni reserva memoria para otra matriz.
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

// Multiply requiere matrices válidas del mismo tamaño y no modifica A ni B.
// Valida A, luego B y luego compara sus dimensiones. Ante un error devuelve
// una matriz vacía. Implementa bucles i,k,j estándar.
func Multiply(a, b Matrix) (Matrix, error) {
	if err := a.Validate(); err != nil {
		return Matrix{}, fmt.Errorf("matriz A: %w", err)
	}
	if err := b.Validate(); err != nil {
		return Matrix{}, fmt.Errorf("matriz B: %w", err)
	}
	if a.N != b.N {
		return Matrix{}, fmt.Errorf("%w: A=%d, B=%d", ErrDimensionMismatch, a.N, b.N)
	}
	n := a.N
	count := n * n
	c := Matrix{N: n, Data: make([]float64, count)}
	for i := 0; i < n; i++ {
		for k := 0; k < n; k++ {
			aik := a.Data[i*n+k]
			for j := 0; j < n; j++ {
				c.Data[i*n+j] += aik * b.Data[k*n+j]
			}
		}
	}
	return c, nil
}
