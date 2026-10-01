# Diagnóstico funcional: Go paralelo

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)
**Sprint:** 1 · **Integrante:** 4 Moreno Eva · **Versión analizada:** `go_paralelo`
**Estado:** Diagnóstico completado a partir de lectura de código y ejecución de pruebas base. Solo existe una prueba de instalación (`--smoke-test`); la lógica de multiplicación y argumentos CLI está pendiente.
**Método:** Lectura analítica del código en `go_paralelo/`, ejecución de `go test` y `go build` desde `go_paralelo/` (directorio del módulo Go), y verificación de `status.json`. **Evidencia real ejecutada 2026-10-01 con Go 1.27.1.**

---

## 1. Resumen

La versión `go_paralelo` contiene únicamente una prueba de instalación (`--smoke-test`) que verifica que dos goroutines se comuniquen por canal y terminen sincronizadas con `sync.WaitGroup`. No hay análisis de argumentos (`--n`, `--seed`, `--workers`), no hay generación de matrices, no hay multiplicación (ni secuencial ni paralela), y no hay salida CSV. El código en `workers.go`, `matrix.go` e `input.go` son esqueletos que retornan `ErrPending`. El mayor riesgo para los siguientes sprints es implementar la arquitectura completa de workers, distribución de filas por canal, y multiplicación por bloques sin introducir *data races* ni *deadlocks*.

## 2. Flujo actual de ejecución

1. `main()` recibe argumentos de línea de comandos.
2. Si el único argumento es `--smoke-test`, ejecuta `smokeTest()` (definida en `workers.go`).
3. `smokeTest()` crea un canal `results`, lanza 2 goroutines que envían su ID al canal, espera con `WaitGroup`, cierra el canal, y verifica que recibió ambos IDs.
4. Imprime "OK: prueba de instalacion Go. Algoritmo y contrato de argumentos pendientes." y sale con código 0.
5. Cualquier otro uso imprime mensaje de error a `stderr` y sale con código 2.

## 3. Inventario por módulo

| Archivo | Función o elemento | Estado | Observaciones |
| --- | --- | --- | --- |
| `go_paralelo/main.go` | `main`, `smokeTest` | Parcial | Solo implementa `--smoke-test`; resto del flujo (args, matrices, tiempo, CSV) pendiente. |
| `go_paralelo/workers.go` | `smokeTest` | Parcial | Contiene `smokeTest` (2 goroutines + canal + WaitGroup); no hay pool de workers, no hay distribución de filas, no hay multiplicación. |
| `go_paralelo/matrix.go` | `Matrix` (struct), `Multiply`, `ErrPending` | Pendiente | Struct definido; `Multiply` retorna `ErrPending`; no hay `NewMatrix` ni `MultiplyParallel`. |
| `go_paralelo/input.go` | `Generate` | Pendiente | Retorna `ErrPending`; no hay lectura de archivo ni generación determinista. |
| `go_paralelo/workers_test.go` | `TestGoroutinesSynchronize` | Implementado | Verifica que `smokeTest` pasa 10 veces seguidas. |
| `go_paralelo/matrix_test.go` | `TestMultiplyReportsPending` | Implementado | Verifica que `Multiply` retorna `ErrPending` y no un producto falso. |
| `go_paralelo/input_test.go` | `TestGenerateReportsPending` | Implementado | Verifica que `Generate` retorna `ErrPending` y no entradas falsas. |
| `go_paralelo/status.json` | Estado del módulo | Pendiente | `{"algorithm":"pending","validation":"pending"}`. |

## 4. Funciones pendientes priorizadas

| Prioridad | Pendiente | Por qué bloquea o importa | Sprint sugerido |
| --- | --- | --- | --- |
| **P0** | Implementar parsing de `--n`, `--seed`, `--workers` en `main.go` | Bloquea cualquier ejecución real del programa. | Sprint 2 |
| **P0** | Implementar `Generate` en `input.go` (generación determinista con semilla) | Bloquea la creación de matrices de entrada. | Sprint 2 |
| **P0** | Implementar `Multiply` secuencial en `matrix.go` (referencia numérica) | Necesaria como baseline para validar la versión paralela. | Sprint 3 |
| **P0** | Diseñar arquitectura de workers: canal de tareas, `WaitGroup`, propiedad exclusiva de filas | Bloquea la concurrencia real y la validez matemática. | Sprint 2 |
| **P0** | Implementar `MultiplyParallel` en `workers.go` (distribución de bloques de filas) | Bloquea el producto matricial paralelo real ($C = A \times B$). | Sprint 4 |
| **P1** | Implementar salida CSV en `stdout` con métricas (`total_s`, `kernel_s`) | Requerido por el contrato de medición. | Sprint 4 |
| **P2** | Ajustar granularidad de bloques según `--workers` y CPUs físicas | Previene sobrecarga del runtime. | Sprint 6 |

## 5. Supuestos del contrato

| Supuesto | Documento de origen | Cumplido hoy |
| --- | --- | --- |
| Argumentos obligatorios `--n`, `--seed` y `--workers` | `docs/contrato.md` | No (solo `--smoke-test`) |
| Almacenamiento contiguo por filas utilizando `float64` | `docs/formato_datos.md` | Parcial (struct `Matrix` definido, pero no se usa) |
| Salida de errores por `stderr` y resultados por `stdout` | `docs/contrato.md` | Parcial (solo mensaje de smoke test) |
| Asignación de tareas por canal sin crear una goroutine por celda | `docs/guia-extraida.txt` | No |
| Propiedad exclusiva de fila: un único worker es dueño de cada fila de $C$ | `docs/guia-extraida.txt` | No |
| Formato CSV con columnas `N,workers,total_s,kernel_s,checksum` | `docs/protocolo_medicion.md` | No |

## 6. Puntos de validación y riesgos

| # | Punto de validación | Riesgo o decisión pendiente | Cómo se comprobará |
| --- | --- | --- | --- |
| **V1** | Propiedad exclusiva de filas en $C$ | Riesgo de *data races* si dos goroutines escriben la misma fila. | `go test -race ./go_paralelo/...` con matriz real. |
| **V2** | Cierre del canal y sincronización `WaitGroup` | Riesgo de *deadlock* si el canal no se cierra o workers no terminan. | Pruebas de estrés variando `--workers` (1, 2, 4, 8). |
| **V3** | Casos límite ($N < \text{workers}$) | Asignación de más workers que filas disponibles. | Fixtures con $N=1, 2$ y `workers=4, 8`. |
| **V4** | Equivalencia numérica vs. referencia secuencial | Inconsistencia de resultados. | Comparación contra `tests/fixtures/` usando `compare_results.ps1`. |
| **V5** | Parsing y validación de argumentos CLI | Entrada inválida no controlada. | Pruebas con argumentos faltantes, negativos, no numéricos. |

## 7. Comandos de verificación y evidencia

Ejecutados desde **`go_paralelo/`** (directorio del módulo Go):

| Comando | Resultado esperado | Resultado observado | Fecha |
| --- | --- | --- | --- |
| `go test ./...` | Ejecución de suite de pruebas del paquete. | PASS: `TestGoroutinesSynchronize` (10 iteraciones), `TestMultiplyReportsPending`, `TestGenerateReportsPending`. | 2026-10-01 |
| `go build -o go_paralelo.exe .` | Compilación exitosa del binario en Windows 11. | Generación correcta de `go_paralelo.exe`. | 2026-10-01 |
| `go test -race ./...` | Detección de carreras de datos. | PASS: sin alertas (smoke test no tiene carreras). | 2026-10-01 |
| `.\go_paralelo.exe --smoke-test` | Prueba de instalación exitosa. | `Prueba de instalacion: 2 goroutines completadas mediante canal y WaitGroup.` + `OK: prueba de instalacion Go. Algoritmo y contrato de argumentos pendientes.` | 2026-10-01 |
| `.\go_paralelo.exe --n 10 --seed 123 --workers 2` | Ejecución con argumentos reales (pendiente). | `PENDIENTE: multiplicacion y argumentos. Use --smoke-test para probar la instalacion.` (exit 2) | 2026-10-01 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo` | Suite oficial: build, fmt, vet, test, smoke-test, rechazo pending. | PASS: build OK, tests OK, smoke-test OK, rechaza pending (exit 2). | 2026-10-01 |

## 8. Trazabilidad con los sprints

| Pendiente | Sprint | Responsable |
| --- | --- | --- |
| Parsing de argumentos CLI (`--n`, `--seed`, `--workers`) | Sprint 2 | Integrante 4 |
| Generación determinista de matrices (`input.go`) | Sprint 2 | Integrante 4 |
| Multiplicación secuencial de referencia (`matrix.go`) | Sprint 3 | Integrante 4 |
| Arquitectura de workers: canal, `WaitGroup`, propiedad de filas | Sprint 2 | Integrante 4 / Integrante 3 |
| `MultiplyParallel` real con distribución de bloques | Sprint 4 | Integrante 4 / Integrante 3 |
| Salida CSV y medición de tiempos | Sprint 4 | Integrante 4 |
| Revisión de límites de workers y estabilidad de memoria | Sprint 5 | Integrante 4 |
| Sintonización de granularidad y campaña de medición | Sprint 6 / Sprint 7 | Integrante 4 |

---

## Registro de revisión

- **Autor:** Moreno Eva.
- **Revisión cruzada:** Pendiente (Integrante 3).
- **Observaciones de la revisión:** Pendiente.
