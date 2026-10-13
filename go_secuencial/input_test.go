package main

import (
	"bytes"
	"errors"
	"math"
	"testing"
)

// TestGenerate_ValidacionDimension verifica que dimensiones inválidas sean rechazadas.
func TestGenerate_ValidacionDimension(t *testing.T) {
	casosInvalidos := []int{0, -1, -100}
	for _, n := range casosInvalidos {
		a, b, err := Generate(n, 42)
		if !errors.Is(err, ErrDimensionInvalida) {
			t.Errorf("Generate(%d, 42) esperaba ErrDimensionInvalida, pero obtuvo: %v", n, err)
		}
		if a.Data != nil || b.Data != nil {
			t.Errorf("Generate(%d, 42) no debe devolver matrices con datos en caso de error", n)
		}
	}
}

// TestGenerate_EstadosControl verifica que los estados del LCG coincidan exactamente
// con los 4 primeros estados descritos en docs/contrato.md para seed = 42.
func TestGenerate_EstadosControl(t *testing.T) {
	estadosEsperados := []uint32{
		1083814273,
		378494188,
		2479403867,
		955863294,
	}

	state := uint32(42)
	for i, esperado := range estadosEsperados {
		state = nextState(state)
		if state != esperado {
			t.Fatalf("Paso %d: estado obtenido %d != esperado %d", i+1, state, esperado)
		}
	}
}

// TestGenerate_VectoresControlSeed42 verifica los valores generados para N = 2 y seed = 42.
// Para seed = 42:
// Paso 1: state = 1083814273 -> rem = 637  -> val = (637-1000)/1000  = -0.363 (A[0,0])
// Paso 2: state = 378494188  -> rem = 1036 -> val = (1036-1000)/1000 = +0.036 (A[0,1])
// Paso 3: state = 2479403867 -> rem = 785  -> val = (785-1000)/1000  = -0.215 (A[1,0])
// Paso 4: state = 955863294  -> rem = 1602 -> val = (1602-1000)/1000 = +0.602 (A[1,1])
// Paso 5: state = 4063273413 -> rem = 1941 -> val = (1941-1000)/1000 = +0.941 (B[0,0])
// Paso 6: state = 3884877796 -> rem = 547  -> val = (547-1000)/1000  = -0.453 (B[0,1])
// Paso 7: state = 840848195  -> rem = 446  -> val = (446-1000)/1000  = -0.554 (B[1,0])
// Paso 8: state = 3307669082 -> rem = 1579 -> val = (1579-1000)/1000 = +0.579 (B[1,1])
func TestGenerate_VectoresControlSeed42(t *testing.T) {
	a, b, err := Generate(2, 42)
	if err != nil {
		t.Fatalf("Generate(2, 42) falló con error: %v", err)
	}

	if a.N != 2 || b.N != 2 {
		t.Fatalf("Dimensiones incorrectas: a.N=%d, b.N=%d", a.N, b.N)
	}
	if len(a.Data) != 4 || len(b.Data) != 4 {
		t.Fatalf("Largo de datos incorrecto: len(A)=%d, len(B)=%d", len(a.Data), len(b.Data))
	}

	valoresEsperadosA := []float64{-0.363, 0.036, -0.215, 0.602}
	valoresEsperadosB := []float64{0.941, -0.453, -0.554, 0.579}

	const tol = 1e-9
	for i, esperado := range valoresEsperadosA {
		if math.Abs(a.Data[i]-esperado) > tol {
			t.Errorf("A[%d]: obtenido %f != esperado %f", i, a.Data[i], esperado)
		}
	}

	for j, esperado := range valoresEsperadosB {
		if math.Abs(b.Data[j]-esperado) > tol {
			t.Errorf("B[%d]: obtenido %f != esperado %f", j, b.Data[j], esperado)
		}
	}
}

// TestGenerate_RangoValores verifica que todos los valores generados estén en [-1.0, 1.0].
func TestGenerate_RangoValores(t *testing.T) {
	n := 16
	a, b, err := Generate(n, 12345)
	if err != nil {
		t.Fatalf("Generate(%d, 12345) falló: %v", n, err)
	}

	for i, val := range a.Data {
		if val < -1.0 || val > 1.0 {
			t.Fatalf("A[%d]=%f fuera del rango [-1.0, 1.0]", i, val)
		}
	}
	for j, val := range b.Data {
		if val < -1.0 || val > 1.0 {
			t.Fatalf("B[%d]=%f fuera del rango [-1.0, 1.0]", j, val)
		}
	}
}

// TestGenerate_ContinuidadEstado verifica que la matriz B continúe el estado de A
// y no reinicie la semilla.
func TestGenerate_ContinuidadEstado(t *testing.T) {
	// Generar N=1 (A tiene 1 elemento, B tiene 1 elemento)
	a1, b1, err := Generate(1, 42)
	if err != nil {
		t.Fatalf("Generate(1, 42) falló: %v", err)
	}

	// b1[0] debe ser diferente de a1[0] ya que fue el segundo paso del generador
	if a1.Data[0] == b1.Data[0] {
		t.Errorf("b1[0] no debería ser igual a a1[0] en una secuencia determinista no trivial")
	}

	// Comprobar con los valores conocidos para seed=42 (paso 1 y paso 2)
	if math.Abs(a1.Data[0]-(-0.363)) > 1e-9 {
		t.Errorf("a1[0]: esperado -0.363, obtenido %f", a1.Data[0])
	}
	if math.Abs(b1.Data[0]-0.036) > 1e-9 {
		t.Errorf("b1[0]: esperado 0.036, obtenido %f", b1.Data[0])
	}
}

// TestGenerate_SemillasExtremas verifica semillas límites 0 y MaxUint32.
func TestGenerate_SemillasExtremas(t *testing.T) {
	semillas := []uint32{0, math.MaxUint32}
	for _, seed := range semillas {
		a, b, err := Generate(4, seed)
		if err != nil {
			t.Errorf("Generate(4, %d) falló con error: %v", seed, err)
		}
		if len(a.Data) != 16 || len(b.Data) != 16 {
			t.Errorf("Generate(4, %d) longitud de datos inválida", seed)
		}
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

func TestGenerateBoundarySeedVectors(t *testing.T) {
	cases := []struct {
		name  string
		seed  uint32
		wantA []float64
		wantB []float64
	}{
		{
			name:  "zero",
			seed:  0,
			wantA: []float64{0.525, 0.844, 0.642, -0.032},
			wantB: []float64{0.360, -0.832, 0.853, -0.771},
		},
		{
			name:  "maximum",
			seed:  ^uint32(0),
			wantA: []float64{0.832, -0.174, 0.670, -0.661},
			wantB: []float64{0.975, -0.773, 0.964, -0.454},
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a, b, err := Generate(2, tc.seed)
			if err != nil {
				t.Fatal(err)
			}
			if !equalValues(a.Data, tc.wantA) || !equalValues(b.Data, tc.wantB) {
				t.Fatalf("Generate(2, %d) = A %v, B %v; want A %v, B %v",
					tc.seed, a.Data, b.Data, tc.wantA, tc.wantB)
			}
		})
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
