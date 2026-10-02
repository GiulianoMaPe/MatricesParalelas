package main

import (
	"bytes"
	"errors"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"testing"
)

func TestGenerateSeed42Vector(t *testing.T) {
	wantStates := []uint32{1083814273, 378494188, 2479403867, 955863294, 1613448261, 110225632, 1921058495, 508781842}
	state := uint32(42)
	for i, want := range wantStates {
		state = nextState(state)
		if state != want {
			t.Fatalf("state[%d] = %d, want %d", i, state, want)
		}
	}
	a, b, err := Generate(2, 42)
	if err != nil {
		t.Fatal(err)
	}
	wantA := []float64{-0.363, 0.036, -0.215, 0.602}
	wantB := []float64{0.941, -0.453, -0.554, 0.579}
	for i, want := range wantA {
		if math.Abs(a.Data[i]-want) > 1e-15 {
			t.Fatalf("A[%d] = %.17g, want %.17g", i, a.Data[i], want)
		}
	}
	for i, want := range wantB {
		if math.Abs(b.Data[i]-want) > 1e-15 {
			t.Fatalf("B[%d] = %.17g, want %.17g", i, b.Data[i], want)
		}
	}
}

func TestReadSharedFixtures(t *testing.T) {
	fixtures := []struct {
		name string
		a, b []float64
	}{
		{"producto2", []float64{1, 2, 3, 4}, []float64{5, 6, 7, 8}},
		{"escalar", []float64{-3}, []float64{4}},
		{"identidad", []float64{1, 0, 0, 1}, []float64{-1, 2, 3, -4}},
		{"cero", []float64{0, 0, 0, 0}, []float64{1, -2, 3, -4}},
	}
	for _, fixture := range fixtures {
		t.Run(fixture.name, func(t *testing.T) {
			content, err := os.ReadFile(filepath.Join("..", "tests", "fixtures", fixture.name+".input.txt"))
			if err != nil {
				t.Fatal(err)
			}
			a, b, err := ReadMatrices(bytes.NewReader(content))
			if err != nil {
				t.Fatal(err)
			}
			if a.N*a.N != len(fixture.a) || b.N != a.N || !equalValues(a.Data, fixture.a) || !equalValues(b.Data, fixture.b) {
				t.Fatalf("parsed matrices A=%v B=%v; want A=%v B=%v", a.Data, b.Data, fixture.a, fixture.b)
			}
		})
	}
}

func TestReadMatricesAcceptsCRLFAndDecimalForms(t *testing.T) {
	a, b, err := ReadMatrices(bytes.NewBufferString("2\r\n+1 2.\r\n.5 -2e-1\r\n3 4\r\n5 6  \r\n"))
	if err != nil {
		t.Fatal(err)
	}
	wantA := []float64{1, 2, 0.5, -0.2}
	wantB := []float64{3, 4, 5, 6}
	if a.N != 2 || !equalValues(a.Data, wantA) || !equalValues(b.Data, wantB) {
		t.Fatalf("parsed matrices A=%v B=%v", a.Data, b.Data)
	}
}

func TestReadMatricesRejectsMalformedInputs(t *testing.T) {
	for _, input := range []string{
		"", "x 1 2", "0 1 2", "-1 1 2", "1 1", "1 1 2 3", "1 NaN 2", "1 +Inf 2", "1 0x1p2 2", "1 1e 2", "1 1e9999 2", "1 1 2 extra",
	} {
		t.Run(input, func(t *testing.T) {
			if _, _, err := ReadMatrices(bytes.NewBufferString(input)); !errors.Is(err, ErrInvalidFixture) {
				t.Fatalf("ReadMatrices(%q) error = %v, want ErrInvalidFixture", input, err)
			}
		})
	}
}

func TestReadMatricesReportsReaderErrors(t *testing.T) {
	if _, _, err := ReadMatrices(failingReader{}); !errors.Is(err, ErrFixtureIO) {
		t.Fatalf("ReadMatrices(reader error) = %v, want ErrFixtureIO", err)
	}
}

type failingReader struct{}

func (failingReader) Read([]byte) (int, error) {
	return 0, errors.New("read failed")
}

func equalValues(got, want []float64) bool {
	if len(got) != len(want) {
		return false
	}
	for i := range got {
		if math.Abs(got[i]-want[i]) > 1e-15 {
			return false
		}
	}
	return true
}

func TestGenerateValidatesArguments(t *testing.T) {
	cases := []struct {
		name string
		n    int
		seed uint32
		want error
	}{
		{"zero_dimension", 0, 42, ErrInvalidDimension},
		{"negative_dimension", -1, 42, ErrInvalidDimension},
		{"size_overflow", int(^uint(0) >> 1), 42, ErrSizeOverflow},
		{"byte_size_overflow", 1 << (strconv.IntSize/2 - 2), 42, ErrSizeOverflow},
		{"minimum_seed", 1, 0, nil},
		{"maximum_seed", 1, ^uint32(0), nil},
		{"valid_dimension", 2, 42, nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a, b, err := Generate(tc.n, tc.seed)
			if !errors.Is(err, tc.want) {
				t.Fatalf("Generate(%d, %d) error = %v; want %v", tc.n, tc.seed, err, tc.want)
			}
			if tc.want != nil {
				if a.N != 0 || b.N != 0 || a.Data != nil || b.Data != nil {
					t.Fatal("invalid inputs must not produce matrices", a, b)
				}
				return
			}
			if a.N != tc.n || b.N != tc.n {
				t.Fatalf("generated dimensions A=%d B=%d; want %d", a.N, b.N, tc.n)
			}
			if err := a.Validate(); err != nil {
				t.Fatalf("generated A is invalid: %v", err)
			}
			if err := b.Validate(); err != nil {
				t.Fatalf("generated B is invalid: %v", err)
			}
		})
	}
}

// This table exercises the same file grammar in both independent Go modules.
func TestReadMatricesLayoutContract(t *testing.T) {
	cases := []struct {
		name, input string
		valid       bool
		a, b        float64
	}{
		{"lf_without_final_newline", "1\n1\n2", true, 1, 2},
		{"crlf", "1\r\n1\r\n2\r\n", true, 1, 2},
		{"whitespace", " \t1 \n \t1\t \n2  \n\t \n", true, 1, 2},
		{"mixed_newlines", "1\r\n1\n2\r\n", true, 1, 2},
		{"subnormal_and_underflow", "1\n4.9406564584124654e-324\n1e-9999", true, math.SmallestNonzeroFloat64, 0},
		{"header_extra_value", "1 1\n2", false, 0, 0},
		{"fused_rows", "2\n1 2 3 4\n5 6\n7 8", false, 0, 0},
		{"split_rows", "2\n1\n2 3 4\n5 6\n7 8", false, 0, 0},
		{"internal_blank_line", "1\n\n1\n2", false, 0, 0},
		{"extra_row", "1\n1\n2\n3", false, 0, 0},
		{"missing_value", "1\n1", false, 0, 0},
		{"bare_cr", "1\r1\r2", false, 0, 0},
		{"bom", "\ufeff1\n1\n2", false, 0, 0},
		{"nul", "1\n1\x00x\n2", false, 0, 0},
		{"non_ascii_space", "1\n1\u00a0\n2", false, 0, 0},
		{"invalid_utf8", "1\n1\xff\n2", false, 0, 0},
		{"nan", "1\nNaN\n2", false, 0, 0},
		{"infinity", "1\n+Inf\n2", false, 0, 0},
		{"overflow", "1\n1e9999\n2", false, 0, 0},
		{"hexadecimal", "1\n0x1p2\n2", false, 0, 0},
		{"invalid_decimal", "1\n1e\n2", false, 0, 0},
		{"unsigned_dimension_overflow", "18446744073709551615\n1\n2", false, 0, 0},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a, b, err := ReadMatrices(bytes.NewBufferString(tc.input))
			if !tc.valid {
				if !errors.Is(err, ErrInvalidFixture) || a.N != 0 || b.N != 0 || a.Data != nil || b.Data != nil {
					t.Fatalf("invalid input returned A=%v B=%v error=%v", a, b, err)
				}
				return
			}
			if err != nil || a.N != 1 || b.N != 1 || len(a.Data) != 1 || len(b.Data) != 1 {
				t.Fatalf("valid input returned A=%v B=%v error=%v", a, b, err)
			}
			if a.Data[0] != tc.a || b.Data[0] != tc.b {
				t.Fatalf("A=%v B=%v; want %v and %v", a.Data, b.Data, tc.a, tc.b)
			}
		})
	}
}
