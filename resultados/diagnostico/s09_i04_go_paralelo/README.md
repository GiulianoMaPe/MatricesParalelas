# S9 · I4 · Diagnóstico del kernel Go paralelo · **no oficial**

Evidencia de laboratorio de la conclusión C3 de
[docs/analisis_go_paralelo.md](../../../docs/analisis_go_paralelo.md). No son
datos de campaña: se obtuvieron en el equipo de I4 (`FLDSMDFR`, AMD Ryzen 7 3700X,
Zen 2, Windows 11 build 26200, Go 1.27.1), no en la PC oficial. No sustituyen ni
se combinan con los CSV de `resultados/raw/`.

## Pregunta

En la campaña oficial, `go_paralelo` con W=1 tarda 1,41–1,49 veces más que
`go_secuencial` dentro de `kernel_s`. Los dos kernels tienen el mismo cuerpo
`i,k,j`; solo cambia la firma: `multiplyBlock(a, b, c *Matrix, ...)` frente a
`multiplyKernel(a, b, c Matrix)`.

## Método

[`go_paralelo/sprint09_kernel_test.go`](../../../go_paralelo/sprint09_kernel_test.go)
añade `multiplyBlockByValue`, una copia de laboratorio de `multiplyBlock` que
recibe las matrices por valor. El código de producción no cambia.

- `TestMultiplyBlockByValueBitwise` comprueba que ambas firmas dan C idéntica bit
  a bit (N=1, 7 y 64).
- `BenchmarkKernelPointerVsValue` mide un producto completo en una goroutine
  (`-cpu 1`, como W=1) para N=512 y 1024; 5 repeticiones de 3 productos.
- El ensamblador se obtiene con `go test -c -gcflags=-S`, y las comprobaciones de
  límites con `go build -gcflags=-d=ssa/check_bce/debug=1`.

## Resultados

| Archivo | Contenido |
| --- | --- |
| [`ensamblador_bucle_interno.txt`](ensamblador_bucle_interno.txt) | Instrucciones de la línea del bucle interno de ambas firmas |
| [`benchmark_puntero_valor.txt`](benchmark_puntero_valor.txt) | Salida completa del benchmark |

- **Ensamblador.** La versión por puntero hace cuatro cargas por iteración que la
  versión por valor no hace: `MOVQ 8(BX)`, `MOVQ 16(BX)`, `MOVQ 8(CX)` y
  `MOVQ 16(CX)`. En `Matrix{N int; Data []float64}`, los desplazamientos 8 y 16
  son el puntero y la longitud de `Data`; el compilador recarga las cabeceras de
  `b.Data` y `c.Data` porque no puede probar que la escritura en `c.Data[...]` no
  las modifica.
- **Comprobaciones de límites.** Las dos firmas tienen las mismas tres
  comprobaciones en el bucle (`go_secuencial/matrix.go:101,104` y
  `go_paralelo/workers.go:115,118`). La diferencia no está en ellas.
- **Tiempo** (mediana de 5 repeticiones):

| N | Por puntero (producción) | Por valor (copia) | Cociente | Oficial W=1 / secuencial |
| ---: | ---: | ---: | ---: | ---: |
| 512 | 143,5 ms · 1,87 GFLOPS | 88,1 ms · 3,05 GFLOPS | 1,63 | 1,48 |
| 1024 | 1085,6 ms · 1,98 GFLOPS | 718,7 ms · 2,99 GFLOPS | 1,51 | 1,49 |

Con N=512, una de las cinco repeticiones por puntero fue anómala (186,8 ms) y la
mediana la absorbe. Con N=1024 las dispersiones son bajas. Los GFLOPS de cada
firma coinciden con los oficiales de `go_paralelo` W=1 (~2,0) y `go_secuencial`
(~3,0).

## Reproducción

Desde `go_paralelo/`:

```powershell
go test -run 'TestMultiplyBlockByValueBitwise' ./...
go test -run '^$' -bench KernelPointerVsValue -benchtime 3x -count 5 -cpu 1 ./...
go build -o NUL -gcflags='-d=ssa/check_bce/debug=1' .
```
