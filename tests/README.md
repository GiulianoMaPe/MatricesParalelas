# Pruebas del proyecto

## Sprint 7 · I3: medidor Go secuencial

`bench_go_secuencial_test.ps1` comprueba el CSV de veinte campos, parámetros,
metadatos Release/VCS, captura y terminación de procesos controlados, entorno,
timeout y conservación de datos parciales. La modalidad predeterminada usa
datos sintéticos; está diseñada para PowerShell 5.1/7 y validada localmente con
7.4.6 en Linux. No genera resultados de piloto.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_go_secuencial_test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version go_secuencial -Configuration Release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_go_secuencial_test.ps1 -WithExecutable
```

`-WithExecutable` añade seis lotes reales con N=1,3,17, semillas 0/4294967295,
calentamiento y cinco medidas. Exige Windows x64 y el ejecutable Release de HEAD.
La evidencia se guarda bajo `tests/outputs/s07-i03/<id>/`. Consultar
[resultados locales, procedimiento y aceptación Windows](../docs/validacion_s07_i03.md).

## Batería común

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

## Diagnóstico del Sprint 6

Los archivos `go_secuencial/sprint06_test.go` y `go_paralelo/sprint06_test.go`
contienen candidatas aisladas y comprobaciones de producto, repetición e
inmutabilidad. No sustituyen los kernels de producción. Las observaciones
`TestSprint06Observation` solo se activan con `S06_OUTPUT` y usan un esquema
propio de laboratorio, no el CSV de campaña.

`tests/sprint06_kernel_bench.c` se enlaza con `tests/sprint06_candidates.c`
como unidad independiente y por separado con C secuencial o con el
kernel local OpenMP (`S06_OPENMP`); este último no ejecuta comunicación MPI.
Cada observación usa la referencia independiente i,j,k y verifica cada celda.

En Linux con Python 3.9+, GCC/OpenMP, Go compatible con go.mod y GNU time:

```bash
python3 -B tests/sprint06_lab_test.py
python3 -B scripts/sprint06_lab.py --go /ruta/a/go --sizes 256 512 1024 --workers 1 2 4
```

El runner construye los harnesses, toma un calentamiento y cinco medidas por
combinación, alterna el orden por rondas y conserva fuentes, hashes, entorno,
memoria RSS y datos originales bajo `resultados/diagnostico/s06/`. Incluye
bloqueo por repositorio, timeout del grupo de procesos y validación de salida;
no sobreescribe intentos ni modifica los programas de campaña.

Los resultados Linux no certifican MSVC/MS-MPI ni la campaña Windows. Para
cerrar S6 deben repetirse la batería común Windows en Debug/Release, P/T y
los picos de memoria por rank según [el acta](../docs/sprints/sprint-06.md).
