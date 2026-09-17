# Pruebas disponibles y pendientes

`scripts/test_windows.ps1` compila cada versión elegida, prueba la instalación y
comprueba que un intento de cálculo pendiente devuelve 2. Un faltante de dependencias
es un fallo/incompleto, nunca un PASS omitido silenciosamente.

- C: prueba de rechazo de multiplicación/generación pendientes, sin modificar buffers.
- C secuencial: ejecución de un binario nativo sin MPI ni OpenMP.
- C híbrido: dos procesos, exactamente dos hilos observados por proceso y
  MPI_THREAD_FUNNELED comprobado. MPI se invoca fuera de OpenMP.
- Ambos Go: go fmt, go vet, go test, ejecución de --smoke-test y rechazo de cálculo.
- Go paralelo: canal y WaitGroup, comprobación de que completan ambos trabajadores.

No son pruebas matemáticas finales. Los fixtures compartidos están preparados, pero
ningún multiplicador los consume todavía. Faltan equivalencia entre lenguajes,
tolerancias, N impar, P>N, workers>N, particiones no divisibles, entradas inválidas,
overflow y memoria insuficiente. Las pruebas de estados pendientes deben sustituirse
por pruebas matemáticas al implementar cada módulo; no ocultar fallos cambiando
solamente `status.json`.
