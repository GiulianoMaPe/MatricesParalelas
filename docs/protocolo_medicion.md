# Protocolo de medición y diseño experimental

**Estado:** Propuesta de preguntas experimentales, alcance y dimensionamiento (Sprint 1 · Integrante 7 · Andrés).  
**Documento base:** [`docs/guia-extraida.txt`](guia-extraida.txt) y [`docs/contrato.md`](contrato.md).

> [!NOTE]
> En la entrega inicial no se generan datos experimentales ficticios. Los ejecutables retornan código `2` (`MATRIX_PENDING`) hasta que los núcleos matemáticos sean implementados en S3 y S4. Este documento fija las bases metodológicas, las preguntas de rendimiento y el alcance de las campañas para garantizar que las futuras mediciones sean científicamente rigurosas, reproducibles y comparables.

---

## 1. Preguntas experimentales y de rendimiento

La experimentación no se limita a reportar tiempos de ejecución; su objetivo es caracterizar el comportamiento algorítmico y la escalabilidad del hardware ante diferentes paradigmas de paralelismo (memoria compartida con OpenMP, memoria distribuida con MPI y modelo de paso de mensajes/goroutines en Go).

Se establecen las siguientes preguntas de investigación estructuradas:

### P1. Umbral de rentabilidad y sobrecoste de comunicación (Overhead)
* **Pregunta:** ¿A partir de qué tamaño de matriz $N$ el beneficio del cómputo paralelo compensa el sobrecoste fijo de inicialización, distribución (`MPI_Scatterv`) y recolección (`MPI_Gatherv`), así como la creación de goroutines/canales en Go?
* **Variables involucradas:** Dimensión $N$, tiempo de kernel ($T_{\text{kernel}}$) vs. tiempo total ($T_{\text{total}}$).
* **Métrica asociada:** 
  $$\text{Overhead} = T_{\text{total}} - T_{\text{kernel}}$$
  $$\% \text{ Cómputo Útil} = \frac{T_{\text{kernel}}}{T_{\text{total}}} \times 100$$
* **Hipótesis:** Para matrices pequeñas ($N \le 256$), las versiones secuenciales serán más rápidas que las paralelas debido al predominio de la latencia de comunicación y sincronización. A partir de $N \ge 512$, el costo computacional de orden $\mathcal{O}(N^3)$ dominará sobre la comunicación $\mathcal{O}(N^2)$, logrando un speedup positivo.

### P2. Sensibilidad topológica en C híbrido ($P$ procesos MPI vs. $T$ hilos OpenMP)
* **Pregunta:** Para un presupuesto constante de trabajadores $W = P \times T$ (ej. $W = 4$), ¿qué configuración maximiza el rendimiento y minimiza el sobrecoste?
  * Opción A: Dominada por procesos ($4 \times 1$).
  * Opción B: Balanceada ($2 \times 2$).
  * Opción C: Dominada por hilos ($1 \times 4$).
* **Variables involucradas:** Número de procesos $P$, hilos por proceso $T$, tiempo de comunicación MPI vs. contención de memoria en OpenMP.
* **Hipótesis:** Las configuraciones dominadas por hilos ($1 \times 4$ o $2 \times 2$) superarán a las dominadas por procesos ($4 \times 1$), dado que la memoria compartida de OpenMP evita la duplicación de la matriz $B$ completa y prescinde del copiado explícito de memoria entre procesos locales en Windows.

### P3. Eficiencia y contención de Go paralelo vs. OpenMP
* **Pregunta:** ¿Cómo se compara la eficiencia del modelo de concurrencia de Go (pool acotado de workers sobre canales y `sync.WaitGroup`) frente a los hilos de OpenMP en C al escalar en núcleos físicos?
* **Variables involucradas:** Trabajadores ($W$), `GOMAXPROCS`, tiempo de ejecución por iteración.
* **Hipótesis:** C con OpenMP exhibirá una mayor eficiencia en núcleos físicos debido al acceso a memoria contigua sin la sobrecarga del planificador de Go (*runtime scheduler*) ni la sincronización de canales, pero Go paralelo mostrará una curva de escalabilidad predecible sin riesgo de condiciones de carrera gracias al particionamiento disjunto de filas.

### P4. Impacto de la jerarquía de memoria (Caché L1/L2/L3 vs. Ancho de banda de RAM)
* **Pregunta:** ¿En qué dimensión de matriz $N$ se observa un decremento abrupto en la tasa de operaciones por segundo (GFLOPS) atribuible a fallos de caché (*cache misses*) al exceder la capacidad de la caché L3 del procesador?
* **Variables involucradas:** Tamaño de la matriz en memoria ($3 \times N^2 \times 8$ bytes) frente a la capacidad de la caché L3 del equipo de prueba (ej. 32 MB en AMD Ryzen o 12–24 MB en Intel Core).

### P5. Equidad algorítmica entre lenguajes (C vs. Go)
* **Pregunta:** Al utilizar exactamente el mismo orden de bucles (`i, k, j`) y la misma representación contigua por filas, ¿cuál es la diferencia intrínseca de rendimiento entre el código máquina generado por MSVC x64 y el compilador de Go windows/amd64?
* **Métrica:** Ratio de tiempo base secuencial:
  $$\text{Ratio}_{\text{base}}(N) = \frac{T_{\text{secuencial, Go}}(N)}{T_{\text{secuencial, C}}(N)}$$

---

## 2. Alcance de medición y dimensionamiento

Para responder a las preguntas planteadas sin sobrecargar los recursos de las máquinas de desarrollo ni generar ejecuciones inviables, la campaña se divide en dos fases:

### 2.1. Fases del plan experimental

| Fase | Sprint | Tamaños $N$ | Propósito | Criterio de parada |
| :--- | :---: | :---: | :--- | :--- |
| **Piloto preliminar** | **S7** | $256, 512, 1024$ | Calibración de scripts de automatización, verificación de consistencia de CSV, validación de captura de errores y detección temprana de fugas de memoria. | Errores en CSV o tiempos anormales. Salida a `resultados/piloto/`. |
| **Campaña oficial** | **S8** | $512, 1024, 2048$ *(4096 condicional)* | Toma de datos definitiva para el análisis científico. Cada corrida se realiza sobre binarios Release congelados. | Cinco repeticiones válidas con verificación matemática completa. Salida a `resultados/raw/`. |

#### Análisis de viabilidad de memoria (RAM)
Cada elemento es de tipo `double` (C) o `float64` (Go), ocupando 8 bytes. La operación involucra 3 matrices cuadradas ($A$, $B$ y $C$):

$$\text{Memoria total} = 3 \times N^2 \times 8 \text{ bytes}$$

* **$N = 256$:** $3 \times 65.536 \times 8 \approx 1{,}5 \text{ MB}$ (entra en caché L2/L3).
* **$N = 512$:** $3 \times 262.144 \times 8 \approx 6 \text{ MB}$ (cabe holgadamente en caché L3).
* **$N = 1024$:** $3 \times 1.048.576 \times 8 \approx 24 \text{ MB}$ (límite de caché L3 en muchas CPUs de escritorio).
* **$N = 2048$:** $3 \times 4.194.304 \times 8 \approx 96 \text{ MB}$ (reside completamente en RAM; mide el impacto real del bus de memoria).
* **$N = 4096$ (Condicional):** $3 \times 16.777.216 \times 8 \approx 384 \text{ MB}$. Factible en RAM (los equipos del grupo disponen de 16 GB), pero el cálculo secuencial $\mathcal{O}(N^3) \approx 6{,}87 \times 10^{10}$ operaciones puede demorar varios minutos. Se evaluará en S7 si se incluye en la campaña final.

---

### 2.2. Presupuestos de trabajadores ($W$)

De acuerdo con el inventario de hardware del equipo (procesadores de 4, 6 y 8 núcleos físicos con soporte de hasta 16 hilos lógicos), se definen cuatro presupuestos homogéneos de trabajadores:

$$W \in \{1, 2, 4, 8\}$$

#### Asignación para C Paralelo Híbrido ($P \times T = W$)
Para aislar el efecto de la distribución de procesos frente al multihilo, se evaluarán las siguientes combinaciones:
* **$W = 1$:** 
  * $1 \times 1$: Permite medir el sobrecoste intrínseco de las directivas OpenMP y el runtime de MS-MPI frente a la referencia secuencial pura (`c_secuencial`).
* **$W = 2$:**
  * $1 \text{ proceso} \times 2 \text{ hilos}$ (solo OpenMP).
  * $2 \text{ procesos} \times 1 \text{ hilo}$ (solo MPI).
* **$W = 4$:**
  * $1 \text{ proceso} \times 4 \text{ hilos}$ (OpenMP puro).
  * $2 \text{ procesos} \times 2 \text{ hilos}$ (Híbrido equilibrado).
  * $4 \text{ procesos} \times 1 \text{ hilo}$ (MPI puro).
* **$W = 8$** *(para PCs con $\ge 8$ hilos lógicos)*:
  * $1 \times 8$, $2 \times 4$, $4 \times 2$, $8 \times 1$.

#### Asignación para Go Paralelo
* Se evaluarán `workers` $\in \{1, 2, 4, 8\}$.
* En cada ejecución se fijará de forma coherente la variable de entorno `GOMAXPROCS = workers` para garantizar paridad de recursos hardware con C.

---

## 3. Protocolo de ejecución y mitigación de sesgos

Para garantizar la validez científica y mitigar perturbaciones externas del sistema operativo:

1. **Precalentamiento (*Warmup*):** Por cada configuración experimental, se realizará **1 repetición inicial descartada** para cargar páginas de memoria en RAM, estabilizar la frecuencia del procesador y llenar las memorias caché.
2. **Número de repeticiones:** Se registrarán **5 mediciones oficiales consecutivas** por cada combinación $(N, \text{configuración})$.
3. **Orden intercalado (*Round-Robin*):** Las pruebas no se ejecutarán en bloques monótonos (ej. todas las corridas de $N=2048$ juntas), sino intercalando tamaños y tecnologías. Esto evita que el calentamiento progresivo de la CPU (*thermal throttling*) penalice injustamente a las últimas configuraciones.
4. **Condiciones del equipo de pruebas:**
   * Cerrar aplicaciones no esenciales (navegadores, indexadores, clientes de sincronización en la nube).
   * Plan de energía fijado en **Alto rendimiento** o **Equilibrado** documentado en la ficha del equipo.
   * Ejecución aislada: no lanzar más de un proceso de benchmark simultáneamente.
   * Utilizar únicamente compilaciones en modo `Release` (sin flags de depuración `/Zi` ni sanitizers).

---

## 4. Definición rigurosa de intervalos y cronómetros

Para asegurar comparaciones justas entre C y Go, se establecen límites de medición estrictamente equivalentes:

```
[Inicio Programa]
   │  Lectura de argumentos y parámetros
   │  Reserva de memoria para A, B y C
   │  Generación/Lectura de datos de entrada
   ├────────────────────────────────────────────► INICIO total_s
   │  MPI_Bcast (matriz B completa)
   │  MPI_Scatterv (filas de A a procesos)
   │  ├─────────────────────────────────────────► INICIO kernel_s
   │  │  Multiplicación local de bloques de filas
   │  │  (Bucle i, k, j con OpenMP o worker Go)
   │  └─────────────────────────────────────────► FIN kernel_s
   │  MPI_Gatherv (recolección de filas de C)
   │  Sincronización final colectiva / WaitGroup
   ├────────────────────────────────────────────► FIN total_s
   │  Verificación matemática de tolerancia
   │  Liberación de memoria
   │  Escritura de resultados en CSV
[Fin Programa]
```

### Relojes de alta resolución utilizados:
* **C Secuencial:** `QueryPerformanceCounter` y `QueryPerformanceFrequency` de la API Win32 (resolución de submicrosegundos).
* **C Paralelo:** `MPI_Wtime()`. Para el tiempo global entre procesos, se sincroniza el inicio y se recolecta el tiempo máximo mediante:
  ```c
  MPI_Reduce(&local_total_s, &global_total_s, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
  ```
* **Go (Secuencial y Paralelo):** Monotonic clock con `time.Now()` y `time.Since()`.

---

## 5. Fórmulas matemáticas para el análisis de resultados

Los resúmenes estadísticos (Sprint 7 y 9) se computarán utilizando las siguientes fórmulas oficiales:

1. **Agregación por configuración:**
   Para mitigar el efecto de fluctuaciones del sistema operativo, se utilizará la **mediana** de las 5 repeticiones de `total_s`, reportando también el valor mínimo y máximo (o rango intercuartílico IQR):
   $$\widetilde{T} = \text{Mediana}(T_1, T_2, T_3, T_4, T_5)$$

2. **Speedup ($S$):**
   Calculado estrictamente respecto a la referencia secuencial nativa del **mismo lenguaje**:
   $$S_{\text{C}}(N, P, T) = \frac{\widetilde{T}_{\text{c\_secuencial}}(N)}{\widetilde{T}_{\text{c\_paralelo}}(N, P, T)}$$
   $$S_{\text{Go}}(N, W) = \frac{\widetilde{T}_{\text{go\_secuencial}}(N)}{\widetilde{T}_{\text{go\_paralelo}}(N, W)}$$

3. **Eficiencia paralela ($E$):**
   Normalizada según el número nominal de trabajadores asignados:
   $$E_{\text{C}} = \frac{S_{\text{C}}}{P \times T}, \quad E_{\text{Go}} = \frac{S_{\text{Go}}}{W}$$

4. **Comparación entre lenguajes:**
   Se realizará mediante comparaciones directas de tiempos absolutos en segundos y no mediante porcentajes arbitrarios.

---

## 6. Estructura del archivo de datos CSV

El script de recolección exportará los resultados en formato UTF-8 con punto decimal y las siguientes columnas obligatorias:

```csv
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status
```

* **Rutas de almacenamiento:**
  * Piloto (S7): `resultados/piloto/mediciones_piloto.csv`
  * Oficial (S8): `resultados/raw/mediciones_oficiales.csv`
  * Agregados y tablas (S9): `resultados/resumen/resumen_estadistico.csv`
  * Gráficas generadas (S9): `resultados/graficos/*.png`
