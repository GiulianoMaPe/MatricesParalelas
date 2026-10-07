package main

import (
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"strings"
	"unicode/utf8"
)

var ErrInvalidFixture = errors.New("fixture invalido")
var ErrFixtureIO = errors.New("error al leer fixture")

// Generate returns two row-major matrices using the shared uint32 LCG contract.
// It validates N with the same rules as Matrix.Validate before allocating.
// Invalid dimensions return ErrInvalidDimension or ErrSizeOverflow and empty
// matrices. Valid input returns generated matrices, not ErrPending.
func Generate(n int, seed uint32) (Matrix, Matrix, error) {
	count, err := matrixElementCount(n)
	if err != nil {
		return Matrix{}, Matrix{}, err
	}
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

// ReadMatrices requires N on its own line, then N rows of A and N rows of B.
// Each row has exactly N decimal values; LF/CRLF and trailing whitespace are
// accepted. Invalid input returns empty matrices and ErrInvalidFixture; reader
// failures return ErrFixtureIO. Neither error is an executable exit code.
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
	text := strings.ReplaceAll(string(content), "\r\n", "\n")
	if strings.ContainsRune(text, '\r') {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	lines := strings.Split(text, "\n")
	header := rowTokens(lines[0])
	if len(header) != 1 || !isUnsignedDecimal(header[0]) {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	dimension, err := strconv.ParseUint(header[0], 10, strconv.IntSize)
	maxInt := int(^uint(0) >> 1)
	if err != nil || dimension == 0 || dimension > uint64(maxInt) {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	n := int(dimension)
	if n > maxInt/n || n*n > maxInt/8 || n > (maxInt-1)/2 || len(lines) < 1+2*n {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	for _, line := range lines[1 : 1+2*n] {
		if len(rowTokens(line)) != n {
			return Matrix{}, Matrix{}, ErrInvalidFixture
		}
	}
	for _, line := range lines[1+2*n:] {
		if strings.Trim(line, " \t") != "" {
			return Matrix{}, Matrix{}, ErrInvalidFixture
		}
	}
	count := n * n
	a := Matrix{N: n, Data: make([]float64, count)}
	b := Matrix{N: n, Data: make([]float64, count)}
	for row, line := range lines[1 : 1+2*n] {
		for column, token := range rowTokens(line) {
			if !isDecimalFloat(token) {
				return Matrix{}, Matrix{}, ErrInvalidFixture
			}
			value, parseErr := strconv.ParseFloat(token, 64)
			if parseErr != nil || math.IsInf(value, 0) || math.IsNaN(value) {
				return Matrix{}, Matrix{}, ErrInvalidFixture
			}
			if row < n {
				a.Data[row*n+column] = value
			} else {
				b.Data[(row-n)*n+column] = value
			}
		}
	}
	return a, b, nil
}

func rowTokens(line string) []string {
	return strings.FieldsFunc(line, func(r rune) bool { return r == ' ' || r == '\t' })
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

func WriteMatrix(writer io.Writer, m Matrix) error {
	if writer == nil {
		return ErrInvalidFixture
	}
	if err := m.Validate(); err != nil {
		return err
	}
	n := m.N
	if _, err := fmt.Fprintln(writer, n); err != nil {
		return err
	}
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			if j > 0 {
				if _, err := writer.Write([]byte{' '}); err != nil {
					return err
				}
			}
			val := m.Data[i*n+j]
			if _, err := fmt.Fprintf(writer, "%.17g", val); err != nil {
				return err
			}
		}
		if _, err := writer.Write([]byte{'\n'}); err != nil {
			return err
		}
	}
	return nil
}
