//go:build !windows

package main

import "fmt"

func systemEnvironment() (environmentInfo, error) {
	return environmentInfo{}, fmt.Errorf("la captura de metadatos de este proyecto requiere Windows")
}
