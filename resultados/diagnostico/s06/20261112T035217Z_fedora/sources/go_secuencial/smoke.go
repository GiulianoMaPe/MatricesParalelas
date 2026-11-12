package main

import "fmt"

// smokeTest only confirms that a native Go executable can run.
func smokeTest() error {
	fmt.Println("Prueba de instalacion: Go secuencial ejecutado sin trabajadores de calculo.")
	return nil
}
