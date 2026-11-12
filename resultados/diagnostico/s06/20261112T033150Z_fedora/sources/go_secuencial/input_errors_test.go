package main

import (
	"bytes"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type dataAndErrorReader struct {
	data string
	err  error
}

func (r *dataAndErrorReader) Read(p []byte) (int, error) {
	n := copy(p, r.data)
	r.data = r.data[n:]
	if len(r.data) == 0 {
		return n, r.err
	}
	return n, nil
}

func TestReadMatricesPreservesIOCauseAndDiscardsPartialData(t *testing.T) {
	cause := errors.New("device disconnected")
	for _, data := range []string{"", "2\n1 2\n3", "1\n1\n2", "1\n1\n2\n", "1\n1\n2\n \t"} {
		t.Run(data, func(t *testing.T) {
			a, b, err := ReadMatrices(&dataAndErrorReader{data: data, err: cause})
			if !errors.Is(err, ErrFixtureIO) || !errors.Is(err, cause) {
				t.Fatalf("read failure lost its classification or cause: %v", err)
			}
			if a.N != 0 || b.N != 0 || a.Data != nil || b.Data != nil {
				t.Fatalf("read failure returned partial matrices: A=%v B=%v", a, b)
			}
		})
	}
}

func TestReadMatricesRejectsHeaderBeforeReadingBody(t *testing.T) {
	for _, header := range []string{"0\n", "1073741824\n", "+1\n"} {
		reader := io.MultiReader(strings.NewReader(header), failingReader{})
		if _, _, err := ReadMatrices(reader); !errors.Is(err, ErrInvalidFixture) {
			t.Fatalf("invalid header %q was not rejected before reading body: %v", header, err)
		}
	}
}

func TestReadMatricesAllowsLongRowsAndRejectsTruncatedLargeDimension(t *testing.T) {
	// The grammar imposes no Scanner-style 64 KiB line limit.
	input := "1\n" + strings.Repeat(" ", 70_000) + "1\n2"
	a, b, err := ReadMatrices(strings.NewReader(input))
	if err != nil || a.N != 1 || b.N != 1 || a.Data[0] != 1 || b.Data[0] != 2 {
		t.Fatalf("long valid row rejected: A=%v B=%v err=%v", a, b, err)
	}
	// Arithmetically valid on both 32/64-bit int; must not preallocate N*N.
	if a, b, err := ReadMatrices(strings.NewReader("10000\n")); !errors.Is(err, ErrInvalidFixture) || a.Data != nil || b.Data != nil {
		t.Fatalf("truncated large input returned A=%v B=%v err=%v", a, b, err)
	}
}

type limitedWriter struct {
	remaining int
	err       error
	bytes.Buffer
}

func (w *limitedWriter) Write(p []byte) (int, error) {
	if len(p) > w.remaining {
		p = p[:w.remaining]
		n, _ := w.Buffer.Write(p)
		w.remaining = 0
		return n, w.err
	}
	w.remaining -= len(p)
	return w.Buffer.Write(p)
}

func TestWriteMatrixReportsPartialAndShortWrites(t *testing.T) {
	m := Matrix{N: 2, Data: []float64{1, 2, 3, 4}}
	for _, budget := range []int{0, 1, 5, 9} {
		for _, cause := range []error{nil, errRejectedWrite} {
			writer := &limitedWriter{remaining: budget, err: cause}
			want := cause
			if want == nil {
				want = io.ErrShortWrite
			}
			if err := WriteMatrix(writer, m); !errors.Is(err, want) {
				t.Errorf("budget=%d cause=%v: got %v, want %v", budget, cause, err, want)
			}
		}
	}
	var out bytes.Buffer
	if err := WriteMatrix(&out, Matrix{N: 2, Data: []float64{1}}); err == nil || out.Len() != 0 {
		t.Fatal("invalid matrix wrote partial output")
	}
}

func TestLoadMatricesChecksFileCapacityFromHeader(t *testing.T) {
	input := filepath.Join(t.TempDir(), "input.txt")
	// Body is deliberately incomplete: capacity must be checked from N first.
	if err := os.WriteFile(input, []byte("2\n"), 0600); err != nil {
		t.Fatal(err)
	}
	a, b, err := loadMatrices(config{inputFile: input}, 127) // 4 matrices * 4 cells * 8 bytes = 128.
	if err == nil || !strings.Contains(err.Error(), "memoria disponible insuficiente") || a.Data != nil || b.Data != nil {
		t.Fatalf("capacity not checked from header: A=%v B=%v err=%v", a, b, err)
	}
	var stdout, stderr bytes.Buffer
	output := filepath.Join(t.TempDir(), "result.txt")
	code := runWithMetadata([]string{"--input", input, "--output", output}, &stdout, &stderr, func() (environmentInfo, error) {
		info, err := testEnvironment()
		info.availableMemory = 127
		return info, err
	})
	if code != 1 || stdout.Len() != 0 || !strings.Contains(stderr.String(), "memoria disponible insuficiente") {
		t.Fatalf("exit=%d stdout=%q stderr=%q", code, stdout.String(), stderr.String())
	}
	if _, err := os.Stat(output); !os.IsNotExist(err) {
		t.Fatalf("capacity failure published output: %v", err)
	}
}
