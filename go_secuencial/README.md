# Go secuencial

El núcleo de multiplicación secuencial está implementado y probado en el Sprint 3 (I3 · Giuliano). El generador y el lector de archivos funcionan desde el Sprint 2. La integración de argumentos, lectura/escritura, cronómetros y CSV en el ejecutable corresponde a I4 · Eva y sigue pendiente.

## Qué dejé listo

| Función | Qué comprueba o hace |
| --- | --- |
| `ValidateDimension` | Rechaza tamaños no positivos o demasiado grandes. |
| `Matrix.Validate` | Comprueba tamaño, cantidad de datos y valores finitos. |
| `Multiply` | Valida A, B y sus dimensiones; reserva C independiente, la vacía y calcula A×B. Rechaza resultados no finitos y devuelve una matriz vacía ante error. |
| `multiplyKernel` | Acumula A×B en una C preparada, con bucles i,k,j. Separa el cálculo de reservas, validaciones y vaciado. |
| `Generate` | Valida el tamaño y genera A y B con la semilla común. |
| `ReadMatrices` | Lee archivos de prueba y rechaza datos malformados o errores de lectura. |

Se aceptan ceros y negativos; se rechazan NaN e infinitos en entradas y resultados. A y B son de solo lectura y C tiene memoria propia. Ante un tamaño inválido, el generador devuelve un error y matrices vacías. Comprobar el tamaño no garantiza que haya suficiente RAM.

## Cómo lo compruebo

Desde `go_secuencial`:

```powershell
go test -count=1 -timeout=30s ./...
go vet ./...
```

El 05/10/2026 ambas comprobaciones terminaron con **código 0** con Go 1.27.0 en Windows amd64. Las pruebas comparan todas las celdas de los cinco fixtures compartidos (`producto2`, `escalar`, `identidad`, `cero`, `impar3`) con sus archivos esperados. También cubren decimales, entradas inválidas, orden de validación, conservación de A/B, independencia de C, A×A, llamadas repetidas y resultados NaN/Inf por desbordamiento. La comparación rechaza valores no finitos y aplica `abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`.

El script `scripts/test_windows.ps1 -Version go_secuencial` conserva las comprobaciones del esqueleto y exige salida 2 ante una solicitud de cálculo. La comprobación del 01/10/2026 fue de entorno e interfaces. El ejecutable actual sigue aceptando solo `--smoke-test`; su integración y la actualización del script son entregas pendientes de I4 e I8. La evidencia actual del núcleo se registra en [Sprint 3](../docs/sprints/sprint-03.md).

## Interfaz para integrar los cronómetros

`Multiply(a, b)` proporciona la operación completa y devuelve `(Matrix, error)`. La función interna `multiplyKernel(a, b, c)` solo acumula; requiere matrices válidas de igual dimensión, C previamente vaciada y almacenamiento de C independiente de A/B. El llamador comprueba el resultado al terminar.

Para respetar el protocolo, la integración prepara y valida A/B y reserva C antes de iniciar `total_s`. Después inicia `total_s`, vacía C explícitamente, inicia `kernel_s`, llama a `multiplyKernel` y detiene ambos cronómetros al terminar. La validación de C y la escritura ocurren después. Cronometrar una llamada completa a `Multiply` incluiría preparación y validaciones fuera de las fronteras acordadas.

## Acuerdo con C

Dejé las reglas en [las especificaciones comunes](../docs/especificaciones_c_go_secuencial.md): `--n` y `--seed` para generar datos, `--input` para leerlos y `--output` para guardar el resultado. Acordé 0 para éxito, 1 para error y 2 para pendiente, con errores en `stderr`.

La revisión cruzada del núcleo de S3 corresponde a Sebastian (I2) y queda pendiente. Los datos de prueba están descritos en [formato_datos.md](../docs/formato_datos.md).

El [contrato común](../docs/contrato.md) exige N en línea propia y N valores por fila, con LF/CRLF. ReadMatrices devuelve ErrInvalidFixture ante formato incorrecto y ErrFixtureIO ante fallo de lectura; ambos se convierten a salida 1. El [protocolo](../docs/protocolo_medicion.md) incluye el vaciado de C en total_s y lo excluye de kernel_s; validación e I/O quedan fuera de ambos. La instrumentación se implementará en S3.
