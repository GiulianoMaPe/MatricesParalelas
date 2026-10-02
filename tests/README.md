# Pruebas disponibles y pendientes

`scripts/test_windows.ps1` compila cada versión elegida, prueba la instalación y
comprueba que un intento de cálculo pendiente devuelve 2. Un faltante de dependencias
es un fallo/incompleto, nunca un PASS omitido silenciosamente.

- C: generación LCG y lectura de fixtures; rechazo de multiplicación pendiente sin modificar buffers.
- C secuencial: ejecución de un binario nativo sin MPI ni OpenMP.
- C híbrido: dos procesos, exactamente dos hilos observados por proceso y
  MPI_THREAD_FUNNELED comprobado. MPI se invoca fuera de OpenMP.
- Ambos Go: go fmt, go vet, go test, ejecución de --smoke-test y rechazo de cálculo.
- Go paralelo: canal y WaitGroup, comprobación de que completan ambos trabajadores.
- Los cuatro lectores: N en línea propia, N valores por fila, LF/CRLF, salto final opcional, subnormales y underflow finito. Rechazan filas fusionadas/divididas, líneas vacías internas, BOM, NUL, CR aislado, NaN, infinito y datos sobrantes/faltantes.

No son pruebas matemáticas finales. Los fixtures compartidos están preparados, pero
ningún multiplicador los consume todavía. Los generadores usan los mismos vectores
de control y los lectores aplican el [formato común](../docs/formato_datos.md).
Faltan pruebas de productos con tolerancias, P>N, workers>N, particiones ejecutables
y memoria insuficiente del programa completo. Las pruebas de multiplicación pendiente deben sustituirse
por pruebas matemáticas al implementar cada módulo; no ocultar fallos cambiando
solamente `status.json`.

Los códigos del ejecutable serán 0 para éxito, 1 para cualquier error y 2 solo para
una operación pendiente; los estados internos C no se propagan como códigos del proceso.
Las fronteras de los cronómetros se especifican en el [protocolo](../docs/protocolo_medicion.md),
pero todavía no hay cálculo instrumentado que produzca mediciones.
