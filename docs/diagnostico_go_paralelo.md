# Diagnóstico funcional: Go paralelo

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)
**Sprint:** 1 · **Integrante:** 4 · **Versión analizada:** `go_paralelo`
**Estado:** Diagnóstico completado a partir de lectura de código, verificación de pruebas base y alineación con la guía del proyecto.
**Método:** Lectura analítica del código en `go_paralelo/`, verificación de ejecución de comandos e inventario inicial.

---

## 1. Resumen

La versión `go_paralelo` cuenta con una estructura inicial en `go_paralelo/` para el manejo de argumentos CLI (`--n`, `--seed`, `--workers`) e I/O básica. Sin embargo, todo el módulo de concurrencia y cálculo matemático en `workers.go` se encuentra en estado pendiente. El mayor riesgo para los siguientes sprints radica en garantizar que la distribución por bloques de filas mediante canales y sincronización con `sync.WaitGroup` no genere carreras de datos (*data races*) ni cuellos de botella por sobrecoste de goroutines.

## 2. Flujo actual de ejecución

1. `main()` parsea los argumentos de línea de comandos (`--n`, `--seed`, `--workers`, `--input`, `--output`).
2. Valida la coherencia de dimensiones ($N \ge 1$), semilla y cantidad de trabajadores (`workers` $\ge 1$).
3. Reserva e inicializa las matrices cuadradas $A$ y $B$ de dimensión $N \times N$ (almacenamiento contiguo por filas con `float64`).
4. Invoca la generación determinista o la lectura de matriz según las banderas de entrada.
5. Inicia el cronómetro de tiempo monotónico (`time.Now()`).
6. Llama a `MultiplyParallel(A, B, N, workers)`, la cual actualmente no realiza el producto matricial real (pendiente).
7. Registra el tiempo transcurrido (`total_s` y `kernel_s`).
8. Valida la salida mediante *checksum* o comparación con *fixtures* (si se especificó salida).
9. Imprime métricas en `stdout` en formato CSV y finaliza con código de salida `0` (o `1` en caso de error).

## 3. Inventario por módulo

| Archivo | Función o elemento | Estado | Observaciones |
| --- | --- | --- | --- |
| `go_paralelo/main.go` | `main` | Parcial | Mantiene el flujo principal pero depende del módulo de cálculo pendiente. |
| `go_paralelo/matrix.go` | `Matrix`, `NewMatrix` | Pendiente | Representación contigua por filas pendiente de validación completa. |
| `go_paralelo/workers.go` | `MultiplyParallel` | Pendiente | Función base declarada; falta el canal de tareas y la lógica de workers. |
| `go_paralelo/workers.go` | `workerTask` / Distribución | Pendiente | Asignación de bloques de filas a workers por implementar en S2/S4. |
| `go_paralelo/input.go` | `GenerateInput`, `ReadInput` | Pendiente | Generación determinista y lectura I/O pendiente de pruebas cruzadas. |
| `go_paralelo/workers_test.go` | `TestMultiplyParallel` | Pendiente | Pruebas unitarias pendientes de completar para el producto real. |
| `go_paralelo/status.json` | Estado del módulo | Pendiente | Metadatos y control de estado de la versión. |

## 4. Funciones pendientes priorizadas

| Prioridad | Pendiente | Por qué bloquea o importa | Sprint sugerido |
| --- | --- | --- | --- |
| **P0** | Diseñar e implementar canal de tareas y `sync.WaitGroup` en `workers.go` | Bloquea la concurrencia real y la distribución del trabajo entre goroutines. | Sprint 2 / Sprint 4 |
| **P0** | Implementar la multiplicación por bloques de filas asignados a cada worker | Bloquea la validez matemática del programa ($C = A \times B$). | Sprint 4 |
| **P1** | Garantizar la propiedad exclusiva de filas en la matriz de salida $C$ | Evita condiciones de carrera (*data races*) sin recurrir a bloqueos por mutex. | Sprint 2 / Sprint 4 |
| **P2** | Ajustar la granularidad de bloques de filas según la cantidad de `--workers` | Previene la sobrecarga del runtime cuando `workers` es mayor a las CPUs físicas. | Sprint 6 |

## 5. Supuestos del contrato

| Supuesto | Documento de origen | Cumplido hoy |
| --- | --- | --- |
| Argumentos obligatorios `--n`, `--seed` y `--workers` | `docs/contrato.md` | Sí |
| Almacenamiento contiguo por filas utilizando `float64` | `docs/formato_datos.md` | Sí |
| Salida de errores por `stderr` y resultados por `stdout` | `docs/contrato.md` | Sí |
| Asignación de tareas por canal sin crear una goroutine por celda | `docs/guia-extraida.txt` | No |
| Propiedad exclusiva de fila: un único worker es dueño de cada fila de $C$ | `docs/guia-extraida.txt` | No |

## 6. Puntos de validación y riesgos

| # | Punto de validación | Riesgo o decisión pendiente | Cómo se comprobará |
| --- | --- | --- | --- |
| **V1** | Propiedad exclusiva de filas en $C$ | Riesgo de *data races* si dos goroutines escriben la misma fila. | Ejecución con el detector de carreras de Go (`go test -race`). |
| **V2** | Cierre del canal y sincronización | Riesgo de *deadlock* si el canal no se cierra o los workers no terminan. | Pruebas de estrés variando `--workers` (1, 2, 4, 8). |
| **V3** | Casos límite ($N < \text{workers}$) | Asignación de más workers que filas disponibles en la matriz. | Fixtures con $N=1, 2$ y `workers=4, 8`. |
| **V4** | Equivalencia numérica | Inconsistencia de resultados frente a la referencia secuencial. | Comparación contra `tests/fixtures/` usando `compare_results.ps1`. |

## 7. Comandos de verificación y evidencia

| Comando | Resultado esperado | Resultado observado | Fecha |
| --- | --- | --- | --- |
| `go test ./go_paralelo/...` | Ejecución de suite de pruebas del paquete. | Pruebas ejecutadas; pendientes de lógica matemática real. | 2026-09-30 |
| `go build -o go_paralelo.exe ./go_paralelo` | Compilación exitosa del binario en Windows 11. | Generación correcta de `go_paralelo.exe`. | 2026-09-30 |
| `go test -race ./go_paralelo/...` | Detección de carreras de datos (*data race detector*). | Sin alertas en la estructura base actual. | 2026-09-30 |

## 8. Trazabilidad con los sprints

| Pendiente | Sprint | Responsable |
| --- | --- | --- |
| Diseño de arquitectura de workers, canal de tareas e invariantes | Sprint 2 | Integrante 4 |
| Implementación de `workers.go` y sincronización con `WaitGroup` | Sprint 4 | Integrante 4 / Integrante 3 |
| Revisión de límites de workers y estabilidad de memoria | Sprint 5 | Integrante 4 |
| Sintonización de granularidad y campaña de medición | Sprint 6 / Sprint 7 | Integrante 4 |

---

## Registro de revisión

- **Autor:** Integrante 4.
- **Revisión cruzada:** Pendiente (Integrante 5).
- **Observaciones de la revisión:** Pendiente.