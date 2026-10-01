# Contrato de Formato de Datos y Fixtures

## 1. Especificación del Formato (Reglas de entrada y salida)

Texto UTF-8 sin BOM, separador decimal punto, espacios entre valores; sin comentarios ni encabezados. 
* **Estructura de entrada:** Primera línea: entero positivo N. A continuación N filas de la matriz A y N filas de la matriz B, exactamente N números por fila. 
* **Salida esperada:** N seguido de N filas de la matriz C (resultado).
* **Manejo de caracteres:** Aceptar LF y CRLF, espacios finales y salto de línea final. 
* **Validación estricta:** Rechazar valores extra, faltantes, dimensiones inválidas, NaN e infinitos. (El lector aún no está implementado).

## 2. Vectores de Control (Fixtures compartidos)

Actualmente existen casos de prueba preparados a mano, **no resultados producidos por los esqueletos**. Faltan el lector, el comparador, N impar, pruebas de error y particiones no divisibles.

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

*(Nota: También hay casos `escalar` negativo (N=1), `identidad` y `cero`).*

---

## 3. Sprint 1: Matriz de Diferencias (Estado Actual del Código)

Esta tabla documenta el estado actual y las discrepancias detectadas entre las implementaciones de C y Go durante la fase de auditoría. Se observa que ambas implementaciones se encuentran en un estado base (*stub*), pendientes de desarrollo de lógica capaz de procesar el formato arriba mencionado.

| Criterio | Implementación en C | Implementación en Go | Discrepancia / Problema detectado |
| :--- | :--- | :--- | :--- |
| **Lectura de Dimensiones** | No lee dimensiones. `input_generate` recibe `n` como parámetro, pero devuelve `MATRIX_PENDING` sin usarlo. | No lee dimensiones. `Generate` recibe `n` como parámetro, pero devuelve `ErrPending`. | Ninguna implementación lee dimensiones desde un archivo ni valida el valor de `N`. El formato de lectura aún está pendiente. |
| **Formato y Delimitadores** | No hay parser de archivos implementado. | No hay parser de archivos implementado. | No se puede comparar el comportamiento de lectura. El formato textual de *fixtures* está especificado en la documentación, pero los programas aún no lo procesan. |
| **Generación (Semilla/Random)** | La interfaz usa `uint32_t seed`, pero `input_generate` devuelve `MATRIX_PENDING`; no genera valores. | `Generate` recibe `uint32 seed`, pero devuelve `ErrPending`; no genera valores. | Los tipos de semilla tienen el mismo rango previsto, pero ninguna implementación aplica un generador. Todavía no se puede comprobar que una semilla produzca las mismas matrices en ambos lenguajes. |
| **Manejo de Errores** | La función de generación devuelve el estado pendiente `MATRIX_PENDING`. | La función de generación devuelve `ErrPending`; el ejecutable solo acepta `--smoke-test` y, para otra operación, termina con código `2` como pendiente. | Los mecanismos y mensajes son distintos por lenguaje y todavía no existe un contrato implementado para entradas inválidas, errores de archivo o dimensiones. Deben alinearse en semántica: informar el error por `stderr`, devolver un código distinto de cero y no producir una salida parcial. |
