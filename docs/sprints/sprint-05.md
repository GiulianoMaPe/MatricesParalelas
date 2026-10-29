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
