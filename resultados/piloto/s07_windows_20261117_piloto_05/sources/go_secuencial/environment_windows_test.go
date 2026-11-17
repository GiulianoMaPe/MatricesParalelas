package main

import "testing"

func TestSystemEnvironment(t *testing.T) {
	info, err := systemEnvironment()
	if err != nil {
		t.Fatal(err)
	}
	if info.cpuModel == "" || info.osVersion == "" || info.totalMemory == 0 || info.availableMemory > info.totalMemory {
		t.Fatalf("invalid system metadata: %+v", info)
	}
}
