package main

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"path/filepath"
	"runtime"
	"strconv"
	"testing"
)

func cliTestEnvironment() (environmentInfo, error) {
	return environmentInfo{
		commit: "0123456789abcdef0123456789abcdef01234567", hostname: "test-host",
		cpuModel: "test-cpu", osVersion: "test-os",
		totalMemory: 4 << 30, availableMemory: 2 << 30,
	}, nil
}

func TestRunSingleRepetitionAndEffectiveConcurrency(t *testing.T) {
	previous := runtime.GOMAXPROCS(3)
	defer runtime.GOMAXPROCS(previous)
	for repetition := 0; repetition <= 5; repetition++ {
		for _, workers := range []int{1, 2, 4, 8} {
			t.Run(fmt.Sprintf("rep%d/W%d", repetition, workers), func(t *testing.T) {
				var stdout, stderr bytes.Buffer
				args := []string{"--n", "2", "--seed", "42", "--workers", strconv.Itoa(workers), "--repetition", strconv.Itoa(repetition)}
				if code := runWithMetadata(args, &stdout, &stderr, cliTestEnvironment); code != 0 {
					t.Fatalf("exit=%d stderr=%s", code, stderr.String())
				}
				if stderr.Len() != 0 {
					t.Fatalf("unexpected stderr: %s", stderr.String())
				}
				records, err := csv.NewReader(&stdout).ReadAll()
				if err != nil || len(records) != 2 {
					t.Fatalf("want one header and one measurement, got %d records, error=%v", len(records), err)
				}
				if len(records[0]) != 20 || len(records[1]) != 20 {
					t.Fatal("CSV must contain 20 fields")
				}
				fields := make(map[string]string, 20)
				for i, name := range records[0] {
					fields[name] = records[1][i]
				}
				if fields["repetition"] != strconv.Itoa(repetition) || fields["is_warmup"] != strconv.FormatBool(repetition == 0) ||
					fields["workers"] != strconv.Itoa(workers) || fields["gomaxprocs"] != strconv.Itoa(workers) || fields["validation_status"] != "OK" {
					t.Fatalf("incorrect CSV: %v", fields)
				}
				if got := runtime.GOMAXPROCS(0); got != 3 {
					t.Fatalf("GOMAXPROCS not restored: got %d, want 3", got)
				}
			})
		}
	}
}

func TestRunRestoresConcurrencyOnOutputError(t *testing.T) {
	previous := runtime.GOMAXPROCS(3)
	defer runtime.GOMAXPROCS(previous)
	var stdout, stderr bytes.Buffer
	output := filepath.Join(t.TempDir(), "missing-directory", "product.txt")
	args := []string{"--n", "2", "--seed", "42", "--workers", "2", "--output", output}
	if code := runWithMetadata(args, &stdout, &stderr, cliTestEnvironment); code != 1 || stdout.Len() != 0 || stderr.Len() == 0 {
		t.Fatalf("output error: exit=%d stdout=%s stderr=%s", code, stdout.String(), stderr.String())
	}
	if got := runtime.GOMAXPROCS(0); got != 3 {
		t.Fatalf("GOMAXPROCS not restored after failure: got %d, want 3", got)
	}
}
