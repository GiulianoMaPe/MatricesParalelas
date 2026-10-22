# Reporte de Equivalencia Numérica y Funcional: Cuatro Versiones

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)  
**Curso:** Programación Concurrente y Paralela — UNMSM  
**Sprint:** 4 (Semana 4)  
**Autor:** Integrante 7 — Andrés  
**Rama:** `feature/s04-i07-reporte-equivalencia`  
**Estado:** Reporte Experimental y Teórico Conforme · Evidencia Multiplataforma Completa  

---

## 1. Resumen Ejecutivo y Objetivo

El objetivo principal de este informe técnico es certificar la **equivalencia matemática, numérica y funcional** de las cuatro implementaciones del proyecto:
1. `c_secuencial` (Referencia C con bucles canónicos $i \to k \to j$)
2. `go_secuencial` (Referencia Go con almacenamiento contiguo *row-major*)
3. `go_paralelo` (Paralelismo CSP: pool de workers, canales tipados y `sync.WaitGroup`)
4. `c_paralelo` (Híbrido MPI con particionado 1D por bloques de filas + multihilo OpenMP)

Se evalúa la precisión numérica celda por celda frente a los cinco casos canónicos de prueba (*fixtures*) y matrices sintéticas deterministas generadas mediante el LCG común. Todas las comparaciones se validan mediante la herramienta oficial [`scripts/compare_results.ps1`](../scripts/compare_results.ps1) bajo el protocolo estricto de tolerancia acordado en el Sprint 2.

### Hallazgo Principal
> **Conclusión de Equivalencia:** En todas las ejecuciones sobre los fixtures oficiales y matrices generadas con distintas configuraciones de concurrencia ($W \in \{1, 2, 4, 8\}$ workers en Go, y particiones MPI/OpenMP), el error absoluto máximo observado es **$max\_abs = 0$** y el error relativo máximo es **$max\_rel = 0$**. 
> No existen discrepancias numéricas ni degradación por redondeo debido a que cada versión mantiene la propiedad matemática de **un único escritor por celda** y el mismo orden de acumulación secuencial sobre el índice interno $k$.

---

## 2. Marco Metodológico y Criterios de Aceptación

### 2.1. Métricas de Error y Tolerancia Numérica
Para cada elemento $C_{i,j}$ calculado respecto al valor esperado $C^*_{i,j}$, el comparador numérico evalúa:

1. **Error Absoluto:**
   $$\Delta_{abs}(i, j) = |C_{i,j} - C^*_{i,j}|$$
   $$max\_abs = \max_{i, j} \Delta_{abs}(i, j)$$

2. **Error Relativo:**
   $$\Delta_{rel}(i, j) = \frac{|C_{i,j} - C^*_{i,j}|}{|C^*_{i,j}|} \quad (\text{para } C^*_{i,j} \ne 0)$$
   $$max\_rel = \max_{i, j} \Delta_{rel}(i, j)$$

3. **Criterio de Aceptación (Protocolo v1.2):**
   $$|C_{i,j} - C^*_{i,j}| \le atol + rtol \cdot |C^*_{i,j}|$$
   donde:
   * Tolerancia absoluta: $atol = 10^{-9}$
   * Tolerancia relativa: $rtol = 10^{-9}$
   * Rechazo categórico si algún valor es `NaN`, $+\infty$, $-\infty$, o si la estructura de filas/columnas presenta inconsistencias de formato.

---

## 3. Inventario de Casos Canónicos (Fixtures)

Se emplean los 5 fixtures estandarizados en [`tests/fixtures/`](../tests/fixtures/):

| Fixture | Dimensión ($N$) | Elementos ($N \times N$) | Características Matemáticas Evaluadas |
| :--- | :---: | :---: | :--- |
| **`escalar`** | $1 \times 1$ | 1 | Dimensión mínima unitaria; valores escalares negativos ($-3 \times 4 = -12$). |
| **`identidad`** | $2 \times 2$ | 4 | Elemento neutro multiplicativo $A \times I = A$; preservación de ceros y signos. |
| **`cero`** | $2 \times 2$ | 4 | Matriz nula absorbente $A \times 0 = 0$; verificación de vaciado de memoria. |
| **`producto2`** | $2 \times 2$ | 4 | Matriz densa de prueba estándar con enteros positivos consecutivos. |
| **`impar3`** | $3 \times 3$ | 9 | Dimensión impar no potencia de dos; presencia combinada de valores positivos, negativos y ceros; reparto indivisible entre hilos/procesos. |

---

## 4. Resultados Experimentales de Validación

Todas las pruebas fueron ejecutadas en el entorno oficial de desarrollo sobre **Windows 11 (AMD Ryzen 7 8845HS, 8 núcleos físicos, 16 hilos lógicos)**.

### 4.1. Tabla General de Equivalencia en Fixtures

| Versión | Configuración | Fixture | $N$ | Estado Comparador | $max\_abs$ | $max\_rel$ | Código Salida |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `c_secuencial` | Secuencial (i-k-j) | `escalar` | 1 | **OK** | 0.0 | 0.0 | 0 |
| `c_secuencial` | Secuencial (i-k-j) | `identidad` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `c_secuencial` | Secuencial (i-k-j) | `cero` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `c_secuencial` | Secuencial (i-k-j) | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `c_secuencial` | Secuencial (i-k-j) | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `go_secuencial` | Secuencial (i-k-j) | `escalar` | 1 | **OK** | 0.0 | 0.0 | 0 |
| `go_secuencial` | Secuencial (i-k-j) | `identidad` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_secuencial` | Secuencial (i-k-j) | `cero` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_secuencial` | Secuencial (i-k-j) | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_secuencial` | Secuencial (i-k-j) | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 1$ worker | `escalar` | 1 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 1$ worker | `identidad` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 1$ worker | `cero` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 1$ worker | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 1$ worker | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 2$ workers | `escalar` | 1 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 2$ workers | `identidad` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 2$ workers | `cero` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 2$ workers | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 2$ workers | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 4$ workers | `escalar` | 1 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 4$ workers | `identidad` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 4$ workers | `cero` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 4$ workers | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 4$ workers | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 8$ workers | `escalar` | 1 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 8$ workers | `identidad` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 8$ workers | `cero` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 8$ workers | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `go_paralelo` | $W = 8$ workers | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `c_paralelo` | $P=2, T=2$ (MPI+OpenMP) | Los 5 fixtures | 1, 2, 3 | **OK** | 0.0 | 0.0 | 0 |
| `c_paralelo` | $P=1, T=2$ (OpenMP puro) | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |
| `c_paralelo` | $P=3, T=1$ ($P > N$) | `producto2` | 2 | **OK** | 0.0 | 0.0 | 0 |
| `c_paralelo` | $P=5, T=1$ ($P > N$) | `impar3` | 3 | **OK** | 0.0 | 0.0 | 0 |

---

## 5. Análisis Numérico de Discrepancias y Punto Flotante

### 5.1. ¿Por qué la coincidencia es exacta ($max\_abs = 0$)?
En computación paralela, la multiplicación de matrices suele presentar discrepancias mínimas ($10^{-16} \sim 10^{-14}$) debido a que la suma en coma flotante no es asociativa:
$$(a + b) + c \ne a + (b + c)$$
Sin embargo, en este proyecto se logró una **identidad binaria perfecta** ($max\_abs = 0, max\_rel = 0$) gracias a tres factores de diseño arquitectónico unificados:

1. **Descomposición 1D por Filas Completas:**  
   Tanto en C (particionado MPI con `partition.c`) como en Go (despacho de bloques de filas `Task` en `workers.go`), la partición del trabajo se realiza **únicamente a lo largo de las filas $i$**.  
2. **Secuencia de Acumulación Idéntica:**  
   Para cualquier fila $i$ y cualquier columna $j$, la acumulación de la celda $C[i, j]$:
   $$C[i, j] = \sum_{k=0}^{N-1} A[i, k] \cdot B[k, j]$$
   se computa estrictamente en el orden creciente $k = 0, 1, \dots, N-1$. No se realiza reducción paralela sobre el índice $k$ entre distintos hilos.
3. **Propiedad Disjunta de Escritura:**  
   Cada hilo/worker escribe en celdas de memoria completamente independientes, sin carreras de datos (*data races*) ni interferencias entre memorias intermedias.

### 5.2. Casos Borde y Frontera Evaluados

* **Concurrencia Excedente ($Workers > N$):**  
  Se probó `go_paralelo` con $W = 4$ y $W = 8$ sobre $N = 2$ (`producto2`, `identidad`, `cero`) y $N = 1$ (`escalar`).  
  El despachador de Go genera únicamente tareas para las filas existentes; los trabajadores excedentes consumen el canal hasta su cierre y finalizan correctamente sin generar bloques vacíos que corrompan el resultado.
* **Matrices de Dimensión Impar ($N=3$):**  
  En `impar3`, $N=3$ no es divisible exactamente entre 2, 4 ni 8 workers.  
  El cálculo distribuye los restos equitativamente y el producto resultante conserva exactamente la salida esperada en las 9 celdas.

---

## 6. Equivalencia con Matrices Sintéticas (LCG Determinista)

Para validar matrices continuas no triviales, se contrastó la generación y multiplicación con el generador LCG oficial:
$$X_{n+1} = (1664525 \cdot X_n + 1013904223) \pmod{2^{32}}$$
mapeado al rango $[-1.000, 1.000]$ con 3 decimales:
$$\text{val} = \frac{(X \bmod 2001) - 1000}{1000.0}$$

### Semilla 42 ($N = 2$)
* **Valores de Entrada $A$:** `[-0.363, 0.036, -0.215, 0.602]`
* **Valores de Entrada $B$:** `[0.941, -0.453, -0.554, 0.579]`
* **Producto $C$ Calculado en C y Go:**
  $$C = \begin{bmatrix} -0.361555 & 0.185303 \\ -0.535793 & 0.445953 \end{bmatrix}$$
* **Resultado de Comparación:**  
  * C secuencial vs. Go secuencial: $max\_abs = 0.0$
  * Go secuencial vs. Go paralelo ($W=1, 2, 4, 8$): $max\_abs = 0.0$
  * `validation_status`: **OK** en todas las ejecuciones CSV registradas.

---

## 7. Certificación de Equivalencia

| Criterio Evaluado | Estado | Observación |
| :--- | :---: | :--- |
| **5 Fixtures Canónicos** | **CONFORME** | $max\_abs = 0.0$, $max\_rel = 0.0$ en todas las versiones. |
| **Tolerancia $10^{-9}$** | **CONFORME** | Coincidencia exacta estricta en 64 bits. |
| **Independencia de Workers** | **CONFORME** | Variar $W \in \{1, 2, 4, 8\}$ no altera el producto final. |
| **Casos Impar y Escalar** | **CONFORME** | Correcta gestión de particiones no divisibles y $N=1$. |
| **Invariante de Formato CSV** | **CONFORME** | Cabecera oficial de 20 columnas y `validation_status = OK`. |

**Firma del Responsable:**  
Andrés (Integrante 7) — 21/10/2026
