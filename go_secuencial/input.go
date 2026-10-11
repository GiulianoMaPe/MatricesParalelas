package main

import (
	"errors"
	"math"
)

// Constantes del Generador Congruencial Lineal (LCG de 32 bits) segun docs/contrato.md
const (
	lcgMultiplier uint32 = 1664525
	lcgIncrement  uint32 = 1013904223
	lcgModulus    uint32 = 2001
)

// Errores específicos del generador determinista
var (
	ErrDimensionInvalida = errors.New("dimension n debe ser mayor que cero")
	ErrOverflowDimension = errors.New("dimension n causa desbordamiento de memoria")
)

// nextState calcula la siguiente transición de estado del LCG de 32 bits.
// El desbordamiento de uint32 realiza implicitamente la reduccion modulo 2^32.
func nextState(state uint32) uint32 {
	return lcgMultiplier*state + lcgIncrement
}

// stateToValue convierte un estado uint32 a un valor float64 en el rango [-1.000, 1.000].
// Se realiza conversion explicita a entero con signo antes de restar para evitar underflow.
func stateToValue(state uint32) float64 {
	rem := int64(state % lcgModulus)
	return float64(rem-1000) / 1000.0
}

// Generate genera deterministamente dos matrices cuadradas A y B de dimension n x n
// con valores contiguos por filas segun la formula especificada en docs/contrato.md.
// Llena primero la matriz A completa y luego B continuando la misma secuencia de estados.
func Generate(n int, seed uint32) (Matrix, Matrix, error) {
	if n <= 0 {
		return Matrix{}, Matrix{}, ErrDimensionInvalida
	}

	// Prevención de overflow si n causa desbordamiento en enteros de 32/64 bits
	if int64(n)*int64(n) > int64(math.MaxInt32) {
		return Matrix{}, Matrix{}, ErrOverflowDimension
	}

	total := n * n
	aData := make([]float64, total)
	bData := make([]float64, total)

	state := seed

	// Llenar matriz A por filas
	for i := 0; i < total; i++ {
		state = nextState(state)
		aData[i] = stateToValue(state)
	}

	// Llenar matriz B continuando con el mismo estado de 32 bits
	for j := 0; j < total; j++ {
		state = nextState(state)
		bData[j] = stateToValue(state)
	}

	return Matrix{N: n, Data: aData}, Matrix{N: n, Data: bData}, nil
}
