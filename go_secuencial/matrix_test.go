package main

import (
	"errors"
	"testing"
)

func TestMultiplyReportsPending(t *testing.T) {
	result, err := Multiply(Matrix{N: 1, Data: []float64{3}}, Matrix{N: 1, Data: []float64{4}})
	if !errors.Is(err, ErrPending) || result.Data != nil || result.N != 0 {
		t.Fatal("pending multiplication must not return a fake product", result, err)
	}
}
