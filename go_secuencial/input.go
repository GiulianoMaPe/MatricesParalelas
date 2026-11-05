package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"strings"
	"unicode/utf8"
)

// Constantes del Generador Congruencial Lineal (LCG de 32 bits) segun docs/contrato.md
const (
	lcgMultiplier uint32 = 1664525
	lcgIncrement  uint32 = 1013904223
	lcgModulus    uint32 = 2001
)

// Errores específicos del generador determinista y fixtures
var (
	ErrDimensionInvalida = ErrInvalidDimension
	ErrOverflowDimension = ErrSizeOverflow
	ErrInvalidFixture    = errors.New("fixture invalido")
	ErrFixtureIO         = errors.New("error al leer fixture")
)

// nextState calcula la siguiente transición de estado del LCG de 32 bits.
// El desbordamiento de uint32 realiza implicitamente la reduccion modulo 2^32.
func nextState(state uint32) uint32 {
	return lcgMultiplier*state + lcgIncrement
}

// stateToValue convierte un estado uint32 a un valor float64 en el rango [-1.000, 1.000].
// Se realiza conversion explicita a entero con signo antes de restar para evitar underflow.
func stateToValue(state uint32) float64 {
	rem := int64(state % lcgModulus)
	return float64(rem-1000) / 1000.0
}

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
		a.Data[i] = stateToValue(state)
	}
	for i := 0; i < count; i++ {
		state = nextState(state)
		b.Data[i] = stateToValue(state)
	}
	return a, b, nil
}

// ReadMatrices requires N on its own line, then N rows of A and N rows of B.
// Each row has exactly N decimal values; LF/CRLF and trailing whitespace are
// accepted. Invalid input returns empty matrices and ErrInvalidFixture; reader
// failures return ErrFixtureIO. Neither error is an executable exit code.
func ReadMatrices(reader io.Reader) (Matrix, Matrix, error) {
	return readMatrices(reader, nil)
}

// checkSize lets the executable check capacity from N before reading matrix
// rows or allocating their storage. The public reader only checks arithmetic.
func readMatrices(reader io.Reader, checkSize func(int) error) (Matrix, Matrix, error) {
	if reader == nil {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	buffer := bufio.NewReader(reader)
	headerLine, err := requiredFixtureLine(buffer)
	if err != nil {
		return Matrix{}, Matrix{}, fmt.Errorf("cabecera: %w", err)
	}
	header := rowTokens(headerLine)
	if len(header) != 1 || !isUnsignedDecimal(header[0]) {
		return Matrix{}, Matrix{}, fmt.Errorf("%w: cabecera debe contener solo N decimal sin signo", ErrInvalidFixture)
	}
	dimension, err := strconv.ParseUint(header[0], 10, strconv.IntSize)
	maxInt := int(^uint(0) >> 1)
	if err != nil || dimension == 0 || dimension > uint64(maxInt) {
		return Matrix{}, Matrix{}, ErrInvalidFixture
	}
	n := int(dimension)
	if err := ValidateDimension(n); err != nil {
		return Matrix{}, Matrix{}, fmt.Errorf("%w: %w", ErrInvalidFixture, err)
	}
	if checkSize != nil {
		if err := checkSize(n); err != nil {
			return Matrix{}, Matrix{}, err
		}
	}
	// Grow only from actual rows, so a truncated file with a huge but
	// representable N cannot trigger a full N*N allocation from its header.
	matrices := [2]Matrix{{N: n}, {N: n}}
	for matrixIndex := range matrices {
		matrix := &matrices[matrixIndex]
		for row := 0; row < n; row++ {
			line, err := requiredFixtureLine(buffer)
			if err != nil {
				return Matrix{}, Matrix{}, fmt.Errorf("matriz %c, fila %d: %w", 'A'+matrixIndex, row+1, err)
			}
			tokens := rowTokens(line)
			if len(tokens) != n {
				return Matrix{}, Matrix{}, fmt.Errorf("%w: matriz %c, fila %d: esperados %d valores, recibidos %d", ErrInvalidFixture, 'A'+matrixIndex, row+1, n, len(tokens))
			}
			for column, token := range tokens {
				if !isDecimalFloat(token) {
					return Matrix{}, Matrix{}, fmt.Errorf("%w: matriz %c, fila %d, columna %d: decimal invalido", ErrInvalidFixture, 'A'+matrixIndex, row+1, column+1)
				}
				value, parseErr := strconv.ParseFloat(token, 64)
				if parseErr != nil || math.IsInf(value, 0) || math.IsNaN(value) {
					return Matrix{}, Matrix{}, fmt.Errorf("%w: matriz %c, fila %d, columna %d: valor fuera de rango finito", ErrInvalidFixture, 'A'+matrixIndex, row+1, column+1)
				}
				matrix.Data = append(matrix.Data, value)
			}
		}
	}
	for {
		line, err := readFixtureLine(buffer)
		if err == io.EOF {
			return matrices[0], matrices[1], nil
		}
		if err != nil {
			return Matrix{}, Matrix{}, fmt.Errorf("final del archivo: %w", err)
		}
		if strings.Trim(line, " \t") != "" {
			return Matrix{}, Matrix{}, fmt.Errorf("%w: datos extra despues de B", ErrInvalidFixture)
		}
	}
}

// ReadString supports long rows without Scanner's default token limit.
// A partial last line is valid only at EOF, never on another reader failure.
func readFixtureLine(reader *bufio.Reader) (string, error) {
	line, err := reader.ReadString('\n')
	if err != nil && err != io.EOF {
		return "", fmt.Errorf("%w: %w", ErrFixtureIO, err)
	}
	if err == io.EOF && len(line) == 0 {
		return "", io.EOF
	}
	if strings.HasSuffix(line, "\n") {
		line = strings.TrimSuffix(line, "\n")
		line = strings.TrimSuffix(line, "\r")
	}
	if !utf8.ValidString(line) || strings.ContainsRune(line, '\r') {
		return "", fmt.Errorf("%w: UTF-8 invalido o CR aislado", ErrInvalidFixture)
	}
	return line, nil
}

func requiredFixtureLine(reader *bufio.Reader) (string, error) {
	line, err := readFixtureLine(reader)
	if err == io.EOF {
		return "", fmt.Errorf("%w: archivo incompleto", ErrInvalidFixture)
	}
	return line, err
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
	// Flush also detects an underlying short write without an explicit error.
	out := bufio.NewWriter(writer)
	n := m.N
	if _, err := fmt.Fprintln(out, n); err != nil {
		return err
	}
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			if j > 0 {
				if err := out.WriteByte(' '); err != nil {
					return err
				}
			}
			val := m.Data[i*n+j]
			if _, err := fmt.Fprintf(out, "%.17g", val); err != nil {
				return err
			}
		}
		if err := out.WriteByte('\n'); err != nil {
			return err
		}
	}
	return out.Flush()
}
