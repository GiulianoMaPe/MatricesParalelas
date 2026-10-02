# Go secuencial

Revisé las interfaces de Go secuencial y corregí sus pruebas para Sprint 2. El generador y el lector de archivos ya funcionan; la multiplicación y los argumentos del programa quedan para Sprint 3.

## Qué dejé listo

| Función | Qué comprueba o hace |
| --- | --- |
| `ValidateDimension` | Rechaza tamaños no positivos o demasiado grandes. |
| `Matrix.Validate` | Comprueba tamaño, cantidad de datos y valores finitos. |
| `Multiply` | Revisa las dos matrices y sus dimensiones. Aún devuelve pendiente con entradas válidas. |
| `Generate` | Valida el tamaño y genera A y B con la semilla común. |
| `ReadMatrices` | Lee archivos de prueba y rechaza datos malformados o errores de lectura. |

Acepto ceros y negativos; rechazo NaN e infinitos. Ante un tamaño inválido, el generador devuelve un error y matrices vacías. Comprobar el tamaño no garantiza que haya suficiente RAM.

## Cómo lo compruebo

Desde la raíz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial
```

Lo ejecuté el 01/10/2026 y terminó con **código 0**. El ejecutable solo acepta `--smoke-test`; una solicitud de cálculo termina con código 2.

## Acuerdo con C

Dejé las reglas en [las especificaciones comunes](../docs/especificaciones_c_go_secuencial.md): `--n` y `--seed` para generar datos, `--input` para leerlos y `--output` para guardar el resultado. Acordé 0 para éxito, 1 para error y 2 para pendiente, con errores en `stderr`.

Comprobé la adaptación de Yessly. Me falta la revisión de Sebastian sobre mi entregable. Los datos de prueba están descritos en [formato_datos.md](../docs/formato_datos.md).

El [contrato común](../docs/contrato.md) exige N en línea propia y N valores por fila, con LF/CRLF. ReadMatrices devuelve ErrInvalidFixture ante formato incorrecto y ErrFixtureIO ante fallo de lectura; ambos se convierten a salida 1. El [protocolo](../docs/protocolo_medicion.md) incluye el vaciado de C en total_s y lo excluye de kernel_s; validación e I/O quedan fuera de ambos. La instrumentación se implementará en S3.
