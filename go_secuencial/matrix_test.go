package main

import (
	"errors"
	"math"
	"reflect"
	"strconv"
	"testing"
)

func TestValidateDimension(t *testing.T) {
	maxInt := int(^uint(0) >> 1)
	// En int de 32 o 64 bits, este es el mayor N cuyos N*N*8 bytes caben en int.
	maxN := (1 << (strconv.IntSize/2 - 2)) - 1
	cases := []struct {
		name string
		n    int
		want error
	}{
		{"zero", 0, ErrInvalidDimension},
		{"negative", -2, ErrInvalidDimension},
		{"one", 1, nil},
		{"two", 2, nil},
		{"largest_representable_size", maxN, nil},
		{"byte_size_overflow", maxN + 1, ErrSizeOverflow},
		{"element_count_overflow", maxInt, ErrSizeOverflow},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := ValidateDimension(tc.n); !errors.Is(err, tc.want) {
				t.Fatalf("ValidateDimension(%d) = %v; want %v", tc.n, err, tc.want)
			}
		})
	}
}

func TestMatrixValidate(t *testing.T) {
	cases := []struct {
		name   string
		matrix Matrix
		want   error
	}{
		{"zero_dimension", Matrix{}, ErrInvalidDimension},
		{"negative_dimension", Matrix{N: -1}, ErrInvalidDimension},
		{"size_overflow", Matrix{N: int(^uint(0) >> 1)}, ErrSizeOverflow},
		{"nil_data", Matrix{N: 1}, ErrInvalidDataLength},
		{"empty_data", Matrix{N: 1, Data: []float64{}}, ErrInvalidDataLength},
		{"missing_value", Matrix{N: 2, Data: []float64{1, 2, 3}}, ErrInvalidDataLength},
		{"extra_value", Matrix{N: 1, Data: []float64{1, 2}}, ErrInvalidDataLength},
		{"nan", Matrix{N: 2, Data: []float64{1, 2, math.NaN(), 4}}, ErrNonFiniteValue},
		{"positive_infinity", Matrix{N: 1, Data: []float64{math.Inf(1)}}, ErrNonFiniteValue},
		{"negative_infinity", Matrix{N: 1, Data: []float64{math.Inf(-1)}}, ErrNonFiniteValue},
		{"valid_zero", Matrix{N: 1, Data: []float64{0}}, nil},
		{"valid_negative", Matrix{N: 1, Data: []float64{-3}}, nil},
		{"valid_two_by_two", Matrix{N: 2, Data: []float64{1, -2, 0, 4}}, nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := tc.matrix.Validate(); !errors.Is(err, tc.want) {
				t.Fatalf("Validate() = %v; want %v", err, tc.want)
			}
		})
	}
}

func TestMultiplyRejectsInvalidInputs(t *testing.T) {
	valid := Matrix{N: 1, Data: []float64{3}}
	cases := []struct {
		name string
		a, b Matrix
		want error
	}{
		{"invalid_a", Matrix{}, valid, ErrInvalidDimension},
		{"invalid_b", valid, Matrix{}, ErrInvalidDimension},
		{"short_a", Matrix{N: 2, Data: []float64{1}}, valid, ErrInvalidDataLength},
		{"long_b", valid, Matrix{N: 1, Data: []float64{1, 2}}, ErrInvalidDataLength},
		{"nan_in_a", Matrix{N: 1, Data: []float64{math.NaN()}}, valid, ErrNonFiniteValue},
		{"infinity_in_b", valid, Matrix{N: 1, Data: []float64{math.Inf(1)}}, ErrNonFiniteValue},
		{"size_overflow", Matrix{N: int(^uint(0) >> 1)}, valid, ErrSizeOverflow},
		{"different_dimensions", valid, Matrix{N: 2, Data: []float64{1, 2, 3, 4}}, ErrDimensionMismatch},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			result, err := Multiply(tc.a, tc.b)
			if !errors.Is(err, tc.want) {
				t.Fatalf("Multiply() error = %v; want %v", err, tc.want)
			}
			if result.N != 0 || result.Data != nil {
				t.Fatalf("invalid inputs must not produce a matrix: %+v", result)
			}
		})
	}
}

func TestMultiplyReportsPending(t *testing.T) {
	result, err := Multiply(Matrix{N: 1, Data: []float64{3}}, Matrix{N: 1, Data: []float64{4}})
	if !errors.Is(err, ErrPending) || result.Data != nil || result.N != 0 {
		t.Fatal("pending multiplication must not return a fake product", result, err)
	}
}

func TestMultiplyPreservesInputs(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{1, -2, 0, 4}}
	b := Matrix{N: 2, Data: []float64{5, 6, 7, 8}}
	wantA := append([]float64(nil), a.Data...)
	wantB := append([]float64(nil), b.Data...)
	_, err := Multiply(a, b)
	if !errors.Is(err, ErrPending) {
		t.Fatalf("valid inputs should still report pending: %v", err)
	}
	if a.N != 2 || b.N != 2 || !reflect.DeepEqual(a.Data, wantA) || !reflect.DeepEqual(b.Data, wantB) {
		t.Fatal("Multiply modified its input matrices")
	}
}
