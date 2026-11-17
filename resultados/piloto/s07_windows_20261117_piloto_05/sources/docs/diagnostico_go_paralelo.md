# Diagnóstico funcional: Go paralelo

**Proyecto:** Multiplicación de matrices densas en C y Go (Windows 11)
**Sprint:** 1 · **Integrante:** 4 Moreno Eva · **Versión analizada:** `go_paralelo`
**Estado:** Diagnóstico conforme al código actual. El generador y el lector funcionan; la multiplicación y la integración del ejecutable paralelo quedan para los sprints posteriores.
**Método:** Lectura de los módulos, sus pruebas, `status.json` y la [Guía de Sprints](Guia_Sprints.md). Verificación ejecutada el **01/10/2026** con **Go 1.27.0, Windows amd64**, mediante el script oficial desde la raíz.

## 1. Resumen

Go paralelo ya genera matrices con una semilla y lee los archivos de entrada del formato común. Ambas funciones tienen pruebas que pasaron.

El ejecutable todavía ofrece solo `--smoke-test`: comprueba que dos goroutines se comunican por un canal y terminan mediante `sync.WaitGroup`. La multiplicación devuelve `ErrPending`; los argumentos de cálculo y la salida CSV aún no están integrados.

El [diseño de workers](arquitectura.md) está definido para el Sprint 2. Su implementación corresponde al Sprint 4. La prueba de instalación comprueba comunicación y terminación, pero todavía no comprueba productos de matrices.

## 2. Flujo actual de ejecución

1. `main()` recibe los argumentos.
2. Si se solicita únicamente `--smoke-test`, llama a `smokeTest()`.
3. Esa función crea un canal y lanza dos goroutines que envían sus identificadores.
4. Una goroutine de cierre espera a que ambas terminen y después cierra el canal. Mientras tanto, el receptor consume los identificadores y comprueba que no falte ninguno.
5. Si todo sale bien, imprime el mensaje de instalación y termina con código 0. Si la prueba falla, informa por `stderr` y termina con código 1.
6. Cualquier otro uso informa que el cálculo y los argumentos están pendientes y termina con código 2.

`Generate` y `ReadMatrices` se utilizan desde las pruebas. Todavía no forman parte de ese flujo del ejecutable.

## 3. Inventario por módulo

| Archivo | Función o elemento | Estado actual |
| --- | --- | --- |
| `go_paralelo/main.go` | `main` | Prueba de instalación disponible; argumentos de cálculo, tiempos y CSV pendientes de integrar. |
| `go_paralelo/workers.go` | `smokeTest` | Dos goroutines, canal y espera implementados. El pool de trabajadores para multiplicar sigue pendiente. |
| `go_paralelo/matrix.go` | `Matrix`, `Multiply`, `ErrPending` | Matriz con dimensión y datos por filas. `Multiply` devuelve una matriz vacía y `ErrPending`. |
| `go_paralelo/input.go` | `Generate` | Implementado: genera A y B con el generador entero común y valida la dimensión y los límites de tamaño. |
| `go_paralelo/input.go` | `ReadMatrices` | Implementado: lee N, las filas de A y las de B; valida formato y valores finitos. |
| `go_paralelo/workers_test.go` | `TestGoroutinesSynchronize` | Comprueba diez ejecuciones de la prueba de instalación. |
| `go_paralelo/matrix_test.go` | `TestMultiplyReportsPending` | Comprueba que una función pendiente no entregue un producto falso. |
| `go_paralelo/input_test.go` | Pruebas de generación y lectura | Comprueban semilla, tamaños, fixtures, formato y errores de lectura. |
| `go_paralelo/status.json` | Estado del algoritmo y su validación | Ambos siguen en `pending`, porque aún no se multiplica. |

## 4. Trabajo disponible y pendientes priorizados

| Prioridad | Trabajo | Estado y etapa |
| --- | --- | --- |
| Base disponible | Generar matrices y leer archivos | Implementado y probado. Conservar estas pruebas al integrar el flujo en S3/S4. |
| Diseño S2 | Definir bloques de filas, canal, cierre y espera | Definido en [arquitectura.md](arquitectura.md); implementación en S4. |
| P0 | Disponer de una referencia secuencial fiable | Corresponde a Go secuencial en S3, a cargo de I3. |
| P0 | Implementar el cálculo paralelo por bloques | S4, I3 e I4. Cada fila debe tener un único escritor. |
| P0 | Integrar `--n`, `--seed` y `--workers` en Go paralelo | S4, I4. La integración del ejecutable Go secuencial corresponde a S3. |
| P1 | Integrar tiempos y salida CSV | S4, conforme al protocolo común. |
| P1 | Probar estabilidad y límites de trabajadores | S5. |
| P2 | Ajustar el tamaño de bloque con mediciones | S6. |

El generador y el lector ya implementados son avance disponible. Su integración no se registra como un faltante del Sprint 2.

## 5. Reglas del contrato y situación actual

| Regla | Documento | Situación actual |
| --- | --- | --- |
| Matrices cuadradas con datos `float64` por filas | [Formato de datos](formato_datos.md) | `Matrix`, el generador y el lector usan esa representación. |
| Misma secuencia para la misma semilla | [Formato de datos](formato_datos.md) | Generador entero común implementado; el vector de semilla 42 pasó. |
| N en línea propia, seguido de N filas de A y N de B | [Formato de datos](formato_datos.md) | Lector implementado y probado; cada fila debe contener exactamente N valores. |
| Rechazar tamaños inválidos y valores no finitos | [Contrato](contrato.md) | Generación y lectura tienen comprobaciones y pruebas. |
| `--n`, `--seed` y `--workers` en el ejecutable | [Contrato](contrato.md) | Pendiente de integración en S4. |
| Canal de tareas y propiedad exclusiva de cada fila de C | [Guía](Guia_Sprints.md) y [arquitectura](arquitectura.md) | Diseño de S2 disponible; implementación y comprobación matemática en S4. |
| Código 0 para éxito, 1 para error y 2 para pendiente | [Contrato](contrato.md) | Aplicado a la prueba de instalación y al rechazo del cálculo pendiente. Los errores internos de entrada se convertirán a salida 1 al integrarlos. |
| CSV común de 20 campos | [Protocolo](protocolo_medicion.md) | Definido; salida pendiente de integrar. |

`Generate` distingue `ErrInvalidDimension` y `ErrSizeOverflow`.
`ReadMatrices` distingue `ErrInvalidFixture` y `ErrFixtureIO`; ante un error devuelve matrices vacías.

## 6. Validaciones y riesgos para la implementación

| Punto | Qué se debe cuidar | Comprobación prevista |
| --- | --- | --- |
| Propiedad de filas | Que dos trabajadores no escriban la misma fila de C. | Pruebas con matrices reales y detector de carreras en S4/S5. |
| Cierre del canal | Enviar todas las tareas, cerrar el canal desde el productor y esperar a los trabajadores. | Variar trabajadores y comprobar que todas las ejecuciones terminan en S4. |
| Más trabajadores que filas | Que quien no reciba tareas pueda terminar correctamente. | Casos N=1 y N=2 con varios trabajadores en S4. |
| Producto correcto | Que el resultado coincida con la referencia secuencial y los fixtures. | Comparación completa con las tolerancias acordadas en S4/S5. |
| Argumentos y memoria | Rechazar valores inválidos y manejar los límites de capacidad. | Pruebas de argumentos y tamaños al integrar el ejecutable en S4/S5. |

Las pruebas actuales de sincronización no certifican todavía un algoritmo paralelo ni la ausencia de carreras en un cálculo que aún no está implementado.

## 7. Comando de verificación y evidencia

Ejecutado desde **la raíz del proyecto** el **01/10/2026**:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_paralelo
```

**Resultado: código 0.** La compilación, el formato, `go vet`, las pruebas, el smoke test y el rechazo del cálculo pendiente pasaron.

La suite actual incluye:

- Generación: `TestGenerateSeed42Vector`, `TestGenerateRejectsInvalidDimensions` y `TestGenerateAcceptsUint32SeedLimits`.
- Lectura: `TestReadSharedFixtures`, `TestReadMatricesAcceptsCRLFAndDecimalForms`, `TestReadMatricesRejectsMalformedInputs`, `TestReadMatricesReportsReaderErrors` y `TestReadMatricesLayoutContract`.
- Sincronización: `TestGoroutinesSynchronize`.
- Cálculo pendiente: `TestMultiplyReportsPending`.

El script comprobó que la solicitud de cálculo con `--n 2 --seed 42` termina con código 2. No se produjeron productos ni mediciones de rendimiento. Las pruebas con detector de carreras sobre el núcleo matemático corresponden a S4/S5.

## 8. Trazabilidad con los sprints

| Trabajo | Sprint y situación | Responsable |
| --- | --- | --- |
| Diagnóstico funcional | S1: conforme al código actual | I4 |
| Diseño de workers, bloques, canal y espera | S2: definido en [arquitectura.md](arquitectura.md) | I4, revisión de I3 |
| Referencia Go secuencial | S3: pendiente de implementar | I3 |
| Integración del ejecutable Go secuencial | S3: argumentos, lectura, escritura y tiempos | I4 |
| Generador Go y evidencia cruzada con C | S3: funciones disponibles; conservar pruebas y completar su integración | I7, coordinación con I4 |
| Cálculo paralelo por bloques | S4: pendiente de implementar | I3 / I4 |
| Argumentos, canal, espera, tiempos y salida Go paralelo | S4: pendiente de integrar | I4 |
| Estabilidad y límites | S5 | I4 |
| Ajuste de bloques con evidencia | S6 | I4 |
| Automatización de mediciones | S7 | I4 |

## Registro de revisión

- **Autor del entregable:** Moreno Eva.
- **Revisión cruzada:** Evaluación redactada en la voz de Giuliano (I3), registrada en [Sprint 1](sprints/sprint-01.md).
- **Resultado:** Conforme al alcance de S1.
- **Revisión a I4:** Revisé el diagnóstico de Eva y confirmé que ahora distingue las entradas que ya funcionan del cálculo que sigue pendiente. Los nombres de las pruebas y la distribución de tareas por sprint coinciden con el proyecto y la guía. Las pruebas de Go paralelo pasaron. Su diagnóstico queda conforme.
