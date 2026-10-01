package main

import (
	"errors"
	"io"
	"math"
	"strconv"
	"strings"
	"unicode/utf8"
)

var ErrInvalidInput = errors.New("dimension invalida para generar matrices")
var ErrInvalidFixture = errors.New("fixture invalido")
var ErrFixtureIO = errors.New("error al leer fixture")

// Generate returns two row-major matrices using the shared uint32 LCG contract.
func Generate(n int, seed uint32) (Matrix, Matrix, error) {
	maxInt := int(^uint(0) >> 1)
	if n <= 0 || n > maxInt/n || n*n > maxInt/8 {
		return Matrix{}, Matrix{}, ErrInvalidInput
	}
	count := n * n
	a := Matrix{N: n, Data: make([]float64, count)}
	b := Matrix{N: n, Data: make([]float64, count)}
	state := seed

	for i := 0; i < count; i++ {
		state = nextState(state)
		a.Data[i] = (float64(int64(state%2001) - 1000)) / 1000.0
	}
	for i := 0; i < count; i++ {
		state = nextState(state)
		b.Data[i] = (float64(int64(state%2001) - 1000)) / 1000.0
	}
	return a, b, nil
}

func nextState(state uint32) uint32 {
	return 1664525*state + 1013904223
}

// ReadMatrices parses the shared fixture format from an input stream.
func ReadMatrices(reader io.Reader) (Matrix, Matrix, error) {
	if reader == nil {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	content, err := io.ReadAll(reader)
	if err != nil {
		return Matrix{}, Matrix{}, ErrFixtureIO
	}
	if !utf8.Valid(content) {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	tokens := strings.FieldsFunc(string(content), func(r rune) bool {
		return r == ' ' || r == '\t' || r == '\r' || r == '\n'
	})
	if len(tokens) == 0 || !isUnsignedDecimal(tokens[0]) {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	dimension, err := strconv.ParseUint(tokens[0], 10, strconv.IntSize)
	if err != nil || dimension == 0 {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	n := int(dimension)
	maxInt := int(^uint(0) >> 1)
	if n > maxInt/n || n*n > maxInt/16 || len(tokens) != 1+2*n*n {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	count := n * n
	a := Matrix{N: n, Data: make([]float64, count)}
	b := Matrix{N: n, Data: make([]float64, count)}
	for i, token := range tokens[1:] {
		if !isDecimalFloat(token) {
			return Matrix{}, Matrix{}, ErrInvalidFixture
		}
		value, parseErr := strconv.ParseFloat(token, 64)
		if parseErr != nil || math.IsInf(value, 0) || math.IsNaN(value) {
			return Matrix{}, Matrix{}, ErrInvalidFixture
		}
		if i < count {
			a.Data[i] = value
		} else {
			b.Data[i-count] = value
		}
	}
	return a, b, nil
}

func isUnsignedDecimal(token string) bool {
	if token == "" {
		return false
	}
	for _, r := range token {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

func isDecimalFloat(token string) bool {
	i := 0
	if i < len(token) && (token[i] == '+' || token[i] == '-') {
		i++
	}
	digits := 0
	for i < len(token) && token[i] >= '0' && token[i] <= '9' {
		i++
		digits++
	}
	if i < len(token) && token[i] == '.' {
		i++
		for i < len(token) && token[i] >= '0' && token[i] <= '9' {
			i++
			digits++
		}
	}
	if digits == 0 {
		return false
	}
	if i < len(token) && (token[i] == 'e' || token[i] == 'E') {
		i++
		if i < len(token) && (token[i] == '+' || token[i] == '-') {
			i++
		}
		exponentStart := i
		for i < len(token) && token[i] >= '0' && token[i] <= '9' {
			i++
		}
		if i == exponentStart {
			return false
		}
	}
	return i == len(token)
}
