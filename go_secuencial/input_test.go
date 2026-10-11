package main

import (
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
	}
}
