package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) == 2 && os.Args[1] == "--smoke-test" {
		if err := smokeTest(); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		fmt.Println("OK: prueba de instalacion Go. Integracion de argumentos y nucleo paralelo pendiente.")
		return
	}
	fmt.Fprintln(os.Stderr, "PENDIENTE: integracion CLI de multiplicacion y argumentos. Use --smoke-test para probar la instalacion.")
	os.Exit(2)
}
