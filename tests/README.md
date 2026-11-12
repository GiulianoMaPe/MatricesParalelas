# Pruebas del proyecto

`scripts/test_windows.ps1` ejecuta primero las pruebas de
`scripts/compare_results.ps1`, compila cada versión elegida y prueba su estado
actual. Un faltante de dependencias es un fallo/incompleto, nunca un PASS omitido
silenciosamente.

- C: generación LCG, lectura de fixtures y contratos de dimensión, datos y buffers.
- C secuencial: producto real de cinco fixtures y CSV, sin MPI ni OpenMP.
- C híbrido: dos procesos, exactamente dos hilos observados por proceso y
  MPI_THREAD_FUNNELED comprobado. MPI se invoca fuera de OpenMP.
- Ambos Go: go fmt, go vet, go test y ejecución de --smoke-test.
- Go secuencial: producto real de los cinco fixtures, archivo de salida y CSV.
- Comparador: cinco referencias, doble tolerancia, dimensiones, filas y rechazo de NaN.
- Go paralelo: producto real, cinco fixtures, CSV, workers>N, canal y WaitGroup.
- Los cuatro lectores: N en línea propia, N valores por fila, LF/CRLF, salto final opcional, subnormales y underflow finito. Rechazan filas fusionadas/divididas, líneas vacías internas, BOM, NUL, CR aislado, NaN, infinito y datos sobrantes/faltantes.

Los generadores usan los mismos vectores de control y los lectores aplican el
[formato común](../docs/formato_datos.md). El cierre técnico de S4 y sus pruebas
de equivalencia están registrados en [sprint-04.md](../docs/sprints/sprint-04.md).
El [cierre técnico de S5](../docs/sprints/sprint-05.md) integra casos negativos,
manejo de errores y validación integral. Las pruebas
de instalación por sí solas no verifican la corrección matemática.

Los códigos del ejecutable son 0 para éxito, 1 para cualquier error y 2 solo para
una operación pendiente; los estados internos C no se propagan como códigos del proceso.
Las fronteras de los cronómetros se especifican en el [protocolo](../docs/protocolo_medicion.md).

## Sprint 5 · I3: compatibilidad de entrada/salida C y Go secuenciales

`go_secuencial_io_test.ps1` puede ejecutarse de forma independiente y ya está
integrada en `test_windows.ps1 -Version all` durante el cierre de S5.
Requiere binarios recién compilados de las dos versiones secuenciales. Desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\go_secuencial_io_test.ps1 -Configuration Debug
```

Repetir con `-Configuration Release` en los tres comandos. La batería realiza
**148 ejecuciones por configuración**: 65 entradas comunes en ambos programas
(17 válidas y 48 inválidas) y nueve pares de generación N=1,3,5 con semillas
0,42,4294967295. Incluye los cinco fixtures, LF/CRLF, filas largas, decimales,
límites finitos, errores de estructura/codificación y desbordamiento del producto.
Construye además una entrada a partir de las salidas reales de ambos escritores.

Cada proceso tiene un timeout de 15 segundos. En éxito se comprueban el CSV y
todos los valores de la matriz con el comparador común; en error se exige
código 1, stdout vacío, stderr y conservación del destino anterior. Cualquier
fallo termina la batería con 1. Los archivos de entrada, salida, diagnósticos
y `summary.csv` quedan en `go_secuencial/build/<configuración>/s05-io/<id>/`,
ignorados por Git; no se reutilizan salidas de otra corrida.

Las pruebas Go comprueban por bits los extremos numéricos y la serialización,
para detectar pérdida de subnormales o del signo de cero que la tolerancia de
productos no detectaría. También inyectan errores de lectura/escritura y
capacidad insuficiente. El acta y las limitaciones están en
[sprint-05.md](../docs/sprints/sprint-05.md).

## Batería integral de Sprint 5

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Release
```

Cada comando compila las cuatro versiones, ejecuta las pruebas del comparador
y de cada módulo, verifica 24 productos frente a los fixtures y valida sus CSV
(20 columnas, versión, configuración y tiempos finitos). El híbrido incluye
P=1, P>N, reparto no divisible y T=1/2. Después de cada versión ejecuta
`sprint05_errors_test.ps1`: 11 casos comunes, más tres de workers Go y dos de
MPI, **49 casos por configuración**. Si los cuatro módulos pasan, ejecuta las
148 invocaciones de compatibilidad secuencial. Cualquier fallo devuelve 1.

Los casos negativos exigen código 1, stdout vacío, stderr y conservación de
la salida previa; incluyen lectura truncada, NaN, producto no finito y salida
que apunta a un directorio. MPI usa P=3/T=2 y comprueba el límite de N y la
configuración OpenMP inválida. Cada invocación tiene timeout de 15 s; al vencer
se termina el árbol de ese proceso y falla la prueba. El diagnóstico identifica
versión y caso. Los archivos y `summary.csv` quedan en
`<versión>/build/<configuración>/s05-errors/<id>/`.

Para repetir solo los errores de un binario recién compilado:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\sprint05_errors_test.ps1 -Version c_paralelo -Configuration Debug
```

MPI requiere permiso para lanzar procesos de MS-MPI. Una restricción del
entorno se reporta como fallo; no se omite la prueba ni se presenta como éxito.

## Sprint 7 — caso `c_paralelo` del script de campaña

`bench_c_paralelo_test.ps1` prueba las funciones puras de
`scripts/bench_windows.ps1` sin MSVC ni MS-MPI: cabecera y parser CSV,
validación de configuración/P/T/`observed_threads`/tiempos, filas de fallo sin
tiempos inventados, resolución de configuraciones por núcleos físicos,
exclusiones por memoria, `plan.csv`, `entorno.json` y el lock de campaña.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_c_paralelo_test.ps1
```

El script hace dot-source de `bench_windows.ps1` y ejecuta 23 pruebas. No sustituye a
la campaña real: esta requiere compilar Release, MS-MPI y permisos para lanzar
procesos.

