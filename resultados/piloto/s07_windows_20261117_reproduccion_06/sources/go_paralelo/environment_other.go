//go:build !windows

package main

import "fmt"

// Allow portable arithmetic tests to compile, as in go_secuencial. This is
// deliberately not a Linux metadata implementation or a campaign port.
func systemEnvironment() (environmentInfo, error) {
	return environmentInfo{}, fmt.Errorf("la captura de metadatos de este proyecto requiere Windows")
}
