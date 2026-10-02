# Acuerdo para C y Go secuencial

**Integrante:** 3 · Giuliano
**Sprint:** 2 · Fecha: 01/10/2026

Revisé estas reglas para que C y Go acepten los mismos datos y detecten los mismos errores. Comprobé la adaptación de Yessly y ajusté la validación del generador Go.

## Matrices

Acordé matrices cuadradas con tamaño positivo y exactamente `N*N` valores, guardados por filas. C usa `double` y Go usa `float64`. Acepto ceros y negativos; rechazo NaN e infinitos.

Compruebo el tamaño antes de reservar memoria. En Windows x64, `N=1073741823` pasa la comprobación de tamaño y `N=1073741824` se rechaza. Estos límites no garantizan RAM disponible; los pruebo sin reservar matrices gigantes.

Reviso primero A, luego B y después que tengan la misma dimensión. La multiplicación debe conservar ambas entradas.

## Argumentos para Sprint 3

| Opción | Regla acordada |
| --- | --- |
| `--n N --seed S` | Ambos son obligatorios para generar datos. N es positivo y S está entre 0 y 4294967295. |
| `--input archivo` | Obtiene el tamaño y las matrices del archivo; no se combina con N ni semilla. |
| `--output archivo` | Guarda una matriz pequeña en el formato común. |
| `--smoke-test` | Comprueba la instalación; no se combina con cálculo. |

Acordé N y semilla en decimal, sin signos ni fracciones. Se permiten ceros iniciales y cualquier orden de opciones; se rechazan opciones repetidas, desconocidas o sin valor. El formato está en [formato_datos.md](formato_datos.md).

Con el mismo tamaño y semilla, ambos lenguajes deben generar las mismas matrices. Acordé llenar primero A y después B, continuando el mismo generador.

## Errores y resultados

| Problema | Error en Go |
| --- | --- |
| Tamaño no positivo | `ErrInvalidDimension` |
| Tamaño que excede los límites | `ErrSizeOverflow` |
| Datos faltantes o sobrantes | `ErrInvalidDataLength` |
| NaN o infinito | `ErrNonFiniteValue` |
| Dimensiones distintas | `ErrDimensionMismatch` |
| Cálculo sin implementar | `ErrPending` |

C puede usar otros nombres internos. Acordé que el programa termine con **0 si funciona, 1 si hay un error y 2 si la operación está pendiente**. Los errores se escriben en `stderr` y no deben dejar resultados parciales.

## Qué comprobé

Comprobé entradas válidas, tamaños inválidos, datos incompletos, NaN, infinitos, dimensiones distintas y semillas límite. Corregí las pruebas del generador: ya entrega matrices con entradas válidas; solo la multiplicación sigue pendiente.

El 01/10/2026 ejecuté `test_windows.ps1 -Version go_secuencial` desde la raíz y obtuve **código 0**. Me falta la revisión de Sebastian (I2).

## Confirmación de Yessly (I1)

Conservo su confirmación sobre la parte C:

> Completé las interfaces C para validar matrices y reservar y liberar memoria. Confirmé los argumentos y códigos de salida de esta propuesta para S3, con el mismo límite de tamaño que Go en Windows x64.
>
> Ejecuté las pruebas C en Debug y Release; pasaron. También contrasté las validaciones de matrices con Go. Dejé los resultados en [S2](sprints/sprint-02.md). Me falta la revisión de Roberto (I8).

**Actualización posterior de revisión · 01/10/2026:** la [revisión técnica asistida para I8](revision_i08_sprints_01_02.md) ya está realizada, con interfaces y pruebas C Debug/Release conformes. La cita conserva la confirmación original de Yessly; la observación sobre sus horas declaradas sigue pendiente de respuesta.
