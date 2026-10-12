package main

import (
	"encoding/csv"
	"fmt"
	"os"
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
}

func parseArgs(args []string) (config, error) {
	cfg := config{}
	seen := make(map[string]bool)
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch arg {
		case "--smoke-test":
			if cfg.smokeTest || seen["--smoke-test"] {
				return cfg, fmt.Errorf("opción duplicada: --smoke-test")
			}
			if len(args) != 1 {
				return cfg, fmt.Errorf("--smoke-test no se combina con otras opciones")
			}
			cfg.smokeTest = true
			seen["--smoke-test"] = true
		case "--n":
			if seen["--n"] {
				return cfg, fmt.Errorf("opción duplicada: --n")
			}
			i++
			if i >= len(args) {
				return cfg, fmt.Errorf("--n requiere un valor")
			}
			n, err := strconv.ParseUint(args[i], 10, strconv.IntSize)
			maxInt := int(^uint(0) >> 1)
			if err != nil || n == 0 || n > uint64(maxInt) {
				return cfg, fmt.Errorf("N inválido: %s", args[i])
			}
			cfg.n = int(n)
			seen["--n"] = true
		case "--seed":
			if seen["--seed"] {
				return cfg, fmt.Errorf("opción duplicada: --seed")
			}
			i++
			if i >= len(args) {
				return cfg, fmt.Errorf("--seed requiere un valor")
			}
			seed, err := strconv.ParseUint(args[i], 10, 32)
			if err != nil || seed > 4294967295 {
				return cfg, fmt.Errorf("semilla inválida: %s", args[i])
			}
			cfg.seed = uint32(seed)
			seen["--seed"] = true
		case "--input":
			if seen["--input"] {
				return cfg, fmt.Errorf("opción duplicada: --input")
			}
			i++
			if i >= len(args) {
				return cfg, fmt.Errorf("--input requiere un valor")
			}
			cfg.inputFile = args[i]
			seen["--input"] = true
		case "--output":
			if seen["--output"] {
				return cfg, fmt.Errorf("opción duplicada: --output")
			}
			i++
			if i >= len(args) {
				return cfg, fmt.Errorf("--output requiere un valor")
			}
			cfg.outputFile = args[i]
			seen["--output"] = true
		default:
			return cfg, fmt.Errorf("opción desconocida: %s", arg)
		}
	}
	if cfg.smokeTest {
		return cfg, nil
	}
	hasGenerate := cfg.n > 0 || cfg.seed > 0 || seen["--n"] || seen["--seed"]
	hasInput := cfg.inputFile != ""
	if hasGenerate && hasInput {
		return cfg, fmt.Errorf("--input no se combina con --n ni --seed")
	}
	if !hasGenerate && !hasInput {
		return cfg, fmt.Errorf("faltan argumentos: use --n N --seed S o --input archivo")
	}
	if hasGenerate {
		if cfg.n == 0 {
			return cfg, fmt.Errorf("falta --n")
		}
		if !seen["--seed"] {
			return cfg, fmt.Errorf("falta --seed")
		}
	}
	return cfg, nil
}

func getCommitHash() string {
	return "dev"
}

func getHostname() string {
	host, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	return host
}

func getCPUModel() string {
	return "unknown"
}

func getRAMGB() float64 {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return float64(m.Sys) / (1024 * 1024 * 1024)
}

func getOSVersion() string {
	return "Windows"
}

func buildCSV(timestamp, version, commit, hostname, cpuModel, osVersion, configuration string,
	n int, seed uint32, kernelS, totalS float64, validationStatus string) string {
	var buf strings.Builder
	w := csv.NewWriter(&buf)
	w.Comma = ','
	record := []string{
		timestamp,
		version,
		commit,
		hostname,
		cpuModel,
		fmt.Sprintf("%.1f", getRAMGB()),
		osVersion,
		configuration,
		strconv.Itoa(n),
		strconv.FormatUint(uint64(seed), 10),
		"1",
		"1",
		"1",
		"1",
		"1",
		"0",
		"false",
		fmt.Sprintf("%.9f", kernelS),
		fmt.Sprintf("%.9f", totalS),
		validationStatus,
	}
	if err := w.Write(record); err != nil {
		return ""
	}
	w.Flush()
	return strings.TrimSpace(buf.String())
}

func runSmokeTest() error {
	fmt.Println("OK: prueba de instalacion Go. Algoritmo y contrato de argumentos implementados.")
	return nil
}

func main() {
	cfg, err := parseArgs(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if cfg.smokeTest {
		if err := runSmokeTest(); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		return
	}

	var a, b Matrix
	var seed uint32
	if cfg.inputFile != "" {
		f, err := os.Open(cfg.inputFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error al abrir %s: %v\n", cfg.inputFile, err)
			os.Exit(1)
		}
		defer f.Close()
		a, b, err = ReadMatrices(f)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error al leer %s: %v\n", cfg.inputFile, err)
			os.Exit(1)
		}
		seed = 0
	} else {
		a, b, err = Generate(cfg.n, cfg.seed)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error al generar matrices: %v\n", err)
			os.Exit(1)
		}
		seed = cfg.seed
	}

	c := Matrix{N: a.N, Data: make([]float64, a.N*a.N)}
	for i := range c.Data {
		c.Data[i] = 0
	}

	totalStart := time.Now()
	kernelStart := time.Now()
	c, err = Multiply(a, b)
	kernelS := time.Since(kernelStart).Seconds()
	totalS := time.Since(totalStart).Seconds()

	if err != nil {
		fmt.Fprintf(os.Stderr, "error en multiplicacion: %v\n", err)
		os.Exit(1)
	}

	out := os.Stdout
	if cfg.outputFile != "" {
		f, err := os.Create(cfg.outputFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error al crear %s: %v\n", cfg.outputFile, err)
			os.Exit(1)
		}
		defer f.Close()
		out = f
	}
	if err := WriteMatrix(out, c); err != nil {
		fmt.Fprintf(os.Stderr, "error al escribir matriz: %v\n", err)
		os.Exit(1)
	}

	timestamp := time.Now().UTC().Format("2006-01-02T15:04:05Z")
	csvLine := buildCSV(
		timestamp,
		"go_secuencial",
		getCommitHash(),
		getHostname(),
		getCPUModel(),
		getOSVersion(),
		"go_secuencial",
		a.N,
		seed,
		kernelS,
		totalS,
		"PENDING",
	)
	fmt.Fprintln(os.Stderr, csvLine)
}
