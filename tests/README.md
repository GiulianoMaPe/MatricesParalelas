# Pruebas disponibles y pendientes

`scripts/test_windows.ps1` ejecuta primero las pruebas de
`scripts/compare_results.ps1`, compila cada versión elegida y prueba su estado
actual. Un faltante de dependencias es un fallo/incompleto, nunca un PASS omitido
silenciosamente.

- C: generación LCG y lectura de fixtures; rechazo de multiplicación pendiente sin modificar buffers.
- C secuencial: ejecución de un binario nativo sin MPI ni OpenMP.
- C híbrido: dos procesos, exactamente dos hilos observados por proceso y
  MPI_THREAD_FUNNELED comprobado. MPI se invoca fuera de OpenMP.
- Ambos Go: go fmt, go vet, go test y ejecución de --smoke-test.
- Go secuencial: producto real de los cinco fixtures, archivo de salida y CSV.
- Comparador: cinco referencias, doble tolerancia, dimensiones, filas y rechazo de NaN.
- Go paralelo: canal y WaitGroup, comprobación de que completan ambos trabajadores.
- Los cuatro lectores: N en línea propia, N valores por fila, LF/CRLF, salto final opcional, subnormales y underflow finito. Rechazan filas fusionadas/divididas, líneas vacías internas, BOM, NUL, CR aislado, NaN, infinito y datos sobrantes/faltantes.

Go secuencial ya consume los fixtures y su producto se contrasta celda por celda.
Las otras versiones permanecen pendientes de integración. Los generadores usan los
mismos vectores de control y los lectores aplican el
[formato común](../docs/formato_datos.md). Faltan las comparaciones ejecutables de C,
P>N, workers>N, particiones y memoria insuficiente del programa completo. Las pruebas
de multiplicación pendiente deben sustituirse por pruebas matemáticas al implementar
cada módulo; no ocultar fallos cambiando solamente `status.json`.

Los códigos del ejecutable serán 0 para éxito, 1 para cualquier error y 2 solo para
una operación pendiente; los estados internos C no se propagan como códigos del proceso.
Las fronteras de los cronómetros se especifican en el [protocolo](../docs/protocolo_medicion.md),
pero todavía no hay cálculo instrumentado que produzca mediciones.
