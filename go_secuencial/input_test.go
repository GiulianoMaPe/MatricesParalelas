package main

import (
	"bytes"
	"errors"
	"math"
	"os"
	"path/filepath"
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

func TestGenerateRejectsInvalidDimensions(t *testing.T) {
	for _, n := range []int{0, -1, int(^uint(0) >> 1)} {
		if _, _, err := Generate(n, 42); !errors.Is(err, ErrInvalidInput) {
			t.Errorf("Generate(%d) error = %v, want ErrInvalidInput", n, err)
		}
	}
}

func TestGenerateAcceptsUint32SeedLimits(t *testing.T) {
	for _, seed := range []uint32{0, ^uint32(0)} {
		if _, _, err := Generate(1, seed); err != nil {
			t.Errorf("Generate(1, %d): %v", seed, err)
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
		{"minimum_seed", 1, 0, ErrPending},
		{"maximum_seed", 1, ^uint32(0), ErrPending},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a, b, err := Generate(tc.n, tc.seed)
			if !errors.Is(err, tc.want) {
				t.Fatalf("Generate(%d, %d) error = %v; want %v", tc.n, tc.seed, err, tc.want)
			}
			if a.N != 0 || b.N != 0 || a.Data != nil || b.Data != nil {
				t.Fatal("Generate must not return data before implementation", a, b)
			}
		})
	}
}
