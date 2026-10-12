package main

import (
	"bytes"
	"encoding/csv"
	"errors"
	"math"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"
)

func testEnvironment() (environmentInfo, error) {
	return environmentInfo{commit: "1234567", hostname: "test", cpuModel: "CPU, test",
		osVersion: "Windows 11 Pro build 26200", totalMemory: 16 << 30, availableMemory: 8 << 30}, nil
}

func TestParseArgs(t *testing.T) {
	valid := [][]string{
		{"--n", "1", "--seed", "0"},
		{"--seed", "4294967295", "--n", "0002"},
		{"--input", "archivo con espacios.txt", "--output", "resultado.txt"},
		{"--n", "2", "--seed", "42", "--repetition", "0"},
		{"--input", "entrada.txt", "--repetition", "5"},
		{"--smoke-test"},
	}
	for _, args := range valid {
		if _, err := parseArgs(args); err != nil {
			t.Errorf("parseArgs(%q): %v", args, err)
		}
	}
	invalid := [][]string{
		{}, {"--n"}, {"--seed", "0"}, {"--n", "2"},
		{"--input", ""}, {"--input", " "},
		{"--input", "", "--n", "2", "--seed", "42"},
		{"--n", "2", "--seed", "42", "--output", ""},
		{"--n", "2", "--seed", "42", "--output"},
		{"--n", "--seed", "42"},
		{"--n", "0", "--seed", "42"},
		{"--n", "-1", "--seed", "42"},
		{"--n", "+1", "--seed", "42"},
		{"--n", "1.5", "--seed", "42"},
		{"--n", "1073741824", "--seed", "42"},
		{"--n", "2", "--seed", "-1"},
		{"--n", "2", "--seed", "+42"},
		{"--n", "2", "--seed", "4294967296"},
		{"--n", "2", "--seed", "42", "--n", "2"},
		{"--input", "a", "--input", "b"},
		{"--input", "a", "--output", "b", "--output", "c"},
		{"--input", "a", "--seed", "0"},
		{"--input", "a", "--n", "2", "--seed", "42"},
		{"--n", "2", "--seed", "42", "--unknown"},
		{"--smoke-test", "--input", "a"},
		{"--n", "2", "--seed", "42", "--repetition", "6"},
		{"--n", "2", "--seed", "42", "--repetition", "-1"},
	}
	for _, args := range invalid {
		if _, err := parseArgs(args); err == nil {
			t.Errorf("parseArgs(%q) accepted invalid arguments", args)
		}
	}
}

func readMeasurement(t *testing.T, output string) []string {
	t.Helper()
	rows, err := csv.NewReader(strings.NewReader(output)).ReadAll()
	if err != nil || len(rows) != 2 {
		t.Fatalf("want CSV header and one row, got %q: %v", output, err)
	}
	if !reflect.DeepEqual(rows[0], csvHeader) || len(rows[1]) != 20 {
		t.Fatalf("invalid CSV schema: %v", rows)
	}
	return rows[1]
}

func TestRunFixturesAndCSV(t *testing.T) {
	previous := runtime.GOMAXPROCS(4)
	defer runtime.GOMAXPROCS(previous)
	for _, name := range []string{"producto2", "escalar", "identidad", "cero", "impar3"} {
		t.Run(name, func(t *testing.T) {
			output := filepath.Join(t.TempDir(), "resultado.txt")
			input := filepath.Join("..", "tests", "fixtures", name+".input.txt")
			var stdout, stderr bytes.Buffer
			before := time.Now().UTC().Truncate(time.Second)
			code := runWithMetadata([]string{"--input", input, "--output", output}, &stdout, &stderr, testEnvironment)
			if code != 0 || stderr.Len() != 0 {
				t.Fatalf("exit=%d stderr=%q", code, stderr.String())
			}
			assertMatrixClose(t, readExpectedMatrix(t, output), readExpectedMatrix(t, filepath.Join("..", "tests", "fixtures", name+".expected.txt")))
			row := readMeasurement(t, stdout.String())
			if row[2] != "1234567" || row[4] != "CPU, test" || row[5] != "16.000" || row[14] != "1" || row[15] != "1" || row[16] != "false" || row[19] != "OK" {
				t.Fatalf("incorrect CSV fields: %v", row)
			}
			start, err := time.Parse(time.RFC3339, row[0])
			if err != nil || start.Before(before) || start.After(time.Now().UTC()) {
				t.Fatalf("invalid measurement start: %s", row[0])
			}
			kernel, err := strconv.ParseFloat(row[17], 64)
			if err != nil {
				t.Fatal(err)
			}
			total, err := strconv.ParseFloat(row[18], 64)
			if err != nil || kernel < 0 || total < kernel {
				t.Fatalf("invalid durations: kernel=%v total=%v", kernel, total)
			}
		})
	}
}

func TestRunGenerationAndRepetitions(t *testing.T) {
	for _, repetition := range []string{"0", "1", "5"} {
		var stdout, stderr bytes.Buffer
		code := runWithMetadata([]string{"--n", "2", "--seed", "42", "--repetition", repetition}, &stdout, &stderr, testEnvironment)
		if code != 0 || stderr.Len() != 0 {
			t.Fatalf("exit=%d stderr=%q", code, stderr.String())
		}
		row := readMeasurement(t, stdout.String())
		if row[9] != "42" || row[15] != repetition || row[16] != strconv.FormatBool(repetition == "0") {
			t.Fatalf("invalid repetition: %v", row)
		}
	}
}

func TestRunErrorsProduceNoMeasurement(t *testing.T) {
	dir := t.TempDir()
	invalidInput := filepath.Join(dir, "invalid.txt")
	overflowInput := filepath.Join(dir, "overflow.txt")
	if err := os.WriteFile(invalidInput, []byte("1\nNaN\n2\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(overflowInput, []byte("1\n1.7976931348623157e308\n2\n"), 0600); err != nil {
		t.Fatal(err)
	}
	cases := [][]string{
		{"--input", "", "--n", "2", "--seed", "42"},
		{"--n", "2", "--seed", "42", "--output", ""},
		{"--input", filepath.Join(dir, "absent.txt")},
		{"--input", invalidInput}, {"--input", overflowInput},
		{"--n", "2", "--seed", "42", "--output", filepath.Join(dir, "absent", "out.txt")},
		{"--n", "2", "--seed", "42", "--output", dir},
		{"--n", "100000", "--seed", "42"},
	}
	for _, args := range cases {
		var stdout, stderr bytes.Buffer
		code := runWithMetadata(args, &stdout, &stderr, testEnvironment)
		if code != 1 || stdout.Len() != 0 || stderr.Len() == 0 {
			t.Errorf("args=%q exit=%d stdout=%q stderr=%q", args, code, stdout.String(), stderr.String())
		}
	}
	var stdout, stderr bytes.Buffer
	code := runWithMetadata([]string{"--n", "1", "--seed", "0"}, &stdout, &stderr, func() (environmentInfo, error) {
		return environmentInfo{}, errors.New("cannot obtain metadata")
	})
	if code != 1 || stdout.Len() != 0 || stderr.Len() == 0 {
		t.Fatal("missing metadata must not emit a measurement")
	}
}

func TestSmokeDoesNotRequireMetadata(t *testing.T) {
	var stdout, stderr bytes.Buffer
	code := runWithMetadata([]string{"--smoke-test"}, &stdout, &stderr, func() (environmentInfo, error) {
		t.Fatal("smoke test requested measurement metadata")
		return environmentInfo{}, nil
	})
	if code != 0 || stdout.Len() == 0 || stderr.Len() != 0 {
		t.Fatalf("exit=%d stdout=%q stderr=%q", code, stdout.String(), stderr.String())
	}
}

func TestMeasurementResetsPreparedBuffer(t *testing.T) {
	a := Matrix{N: 1, Data: []float64{-3}}
	b := Matrix{N: 1, Data: []float64{4}}
	c := Matrix{N: 1, Data: []float64{999}}
	for iteration := 0; iteration < 2; iteration++ {
		result := measureProduct(a, b, c)
		assertMatrixClose(t, c, Matrix{N: 1, Data: []float64{-12}})
		if result.kernelS < 0 || result.totalS < result.kernelS {
			t.Fatalf("invalid timing: %+v", result)
		}
	}
}

func TestValidateProductRejectsIncorrectResults(t *testing.T) {
	want := Matrix{N: 2, Data: []float64{19, 22, 43, 50}}
	for _, values := range [][]float64{
		{19, 22, 43, 51}, {19, math.NaN(), 43, 50}, {19, 22, math.Inf(1), 50},
	} {
		if err := validateProduct(Matrix{N: 2, Data: values}, want); err == nil {
			t.Fatal("accepted incorrect or non-finite result", values)
		}
	}
	if err := validateProduct(Matrix{N: 1, Data: []float64{19}}, want); err == nil {
		t.Fatal("accepted mismatched dimensions")
	}
}

func TestCSVRejectsInvalidTimesAndWriterFailures(t *testing.T) {
	info, _ := testEnvironment()
	for _, result := range []measurement{
		{kernelS: 2, totalS: 1}, {kernelS: -1, totalS: 1},
		{kernelS: math.NaN(), totalS: 1}, {kernelS: 1, totalS: math.Inf(1)},
	} {
		var stdout bytes.Buffer
		if err := writeCSV(&stdout, config{repetition: 1}, 1, info, result); err == nil || stdout.Len() != 0 {
			t.Fatal("invalid timings produced CSV")
		}
	}
	if err := writeCSV(rejectingWriter{}, config{repetition: 1}, 1, info, measurement{kernelS: 1, totalS: 2}); !errors.Is(err, errRejectedWrite) {
		t.Fatalf("CSV write failure not reported: %v", err)
	}
}

var errRejectedWrite = errors.New("write rejected")

type rejectingWriter struct{}

func (rejectingWriter) Write([]byte) (int, error) { return 0, errRejectedWrite }

func TestWriteMatrixAndAtomicSave(t *testing.T) {
	m := Matrix{N: 2, Data: []float64{0.1, -0.2, 3, 4}}
	var buffer bytes.Buffer
	if err := WriteMatrix(&buffer, m); err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(buffer.String(), "2\n") || len(strings.Split(strings.TrimSpace(buffer.String()), "\n")) != 3 {
		t.Fatal("incorrect output layout", buffer.String())
	}
	if err := WriteMatrix(rejectingWriter{}, m); !errors.Is(err, errRejectedWrite) {
		t.Fatalf("matrix write failure not reported: %v", err)
	}
	if err := WriteMatrix(nil, m); err == nil {
		t.Fatal("accepted nil writer")
	}
	output := filepath.Join(t.TempDir(), "result.txt")
	if err := os.WriteFile(output, []byte("existing output"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := saveMatrix(output, Matrix{N: 1, Data: []float64{math.NaN()}}); err == nil {
		t.Fatal("saved invalid matrix")
	}
	content, err := os.ReadFile(output)
	if err != nil || string(content) != "existing output" {
		t.Fatal("failed output write changed existing file")
	}
	if err := saveMatrix(output, m); err != nil {
		t.Fatal(err)
	}
	assertMatrixClose(t, readExpectedMatrix(t, output), m)
}
