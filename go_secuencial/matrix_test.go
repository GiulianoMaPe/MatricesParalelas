package main

import (
	"bytes"
	"errors"
	"math"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
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
		{"a_error_before_b_error", Matrix{}, Matrix{N: 1}, ErrInvalidDimension},
		{"b_error_before_dimension_mismatch", valid, Matrix{N: 2, Data: []float64{1}}, ErrInvalidDataLength},
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

func TestMultiplyScalar(t *testing.T) {
	result, err := Multiply(Matrix{N: 1, Data: []float64{-3}}, Matrix{N: 1, Data: []float64{4}})
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, result, Matrix{N: 1, Data: []float64{-12}})
}

func TestMultiplyPreservesInputs(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{1, -2, 0, 4}}
	b := Matrix{N: 2, Data: []float64{5, 6, 7, 8}}
	wantA := append([]float64(nil), a.Data...)
	wantB := append([]float64(nil), b.Data...)
	_, err := Multiply(a, b)
	if err != nil {
		t.Fatalf("Multiply() error = %v", err)
	}
	if a.N != 2 || b.N != 2 || !reflect.DeepEqual(a.Data, wantA) || !reflect.DeepEqual(b.Data, wantB) {
		t.Fatal("Multiply modified its input matrices")
	}
}

func TestMultiplySharedFixtures(t *testing.T) {
	for _, name := range []string{"producto2", "escalar", "identidad", "cero", "impar3"} {
		t.Run(name, func(t *testing.T) {
			fixturePath := filepath.Join("..", "tests", "fixtures", name)
			content, err := os.ReadFile(fixturePath + ".input.txt")
			if err != nil {
				t.Fatal(err)
			}
			a, b, err := ReadMatrices(bytes.NewReader(content))
			if err != nil {
				t.Fatal(err)
			}
			want := readExpectedMatrix(t, fixturePath+".expected.txt")
			result, err := Multiply(a, b)
			if err != nil {
				t.Fatal(err)
			}
			assertMatrixClose(t, result, want)
		})
	}
}

func TestMultiplyDecimals(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{0.1, -0.2, 0.3, 0.4}}
	b := Matrix{N: 2, Data: []float64{0.5, 0.6, -0.7, 0.8}}
	result, err := Multiply(a, b)
	if err != nil {
		t.Fatal(err)
	}
	// Resultado calculado manualmente, independiente del núcleo implementado.
	assertMatrixClose(t, result, Matrix{N: 2, Data: []float64{0.19, -0.10, -0.13, 0.50}})
}

func TestMultiplyResultOwnsStorage(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{1, 2, 3, 4}}
	b := Matrix{N: 2, Data: []float64{5, 6, 7, 8}}
	wantA := append([]float64(nil), a.Data...)
	wantB := append([]float64(nil), b.Data...)
	result, err := Multiply(a, b)
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, result, Matrix{N: 2, Data: []float64{19, 22, 43, 50}})
	for i := range result.Data {
		result.Data[i] = 100 + float64(i)
	}
	if !reflect.DeepEqual(a.Data, wantA) || !reflect.DeepEqual(b.Data, wantB) {
		t.Fatal("changing C modified an input matrix")
	}
}

func TestMultiplySameInput(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{1, 2, 3, 4}}
	wantA := append([]float64(nil), a.Data...)
	result, err := Multiply(a, a)
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, result, Matrix{N: 2, Data: []float64{7, 10, 15, 22}})
	if !reflect.DeepEqual(a.Data, wantA) {
		t.Fatal("squaring A modified its data")
	}
}

func TestMultiplyRepeatedCalls(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{1, 2, 3, 4}}
	b := Matrix{N: 2, Data: []float64{5, 6, 7, 8}}
	want := Matrix{N: 2, Data: []float64{19, 22, 43, 50}}
	first, err := Multiply(a, b)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Multiply(a, b)
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, first, want)
	assertMatrixClose(t, second, want)
	clear(first.Data)
	assertMatrixClose(t, second, want)
	third, err := Multiply(a, b)
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, third, want)
}

func TestMultiplyRejectsNonFiniteResults(t *testing.T) {
	cases := []struct {
		name string
		a, b Matrix
	}{
		{"positive_overflow", Matrix{N: 1, Data: []float64{math.MaxFloat64}}, Matrix{N: 1, Data: []float64{2}}},
		{"negative_overflow", Matrix{N: 1, Data: []float64{-math.MaxFloat64}}, Matrix{N: 1, Data: []float64{2}}},
		{"sum_overflow", Matrix{N: 2, Data: []float64{math.MaxFloat64, math.MaxFloat64, 0, 0}}, Matrix{N: 2, Data: []float64{1, 0, 1, 0}}},
		{"nan_from_overflow", Matrix{N: 2, Data: []float64{math.MaxFloat64, math.MaxFloat64, 0, 0}}, Matrix{N: 2, Data: []float64{2, 0, -2, 0}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			wantA := append([]float64(nil), tc.a.Data...)
			wantB := append([]float64(nil), tc.b.Data...)
			result, err := Multiply(tc.a, tc.b)
			if !errors.Is(err, ErrNonFiniteValue) || !strings.HasPrefix(err.Error(), "matriz C:") {
				t.Fatalf("Multiply() error = %v; want non-finite result error", err)
			}
			if result.N != 0 || result.Data != nil {
				t.Fatalf("failed calculation returned a partial matrix: %+v", result)
			}
			if !reflect.DeepEqual(tc.a.Data, wantA) || !reflect.DeepEqual(tc.b.Data, wantB) {
				t.Fatal("failed calculation modified its inputs")
			}
		})
	}
}

// readExpectedMatrix lee la referencia manual de una sola matriz, sin calcularla.
func readExpectedMatrix(t *testing.T, path string) Matrix {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	tokens := strings.Fields(string(content))
	if len(tokens) == 0 {
		t.Fatalf("empty expected matrix: %s", path)
	}
	n, err := strconv.Atoi(tokens[0])
	if err != nil {
		t.Fatalf("invalid expected dimension in %s: %v", path, err)
	}
	count, err := matrixElementCount(n)
	if err != nil {
		t.Fatalf("invalid expected dimension in %s: %v", path, err)
	}
	if len(tokens)-1 != count {
		t.Fatalf("%s: got %d values; want %d", path, len(tokens)-1, count)
	}
	want := Matrix{N: n, Data: make([]float64, count)}
	for i, token := range tokens[1:] {
		value, err := strconv.ParseFloat(token, 64)
		if err != nil || math.IsNaN(value) || math.IsInf(value, 0) {
			t.Fatalf("%s: invalid expected value at index %d: %q", path, i, token)
		}
		want.Data[i] = value
	}
	return want
}

func assertMatrixClose(t *testing.T, got, want Matrix) {
	t.Helper()
	if err := got.Validate(); err != nil {
		t.Fatalf("invalid result: %v", err)
	}
	if err := want.Validate(); err != nil {
		t.Fatalf("invalid reference: %v", err)
	}
	if got.N != want.N {
		t.Fatalf("result dimension = %d; want %d", got.N, want.N)
	}
	const atol, rtol = 1e-9, 1e-9
	for i, expected := range want.Data {
		errorAbs := math.Abs(got.Data[i] - expected)
		tolerance := atol + rtol*math.Abs(expected)
		if errorAbs > tolerance {
			t.Errorf("C[%d,%d] = %.17g; want %.17g (error %.17g, tolerance %.17g)", i/want.N, i%want.N, got.Data[i], expected, errorAbs, tolerance)
		}
	}
}
