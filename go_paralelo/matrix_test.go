package main

import (
	"errors"
	"fmt"
	"io"
	"math"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strconv"
	"testing"
)

func TestValidateDimension(t *testing.T) {
	maxN := (1 << (strconv.IntSize/2 - 2)) - 1
	for _, tc := range []struct {
		name string
		n    int
		want error
	}{
		{"zero", 0, ErrInvalidDimension},
		{"negative", -1, ErrInvalidDimension},
		{"one", 1, nil},
		{"largest_representable", maxN, nil},
		{"byte_overflow", maxN + 1, ErrSizeOverflow},
		{"element_overflow", int(^uint(0) >> 1), ErrSizeOverflow},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if err := ValidateDimension(tc.n); !errors.Is(err, tc.want) {
				t.Fatalf("ValidateDimension(%d) = %v, want %v", tc.n, err, tc.want)
			}
		})
	}
}

func TestMatrixValidate(t *testing.T) {
	for _, tc := range []struct {
		name string
		m    Matrix
		want error
	}{
		{"zero", Matrix{}, ErrInvalidDimension},
		{"negative", Matrix{N: -1}, ErrInvalidDimension},
		{"overflow", Matrix{N: int(^uint(0) >> 1)}, ErrSizeOverflow},
		{"nil", Matrix{N: 1}, ErrInvalidDataLength},
		{"missing", Matrix{N: 2, Data: []float64{1, 2, 3}}, ErrInvalidDataLength},
		{"extra", Matrix{N: 1, Data: []float64{1, 2}}, ErrInvalidDataLength},
		{"nan", Matrix{N: 1, Data: []float64{math.NaN()}}, ErrNonFiniteValue},
		{"positive_inf", Matrix{N: 1, Data: []float64{math.Inf(1)}}, ErrNonFiniteValue},
		{"negative_inf", Matrix{N: 1, Data: []float64{math.Inf(-1)}}, ErrNonFiniteValue},
		{"zero_value", Matrix{N: 1, Data: []float64{0}}, nil},
		{"negative_value", Matrix{N: 1, Data: []float64{-3}}, nil},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if err := tc.m.Validate(); !errors.Is(err, tc.want) {
				t.Fatalf("Validate() = %v, want %v", err, tc.want)
			}
		})
	}
}

func TestMultiplyParallelRejectsInvalidInputs(t *testing.T) {
	valid := Matrix{N: 1, Data: []float64{3}}
	for _, tc := range []struct {
		name    string
		a, b    Matrix
		workers int
		want    error
	}{
		{"zero_workers", valid, valid, 0, ErrInvalidWorkers},
		{"negative_workers", valid, valid, -1, ErrInvalidWorkers},
		{"workers_before_matrices", Matrix{}, Matrix{}, 0, ErrInvalidWorkers},
		{"invalid_a", Matrix{}, valid, 2, ErrInvalidDimension},
		{"invalid_b", valid, Matrix{}, 2, ErrInvalidDimension},
		{"short_a", Matrix{N: 2, Data: []float64{1}}, valid, 2, ErrInvalidDataLength},
		{"long_b", valid, Matrix{N: 1, Data: []float64{1, 2}}, 2, ErrInvalidDataLength},
		{"nan_a", Matrix{N: 1, Data: []float64{math.NaN()}}, valid, 2, ErrNonFiniteValue},
		{"inf_b", valid, Matrix{N: 1, Data: []float64{math.Inf(-1)}}, 2, ErrNonFiniteValue},
		{"size_overflow", Matrix{N: int(^uint(0) >> 1)}, valid, 2, ErrSizeOverflow},
		{"different_dimensions", valid, Matrix{N: 2, Data: []float64{1, 2, 3, 4}}, 2, ErrDimensionMismatch},
		{"a_before_b", Matrix{}, Matrix{N: 1}, 2, ErrInvalidDimension},
		{"b_before_dimensions", valid, Matrix{N: 2}, 2, ErrInvalidDataLength},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := MultiplyParallel(tc.a, tc.b, tc.workers)
			if !errors.Is(err, tc.want) || got.N != 0 || got.Data != nil {
				t.Fatalf("MultiplyParallel() = %+v, %v; want empty matrix, %v", got, err, tc.want)
			}
		})
	}
}

func TestMultiplyCompatibility(t *testing.T) {
	a := Matrix{N: 1, Data: []float64{-3}}
	b := Matrix{N: 1, Data: []float64{4}}
	got, err := Multiply(a, b)
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, got, Matrix{N: 1, Data: []float64{-12}})
	got, err = Multiply(Matrix{}, b)
	if !errors.Is(err, ErrInvalidDimension) || got.N != 0 || got.Data != nil {
		t.Fatalf("invalid compatibility call = %+v, %v", got, err)
	}
}

func TestMultiplyParallelFixtures(t *testing.T) {
	for _, fixture := range []string{"producto2", "escalar", "identidad", "cero", "impar3"} {
		t.Run(fixture, func(t *testing.T) {
			f, err := os.Open(filepath.Join("..", "tests", "fixtures", fixture+".input.txt"))
			if err != nil {
				t.Fatal(err)
			}
			defer f.Close()
			a, b, err := ReadMatrices(f)
			if err != nil {
				t.Fatal(err)
			}
			want := readExpectedMatrix(t, fixture)
			for _, workers := range []int{1, 2, 4, 8} {
				t.Run(fmt.Sprintf("W%d", workers), func(t *testing.T) {
					got, err := MultiplyParallel(a, b, workers)
					if err != nil {
						t.Fatal(err)
					}
					assertMatrixClose(t, got, want)
				})
			}
		})
	}
}

func TestMultiplyParallelDecimalsAndIndependentResults(t *testing.T) {
	a := Matrix{N: 2, Data: []float64{0.5, -1.25, 2, 0.1}}
	b := Matrix{N: 2, Data: []float64{2, 0.4, -0.5, 3}}
	want := Matrix{N: 2, Data: []float64{1.625, -3.55, 3.95, 1.1}}
	aBefore := append([]float64(nil), a.Data...)
	bBefore := append([]float64(nil), b.Data...)
	var previous Matrix
	for _, workers := range []int{1, 8, 2, 4, 1} {
		got, err := MultiplyParallel(a, b, workers)
		if err != nil {
			t.Fatal(err)
		}
		assertMatrixClose(t, got, want)
		if previous.Data != nil && previous.Data[0] != 12345 {
			t.Fatal("a later call changed an earlier result")
		}
		got.Data[0] = 12345
		if !reflect.DeepEqual(a.Data, aBefore) || !reflect.DeepEqual(b.Data, bBefore) {
			t.Fatal("multiplication or modifying C changed A/B")
		}
		previous = got
	}
	got, err := MultiplyParallel(a, a, 4)
	if err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, got, referenceProduct(a, a))
	if !reflect.DeepEqual(a.Data, aBefore) {
		t.Fatal("A*A changed A")
	}
}

func TestMultiplyParallelRejectsNonFiniteResult(t *testing.T) {
	for _, tc := range []struct {
		name string
		a, b Matrix
	}{
		{"infinity", Matrix{N: 1, Data: []float64{math.MaxFloat64}}, Matrix{N: 1, Data: []float64{2}}},
		{"nan_from_overflow", Matrix{N: 2, Data: []float64{math.MaxFloat64, math.MaxFloat64, math.MaxFloat64, math.MaxFloat64}}, Matrix{N: 2, Data: []float64{2, 2, -2, -2}}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			aBefore := append([]float64(nil), tc.a.Data...)
			bBefore := append([]float64(nil), tc.b.Data...)
			for _, workers := range []int{1, 2, 8} {
				got, err := MultiplyParallel(tc.a, tc.b, workers)
				if !errors.Is(err, ErrNonFiniteValue) || got.N != 0 || got.Data != nil {
					t.Fatalf("overflow returned %+v, %v", got, err)
				}
			}
			if !reflect.DeepEqual(tc.a.Data, aBefore) || !reflect.DeepEqual(tc.b.Data, bBefore) {
				t.Fatal("overflow changed inputs")
			}
		})
	}
}

func TestMultiplyParallelIndependentOfGOMAXPROCS(t *testing.T) {
	previous := runtime.GOMAXPROCS(0)
	defer runtime.GOMAXPROCS(previous)
	a, b, err := Generate(5, 42)
	if err != nil {
		t.Fatal(err)
	}
	want := referenceProduct(a, b)
	for _, procs := range []int{1, 2, 4} {
		runtime.GOMAXPROCS(procs)
		for _, workers := range []int{1, 2, 8} {
			got, err := MultiplyParallel(a, b, workers)
			if err != nil {
				t.Fatal(err)
			}
			assertMatrixClose(t, got, want)
			if actual := runtime.GOMAXPROCS(0); actual != procs {
				t.Fatalf("kernel changed GOMAXPROCS: got %d, want %d", actual, procs)
			}
		}
	}
}

// Reference uses i,j,k and shares neither the worker nor the partition code.
func referenceProduct(a, b Matrix) Matrix {
	c := Matrix{N: a.N, Data: make([]float64, a.N*a.N)}
	for i := 0; i < a.N; i++ {
		for j := 0; j < a.N; j++ {
			for k := 0; k < a.N; k++ {
				c.Data[i*a.N+j] += a.Data[i*a.N+k] * b.Data[k*a.N+j]
			}
		}
	}
	return c
}

func assertMatrixClose(t *testing.T, got, want Matrix) {
	t.Helper()
	if err := got.Validate(); err != nil {
		t.Fatalf("invalid result: %v", err)
	}
	if got.N != want.N || len(got.Data) != len(want.Data) {
		t.Fatalf("shape = %d/%d; want %d/%d", got.N, len(got.Data), want.N, len(want.Data))
	}
	for i, expected := range want.Data {
		if math.IsNaN(expected) || math.IsInf(expected, 0) || math.Abs(got.Data[i]-expected) > 1e-9+1e-9*math.Abs(expected) {
			t.Fatalf("C[%d,%d] = %.17g, want %.17g", i/got.N, i%got.N, got.Data[i], expected)
		}
	}
}

func readExpectedMatrix(t *testing.T, fixture string) Matrix {
	t.Helper()
	f, err := os.Open(filepath.Join("..", "tests", "fixtures", fixture+".expected.txt"))
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	var n int
	if _, err := fmt.Fscan(f, &n); err != nil {
		t.Fatal(err)
	}
	if err := ValidateDimension(n); err != nil {
		t.Fatal(err)
	}
	m := Matrix{N: n, Data: make([]float64, n*n)}
	for i := range m.Data {
		if _, err := fmt.Fscan(f, &m.Data[i]); err != nil {
			t.Fatal(err)
		}
	}
	var extra string
	if _, err := fmt.Fscan(f, &extra); err != io.EOF {
		t.Fatalf("unexpected trailing data: %q, %v", extra, err)
	}
	return m
}
