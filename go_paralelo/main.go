package main

import (
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"math"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

type config struct {
	smokeTest  bool
	n          int
	seed       uint32
	inputFile  string
	outputFile string
	workers    int
	repetition int
}

func parseArgs(args []string) (config, error) {
	cfg := config{repetition: 1}
	seen := make(map[string]bool)
	for i := 0; i < len(args); i++ {
		option := args[i]
		if seen[option] {
			return cfg, fmt.Errorf("opci\u00f3n duplicada: %s", option)
		}
		seen[option] = true
		if option == "--smoke-test" {
			if len(args) != 1 {
				return cfg, fmt.Errorf("--smoke-test no se combina con otras opciones")
			}
			cfg.smokeTest = true
			return cfg, nil
		}
		switch option {
		case "--n", "--seed", "--input", "--output", "--workers", "--repetition":
		default:
			return cfg, fmt.Errorf("opci\u00f3n desconocida: %s", option)
		}
		i++
		if i >= len(args) || strings.TrimSpace(args[i]) == "" || strings.HasPrefix(args[i], "--") {
			return cfg, fmt.Errorf("%s requiere un valor", option)
		}
		value := args[i]
		switch option {
		case "--n", "--seed", "--workers", "--repetition":
			if !isUnsignedDecimal(value) {
				return cfg, fmt.Errorf("valor decimal sin signo requerido para %s: %s", option, value)
			}
			bits := strconv.IntSize
			if option == "--seed" {
				bits = 32
			}
			number, err := strconv.ParseUint(value, 10, bits)
			if err != nil {
				return cfg, fmt.Errorf("valor inv\u00e1lido para %s: %s", option, value)
			}
			switch option {
			case "--n":
				if number > uint64(int(^uint(0)>>1)) {
					return cfg, ErrSizeOverflow
				}
				cfg.n = int(number)
				if err := ValidateDimension(cfg.n); err != nil {
					return cfg, err
				}
			case "--seed":
				cfg.seed = uint32(number)
			case "--workers":
				if number == 0 {
					return cfg, fmt.Errorf("--workers debe ser mayor que cero")
				}
				const maxWorkers = 1024
				if number > maxWorkers {
					return cfg, fmt.Errorf("--workers excede el l\u00edmite m\u00e1ximo (%d)", maxWorkers)
				}
				cfg.workers = int(number)
			case "--repetition":
				if number > 5 {
					return cfg, fmt.Errorf("--repetition debe estar entre 0 y 5")
				}
				cfg.repetition = int(number)
			}
		case "--input":
			cfg.inputFile = value
		case "--output":
			cfg.outputFile = value
		}
	}
	if seen["--input"] {
		if seen["--n"] || seen["--seed"] {
			return cfg, fmt.Errorf("--input no se combina con --n ni --seed")
		}
	} else if !seen["--n"] || !seen["--seed"] {
		return cfg, fmt.Errorf("use --n N --seed S o --input archivo")
	}
	if cfg.workers == 0 {
		return cfg, fmt.Errorf("falta --workers W (entero positivo)")
	}
	return cfg, nil
}

type measurement struct {
	start           time.Time
	kernelS, totalS float64
}

func computeReferenceProduct(a, b Matrix) (Matrix, error) {
	reference := Matrix{N: a.N, Data: make([]float64, len(a.Data))}
	for i := 0; i < a.N; i++ {
		for j := 0; j < a.N; j++ {
			var sum float64
			for k := 0; k < a.N; k++ {
				sum += a.Data[i*a.N+k] * b.Data[k*a.N+j]
			}
			reference.Data[i*a.N+j] = sum
		}
	}
	if err := reference.Validate(); err != nil {
		return Matrix{}, fmt.Errorf("resultado de referencia: %w", err)
	}
	return reference, nil
}

func validateProduct(got, want Matrix) error {
	if err := got.Validate(); err != nil {
		return fmt.Errorf("resultado: %w", err)
	}
	if err := want.Validate(); err != nil {
		return fmt.Errorf("referencia: %w", err)
	}
	if got.N != want.N {
		return ErrDimensionMismatch
	}
	for index, expected := range want.Data {
		if math.Abs(got.Data[index]-expected) > 1e-9+1e-9*math.Abs(expected) {
			return fmt.Errorf("resultado incorrecto en C[%d,%d]: obtenido %.17g, esperado %.17g", index/got.N, index%got.N, got.Data[index], expected)
		}
	}
	return nil
}

var csvHeader = []string{
	"timestamp", "version", "commit", "hostname", "cpu_model", "ram_gb",
	"os_version", "configuration", "n", "seed", "processes", "threads",
	"observed_threads", "workers", "gomaxprocs", "repetition", "is_warmup",
	"kernel_s", "total_s", "validation_status",
}

func writeCSV(out io.Writer, cfg config, n int, info environmentInfo, result measurement, workers int, gomaxprocsUsed int, kernelS float64, repetition int, isWarmup bool, firstRow bool) error {
	if math.IsNaN(kernelS) || math.IsInf(kernelS, 0) || kernelS < 0 ||
		math.IsNaN(result.totalS) || math.IsInf(result.totalS, 0) || result.totalS < kernelS {
		return fmt.Errorf("tiempos de medici\u00f3n inv\u00e1lidos")
	}
	record := []string{
		result.start.UTC().Format(time.RFC3339), "go_paralelo", info.commit,
		info.hostname, info.cpuModel, strconv.FormatFloat(float64(info.totalMemory)/(1<<30), 'f', 3, 64),
		info.osVersion, fmt.Sprintf("go_paralelo_W%d", workers), strconv.Itoa(n), strconv.FormatUint(uint64(cfg.seed), 10),
		"1", "1", "1", strconv.Itoa(workers), strconv.Itoa(gomaxprocsUsed),
		strconv.Itoa(repetition), strconv.FormatBool(isWarmup),
		strconv.FormatFloat(kernelS, 'f', 9, 64), strconv.FormatFloat(result.totalS, 'f', 9, 64), "OK",
	}
	w := csv.NewWriter(out)
	if firstRow {
		if err := w.Write(csvHeader); err != nil {
			return err
		}
	}
	if err := w.Write(record); err != nil {
		return err
	}
	w.Flush()
	return w.Error()
}

func checkCapacity(n int, available uint64) error {
	count, err := matrixElementCount(n)
	if err != nil {
		return err
	}
	if uint64(count) > available/(4*8) {
		return fmt.Errorf("memoria disponible insuficiente para N=%d", n)
	}
	return nil
}

func loadMatrices(cfg config, available uint64) (Matrix, Matrix, error) {
	if cfg.inputFile == "" {
		if err := checkCapacity(cfg.n, available); err != nil {
			return Matrix{}, Matrix{}, err
		}
		return Generate(cfg.n, cfg.seed)
	}
	f, err := os.Open(cfg.inputFile)
	if err != nil {
		return Matrix{}, Matrix{}, err
	}
	a, b, readErr := ReadMatrices(f)
	closeErr := f.Close()
	if readErr != nil {
		return Matrix{}, Matrix{}, readErr
	}
	if closeErr != nil {
		return Matrix{}, Matrix{}, closeErr
	}
	if err := checkCapacity(a.N, available); err != nil {
		return Matrix{}, Matrix{}, err
	}
	return a, b, nil
}

func saveMatrix(path string, c Matrix) error {
	f, err := os.CreateTemp(filepath.Dir(path), ".matrix-*.tmp")
	if err != nil {
		return err
	}
	temporary := f.Name()
	defer os.Remove(temporary)
	writeErr := WriteMatrix(f, c)
	closeErr := f.Close()
	if writeErr != nil {
		return writeErr
	}
	if closeErr != nil {
		return closeErr
	}
	return os.Rename(temporary, path)
}

func execute(cfg config, stdout io.Writer, info environmentInfo) error {
	a, b, err := loadMatrices(cfg, info.availableMemory)
	if err != nil {
		return fmt.Errorf("entradas: %w", err)
	}
	if err := a.Validate(); err != nil {
		return fmt.Errorf("matriz A: %w", err)
	}
	if err := b.Validate(); err != nil {
		return fmt.Errorf("matriz B: %w", err)
	}
	if a.N != b.N {
		return ErrDimensionMismatch
	}
	reference, err := computeReferenceProduct(a, b)
	if err != nil {
		return err
	}

	kernelDurations := make([]time.Duration, cfg.workers)
	firstRow := true

	for rep := 0; rep <= cfg.repetition; rep++ {
		isWarmup := (rep == 0)
		repetitionLabel := rep

		c := Matrix{N: a.N, Data: make([]float64, len(a.Data))}

		totalStart := time.Now()
		clear(c.Data)

		previous := runtime.GOMAXPROCS(cfg.workers)

		multiplyParallelKernel(a, b, c, cfg.workers, kernelDurations)

		totalS := time.Since(totalStart).Seconds()

		runtime.GOMAXPROCS(previous)

		var maxKernel time.Duration
		for _, d := range kernelDurations {
			if d > maxKernel {
				maxKernel = d
			}
		}
		kernelS := maxKernel.Seconds()

		if err := validateProduct(c, reference); err != nil {
			return err
		}
		if cfg.outputFile != "" {
			if err := saveMatrix(cfg.outputFile, c); err != nil {
				return fmt.Errorf("archivo de salida: %w", err)
			}
		}
		if err := writeCSV(stdout, cfg, a.N, info, measurement{start: totalStart, totalS: totalS}, cfg.workers, cfg.workers, kernelS, repetitionLabel, isWarmup, firstRow); err != nil {
			return err
		}
		firstRow = false
		for i := range kernelDurations {
			kernelDurations[i] = 0
		}
	}
	return nil
}

func runWithMetadata(args []string, stdout, stderr io.Writer, collect func() (environmentInfo, error)) int {
	cfg, err := parseArgs(args)
	if err == nil && cfg.smokeTest {
		if _, err = fmt.Fprintln(stdout, "OK: prueba de instalaci\u00f3n Go paralelo."); err == nil {
			return 0
		}
	}
	if err == nil {
		var info environmentInfo
		info, err = collect()
		if err == nil {
			err = execute(cfg, stdout, info)
		}
	}
	if err != nil {
		fmt.Fprintln(stderr, err)
		if errors.Is(err, ErrPending) {
			return 2
		}
		return 1
	}
	return 0
}

func main() {
	os.Exit(runWithMetadata(os.Args[1:], os.Stdout, os.Stderr, collectEnvironment))
		fmt.Println("OK: prueba de instalacion Go. Integracion de argumentos y nucleo paralelo pendiente.")
		return
	}
	fmt.Fprintln(os.Stderr, "PENDIENTE: integracion CLI de multiplicacion y argumentos. Use --smoke-test para probar la instalacion.")
	os.Exit(2)
}
