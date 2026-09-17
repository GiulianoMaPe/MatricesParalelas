package main

import "testing"

func TestGoroutinesSynchronize(t *testing.T) {
	for i := 0; i < 10; i++ {
		if err := smokeTest(); err != nil {
			t.Fatal(err)
		}
	}
}
