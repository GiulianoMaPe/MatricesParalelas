# Contrato de Formato de Datos y Fixtures

## 1. Especificación del Formato (Reglas de entrada y salida)

Texto UTF-8 sin BOM, separador decimal punto, espacios entre valores; sin comentarios ni encabezados. 
* **Estructura de entrada:** Primera línea: entero positivo N. A continuación N filas de la matriz A y N filas de la matriz B, exactamente N números por fila. 
* **Salida esperada:** N seguido de N filas de la matriz C (resultado).
* **Manejo de caracteres:** Aceptar LF y CRLF, espacios/tabuladores por línea, blanco al final y ausencia de salto final; rechazar líneas vacías dentro de las matrices.
* **Validación estricta:** Rechazar valores extra, faltantes, dimensiones inválidas, NaN e infinitos. Los cuatro lectores aplican estas reglas; su integración en la CLI sigue pendiente.

## 2. Vectores de Control (Fixtures compartidos)

Actualmente existen casos de prueba preparados a mano, **no resultados producidos por los esqueletos**. Hay lectores, pruebas de entradas malformadas y el fixture impar3. El multiplicador, el comparador y las pruebas de particiones ejecutables siguen pendientes.

**Ejemplo de entrada:** `tests/fixtures/producto2.input.txt`:

    2
    1 2
    3 4
    5 6
    7 8

**Ejemplo de salida esperada:** `tests/fixtures/producto2.expected.txt` contiene en tres líneas:

    2
    19 22
    43 50

*(Nota: También hay casos `escalar` negativo (N=1), `identidad`, `cero` e `impar3`).*

---

## 3. Sprint 1: Matriz de diferencias de la base recibida

Esta tabla conserva la fotografía histórica de la base recibida en S1. No describe el código actual: posteriormente se implementaron los generadores y lectores. El contrato vigente es la sección 4 y `docs/contrato.md`.

| Criterio | Implementación en C | Implementación en Go | Discrepancia / Problema detectado |
| :--- | :--- | :--- | :--- |
| **Lectura de Dimensiones** | No lee dimensiones. `input_generate` recibe `n` como parámetro, pero devuelve `MATRIX_PENDING` sin usarlo. | No lee dimensiones. `Generate` recibe `n` como parámetro, pero devuelve `ErrPending`. | Ninguna implementación lee dimensiones desde un archivo ni valida el valor de `N`. El formato de lectura aún está pendiente. |
| **Formato y Delimitadores** | No hay parser de archivos implementado. | No hay parser de archivos implementado. | No se puede comparar el comportamiento de lectura. El formato textual de *fixtures* está especificado en la documentación, pero los programas aún no lo procesan. |
| **Generación (Semilla/Random)** | La interfaz usa `uint32_t seed`, pero `input_generate` devuelve `MATRIX_PENDING`; no genera valores. | `Generate` recibe `uint32 seed`, pero devuelve `ErrPending`; no genera valores. | Los tipos de semilla tienen el mismo rango previsto, pero ninguna implementación aplica un generador. Todavía no se puede comprobar que una semilla produzca las mismas matrices en ambos lenguajes. |
| **Manejo de Errores** | La función de generación devuelve el estado pendiente `MATRIX_PENDING`. | La función de generación devuelve `ErrPending`; el ejecutable solo acepta `--smoke-test` y, para otra operación, termina con código `2` como pendiente. | Los mecanismos y mensajes son distintos por lenguaje y todavía no existe un contrato implementado para entradas inválidas, errores de archivo o dimensiones. Deben alinearse en semántica: informar el error por `stderr`, devolver un código distinto de cero y no producir una salida parcial. |


---

---

## 4. Sprint 2: Contrato definitivo de entradas

Este contrato define el comportamiento que deberán compartir las implementaciones C y Go. La especificación no implica que el código ya esté implementado o validado; el estado de implementación y las pruebas deben registrarse al cerrar el sprint.

### 4.1 Matrices y representación

- Las entradas son dos matrices densas cuadradas A y B, ambas de dimensión `N × N`, con `N > 0`.
- Los elementos se representan como `double` en C y `float64` en Go.
- Los elementos se ordenan por filas. En almacenamiento contiguo, la posición `i*N+j` corresponde a la fila `i` y columna `j`, con índices internos desde cero.
- Antes de reservar memoria o calcular índices, validar que `N*N` y sus bytes caben en el entero con signo de la plataforma (`PTRDIFF_MAX` en C e `int` en Go). MPI añade los límites de `partition.h`. La validez aritmética no garantiza RAM disponible.
- La multiplicación lee A y B sin modificarlas y produce la matriz C, también de dimensión `N × N`.

### 4.2 Entrada desde archivo

El archivo es texto UTF-8 sin BOM, sin encabezados ni comentarios. Se aceptan
LF y CRLF, incluso mezclados; un CR aislado no es un salto válido.

- La primera línea contiene únicamente `N`, un entero decimal positivo sin signo.
- Siguen exactamente N líneas de A y N líneas de B, con exactamente N valores por línea.
- Los tokens de una línea se separan por uno o más espacios o tabuladores ASCII.
  Se permiten espacios/tabuladores iniciales y finales.
- No se permiten líneas vacías dentro de las matrices ni datos de dos filas en una
  misma línea. N debe ocupar su propia línea. Las líneas vacías o de blanco solo
  se permiten después de la última fila; el salto de línea final es opcional.
- Los valores usan punto decimal y signo opcional. Se aceptan enteros, decimales
  y notación científica decimal; no hexadecimal, NaN, infinito ni comentarios.
- La conversión a double/float64 debe dar un valor finito. Se aceptan subnormales
  y underflow redondeado a cero; overflow a infinito se rechaza en ambos lenguajes.
- Rechazar archivo vacío, BOM, caracteres ajenos a la gramática (incluido NUL),
  dimensión inválida/no representable, filas incompletas, valores extra o faltantes
  y fallos de lectura. Los lectores devuelven el error sin matrices parciales.
- Los códigos del ejecutable son los del contrato común: 0 éxito, 1 error y
  2 pendiente. Los errores internos del lector siempre se convierten a 1.


Ejemplo válido:

```text
2
1 2
3 4
5 6
7 8
```

Este ejemplo corresponde a A = `[[1, 2], [3, 4]]` y B = `[[5, 6], [7, 8]]`.

### 4.3 Entrada generada y semilla

El modo generado recibe `--n N --seed S`.

- `N` es un entero decimal positivo y debe respetar los límites de tamaño de la sección 4.1.
- `S` es un entero decimal sin signo de 32 bits, entre `0` y `4294967295`, ambos inclusive.
- Rechazar semilla negativa, fraccionaria, no numérica o fuera de rango.
- No usar `rand()` de C ni `math/rand` de Go. Ambos lenguajes deben implementar el algoritmo definido en la sección 4.4.

El modo de archivo usa `--input archivo`; en ese modo `N` se obtiene del archivo y `--input` no se combina con `--n` ni con `--seed`.

### 4.4 Generador determinista

Usar un estado de 32 bits sin signo y aritmética módulo `2^32`.

```text
state = seed
state = (1664525 * state + 1013904223) mod 2^32
value = (int64(state mod 2001) - 1000) / 1000.0
```

Actualizar el estado antes de producir cada valor. El residuo se convierte a entero con signo antes de restar `1000`.

- En C, usar `uint32_t` y operaciones unsigned para que el desbordamiento equivalga al módulo `2^32`.
- En Go, usar `uint32`; el wraparound de la aritmética unsigned produce el mismo módulo.
- Generar primero todos los elementos de A por filas y después todos los elementos de B por filas.
- Mantener el estado entre A y B; no reiniciarlo al comenzar B.
- Los valores generados pertenecen al rango `[-1.000, 1.000]`, en incrementos de `0.001`.

### 4.5 Vectores de control obligatorios

Con `seed = 42`, los primeros ocho estados, después de actualizar el generador para cada elemento, son:

```text
1083814273
378494188
2479403867
955863294
1613448261
110225632
1921058495
508781842
```

Para `N = 2` y `seed = 42`, los primeros cuatro valores forman A y los siguientes cuatro forman B:

```text
A:
-0.363   0.036
-0.215   0.602

B:
 0.941  -0.453
-0.554   0.579
```

El producto esperado A × B es:

```text
C:
-0.361527   0.185283
-0.535823   0.445953
```

C y Go deben reproducir los estados y valores de A y B en el orden indicado. El producto verifica además la multiplicación y la salida, cuando esas funciones estén implementadas.

### 4.6 Formato de salida

La salida de una matriz usa texto UTF-8 sin encabezados ni comentarios: `N` en la primera línea, seguido por `N` filas con `N` valores por fila. Los valores se separan por espacios y usan punto decimal.

Para conservar la precisión, imprimir cada valor con una representación decimal que permita recuperarlo como el mismo valor `float64`/`double` al volver a leerlo. El escritor usa LF; el lector acepta también CRLF. El salto final no es obligatorio. La misma gramática de líneas se aplica a C: primera línea N y exactamente N filas de resultado.

Los mensajes de error y diagnósticos van a `stderr`. En caso de error, la ejecución termina con código 1 (2 solo si la operación está pendiente) y no presenta una matriz parcial como resultado válido. Si se escribe a un archivo de salida, un fallo no debe dejar un archivo que parezca un resultado completo.

### 4.7 Comparación de resultados

Comparar todos los elementos de la matriz; un checksum no sustituye la comparación elemento a elemento. Para cada valor esperado `e` y obtenido `x`, aceptar solo si:

```text
abs(x - e) <= 1e-9 + 1e-9 * abs(e)
```

NaN e infinitos siempre son fallo.

### 4.8 Casos mínimos de verificación

Ambas implementaciones deben cubrir los siguientes casos:

- Generador: `N=2, seed=42`, contrastando estados y matrices con la sección 4.5.
- Semillas límite aceptadas: `0` y `4294967295`.
- Semillas inválidas rechazadas: `-1` y `4294967296`.
- Dimensiones: `N=1` y `N=2` aceptadas; `N=0`, dimensión negativa y entrada no entera rechazadas.
- Fixtures existentes: `producto2`, `escalar`, `identidad`, `cero` e `impar3`, comparados con sus resultados esperados.
- Lectura: aceptar fixture con LF y CRLF, con o sin espacios finales y con o sin salto de línea al final.
- Entradas malformadas: archivo vacío, dimensión inválida, valor faltante/extra, filas fusionadas o divididas, línea interna vacía, BOM, NUL, CR aislado, token no numérico, NaN, infinito y archivo ilegible.

### 4.9 Criterios de aceptación del entregable

El contrato de Sprint 2 se considera listo cuando:

1. Las reglas de entrada, generación, salida, errores y comparación están documentadas sin ambigüedades.
2. Los vectores de control tienen un resultado esperado explícito y compartido por C y Go.
3. Las implementaciones C y Go producen las mismas matrices A y B para el vector de control.
4. Los lectores y generadores ejecutan los fixtures/casos de error en ambos lenguajes y los resultados quedan registrados. La comparación de productos corresponde a S3, cuando exista el multiplicador.
5. Una revisión cruzada confirma que ambos lenguajes siguen este mismo contrato.

**Verificación técnica del ajuste (2026-10-01):** la batería disponible de los cuatro módulos pasó en Debug, incluidos vectores del generador y los nuevos casos del formato por líneas. La evidencia se registra en `docs/sprints/sprint-02.md`, apartado «Unificación técnica del contrato». Las evaluaciones asistidas de I5 a I6 y el cierre documental están registrados en [S1](sprints/sprint-01.md) y [S2](sprints/sprint-02.md). La validación de productos se realizará al implementar el cálculo.
