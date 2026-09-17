package main

import (
	"errors"
	"testing"
)

func TestGenerateReportsPending(t *testing.T) {
	a, b, err := Generate(2, 42)
	if !errors.Is(err, ErrPending) || a.Data != nil || b.Data != nil {
		t.Fatal("pending generator must not return fake inputs")
	}
}
