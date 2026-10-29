# Go secuencial

El núcleo y el ejecutable Go secuencial están implementados y probados. El núcleo corresponde a I3 · Giuliano y la integración inicial a I4 · Eva. El 11/10/2026, I3 incorporó esa integración desde `main` y corrigió las observaciones de su revisión: tiempos, CSV, metadatos y argumentos. El generador y el lector funcionan desde el Sprint 2.

## Qué dejé listo

| Función | Qué comprueba o hace |
| --- | --- |
| `ValidateDimension` | Rechaza tamaños no positivos o demasiado grandes. |
| `Matrix.Validate` | Comprueba tamaño, cantidad de datos y valores finitos. |
| `Multiply` | Valida A, B y sus dimensiones; reserva C independiente, la vacía y calcula A×B. Rechaza resultados no finitos y devuelve una matriz vacía ante error. |
| `multiplyKernel` | Acumula A×B en una C preparada, con bucles i,k,j. Separa el cálculo de reservas, validaciones y vaciado. |
| `Generate` | Valida el tamaño y genera A y B con la semilla común. |
| `ReadMatrices` | Lee archivos de prueba y rechaza datos malformados o errores de lectura. |
| `WriteMatrix` | Guarda N y las filas de C con precisión suficiente para conservar los valores. |
| Ejecutable | Procesa argumentos, valida el producto, guarda la matriz solicitada y emite CSV por stdout. |

Se aceptan ceros y negativos; se rechazan NaN e infinitos en entradas y resultados. A y B son de solo lectura y C tiene memoria propia. Ante un tamaño inválido, el generador devuelve un error y matrices vacías. Comprobar el tamaño no garantiza que haya suficiente RAM.

## Cómo lo compruebo

Desde `go_secuencial`:

```powershell
go test -count=1 -timeout=30s ./...
go vet ./...
```

El 05/10/2026 ambas comprobaciones terminaron con **código 0** con Go 1.27.0 en Windows amd64. Las pruebas comparan todas las celdas de los cinco fixtures compartidos (`producto2`, `escalar`, `identidad`, `cero`, `impar3`) con sus archivos esperados. También cubren decimales, entradas inválidas, orden de validación, conservación de A/B, independencia de C, A×A, llamadas repetidas y resultados NaN/Inf por desbordamiento. La comparación rechaza valores no finitos y aplica `abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`.

El 11/10/2026 también pasaron las comprobaciones del ejecutable en Debug y Release. Desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial -Configuration Release
```

El script compila, ejecuta las pruebas Go y comprueba los cinco fixtures mediante el ejecutable real, incluyendo sus archivos y CSV. Se actualizaron únicamente las expectativas de Go secuencial; las versiones pendientes mantienen sus comprobaciones de esqueleto. La evidencia se registra en [Sprint 3](../docs/sprints/sprint-03.md).

## Uso del ejecutable

Compilar desde `go_secuencial` dentro del repositorio para incluir el commit real en el binario:

```powershell
go build -buildvcs=true -o build/Release/go_secuencial.exe .
./build/Release/go_secuencial.exe --n 2 --seed 42
./build/Release/go_secuencial.exe --input ../tests/fixtures/producto2.input.txt --output build/Release/producto2.txt
./build/Release/go_secuencial.exe --n 2 --seed 42 --repetition 0
```

- `--n` y `--seed` son obligatorios para generar entradas. Se aceptan semillas entre 0 y 4294967295 y números decimales sin signo.
- `--input` lee las matrices del archivo y no se combina con N ni semilla. El CSV registra semilla 0 para esta modalidad.
- `--output` guarda C en el formato común. Las matrices se escriben únicamente cuando se solicita esta opción; las rutas vacías se rechazan.
- `--repetition` es opcional, entre 0 y 5. El valor predeterminado es 1; 0 identifica calentamiento y activa `is_warmup=true`.
- `--smoke-test` se ejecuta solo y comprueba la instalación.

Cada ejecución correcta emite en stdout una cabecera CSV de 20 campos y una fila con estado `OK`. Los errores se escriben en stderr, devuelven 1 y no generan una fila de medición. Las ejecuciones correctas devuelven 0. Se rechazan opciones repetidas, desconocidas o incompletas.

## Validación y datos del equipo

Antes de medir se calcula una referencia con bucles i,j,k. Después de medir se comparan todas las celdas con la tolerancia común y se rechazan NaN e infinitos. La referencia, la generación, las reservas, las comprobaciones y los archivos quedan fuera de los tiempos. Se comprueba memoria disponible para A, B, C y la referencia antes de generar matrices.

Los datos de CPU, RAM visible y edición/build de Windows se consultan al sistema. Se fija `GOMAXPROCS=1` durante el cálculo y el CSV registra el valor efectivo. El commit se obtiene de los datos incluidos por Go al compilar; no se sustituye por `dev` ni por datos inventados. Si no se pueden obtener los metadatos, se informa el error.

`go version -m build/Release/go_secuencial.exe` muestra el commit y si había cambios locales al compilar. Para las comprobaciones de desarrollo se permite un árbol modificado; una campaña oficial exige un árbol limpio y los metadatos completos del protocolo. La automatización de campañas sigue correspondiendo a S7/S8.

## Interfaz para integrar los cronómetros

`Multiply(a, b)` proporciona la operación completa y devuelve `(Matrix, error)`. La función interna `multiplyKernel(a, b, c)` solo acumula; requiere matrices válidas de igual dimensión, C previamente vaciada y almacenamiento de C independiente de A/B. El llamador comprueba el resultado al terminar.

Para respetar el protocolo, la integración prepara y valida A/B y reserva C antes de iniciar `total_s`. Después inicia `total_s`, vacía C explícitamente, inicia `kernel_s`, llama a `multiplyKernel` y detiene ambos cronómetros al terminar. La validación de C y la escritura ocurren después. Cronometrar una llamada completa a `Multiply` incluiría preparación y validaciones fuera de las fronteras acordadas.

## Acuerdo con C

Dejé las reglas en [las especificaciones comunes](../docs/especificaciones_c_go_secuencial.md): `--n` y `--seed` para generar datos, `--input` para leerlos y `--output` para guardar el resultado. Acordé 0 para éxito, 1 para error y 2 para pendiente, con errores en `stderr`.

La revisión cruzada del núcleo de S3 corresponde a Sebastian (I2) y queda pendiente. Los datos de prueba están descritos en [formato_datos.md](../docs/formato_datos.md).

El [contrato común](../docs/contrato.md) exige N en línea propia y N valores por fila, con LF/CRLF. ReadMatrices devuelve ErrInvalidFixture ante formato incorrecto y ErrFixtureIO ante fallo de lectura; ambos se convierten a salida 1. La instrumentación implementada sigue el [protocolo](../docs/protocolo_medicion.md): el vaciado de C pertenece a total_s y queda fuera de kernel_s; validación e I/O quedan fuera de ambos.

## Sprint 5 · formatos, índices y errores

El 29/10/2026, I3 revisó la compatibilidad de entrada/salida con C secuencial.
El lector procesa una fila a la vez, conserva la gramática común y reutiliza
`ValidateDimension` antes de almacenar datos. No conserva una copia textual del
archivo completo ni reserva N*N elementos a partir de una cabecera incompleta.
Las filas se incorporan en orden a A y después B; se admiten filas mayores de
64 KiB, LF/CRLF mezclados y ausencia de salto final.

La CLI comprueba la memoria disponible para A/B/C/referencia desde la cabecera,
antes de construir las matrices de un archivo. La API pública `ReadMatrices`
conserva su firma y verifica límites aritméticos; no consulta memoria del sistema.
La comprobación de capacidad estima los cuatro buffers, no toda la memoria del
proceso: las filas de texto, el crecimiento de slices y cambios concurrentes de
RAM disponible siguen requiriendo margen. No se garantiza recuperar un OOM del runtime.

Los errores de formato identifican matriz/fila/columna cuando corresponde;
las posiciones del diagnóstico empiezan en 1. Los fallos del lector conservan
`ErrFixtureIO` y su causa original mediante `errors.Is`, incluso después de
recibir datos parciales. Cualquier fallo devuelve matrices vacías.

`WriteMatrix` conserva `%.17g`, valida antes de escribir y usa un buffer cuyo
vaciado propaga errores y escrituras incompletas (`io.ErrShortWrite`). Un writer
genérico puede haber recibido bytes antes de fallar. `saveMatrix` evita publicar
esa matriz incompleta escribiendo/cerrando un temporal antes de reemplazar el destino.

Las pruebas Go comprueban extremos por bits (incluidos subnormales y cero con
signo), orden de filas, errores de I/O y capacidad insuficiente. La batería
[go_secuencial_io_test.ps1](../tests/go_secuencial_io_test.ps1) realiza 148
ejecuciones C/Go por configuración, verificando aceptación/rechazo, productos,
CSV y conservación de salidas anteriores. Pasó en Debug y Release. Las
[instrucciones](../tests/README.md) permiten reproducirla; la evidencia y las
revisiones personales pendientes se registran en [Sprint 5](../docs/sprints/sprint-05.md).
