# Sprint 5 Integrar y fortalecer la corrección

Estado: entrega técnica de I3 implementada y validada el 29/10/2026; revisión personal de I2 y entregas/cierre del equipo pendientes. Las asignaciones siguientes son el plan de desarrollo de la [guía vigente](../guia-extraida.txt); la evidencia ejecutada se distingue en el registro de I3.

Semana 5 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Eliminar diferencias de formato, manejo de errores y validación entre las cuatro carpetas.

Cierre: La batería común pasa en las cuatro versiones, los fallos esperados terminan sin bloqueos y existe un reporte reproducible.

## Trabajo de cada integrante

Integrante 1  Revisar desbordamientos y errores de asignación en C secuencial (3 h). Corregir límites de dimensión y asegurar limpieza en cada error (3 h). Entregable: C secuencial robusto y casos negativos. Ubicación: c_secuencial/src/ y tests/.

Integrante 2  Revisar errores colectivos y finalización del híbrido (3 h). Probar procesos sin filas y fallos controlados sin esperas indefinidas (3 h). Entregable: C paralelo robusto y registro de fallos. Ubicación: c_paralelo/src/ y tests/.

Integrante 3  Revisar formatos, índices y errores en Go secuencial (3 h). Corregir compatibilidad de entrada y salida frente a C (3 h). Entregable: Go secuencial consistente. Ubicación: go_secuencial/input.go.

Integrante 4  Revisar límites de workers y propiedad de buffers Go (3 h). Probar repeticiones largas y corregir bloqueos o resultados variables (3 h). Entregable: Go paralelo estable. Ubicación: go_paralelo/workers.go.

Integrante 5  Completar casos negativos del comparador y tolerancias (3 h). Calcular error máximo por versión y documentar el criterio numérico (3 h). Entregable: Informe de validación numérica. Ubicación: docs/validacion_numerica.md.

Integrante 6  Ampliar test_windows.ps1 con las pruebas matemáticas completas (3 h). Detectar fallos mediante códigos de salida y reportar el caso exacto (3 h). Entregable: Batería integral automatizada. Ubicación: scripts/test_windows.ps1.

Integrante 7  Verificar que las cuatro mediciones usan límites equivalentes (3 h). Separar validación y escritura de los intervalos medidos (3 h). Entregable: Auditoría del protocolo de tiempo. Ubicación: docs/protocolo_medicion.md.

Integrante 8  Reproducir los casos de validación en una segunda PC preparada (3 h). Analizar diferencias funcionales y resolver errores del programa (3 h). Entregable: Acta de validación independiente. Ubicación: docs/validacion_independiente.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-05.md.

## Registro de cierre

- Participantes y horas reales: entrega técnica de I3 registrada abajo; horas reales y resto del equipo pendientes.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: I3 validado en Debug/Release (296 ejecuciones C/Go); batería integral del equipo pendiente.
- Bloqueos y decisiones: sin bloqueo técnico de I3; revisión personal, coordinación y aceptación del equipo pendientes.
- Revision y criterio de aceptacion: pendiente.

## Registro individual · I5 Fernando

- **Entregable:** [Informe de validación numérica](../validacion_numerica.md).
- **Pruebas:** `tests/compare_results_test.ps1`, Go secuencial Debug y Go paralelo Debug reproducidos; cinco fixtures por versión, todos con código 0 y `max_abs=max_rel=0`.
- **Criterio:** `atol=rtol=1e-9`; añadida cobertura explícita de esperado cero, diferencia aceptada por `atol` y `max_rel=Infinity`.
- **Evidencia C:** se recopilaron en el informe resultados previos del reporte de equivalencia y del reporte de particionado; la compilación local queda pendiente porque no se dispone de MSVC configurado. No se instaló software.
- **Revisión cruzada, coordinación, horas reales e issue/PR:** pendientes de registrar por el equipo.
- **Reproducción de C completada por I4 (Eva) · 04/11/2026:** sobre el commit `6c76be6`, con MSVC x64 14.43.34808, Windows SDK 10.0.26100.0, MS-MPI Runtime y SDK 10.1.12498.52 y Go 1.27.1. `test_windows.ps1` terminó con código 0 para `c_secuencial` y `c_paralelo` en Debug y Release, y para `-Version all` en Debug y Release (24 comparaciones por compilación). Todas dieron `max_abs=0` y `max_rel=0`. El detalle está en el [informe](../validacion_numerica.md#reproducción-de-c-y-ejecución-conjunta).
- **Revisión cruzada de I4 (Eva) a I5 · 04/11/2026:** el criterio documentado coincide con [docs/contrato.md](../contrato.md) (`1e-9 + 1e-9·|esperado|`) y con `scripts/compare_results.ps1` (`atol=rtol=1e-9`). El caso nuevo de esperado cero es correcto: `tests/compare_results_test.ps1` pasa con código 0. Para comprobar que detecta errores reales, fijé temporalmente `atol=0` en el comparador y el caso falló, como corresponde; después restauré el comparador. Completé el informe con la reproducción de C y la ejecución conjunta. Revisión conforme para el alcance de I5. Quedan pendientes el pull request, las horas reales y la aceptación del equipo.

## Registro individual · I4 Eva · 02/11/2026

- **Participantes y horas reales:** Eva (I4). El plan contempla 3 h de revisión de límites de workers y propiedad de buffers, 3 h de repeticiones largas y corrección de bloqueos o resultados variables, 1 h de revisión cruzada a I5 (Fernando) y 1 h de coordinación. Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s05-i04-go-paralelo-estable`; [PR #37](https://github.com/GiulianoMaPe/MatricesParalelas/pull/37). Su revisión corresponde a I3 (Giuliano) según la rotación.

- **Revisión inicial:** el tope de 1024 workers solo existía como constante local de `parseArgs`. `MultiplyParallel` aceptaba cualquier valor positivo: con `workers=1e9` intentaba reservar el vector de tiempos (unos 8 GB) y lanzar mil millones de goroutines, en lugar de devolver un error. Además, las precondiciones de `multiplyParallelKernel` (un slot de tiempo por worker, N*N elementos en A, B y C, y C sin memoria compartida con A/B) solo estaban documentadas: al violarlas se producía un *panic* de índice o un C corrupto, no un error. El reparto ya era determinista (un escritor por fila, orden `i,k,j`), pero las pruebas comparaban solo con tolerancia y con 5 a 10 repeticiones.

- **Cambios:** en [workers.go](../../go_paralelo/workers.go) añadí `MaxWorkers` (1024) como tope único para la API y la CLI, `validateWorkers` y `validateKernelBuffers`, que comprueba en O(1) las precondiciones del kernel e incluye el solapamiento parcial entre subslices del mismo arreglo. `multiplyParallelKernel` no cambió. En [matrix.go](../../go_paralelo/matrix.go) añadí `ErrTooManyWorkers`, `ErrInvalidDurations` y `ErrBufferAlias`; `MultiplyParallel` rechaza `workers > MaxWorkers` antes de reservar memoria. En [main.go](../../go_paralelo/main.go), `parseArgs` usa `MaxWorkers` y `execute` llama a `validateKernelBuffers` antes de fijar `GOMAXPROCS` y de iniciar `total_s`, de modo que la medición no cambia. Documenté el tope, la propiedad de cada buffer y el determinismo en el [README](../../go_paralelo/README.md).

- **Pruebas y evidencias:** añadí [workers_stability_test.go](../../go_paralelo/workers_stability_test.go) sin modificar las pruebas de I3 ni de I6. Cubre repeticiones largas con igualdad bit a bit frente a W=1 (N=1, 2, 3, 17, 64, 129; tres semillas; W=1, 2, 3, 4, 8, 16, N+1 y 1024; unos 20 600 productos por corrida), ausencia de fugas de goroutines, terminación con plazo de 30 s bajo `GOMAXPROCS`=1 y 2, límites de workers en la API y la CLI, trece casos de buffers inválidos o con memoria compartida, y salidas idénticas byte a byte entre corridas del ejecutable. Resultados con Go 1.27.1 en Windows amd64, todos con código 0: `gofmt -l` sin archivos, `go vet ./...` sin avisos, `go test -count=1 ./...` (3,7 s), `go test -race -count=3 ./...` (122 s, sin carreras, con TDM-GCC 10.3.0) y la corrida larga `go test -run 'LongRepetitions|NoGoroutineLeak|Terminates|WorkerLimits|ValidateKernelBuffers|CLIRepeated' -count=5 -timeout 20m ./...` (18 s). `scripts/test_windows.ps1 -Version go_paralelo` pasó en Debug y Release, con los cinco fixtures en `max_abs=0` y `max_rel=0`. El ejecutable Release completó 250 corridas con `impar3` y 50 con N=129, seed 42 (W=1, 2, 4, 8 y 1024): todas con `validation_status=OK` y un único SHA-256 de salida por caso; `--workers 1025` terminó con código 1 en 52 ms.

- **Comprobación de las pruebas:** en una copia aparte inyecté cinco fallos en `workers.go`: no esperar a los workers, no cerrar el canal, aceptar 1025 workers, no detectar memoria compartida y no comprobar los slots de tiempo. Las pruebas nuevas fallaron en los cinco casos; el canal sin cerrar se reportó a los 30 s como "posible bloqueo".

- **Bloqueos y decisiones:** no se encontraron bloqueos ni resultados variables en el código actual; los cambios convierten precondiciones asumidas en errores verificados. El valor de workers solicitado no se reduce cuando supera N, para que el CSV conserve el valor pedido. La comprobación de solapamiento usa `unsafe.SliceData` solo para comparar direcciones y no recorre datos.

- **Revisión y criterio de aceptación:** el entregable cumple los criterios del sprint para Go paralelo: la batería pasa, los fallos esperados terminan con error y sin esperas indefinidas, y los resultados son reproducibles bit a bit. Quedan pendientes la revisión de I3 (Giuliano), mi revisión cruzada de `docs/validacion_numerica.md` de I5 (Fernando) cuando se publique, las horas reales y la aceptación del equipo.

## Registro de I3 · Giuliano · 29/10/2026

**Entrega técnica:** Go secuencial consistente en formatos, orden de datos y
errores, con comparación ejecutable frente a C secuencial. Rama
`feature/s05-i03-go-secuencial-compatibilidad`, basada en `ebf1fca`.
La validación cubre la parte de I3; el cierre global de S5 continúa pendiente.

### Hallazgos y correcciones

| Hallazgo reproducido | Comportamiento anterior | Corrección y regresión |
| --- | --- | --- |
| Capacidad de entrada desde archivo | `loadMatrices` comprobaba RAM después de leer y reservar A/B. | Comprobar los cuatro buffers desde N, antes de construir matrices; con 127 bytes disponibles y N=2 se rechaza antes de procesar filas (se requieren 128 bytes). La CLI devuelve 1 sin salida matricial/CSV. |
| Lectura con error tras bytes parciales | Se conservaba solo `ErrFixtureIO`, perdiendo la causa del dispositivo/reader. | Preservar clasificación y causa con `errors.Is`; descartar A/B incluso si ya se recibieron todas las filas y el lector falla después. |
| Cabecera inválida seguida de fallo de lectura | `io.ReadAll` consumía el resto antes de validar N. | Lector por filas: rechazar la cabecera antes de solicitar el cuerpo; validar tamaños con `ValidateDimension`. |
| Escritura corta sin error explícito | `WriteMatrix` podía devolver nil aunque el writer aceptara menos bytes. | Escritura con buffer y comprobación de `Flush`; propagar `io.ErrShortWrite` o el error original. Probar fallos en cabecera y filas posteriores. |
| Pruebas negativas sin aislamiento | Varias entradas antiguas no tenían saltos de línea y fallaban en la cabecera antes del token bajo prueba. | Dar estructura válida a esos casos y probar tokens inválidos tanto en A como en B. |

No se detectó una diferencia de gramática o de índices frente a C en los casos
comprobados. Se preservaron la precisión `%.17g`, la firma pública del lector,
el LCG compartido, el kernel y las fronteras de medición.
El lector crece a partir de filas recibidas y ya no conserva todo el texto del
archivo; una cabecera truncada N=10000 no provoca reserva completa de matrices.

### Avances guardados

| Commit | Avance |
| --- | --- |
| `97e6970` | Pruebas de gramática, límites finitos, codificación, filas y serialización por bits. |
| `b176dfd` | Lector por filas, control temprano de capacidad, diagnósticos y errores de escritura, con regresiones. |
| `97d6f7b` | Batería reproducible de compatibilidad C/Go y documentación de pruebas. |

Archivos principales: `go_secuencial/input.go`, `main.go`, `input_test.go`,
`input_errors_test.go` y `tests/go_secuencial_io_test.ps1`. No se modificó código C
ni archivos de producción de Go paralelo. La documentación describe el estado real.

### Pruebas ejecutadas y resultados

Entorno: Windows 11 Pro build 26300.9711 x64, Go `go1.27.0 windows/amd64`,
MSVC `19.51.36257.0`. Las cachés Go se configuraron en `.cache/go-build` y
los temporales de compilación en `.cache/go-tmp`, sin cambiar configuración global.

| Comprobación | Resultado |
| --- | --- |
| Base `test_windows.ps1 -Version go_secuencial -Configuration Debug` antes de modificar | Código 0; cinco fixtures/CSV conformes. |
| Regresiones de causa de I/O, cabecera, escritura corta y capacidad sobre el código previo | Fallaron como se esperaba, reproduciendo los hallazgos; se corrigieron antes del commit de implementación. |
| `gofmt` sobre los archivos modificados y `go test -count=1 -timeout=60s ./...` en Go secuencial | Código 0; extremos/serialización por bits, estructura, índices, errores e integración aprobados. |
| `go vet ./...` en Go secuencial | Código 0. |
| `test_windows.ps1 -Version go_secuencial`, Debug y Release | Código 0 en ambas: compilación, fmt/vet/test, producto de cinco fixtures y CSV. |
| `test_windows.ps1 -Version c_secuencial`, Debug y Release | Código 0 en ambas: compilación MSVC, contratos, lector/generador, cinco productos y CSV. |
| `tests/go_secuencial_io_test.ps1`, Debug y Release | Código 0 en ambas; 148 ejecuciones por configuración, **296 en total**, sin bloqueos ni diferencias detectadas. |
| `go test -count=1 -timeout=60s ./...` en Go paralelo, como apoyo a revisión de I4 | Código 0. |
| `git diff --check` | Sin errores de espacios. |

La batería nueva ejecuta 65 entradas en cada programa: 17 válidas y 48 inválidas.
Incluye los cinco fixtures independientes, datos asimétricos N=3, LF/CRLF/mezcla,
sin salto final, espacios/tabuladores, fila de 70000 espacios, decimales y
extremos finitos. Rechaza dimensiones inválidas/desbordadas, filas incompletas,
fusionadas o vacías, tokens sobrantes, NaN/Inf, overflow, hexadecimal, coma,
BOM/NUL, UTF-8 inválido, espacio Unicode y producto no finito.
Además compara nueve pares generados (N=1,3,5; semillas 0,42,4294967295).

En éxito se comprueban código 0, stderr vacío, CSV de 20 campos/estado OK y
todas las celdas frente a referencia. En error se exige código 1, stdout vacío,
stderr no vacío y conservación del destino previo. Cada proceso tiene timeout
de 15 s; no quedan temporales de publicación. El caso de interoperabilidad
combina las salidas reales C/Go de `producto2` como dos matrices bajo una sola
cabecera y verifica su nuevo producto: `[[1307,1518],[2967,3446]]`.

El comparador aplica `abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`.
Las pruebas Go usan igualdad de bits para extremos y serialización: la
tolerancia de productos no demuestra preservación de un subnormal o cero con signo.

Evidencia local, excluida por la regla `**/build/`:

- Debug: `go_secuencial/build/Debug/s05-io/1555042a96ce40e9bc523f15adcb4e8e/`.
- Release: `go_secuencial/build/Release/s05-io/a37f1fba4b494f60b055ae1a266efc63/`.
- Cada carpeta contiene entradas, matrices, stdout/stderr separados y `summary.csv`
  con 148 filas OK (52 éxitos y 96 rechazos esperados).
- Los binarios Go de ambas corridas identifican `b176dfd`; C Debug identifica
  `97e6970` y C Release `b176dfd`. El código C no cambió entre esos commits.
  El script se verificó antes de guardarlo en `97d6f7b`; son pruebas de desarrollo,
  no una campaña oficial de rendimiento.

### Reproducción y entrega a revisión

Desde la raíz, para cada configuración Debug/Release:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\go_secuencial_io_test.ps1 -Configuration Debug
```

Repetir los tres comandos con `-Configuration Release`. La batería exige ambos
binarios y termina con 1 ante un error; no omite dependencias ni usa salidas previas.
Los detalles están en [tests/README.md](../../tests/README.md).

**Revisión técnica inicial de I4 por I3:** inspeccionados `go_paralelo/workers.go`,
`matrix.go` y su integración en `main.go`. Se comprobó en código el reparto
contiguo sin solapamientos, A/B de lectura, C independiente, `Add` antes de
lanzar, cierre por el productor y `Wait` antes de leer C/tiempos. Sus pruebas
existentes pasan. Para el trabajo de I4 en S5 se dejan estas observaciones:

1. La CLI limita workers a 1024, pero `MultiplyParallel` solo exige W>0; revisar
   un límite coherente antes de reservar tiempos/canal y lanzar goroutines en la API.
2. La ruta de archivo paralela aún comprueba capacidad después del lector;
   evaluar el control temprano desde cabecera aplicado aquí.
3. Repeticiones largas, validación de límites y aceptación final de I4 requieren
   su entrega S5. Esta inspección no acredita una revisión humana ya aceptada.

**Para I2:** revisar el diff de I3, especialmente EOF frente a fallos parciales,
errores con `errors.Is`, capacidad desde N, escritura corta y destino previo.
**Para I5/I6:** casos y comandos listos para su evaluación/integración en la
batería común; el script compartido `test_windows.ps1` no se modificó.
**Para I8:** instrucciones y casos disponibles para repetir en una segunda PC.
Estas notas están preparadas para el equipo; no se enviaron mensajes ni se
afirma que otras personas hayan revisado, coordinado o reproducido la entrega.

### Límites y pendientes de aceptación

- La estimación de capacidad comprende A/B/C/referencia; buffers de texto,
  crecimiento de slices y variación de memoria disponible requieren margen.
  No se provocó agotamiento real de RAM ni se garantiza recuperar un OOM.
- El writer genérico puede haber escrito bytes antes de fallar; la publicación
  de archivos usa temporal y renombrado. No se garantiza una transacción conjunta
  entre el archivo de salida y stdout si el dispositivo de stdout falla después.
- La batería nueva valida las dos versiones secuenciales. El cierre de las
  cuatro versiones, los errores MPI y la reproducción en otra PC corresponden
  también a los demás integrantes y siguen pendientes de integración del equipo.
- Revisión personal de Sebastian (I2), cierre de la revisión de Eva (I4),
  coordinación con Fernando (I5) y horas reales de Giuliano: pendientes de
  confirmación. Se mantiene la estimación de 8 h sin declararlas realizadas.
- No se abrieron issues ni PR en esta ejecución; el registro final del equipo
  debe añadir sus enlaces cuando existan.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h reproducción de la batería de pruebas en segunda PC física independiente, 3 h análisis de casos negativos, códigos de salida y elaboración del acta, 1 h coordinación general, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s05-i08-validacion-independiente`.
- Pruebas y evidencias: Entregable `docs/validacion_independiente.md` completado con evidencia empírica en Windows 11 (AMD Ryzen 5 7600X, 16 GB DDR5, host `PC-PETEL`). Se ejecutaron las suites de equivalencia (`test_equivalencia.ps1` en Debug y Release: 25 casos OK con $max\_abs = 0.0$ y $max\_rel = 0.0$), pruebas unitarias Go (`go_secuencial` y `go_paralelo` PASS), pruebas de invariantes de partición C (`partition_test.c` y `verify_partition_design.ps1` PASS con 0 fallos), y matriz de inyección de errores (ERR-01 a ERR-10) confirmando que entradas inválidas terminan limpiamente con código 1 en < 50 ms.
- Bloqueos y decisiones: Se certifica que las cuatro referencias cumplen los contratos numéricos y de cronometría monotónica. La lógica algorítmica de C se comprobó de forma independiente con GCC C11 ante la falta de enlace con MSVC en esta máquina.
- Revision y criterio de aceptacion: Entregable de I8 finalizado y conforme; listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly pendiente a la publicación de su PR de C secuencial.

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h verificación y auditoría comparativa de límites de cronometría en las cuatro versiones; 3 h verificación de aislamiento estricto de I/O, generación y validación matemática, y elaboración del informe técnico en `docs/protocolo_medicion.md`; 1 h revisión cruzada formal a Roberto I8 sobre `docs/validacion_independiente.md`; 1 h coordinación de acuerdos del equipo).
- **Issues y pull requests:** rama de trabajo `feature/s05-i07-auditoria-protocolo-tiempo`. Pull request listo para apertura.
- **Entregable principal:** [`docs/protocolo_medicion.md`](../protocolo_medicion.md) actualizado a versión 1.3 con la Sección 9 ("Informe de Auditoría del Protocolo de Tiempo").
- **Pruebas y evidencias:**
  - Se auditó exhaustivamente la instrumentación temporal en el código fuente de los cuatro módulos (`c_secuencial/src/main.c`, `c_paralelo/src/main.c`, `go_secuencial/main.go`, `go_paralelo/main.go` y `go_paralelo/workers.go`).
  - Se comprobó que `kernel_s` mide exclusivamente la acumulación aritmética canónica $i \to k \to j$: directa en las referencias secuenciales, región OpenMP local reducida con `MPI_Reduce(..., MPI_MAX)` en C híbrido, y suma de intervalos por bloque en workers Go agregados por el máximo individual (`maxKernel`).
  - Se verificó que `total_s` inicia estrictamente en T0 (antes de vaciar C / tras la barrera inicial en MPI) y finaliza en T1 (al terminar el cómputo o en `wg.Wait()` / `MPI_Gatherv`).
  - Se certificó que el parseo de argumentos, generación LCG, lectura de matrices, cálculo desacoplado de la referencia ($i \to j \to k$), validación matemática ($atol=10^{-9}, rtol=10^{-9}$), escritura de archivos de salida (`--output`) y emisión del CSV de 20 columnas se ejecutan **estrictamente fuera** de los intervalos cronometrados.
  - Se confirmó en hardware real (Windows 11 x64, AMD Ryzen 7 8845HS) el cumplimiento sistemático del invariante $0.0 \le \text{kernel\_s} \le \text{total\_s}$ y el rechazo inmediato de duraciones negativas o no finitas.
- **Bloqueos y decisiones:** Se constató que las barreras iniciales (`MPI_Barrier`) y el setup de canales de Go están adecuadamente delimitados sin distorsionar el tiempo de kernel, garantizando condiciones de comparación homogéneas y equitativas para las campañas futuras (S7/S8).
- **Revisión a I8 (Roberto):** Revisé exhaustivamente el acta [`docs/validacion_independiente.md`](../validacion_independiente.md). La reproducción empírica sobre hardware independiente (`PC-PETEL`, AMD Ryzen 5 7600X, DDR5) confirma la estabilidad, equivalencia numérica ($max\_abs = 0.0$, $max\_rel = 0.0$) y terminación limpia con código 1 ante inyección de fallos (ERR-01 a ERR-10). La verificación de cronometría monotónica coincide punto por punto con los hallazgos de la auditoría de I7. El entregable de I8 queda **CONFORME**.
- **Revisión y criterio de aceptación:** Mi entregable técnico (`docs/protocolo_medicion.md` v1.3), las evidencias de auditoría y la revisión cruzada quedan completados y conformes al Sprint 5.
#### Integrante 1 (C secuencial robusto)

- **Rama:** `feature/s05-i01-c-secuencial-robusto`
- **PR:** #40
- **Cambios:**
  - `MATRIX_MAX_N = 4096` en `matrix.h`, coherente con la campaña N ∈ {512, 1024, 2048, 4096}.
  - `matrix_validate_buffer_capacity(n, k, *bytes)` con verificación de overflow en `size_t` y `PTRDIFF_MAX`.
  - Rechazo determinista (exit 1) en `parse_options`, `input_read`, `input_generate`, `matrix_allocate` para `n > MATRIX_MAX_N`.
  - Ganchos `matrix_set_alloc_limit` / `matrix_reset_alloc_limit` documentados como solo para tests.
  - `tests/pending_test.c`: casos negativos (N=0, negativo, no numérico, N>4096, semilla fuera de rango, punteros NULL, fallos simulados de reserva).
  - `docs/contrato.md`: aclara límite C=4096 vs Go sin tope fijo.
  - `.gitignore`: `tests/outputs/` ignorado.
- **Pruebas (Debug + Release):** `check_env_windows.ps1` OK, `build_windows.ps1 -Debug -Tests` OK, `build_windows.ps1 -Release` OK, `test_windows.ps1` OK (5 fixtures, tolerancia 1e-9).
- **Revisión cruzada:** I2 (Sebastian) — ver comentario en PR #39.
- **Horas:** 6 h desarrollo + 1 h revisión + 1 h coordinación.

#### Integrante 2 (C paralelo robusto)

- **Rama:** `feature/s05-i02-c-paralelo-errores-colectivos`
- **PR:** #39
- **Cambios:** manejo de fallos colectivos y finalización del híbrido; los rangos coordinan errores antes de los colectivos críticos para evitar esperas indefinidas. Se documentan además el uso de `MPI_THREAD_FUNNELED` y el comportamiento de procesos sin filas.
- **Pruebas y evidencias:** `c_paralelo/tests/pending_test.c` cubre procesos sin filas, P = N, límites de dimensión y el núcleo con cero filas. `c_paralelo/tests/registro_fallos.md` documenta los fallos controlados y sus códigos de salida. `c_paralelo/status.json` registra `validation: passed`; la ejecución de runtime debe repetirse en un equipo con MSVC, Windows SDK y MS-MPI.
