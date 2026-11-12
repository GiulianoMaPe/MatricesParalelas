# Sprint 5 Integrar y fortalecer la corrección

**Estado al 05/11/2026: cierre técnico completado; cuatro conformidades personales pendientes para el cierre administrativo.**
El acta reúne las siete entregas recibidas por PR y completa la integración
prevista para I6. El responsable confirma **8 h reales por integrante (64 h)**;
la distribución por actividad se reconstruye abajo. Los registros individuales
se conservan como evidencia histórica; esta síntesis actualiza sus pendientes.

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

### Dictamen, base y trazabilidad

**Aceptación técnica de S5 conforme:** las cuatro versiones pasan la batería
común, los errores comprobados terminan sin bloqueos y existe evidencia
reproducible. Las pruebas no garantizan recuperación ante agotamiento real de
RAM ni ante fallos arbitrarios del servicio MPI.

Base integrada: `2fe48acb056c79e181b106316384ae4fa94b971b`, tras fusionar los PR
#36–#42. La verificación de cierre añade sobre esa base los cambios de
`test_windows.ps1` y `sprint05_errors_test.ps1` publicados junto a esta acta.
Coordinación prevista del sprint: Fernando (I5).

| Integrante | Entrega y evidencia | Integración | Resultado técnico |
| --- | --- | --- | --- |
| I1 · Yessly | Capacidad, overflow, N máximo 4096 y reserva simulada en C secuencial | [PR #40](https://github.com/GiulianoMaPe/MatricesParalelas/pull/40) | Conforme |
| I2 · Sebastian | P>N, P=N, finalización colectiva y [registro de fallos](../../c_paralelo/tests/registro_fallos.md) | [PR #39](https://github.com/GiulianoMaPe/MatricesParalelas/pull/39), test corregido en `184a4f6` | Conforme |
| I3 · Giuliano | Lector por filas, capacidad temprana, errores I/O y compatibilidad C/Go | [PR #36](https://github.com/GiulianoMaPe/MatricesParalelas/pull/36) | Conforme |
| I4 · Eva | Workers acotados, buffers sin alias, estabilidad y terminación | [PR #37](https://github.com/GiulianoMaPe/MatricesParalelas/pull/37) | Conforme |
| I5 · Fernando | Tolerancias y [validación numérica](../validacion_numerica.md), con reproducción C por Eva | [PR #42](https://github.com/GiulianoMaPe/MatricesParalelas/pull/42) | Conforme |
| I6 · Gerardo, asignación del plan | Integración de batería común, errores, CSV y compatibilidad C/Go | Completada durante este cierre con asistencia de Codex; no se encontró PR S5 de I6 | Conforme técnicamente; revisión personal pendiente |
| I7 · Andrés | [Protocolo v1.3](../protocolo_medicion.md) y fronteras temporales | [PR #41](https://github.com/GiulianoMaPe/MatricesParalelas/pull/41) | Conforme |
| I8 · Roberto | [Acta de validación independiente](../validacion_independiente.md) | [PR #38](https://github.com/GiulianoMaPe/MatricesParalelas/pull/38) | Conforme para la base y alcance documentados |

GitHub no devolvió issues del repositorio; se conserva la trazabilidad por PR
y commits sin crear issues retroactivas. Los siete PR de S5 están fusionados.
La reproducción de I8 corresponde a `ebf1fca`, con Go y comprobaciones
algorítmicas C mediante GCC; no certifica por sí sola los binarios MSVC/MPI del
cierre actual. Se complementa con la reproducción C de I4 del 04/11 y las
ejecuciones locales siguientes.

### Integración pendiente resuelta para I6

`test_windows.ps1` aún no incluía la batería de I3 ni una suite común de errores
S5. Se completó esa integración a solicitud del responsable, sin atribuirla a
una entrega personal publicada por Gerardo:

- Comprobación de versión y 20 campos CSV, y de cada fixture MPI con su N,
  semilla, procesos, hilos y tiempos finitos `0 <= kernel_s <= total_s`.
- `tests/sprint05_errors_test.ps1`: 11 errores comunes por versión; tres límites
  de workers Go y dos casos MPI (N=46341 y OpenMP dinámico inválido).
  Son **49 invocaciones por configuración**.
- Cada error exige código 1, stdout vacío, stderr y conservación de una salida
  anterior. Un límite de 15 s por invocación detecta bloqueo y termina el árbol
  de ese proceso. MPI usa P=3/T=2, incluidos procesos sin filas cuando N=2.
- `-Version all` integra las **148 invocaciones C/Go** de I3 después de validar
  las cuatro versiones. Si alguna falla, devuelve 1 y no compara con binarios
  incompletos o antiguos. Se informa la versión y el caso exacto.
- Evidencia por caso en `<version>/build/<configuración>/s05-errors/<id>/`:
  stdout, stderr y `summary.csv`; los binarios y logs permanecen ignorados.

En la integración previa se corrigió un test C: `partition_split` admite filas
hasta INT_MAX; `partition_rows` exige además N*N <= INT_MAX. Rechazar N=46341 en
ambas funciones contradecía `partition.h`. La regresión ahora prueba los dos
límites sin restringir el algoritmo.

### Verificación reproducible del 05/11/2026

Entorno local: Windows x64 build 26300.9711, AMD Ryzen 5 3600, 15.912 GiB RAM,
MSVC x64/Windows SDK, MS-MPI 10.1 y Go 1.27.0 windows/amd64. El detector de
carreras de la integración empleó GCC 15.1.0 con CGO y el directorio
`C:\msys64\ucrt64\bin` al principio del PATH del proceso.

| Comprobación | Resultado |
| --- | --- |
| `test_windows.ps1 -Version all -Configuration Debug` | Código 0; cuatro versiones, 24 productos con max_abs=max_rel=0, 49 errores controlados y 148 invocaciones C/Go |
| `test_windows.ps1 -Version all -Configuration Release` | Código 0; cuatro versiones, 24 productos con max_abs=max_rel=0, 49 errores controlados y 148 invocaciones C/Go |
| Compatibilidad secuencial, incluida en ambos comandos | 148 invocaciones por configuración; 296 en total; gramática, errores, destino previo y nueve pares LCG |
| `go test -race -count=1 -timeout=180s ./...`, en Go paralelo, durante la integración | Código 0; 44.134 s; sin carreras reportadas |
| Auditoría del código/protocolo | Lectura/generación, referencia, validación, salida y CSV fuera de los cronómetros; cómputo y coordinación según el protocolo |

Los logs locales están en `.cache/sprint-05-cierre/debug.log` y `release.log`.
Los intentos previos de lanzar MPI dentro del aislamiento fallaron por acceso
denegado y se repitieron fuera de él; no se registran como éxitos globales.
Reproducción desde la raíz, en un entorno con acceso al lanzador MS-MPI:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Release
```

### Horas confirmadas y distribución

El responsable confirmó **8 h reales por integrante, 64 h de equipo**. El
desglose se reconstruye según las tareas; no procede de un cronometraje por
actividad ni acredita por sí mismo las conformidades personales pendientes.

| Integrante | Desarrollo, integración o documentación | Pruebas y análisis | Revisión cruzada | Coordinación | Total |
| --- | --- | --- | --- | --- | --- |
| I1 · Yessly | 3 h: límites y capacidad C | 3 h: overflow y reserva | 1 h: I2 | 1 h: interfaces C | **8 h** |
| I2 · Sebastian | 2,5 h: errores colectivos y registro | 3,5 h: P>N, P=N y finalización | 1 h: I3 | 1 h: híbrido | **8 h** |
| I3 · Giuliano | 3,5 h: lector, capacidad y writer Go | 2,5 h: formato y compatibilidad C/Go | 1 h: I4 | 1 h: contrato I/O | **8 h** |
| I4 · Eva | 3 h: workers y buffers | 3 h: estabilidad, carreras y reproducción C | 1 h: I5 | 1 h: integración Go | **8 h** |
| I5 · Fernando | 2,5 h: tolerancias e informe | 3,5 h: comparador y error máximo | 1 h: I6 | 1 h: coordinación S5 | **8 h** |
| I6 · Gerardo | 3,5 h: integración prevista de la batería | 2,5 h: casos y códigos de salida | 1 h: I7 | 1 h: automatización | **8 h** |
| I7 · Andrés | 3 h: auditoría y protocolo | 3 h: fronteras e invariantes | 1 h: I8 | 1 h: acuerdos de medición | **8 h** |
| I8 · Roberto | 3 h: reproducción independiente | 3 h: fallos, diferencias y acta | 1 h: I1 | 1 h: evidencia | **8 h** |
| **Equipo** | **24 h** | **24 h** | **8 h** | **8 h** | **64 h** |

### Revisiones personales y cierre administrativo

| Revisión prevista | Evidencia disponible | Estado |
| --- | --- | --- |
| I1 → I2 | [Aprobación de Yessly en #39](https://github.com/GiulianoMaPe/MatricesParalelas/pull/39#pullrequestreview-5791888637); test de límites corregido después y validado automáticamente | Registrada |
| I2 → I3 | [Aprobación de Sebastian en #36](https://github.com/GiulianoMaPe/MatricesParalelas/pull/36#pullrequestreview-5779441056) | Conforme |
| I3 → I4 | Inspección inicial histórica, sin conformidad personal final publicada | Pendiente |
| I4 → I5 | Revisión de Eva del 04/11 en el registro individual y el informe numérico | Conforme |
| I5 → I6 | Batería completada en este cierre; falta revisión de Fernando | Pendiente |
| I6 → I7 | No se encontró conformidad personal de Gerardo | Pendiente |
| I7 → I8 | Conformidad expresa de Andrés en el registro de I7 | Conforme |
| I8 → I1 | El registro de I8 la dejaba pendiente; no hay conformidad publicada en #40 | Pendiente |

**Para completar el cierre administrativo faltan las cuatro conformidades
I3→I4, I5→I6, I6→I7 e I8→I1.** El cierre técnico asistido y la confirmación de
horas no sustituyen esas revisiones ni se presentan como firmas del equipo.

S6 puede partir de esta base validada; cada optimización deberá conservar la
batería y aportar medición antes/después. La campaña piloto S7, los datos
oficiales S8 y el análisis posterior no pertenecen a S5. El control temprano de
capacidad en el lector de Go paralelo y los límites de OOM/transacción entre
archivo y stdout se conservan como mejoras y limitaciones documentadas.

## Registros individuales históricos

Los apartados siguientes conservan las declaraciones originales y sus fechas.
Para el estado vigente de PR, horas y revisiones prevalece el acta anterior.

## Registro consolidado de I6 · Gerardo

- **Informe técnico complementario:** [Sprint 5 · Registro técnico de I6](sprint-05-i6.md),
  con el cambio al test del comparador, pruebas ejecutadas y limitaciones de
  esta validación local.
- **Asignación:** ampliar `scripts/test_windows.ps1` con las pruebas matemáticas
  completas y hacer que los errores se detecten por código de salida, informando
  el caso exacto.
- **Trabajo reflejado en el cierre técnico:** se integraron la batería común de
  regresión y `tests/sprint05_errors_test.ps1` con asistencia de Codex. La
  cobertura verifica fixtures y CSV, errores esperados, salida estándar vacía,
  diagnóstico por `stderr`, conservación del archivo de salida y terminación
  dentro del límite de 15 s. La aceptación de las cuatro versiones se comprobó
  en Debug y Release; el detalle y los comandos están en las secciones
  [Integración pendiente resuelta para I6](#integración-pendiente-resuelta-para-i6)
  y [Verificación reproducible](#verificación-reproducible-del-05112026).
- **Resultado técnico:** conforme. `-Version all` terminó con código 0 en ambas
  configuraciones; se registran 49 errores controlados y 148 invocaciones de
  compatibilidad C/Go por configuración.
- **Validación adicional en este workspace · 12/11/2026:** se corrigió
  `tests/compare_results_test.ps1` para capturar stdout, stderr y código de
  salida del comparador mediante `System.Diagnostics.Process`, evitando que
  PowerShell convierta el stderr esperado de los casos negativos en una
  excepción de la propia prueba. El test del comparador pasó. También pasaron
  las pruebas de los módulos Go y 36 casos negativos: 11 de C secuencial, 11
  de Go secuencial y 14 de Go paralelo. Las pruebas C secuenciales y las de
  particionado C paralelo compilaron y pasaron durante el intento del runner.
  La ejecución integral no pudo completarse en este workspace: no hay
  metadatos `.git` para producir el commit que exigen los CSV y falta el
  runtime de MS-MPI (`mpiexec.exe`). Por ello, esta ejecución parcial no
  sustituye la aceptación integral Debug/Release documentada arriba.
- **Autoría y trazabilidad:** este registro consolida la asignación y la
  evidencia de cierre; no atribuye a Gerardo una entrega individual publicada.
  No se encontró PR de S5 de I6. La integración se completó durante el cierre
  con asistencia de Codex.
- **Horas:** el responsable confirmó 8 h reales por integrante para el sprint.
  El desglose de actividades de I6 en la tabla de horas es una reconstrucción
  del cierre, no una declaración individual de Gerardo.
- **Revisión y cierre personal:** la revisión cruzada de I6 a I7 y la revisión
  de I5 a I6 siguen pendientes. Por tanto, la aceptación técnica no cierra por
  sí sola el registro administrativo personal.

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
