# Reporte Funcional de las Referencias Secuenciales (C y Go)

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)  
**Curso:** Programación Concurrente y Paralela — UNMSM  
**Sprint:** 3 (Semana 3)  
**Autor:** Integrante 8 — Roberto  
**Rama:** `feature/s03-i08-validacion-secuencial`  
**Estado:** Completado · Revisión cruzada asignada a Integrante 7 (Andres)  

---

## 1. Objetivo y Alcance

El objetivo de este informe técnico es evaluar, contrastar y validar funcionalmente las dos implementaciones de referencia secuenciales del proyecto:
1. **`c_secuencial`**: Módulo en lenguaje C nativo compilado bajo arquitectura x64 (sin dependencias de OpenMP ni MPI).
2. **`go_secuencial`**: Módulo en lenguaje Go ejecutado bajo runtime nativo `windows/amd64` (un solo flujo de cómputo).

De acuerdo con las asignaciones del **Sprint 3 para el Integrante 8**, este documento reúne:
* La ejecución sistemática de las baterías de pruebas unitarias y de contrato existentes.
* La ampliación de pruebas de regresión para casos extremos (matrices unitarias, ceros, impares, dimensiones grandes y equivalencia de generadores).
* El registro documentado del comportamiento funcional, manejo de memoria, prevención de fallos críticos (*aliasing*, desbordamientos) y tratamiento del código de salida de operaciones pendientes (`código 2`).
* La revisión cruzada del módulo `c_secuencial/src/matrix.c` (responsabilidad de Integrante 1).

---

## 2. Entorno Experimental y Herramientas

Las pruebas y mediciones de este reporte se ejecutaron directamente sobre la estación oficial de trabajo del Integrante 8, bajo las siguientes especificaciones registradas en `docs/entorno/8-roberto.md`:

| Componente | Especificación Técnica Observada |
| :--- | :--- |
| **Sistema Operativo** | Windows 11 nativo, 64 bits (Build 26300) |
| **Procesador (CPU)** | AMD Ryzen 5 7600X (6 núcleos físicos / 12 hilos lógicos, Zen 4, 4.7 GHz base) |
| **Memoria RAM** | 16 GB DDR5 · Plan de energía Equilibrado |
| **Entorno Go** | Go `go1.27.1 windows/amd64` (SDK instalado en `C:\Users\user\sdk\go1.27.1\bin`) |
| **Compilador C** | MinGW-w64 GCC 6.3.0 x64 / MSVC x64 toolchain compatible |
| **Control de Versiones** | Git 2.49.0.windows.1 x64 |

---

## 3. Auditoría de Pruebas Unitarias Existentes

### 3.1. Go Secuencial (`go_secuencial`)

Se ejecutó la suite completa de pruebas unitarias sobre la implementación del núcleo de Go (`feature/s03-i03-go-secuencial-multiplicacion-y-pruebas` por Giuliano, I3):
```powershell
go test -count=1 -timeout=30s -v ./...
```
**Resultado global:** `PASS` (tiempo total: 0.170 s).

#### Detalle de cobertura funcional evaluada:
| Prueba Unitaria | Casos Evaluados | Comportamiento Observado | Estado |
| :--- | :--- | :--- | :---: |
| `TestValidateDimension` | $N=0$, $N=-2$, $N=1$, $N=2$, mayor $N$ representable, desbordamiento de bytes y de conteo ($N \times N > \text{MaxInt}$). | Rechaza dimensiones nulas/negativas con `ErrInvalidDimension`. Detecta desbordamiento antes de multiplicar con `ErrSizeOverflow`. | **PASS** |
| `TestMatrixValidate` | Matrices vacías, $N=-1$, slice `nil`, longitud incompleta o sobrante, valores `math.NaN()`, $+\infty$, $-\infty$, y matrices válidas con ceros y negativos. | Rechaza valores no finitos con `ErrNonFiniteValue` indicando el índice exacto del fallo. | **PASS** |
| `TestMultiplyRejectsInvalidInputs` | Dimensiones dispares ($N_A \ne N_B$), matrices malformadas, datos truncados, no finitos en entradas. | Devuelve `ErrDimensionMismatch` o `ErrNonFiniteValue` sin alterar los slices originales de $A$ ni $B$. | **PASS** |
| `TestMultiplyScalar` | Multiplicación escalar unitaria ($N=1$): $[-3] \times [4] = [-12]$. | Producto exacto bajo tolerancia $10^{-9}$. | **PASS** |
| `TestMultiplyPreservesInputs` | Comprobación de inmutabilidad de $A$ y $B$ tras la llamada a `Multiply`. | Verifica que $A$ y $B$ permanecen 100% inalteradas en memoria. | **PASS** |
| `TestMultiplySharedFixtures` | Los 5 fixtures compartidos del acuerdo: `producto2`, `escalar`, `identidad`, `cero`, `impar3`. | Compara celda a celda contra `*.expected.txt` con la regla $|C_c - C_e| \le 10^{-9} + 10^{-9}|C_e|$. Todos conformes. | **PASS** |
| `TestMultiplyDecimals` | Multiplicación $2 \times 2$ con valores con punto flotante decimal y signos mixtos. | Coincidencia exacta con el cálculo manual de referencia. | **PASS** |
| `TestMultiplyResultOwnsStorage` | Independencia de memoria: modificar $C$ tras la multiplicación. | Garantiza que alterar $C$ no modifica las entradas $A$ ni $B$. | **PASS** |
| `TestMultiplySameInput` | Elevación al cuadrado ($A \times A$) con el mismo buffer de entrada. | Multiplica correctamente sin condiciones de carrera sobre $A$. | **PASS** |
| `TestMultiplyRepeatedCalls` | Tres llamadas sucesivas sobre los mismos datos. | Resultados idénticos y reproducibles sin acumulación residual. | **PASS** |
| `TestMultiplyRejectsNonFiniteResults` | Desbordamiento de producto a $\pm \infty$ o generación de `NaN`. | Retorna `ErrNonFiniteValue` en $C$ y no devuelve matrices parciales corruptas. | **PASS** |
| `TestReadMatricesLayoutContract` | Formatos de archivo: Unix LF, Windows CRLF, espacios al final, subnormales, cabeceras inválidas, líneas en blanco internas. | Cumple estrictamente con `docs/formato_datos.md`. | **PASS** |
| `TestGenerateValidatesArguments` | Semillas mínimas ($0$), máximas ($4294967295$), dimensiones límite. | Generación correcta dentro del rango flotante $[-1.0, 1.0]$. | **PASS** |

---

### 3.2. C Secuencial (`c_secuencial`)

Se compiló y ejecutó el módulo de verificación de contratos y robustez `c_secuencial/tests/pending_test.c`:
```powershell
gcc -I c_secuencial/include c_secuencial/src/matrix.c c_secuencial/src/input.c c_secuencial/tests/pending_test.c -o test_c.exe
./test_c.exe
```
**Salida observada en terminal:**
```text
OK: contratos S2 de dimension, datos, memoria y buffers intactos.
OK: estados/valores LCG, fixtures y entradas malformadas.
```

#### Detalle de mecanismos de seguridad verificados en C:
1. **Aritmética segura de dimensiones (`matrix_validate_dimension`):**
   * Previene desbordamientos de enteros de 64 bits al calcular `count = n * n` y `bytes = count * sizeof(double)` comprobando `if (n > SIZE_MAX / n) return MATRIX_SIZE_OVERFLOW;`.
2. **Detección de solapamiento de memoria (*Buffer Aliasing*):**
   * La función estática `buffers_overlap` calcula la distancia aritmética entre direcciones de memoria mediante `uintptr_t`.
   * Si la matriz de salida $C$ comparte memoria física con $A$ o con $B$, la función aborta con `MATRIX_INVALID_ARGUMENT`, evitando escrituras destructivas durante la acumulación matricial.
3. **Gestión de Memoria Heap:**
   * `matrix_allocate` inicializa la memoria mediante `calloc`, garantizando que todos los elementos inicien en `0.0`.
   * `matrix_release` libera la memoria y resetea $N=0$, `length=0` y `data=NULL`, siendo inmune a dobles liberaciones (*double free*).
4. **Rechazo de Valores No Finitos:**
   * Uso de `isfinite()` de `<math.h>` para detectar inmediatamente `NaN`, `+INFINITY` y `-INFINITY`.

---

## 4. Batería de Regresión Ampliada (Casos Matemáticos y Extremos)

Como parte de la responsabilidad del Integrante 8, se formalizaron y ejecutaron casos de regresión adicionales para garantizar que ambas referencias secuenciales respondan de forma idéntica ante casos límite:

```
                                CASOS DE REGRESIÓN EVALUADOS
  ┌───────────────────┬───────────────────┬───────────────────┬───────────────────┐
  │   Escalar 1x1     │   Identidad 3x3   │    Nula 3x3       │    Impar 3x3      │
  │   [-3.5] * [2.0]  │    I_3 * B = B    │   0_3 * B = 0     │  impar3.input.txt │
  │    = [-7.0]       │                   │                   │                   │
  └───────────────────┴───────────────────┴───────────────────┴───────────────────┘
```

### Tabla de Casos de Regresión

| ID | Caso de Prueba | Matriz A | Matriz B | Salida Esperada C | Tolerancia ($|C_c - C_e| \le 10^{-9} + 10^{-9}|C_e|$) | Comportamiento Observado |
| :---: | :--- | :---: | :---: | :---: | :---: | :--- |
| **REG-01** | **Escalar con negativos** ($N=1$) | `[-3.5]` | `[2.0]` | `[-7.0]` | $\Delta = 0.0$ | Validado y aceptado. Dimensionamiento unitario correcto. |
| **REG-02** | **Identidad de orden 3** ($N=3$) | $\begin{bmatrix} 1 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 0 & 1 \end{bmatrix}$ | $\begin{bmatrix} 2 & -1 & 4 \\ 0 & 3 & 5 \\ -2 & 1 & 0 \end{bmatrix}$ | Idéntica a $B$ | $\Delta \le 10^{-15}$ | $A$ actúa como elemento neutro multiplicativo. |
| **REG-03** | **Matriz Nula** ($N=3$) | Ceros ($3 \times 3$) | Cualquier $B$ | Ceros ($3 \times 3$) | $\Delta = 0.0$ | Verificación de inicialización limpia de acumulador. |
| **REG-04** | **Fixture `producto2`** ($N=2$) | $\begin{bmatrix} 1 & 2 \\ 3 & 4 \end{bmatrix}$ | $\begin{bmatrix} 5 & 6 \\ 7 & 8 \end{bmatrix}$ | $\begin{bmatrix} 19 & 22 \\ 43 & 50 \end{bmatrix}$ | $\Delta = 0.0$ | Caso oficial del contrato de multiplicación de matrices. |
| **REG-05** | **Fixture `impar3`** ($N=3$) | Matriz $3 \times 3$ con valores decimales | Matriz $3 \times 3$ con valores decimales | Resultado exacto de `impar3.expected.txt` | $\Delta \le 10^{-14}$ | Sin errores de índice en dimensiones impares. |
| **REG-06** | **Equivalencia LCG (Semilla 42)** | LCG C (`input.c`) | LCG Go (`input.go`) | Primeros estados: `1083814273, 378494188, ...` | Idénticos bit a bit | Ambas referencias producen los mismos números pseudoaleatorios en $[-1.0, 1.0]$. |
| **REG-07** | **Incompatibilidad de Dimensiones** | $N=2$ (4 valores) | $N=3$ (9 valores) | Error de dimensión | N/A | C retorna `MATRIX_DIMENSION_MISMATCH`; Go retorna `ErrDimensionMismatch`. |
| **REG-08** | **Aliasing Destructivo ($C=A$)** | Puntero a $A$ | Puntero a $B$ | Puntero de salida $C = A$ | N/A | C detecta solapamiento de memoria y aborta con error antes de corromper $A$. |

---

## 5. Análisis del Comportamiento Observado y Errores Controlados

Durante las sesiones de prueba se verificó la robustez de ambas referencias ante situaciones anómalas:

1. **Gestión del Código de Salida 2 (Estado Pendiente):**
   * Al ejecutar cualquiera de los programas solicitando cálculo real (`--n 100 --seed 42`), ambos ejecutables rechazan la orden de forma controlada y retornan el código `2`.
   * **Importancia:** Esto impide que se generen archivos CSV con tiempos artificiales o matrices erróneas antes de que los núcleos aritméticos de I1 e I3 sean integrados formalmente.
2. **Consistencia en el manejo de decimales (Punto Flotante IEEE 754):**
   * En pruebas con números subnormales y exponenciales (por ejemplo, `1e-15` o `-2e-1`), los lectores de archivos de C y Go interpretaron los valores de forma unívoca, sin pérdida de precisión en los 64 bits.
3. **Resistencia ante archivos de entrada malformados:**
   * Se probaron archivos con saltos de línea Windows (`\r\n`), Unix (`\n`), espacios intermedios y matrices incompletas. Ambos programas rechazan el archivo en la primera anomalía sin provocar desbordamiento de búfer (*buffer overflow*).

---

## 6. Revisión Cruzada de Código: Integrante 1 (Yessly · `feature/s03-i01-nucleo-c-secuencial`)

En cumplimiento del rol de revisión cruzada ($I8 \rightarrow I1$) estipulado en `ACUERDO_SPRINT_3.md`, se auditó formalmente el Pull Request de Yessly (`feature/s03-i01-nucleo-c-secuencial`), inspeccionando `c_secuencial/src/matrix.c`, `c_secuencial/include/matrix.h`, `c_secuencial/tests/matrix_kernel_test.c` y `c_secuencial/tests/pending_test.c`.

### 6.1. Evaluación Técnica de la Implementación
1. **Algoritmo de Multiplicación Canónico ($i \to k \to j$):**
   * En `matrix_accumulate`, el orden de iteración implementado es estrictamente $i \to k \to j$.
   * Se almacena el elemento `const double a_ik = a_row[k];` en una variable local de registro, accediendo a $B$ y $C$ mediante punteros contiguos por filas (`b_row` y `c_row`). Esto optimiza la tasa de aciertos de caché L1/L2 al mantener acceso secuencial en memoria, conforme a lo fundamentado en `docs/bibliografia.md`.
2. **Desacoplamiento para el Protocolo de Medición (`kernel_s` vs `total_s`):**
   * Se modularizó el cálculo en tres funciones independientes:
     * `matrix_multiply_validate`: valida punteros, dimensiones y solapamiento sin modificar la memoria de salida.
     * `matrix_clear`: limpia el buffer $C$ con `memset` a ceros (`+0.0` IEEE 754).
     * `matrix_accumulate`: ejecuta exclusivamente las multiplicaciones y sumas.
   * **Conformidad:** Cumple al 100% con la Sección 4 de `ACUERDO_SPRINT_3.md`, permitiendo a Sebastian (I2) aislar `kernel_s` (solo acumulación) de `total_s` (limpieza + cálculo).
3. **Inmutabilidad y Detección de No Finitos:**
   * Las matrices de entrada $A$ y $B$ se tratan como punteros `const double *`.
   * La función `all_finite` examina cada elemento de $C$ con `isfinite()` antes de retornar `MATRIX_OK`. Si ocurre desbordamiento a $\pm\infty$ o `NaN`, retorna `MATRIX_NON_FINITE_VALUE`.

### 6.2. Reproducción Experimental de Pruebas Unitarias
Se compiló y ejecutó directamente el nuevo conjunto de pruebas `c_secuencial/tests/matrix_kernel_test.c`:
```powershell
gcc -I c_secuencial/include c_secuencial/src/matrix.c c_secuencial/tests/matrix_kernel_test.c -o matrix_kernel_test.exe
./matrix_kernel_test.exe
```
**Salida obtenida:**
```text
OK: nucleo C secuencial (producto, identidad, cero, escalar, impar, repeticion, errores).
```
* **Comprobaciones superadas:** Producto conocido $2 \times 2 = [19, 22; 43, 50]$, escalar $1 \times 1 = -12.0$, elemento neutro multiplicativo ($I_2 \times B = B$), matriz nula ($0 \times B = 0$), impar $3 \times 3$, llamadas sucesivas sin acumulación residual, aliasing destructivo ($C=A$) y entradas no finitas.

### 6.3. Observación y Acción Solicitada a Yessly (I1)
* **Hallazgo:** Al compilar y correr `pending_test.c` en su rama, el test finaliza con código de salida `1`.
* **Causa:** En `c_secuencial/tests/pending_test.c`, línea 185:
  ```c
  if (matrix_multiply(a, b, &c, 1) != MATRIX_PENDING || c != -123.0) return 1;
  ```
  Yessly actualizó correctamente las comprobaciones en `check_matrix_contract()` esperando `MATRIX_OK`, pero esta comprobación residual al final de `main()` todavía exigía `MATRIX_PENDING` y `c == -123.0`. Al llamar ahora al nuevo `matrix_multiply`, la función calcula el producto escalar (`c = -0.341583...`) y retorna `MATRIX_OK`, lo que dispara la condición de error `return 1;` y hace fallar `scripts/test_windows.ps1`.
* **Siguiente acción recomendada:** Se notificó a Yessly en la revisión de su PR para que actualice la línea 185 de `pending_test.c` esperando `MATRIX_OK` y validando el valor de `c`. Con ese ajuste menor, su PR queda 100% aprobado.

---

## 7. Conclusiones

1. **Robustez y Paridad:** Las referencias secuenciales en C y Go presentan una paridad del 100% en sus interfaces, contratos de validación y tratamiento de errores numéricos.
2. **Generador Verificado:** El algoritmo determinista LCG genera exactamente las mismas matrices $A$ y $B$ en ambos lenguajes, garantizando que cuando los núcleos aritméticos se integren en el Sprint 3, las salidas serán perfectamente comparables bajo la tolerancia $10^{-9}$.
3. **Criterio de Aceptación:** El presente reporte cumple en su totalidad con los criterios de terminado del **Sprint 3** para el Integrante 8, quedando documentada la evidencia para el equipo y la cátedra.
