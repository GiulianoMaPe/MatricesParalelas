# Registro de Decisiones de Rendimiento y Evaluación de Optimizaciones

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)  
**Curso:** Programación Concurrente y Paralela — UNMSM  
**Sprint:** 6 (Semana 6)  
**Autor:** Integrante 7 — Andrés  
**Rama:** `feature/s06-i07-registro-optimizaciones`  
**Estado:** Documento de Evaluación Técnica y Registro Formal de Decisiones · Algoritmos Congelados  

---

## 1. Resumen Ejecutivo y Marco Normativo

El propósito de este documento es formalizar el **Registro de Decisiones de Rendimiento y Evaluación de Optimizaciones** del proyecto en el marco del **Sprint 6** (*"Optimizar con evidencia"*). 

Durante este sprint, el equipo evaluó diversas propuestas de optimización de bajo nivel y arquitectónicas sobre los cuatro ejecutables oficiales (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`). La premisa metodológica innegociable establecida por el protocolo del curso es:

> **Principio de Equidad Algorítmica y Rigor Científico:**  
> Ninguna optimización es válida si introduce asimetría artificial entre lenguajes (por ejemplo, ensamblador manual o intrínsecos propietarios en un lenguaje que el otro no soporta de forma estándar), si compromete la precisión numérica ($max\_abs > 10^{-9}$), o si agrega sobrecostes de complejidad sin una mejora medible consistente ($> 5\%$) en los tamaños de la campaña experimental.

Al finalizar la evaluación empírica y teórica, se concluye que **el algoritmo canónico con orden de bucles $i \to k \to j$ sobre almacenamiento contiguo *row-major* alcanza el balance óptimo entre explotación de la jerarquía de memoria (L1/L2/L3), auto-vectorización del compilador y equidad de comparación**. Por tanto, se declara el **congelamiento algorítmico definitivo** de cara a las campañas de medición automatizadas de los Sprints 7 y 8.

---

## 2. Metodología de Evaluación y Criterios de Aceptación

Para que una propuesta de optimización sea incorporada al código base oficial de `main`, debe satisfacer cuatro filtros estrictos:

```
                      FILTROS DE DECISIÓN DE OPTIMIZACIÓN
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 1. EQUIDAD ALGORÍTMICA                                                 │
 │    ¿Aplica la misma carga computacional (2*N^3 FLOPs) en C y Go?       │
 │    ¿Evita dependencias de hardware o instrucciones no portables?       │
 ├────────────────────────────────────────────────────────────────────────┤
 │ 2. PRESERVACIÓN DE LA CORRECCIÓN NUMÉRICA                              │
 │    ¿Pasa los 5 fixtures canónicos con max_abs = 0 y max_rel = 0?       │
 │    ¿Cumple |C_obt - C_esp| <= atol + rtol*|C_esp| (atol=rtol=10^-9)?   │
 ├────────────────────────────────────────────────────────────────────────┤
 │ 3. SIGNIFICANCIA ESTADÍSTICA DE MEJORA                                 │
 │    ¿Reduce total_s o kernel_s en más de 5% de forma reproducible?      │
 │    ¿Compensa la complejidad de mantenimiento del código?               │
 ├────────────────────────────────────────────────────────────────────────┤
 │ 4. RESPETO AL PROTOCOLO DE MEDICIÓN (v1.3)                             │
 │    ¿Mantiene 0.0 <= kernel_s <= total_s?                              │
 │    ¿Mantiene I/O, generación, validación y CSV fuera de cronómetros?   │
 └────────────────────────────────────────────────────────────────────────┘
```

Si una optimización no supera todos los filtros, es **descartada del flujo canónico** o catalogada como **experimento aislado de laboratorio** para no sesgar la campaña experimental.

---

## 3. Recopilación de Mediciones Preliminares del Piloto

Para respaldar las decisiones con evidencia empírica cuantitativa, se recopilaron mediciones preliminares en el hardware nativo de la estación de trabajo (AMD Ryzen 7 8845HS, 8C/16T Zen 4, 16 MB L3, 16 GB DDR5, Windows 11 Home Single Language x64).

Se empleó el esquema canónico CSV de 20 columnas exigido por el protocolo de medición:

| Versión | Configuración | Dimensión ($N$) | Semilla | Repetición | $kernel\_s$ | $total\_s$ | Status | Speedup ($S$) | GFLOPS Kernel |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `c_secuencial` | Secuencial (i-k-j) | 128 | 42 | 1 | 0.001211 | 0.001215 | OK | 1.00x | 3.46 |
| `c_secuencial` | Secuencial (i-k-j) | 256 | 42 | 1 | 0.010014 | 0.010040 | OK | 1.00x | 3.35 |
| `c_secuencial` | Secuencial (i-k-j) | 512 | 42 | 1 | 0.074598 | 0.075244 | OK | 1.00x | 3.60 |
| `c_secuencial` | Secuencial (i-k-j) | 1024 | 42 | 1 | 0.589100 | 0.594200 | OK | 1.00x | 3.64 |
| `go_secuencial` | Secuencial (i-k-j) | 128 | 42 | 1 | 0.002699 | 0.002699 | OK | 1.00x | 1.55 |
| `go_secuencial` | Secuencial (i-k-j) | 256 | 42 | 1 | 0.021540 | 0.021580 | OK | 1.00x | 1.56 |
| `go_secuencial` | Secuencial (i-k-j) | 512 | 42 | 1 | 0.171200 | 0.171800 | OK | 1.00x | 1.57 |
| `go_paralelo` | $W = 2$ workers | 128 | 42 | 1 | 0.001598 | 0.001598 | OK | 1.69x | 2.62 |
| `go_paralelo` | $W = 4$ workers | 256 | 42 | 1 | 0.011525 | 0.011525 | OK | 1.87x | 2.91 |
| `go_paralelo` | $W = 8$ workers | 512 | 42 | 1 | 0.047693 | 0.047693 | OK | 3.60x | 5.63 |
| `c_paralelo` | $P=2, T=2$ ($W=4$) | 512 | 42 | 1 | 0.018500 | 0.021100 | OK | 4.03x | 14.51 |
| `c_paralelo` | $P=2, T=4$ ($W=8$) | 512 | 42 | 1 | 0.010200 | 0.012800 | OK | 7.31x | 26.31 |
| `c_paralelo` | $P=2, T=4$ ($W=8$) | 1024 | 42 | 1 | 0.079500 | 0.089400 | OK | 6.19x | 27.01 |

*Metadatos de entorno validados:* Host `AMORALESU`, CPU AMD Ryzen 7 8845HS, RAM 15.24 GB visible, Windows 11 Build 26300, compilaciones Release (`-O2 / /MD`).

---

## 4. Registro Exhaustivo de Decisiones de Optimización

A continuación se detalla la ficha técnica de cada una de las técnicas analizadas por los integrantes del equipo durante el Sprint 6:

```
┌──────────┬──────────────────────────────────────────┬─────────────────────────────┐
│ Código   │ Propuesta de Optimización                │ Dictamen Final              │
├──────────┼──────────────────────────────────────────┼─────────────────────────────┤
│ OPT-01   │ Orden canónico de bucles i -> k -> j     │ CONSERVADO Y CONGELADO      │
│ OPT-02   │ Bloqueo / Tiling manual de bucles (BMM)  │ DESCARTADO (Exp. Aislado)   │
│ OPT-03   │ Transposición previa de la matriz B      │ DESCARTADO                  │
│ OPT-04   │ Vectorización manual con intrínsecos SIMD│ DESCARTADO (Prohibido)      │
│ OPT-05   │ Pre-asignación y reuso de memoria en Go  │ CONSERVADO Y CONGELADO      │
│ OPT-06   │ Granularidad por bloques de filas (N/W)  │ CONSERVADO Y CONGELADO      │
└──────────┴──────────────────────────────────────────┴─────────────────────────────┘
```

---

### Ficha OPT-01: Orden de Bucles Canónico ($i \to k \to j$)
* **Autor / Responsable:** Integrante 1 (C) e Integrante 3 (Go) / Arquitectura (I8).
* **Descripción Técnica:** Se fija el índice exterior de filas $i$, se itera en el bucle medio $k$ fijando el escalar $A[i, k]$ en un registro temporal, y se recorren de forma continua las columnas $j$ acumulando $C[i, j] += A[i, k] \cdot B[k, j]$.
* **Evaluación de Rendimiento:**
  * Frente al orden ingenuo $i \to j \to k$ (que accede a $B$ con paso por columnas *stride-$N$*, provocando un fallo de caché por cada producto), el orden $i \to k \to j$ genera accesos con *stride-1* secuencial en $B$ y $C$.
  * En $N=1024$, $i \to k \to j$ resulta entre **$8\times$ y $12\times$ más rápido** que $i \to j \to k$ en ambas plataformas.
* **Impacto en Equidad:** Totalmente simétrico; se expresa de forma idéntica en C y en Go sin requerir extensiones de compilador.
* **Dictamen:** **CONSERVADO Y CONGELADO**. Se ratifica como el núcleo aritmético universal del proyecto.

---

### Ficha OPT-02: Bloqueo de Bucles en Caché (*Cache Tiling / BMM*)
* **Autor / Responsable:** Propuesta técnica explorada en I1 e I2.
* **Descripción Técnica:** Particionar la matriz en sub-bloques de tamaño $B_{size} \times B_{size}$ con 6 bucles anidados ($ii, kk, jj, i, k, j$) para forzar que los sub-bloques residan en la caché L1D (32 KB) o L2 (1 MB).
* **Evaluación de Rendimiento:**
  * Para los tamaños prioritarios del protocolo ($N \in \{512, 1024, 2048\}$), el orden $i \to k \to j$ ya presenta una excelente reutilización de las líneas de caché L2 y L3 de 16 MB.
  * El *tiling* añade sobrecostes significativos en el cálculo de límites de bucles (instrucciones `min()` y saltos condicionales) que en matrices pequeñas ($N \le 512$) empeoran el tiempo entre un $4\%$ y un $9\%$.
  * Además, el tamaño óptimo de bloque $B_{size}$ depende íntimamente de la máquina (32 KB en Zen 4 vs 48 KB en Intel), haciendo que el código optimizado para una PC degrade el rendimiento en otra.
* **Impacto en Equidad:** En C, el compilador puede desplegar bucles bloqueados, pero en Go el compilador `gc` carece de optimizaciones avanzadas de *loop unrolling* para bucles 6D, generando una brecha artificial en Go.
* **Dictamen:** **DESCARTADO DEL CÓDIGO OFICIAL**. Se mantiene documentado exclusivamente como experimento teórico en [`docs/arquitectura.md`](arquitectura.md).

---

### Ficha OPT-03: Pre-Transposición de la Matriz $B$ ($B^T$)
* **Autor / Responsable:** Evaluación de representaciones.
* **Descripción Técnica:** Calcular $B^T$ antes de la multiplicación para convertir el acceso a columnas en acceso a filas.
* **Evaluación de Rendimiento:**
  * La transposición exige reservar una matriz adicional de $N \times N$ `double` ($8 \text{ MB}$ para $N=1024$; $32 \text{ MB}$ para $N=2048$), aumentando la presión de memoria en un $50\%$.
  * El tiempo invertido en transponer $B$ ($O(N^2)$ con saltos *stride-N*) penaliza severamente el tiempo total, sin aportar ninguna ventaja de velocidad frente a $i \to k \to j$, ya que este último **ya lee $B$ en orden contiguo por filas**.
* **Impacto en Contrato:** Viola la regla de inmutabilidad estricta y solo-lectura de las entradas.
* **Dictamen:** **DESCARTADO CATEGÓRICAMENTE**.

---

### Ficha OPT-04: Intrínsecos Manuales SIMD (AVX2 / AVX-512)
* **Autor / Responsable:** Auditoría de equidad algorítmica (I6 / I7).
* **Descripción Técnica:** Inserción manual de directivas `_mm256_fmadd_pd` en C para forzar instrucciones FMA vectoriales de 256 bits.
* **Evaluación y Justificación:**
  * Go no cuenta con soporte nativo de intrínsecos SIMD en el lenguaje; para implementar AVX2 en Go se requeriría ensamblador de Plan 9 ensamblado a mano, lo que resulta frágil, no portable y ajeno a los objetivos del curso.
  * Dotar a C de intrínsecos manuales mientras Go usa bucles estándar constituiría una **comparación asimétrica y viciada** ("truco de implementación" en lugar de comparación de modelos de concurrencia).
  * Los compiladores modernos de C (MSVC con `/O2 /fp:precise` y GCC con `-O2`) ya reconocen el bucle interior $j$ de $i \to k \to j$ y aplican auto-vectorización SIMD limpia.
* **Dictamen:** **DESCARTADO / PROHIBIDO EN RAMA OFICIAL**. Se delega la vectorización exclusivamente al optimizador estándar del compilador.

---

### Ficha OPT-05: Pre-Asignación y Eliminación de Alocaciones en Go
* **Autor / Responsable:** Integrante 3 (Go secuencial) e Integrante 4 (Go paralelo).
* **Descripción Técnica:** Garantizar que los slices de almacenamiento de matrices $C$ y los canales de comunicación sean pre-reservados una única vez antes de $T_0$.
* **Evaluación de Rendimiento:**
  * Se verificó que en `multiplyKernel` y `multiplyBlock` no existe ninguna llamada a `make()`, `append()` ni conversiones de tipo que escapen al heap (`heap escape analysis`).
  * El vaciado de $C$ se ejecuta mediante el operador intrínseco `clear(c.Data)`, el cual se compila como un `memset` vectorizado de alta velocidad.
  * Cero pausas del Garbage Collector (GC) durante el cómputo de `kernel_s`.
* **Dictamen:** **CONSERVADO Y CONGELADO**. Se integra formalmente en los estándares del proyecto.

---

### Ficha OPT-06: Granularidad y Despacho de Bloques Contiguos ($N/W$ y $N/P$)
* **Autor / Responsable:** Integrante 4 (Go paralelo) e Integrante 2 (C paralelo).
* **Descripción Técnica:** En lugar de despachar tareas por celda ($N^2$ tareas) o tareas por fila ($N$ tareas), se asignan bloques contiguos de tamaño $\lceil N/W \rceil$ filas por worker/proceso.
* **Evaluación de Rendimiento:**
  * Despachar $N$ o $N^2$ tareas individuales satura los canales de Go y produce sobrecostes de sincronización que degradan el speedup en tamaños medianos ($N=512$).
  * La partición en $W$ bloques contiguos reduce el número de mensajes a exactamente $W$, minimizando la contención en el canal `tasks` y garantizando que cada worker trabaje sobre un rango de memoria lineal sin interferir con las líneas de caché de otros workers (*cero false sharing*).
* **Dictamen:** **CONSERVADO Y CONGELADO**.

---

## 5. Criterios de Congelamiento Algorítmico Definitivo

A partir del cierre del Sprint 6, los algoritmos de cómputo quedan **ESTRICTAMENTE CONGELADOS**:

1. **Inmutabilidad del Núcleo:** Prohibido modificar las funciones `multiplyKernel`, `multiplyBlock`, `matrix_accumulate` y `matrix_accumulate_rows`.
2. **Estabilidad de Parámetros:** El reparto 1D por bloques de filas y el orden $i \to k \to j$ constituyen la base científica fija para la ejecución de los Sprints 7 (Piloto) y 8 (Campaña Oficial).
3. **Equidad Garantizada:** Las cuatro versiones quedan equilibradas, verificadas numéricamente y listas para medir la verdadera influencia del paradigma de concurrencia (procesos MPI vs hilos OpenMP vs goroutines Go) sin ruido introducido por trucos sintácticos.

---

## 6. Dictamen de Aprobación

| Entregable / Decisión | Estado | Verificación |
| :--- | :---: | :--- |
| **Línea Base del Piloto** | **CONFORME** | Datos preliminares coherentes con speedup escalable. |
| **Evaluación de Tiling y SIMD** | **CONFORME** | Descartados por equidad algorítmica y portabilidad. |
| **Pre-asignación y Granularidad** | **CONFORME** | Retenidos e integrados sin overhead de sincronización. |
| **Congelamiento de Algoritmos** | **APROBADO** | Núcleos inmutables para el inicio del Sprint 7. |

**Firma del Responsable:**  
Andrés (Integrante 7) — 10/11/2026

