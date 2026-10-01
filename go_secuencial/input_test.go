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
