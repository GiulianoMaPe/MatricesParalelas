# Especificaciones comunes para C y Go secuencial

**Sprint:** 2 · **Autor de la propuesta:** Integrante 3 · **Destinatario:** Integrante 1
**Fecha:** 2026-10-01
**Estado:** propuesta definida por I3; pendiente de adaptación y confirmación de I1.

Propongo estas reglas para que `c_secuencial` y `go_secuencial` acepten los mismos datos y detecten los mismos problemas. Se basan en el [contrato del proyecto](contrato.md). Los nombres de las funciones pueden ser distintos en cada lenguaje.

## 1. Reglas de las matrices

| Regla | Comportamiento común |
| --- | --- |
| Forma | Matrices cuadradas de tamaño `N × N`. |
| Tamaño | `N` debe ser un entero mayor que cero. |
| Cantidad de datos | Cada matriz debe contener exactamente `N*N` valores. |
| Tipo de los valores | `double` en C y `float64` en Go, de 8 bytes por elemento en el entorno del proyecto. |
| Orden | Los valores se guardan fila por fila. La posición de la fila `i`, columna `j`, es `i*N+j`. |
| Valores permitidos | Ceros, positivos y negativos. |
| Valores rechazados | NaN e infinitos. |
| Multiplicación | A y B deben ser válidas y tener el mismo tamaño. La función no modifica sus entradas. |

Por ejemplo, una matriz de tamaño 2 necesita 4 valores. La matriz `[1 2; 3 4]` se guarda como `[1, 2, 3, 4]`.

En C, un puntero no indica cuántos valores contiene. I1 debe hacer que la interfaz reciba o conserve la cantidad de elementos del buffer, para poder comprobarla antes de leer sus valores. Un puntero nulo con N positivo se rechaza como datos faltantes.

## 2. Tamaño y memoria

Antes de reservar memoria, ambos programas deben comprobar la cantidad de elementos `N*N` y sus bytes `N*N*8`. Estas comprobaciones se hacen antes de realizar una multiplicación que pueda exceder los límites del entero.

Para mantener el mismo criterio en Windows de 64 bits, propongo que ambos tamaños quepan en un entero con signo de 64 bits: como máximo `9223372036854775807`. Go ya aplica ese criterio mediante `ValidateDimension`; C debe aplicar el mismo límite, aunque use `size_t` para reservar memoria.

Con valores de 8 bytes, el mayor N que pasa esta comprobación es `1073741823`. `N=1073741824` se rechaza porque sus bytes ya exceden el límite. Estos casos se comprueban solo mediante aritmética: no se intenta reservar una matriz de ese tamaño para probarlos.

Este límite solo comprueba que el tamaño se pueda representar. No significa que haya suficiente RAM para guardar las matrices. La implementación también deberá considerar los buffers de A, B y C. En C, si una reserva falla, se informa el error y se libera la memoria que ya se hubiera reservado.

## 3. Argumentos del programa

Estas reglas corresponden al programa completo que se integrará en Sprint 3. Actualmente, los ejecutables solo aceptan `--smoke-test`.

| Forma de uso | Regla |
| --- | --- |
| `--n N --seed SEED` | Ambos argumentos son obligatorios para generar matrices. N debe cumplir las comprobaciones de tamaño. |
| `--seed SEED` | Entero entre 0 y 4294967295, incluidos ambos extremos. Rechazar negativos, valores fuera de rango y texto que no sea un entero. |
| `--input archivo` | El tamaño y los datos se obtienen del archivo. No se combina con `--n` ni `--seed`. |
| `--output archivo` | Permite guardar el resultado de un caso pequeño en el formato común. |
| `--smoke-test` | Se utiliza solo para comprobar la instalación. No se combina con argumentos de cálculo. |
| Argumentos incorrectos | Rechazar valores faltantes, opciones desconocidas y combinaciones inválidas. |

Los valores de `--n` y `--seed` se escriben en decimal, usando solo dígitos del 0 al 9. Se permiten ceros al inicio; no se permiten signos, decimales ni notación científica. Los argumentos pueden ir en cualquier orden, pero una opción repetida se rechaza. Si N es 0, se informa tamaño inválido; la semilla 0 sí es válida.

El formato de los archivos está definido en [formato_datos.md](formato_datos.md): la entrada contiene N, las filas de A y las filas de B; la salida contiene N y las filas de C. Deben rechazarse archivos con valores faltantes o sobrantes.

La generación debe seguir la misma regla determinista de [contrato.md](contrato.md): con el mismo N y la misma semilla, C y Go deben producir las mismas matrices. Usar la misma semilla con generadores diferentes no garantiza esa igualdad.

## 4. Errores y resultados

Propongo comprobar primero A, luego B y después que sus tamaños coincidan. En cada matriz se revisa el tamaño, la cantidad de datos y finalmente los valores. Se informa el primer problema encontrado.

| Problema | Error disponible en Go | Qué debe detectar C |
| --- | --- | --- |
| N es cero o negativo | `ErrInvalidDimension` | Tamaño inválido. |
| La cantidad de elementos o sus bytes excede los límites | `ErrSizeOverflow` | Tamaño no representable. |
| Faltan o sobran valores | `ErrInvalidDataLength` | Datos incompatibles con N. |
| Hay NaN o infinito | `ErrNonFiniteValue` | Valor no permitido. |
| A y B tienen tamaños diferentes | `ErrDimensionMismatch` | Dimensiones incompatibles. |
| La operación aún no está implementada | `ErrPending` | Operación pendiente. |

C puede usar sus propios nombres y códigos internos. Las funciones devuelven el error al programa principal; el programa principal muestra el mensaje y decide el código de salida. Los mensajes deben explicar el problema, pero no necesitan tener exactamente el mismo texto en ambos lenguajes.

Si la validación falla, Go devuelve una matriz vacía y C debe devolver el error sin escribir en el buffer del resultado. Las entradas A y B permanecen intactas.

Los siguientes códigos quedan definidos en esta propuesta para los **ejecutables**, no para los códigos internos de sus funciones:

| Código | Significado |
| --- | --- |
| `0` | Operación completada correctamente. En `--smoke-test`, solo indica que la prueba de instalación pasó. |
| `1` | Entrada incorrecta, fallo de lectura/escritura, fallo controlado de memoria o problema del entorno. |
| `2` | Operación pendiente de implementación. |

Los errores se escriben en `stderr`. Una ejecución fallida no debe presentar matrices como resultados correctos ni producir mediciones válidas. Los resultados y las mediciones del programa completo usan `stdout` o el archivo de salida que corresponda.

## 5. Casos para comprobar que ambas versiones coinciden

| Caso | Resultado esperado |
| --- | --- |
| N igual a 0 o negativo | Error de tamaño. |
| N igual a 2 con 3 o 5 valores | Error de cantidad de datos. |
| A de tamaño 1 y B de tamaño 2, ambas bien formadas | Error de dimensiones diferentes. |
| Matrices con ceros o negativos | Aceptar las entradas. |
| Matriz con NaN o infinito | Rechazar la entrada. |
| Tamaño que exceda los límites | Rechazar antes de reservar memoria. |
| N igual a 1073741823 | Pasa la comprobación aritmética del tamaño; no garantiza memoria disponible. No reservar para probar este límite. |
| N igual a 1073741824 | Error de tamaño no representable, sin reservar memoria. |
| Semilla igual a 0 o 4294967295 | Aceptar la semilla. |
| Semilla negativa o mayor que 4294967295 | Rechazar antes de convertirla al tipo sin signo. |
| Datos válidos y cálculo todavía pendiente | Devolver operación pendiente y no un producto ficticio. |

Cuando el cálculo esté implementado, se comparará cada celda con el resultado esperado usando la tolerancia del contrato: `abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`.

## 6. Estado actual

En Go ya están implementadas las comprobaciones de `Matrix`, `Multiply` y el tamaño recibido por `Generate`. La multiplicación, la generación de valores y el procesamiento de argumentos siguen pendientes.

I1 debe adaptar sus interfaces a estas reglas y confirmar el resultado para registrar el acuerdo común. El programa principal de cada versión aplicará los códigos de salida cuando se integren los argumentos en Sprint 3; el ejecutable actual aún trata las solicitudes de cálculo como pendientes.
