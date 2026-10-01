# Protocolo de medición y diseño experimental

**Versión:** 1.0 (Versión inicial aprobada · Sprint 2 · Integrante 7 · Andrés)  
**Estado:** Especificación formal aprobada para los núcleos y scripts de medición  
**Documentos relacionados:** [`docs/guia-extraida.txt`](guia-extraida.txt), [`docs/contrato.md`](contrato.md), [`docs/bibliografia.md`](bibliografia.md)

---

## 1. Propósito y Marco Metodológico

Este documento establece el **Protocolo de Medición Versión Inicial** del proyecto, en cumplimiento de los objetivos del Sprint 2 para el **Integrante 7**. Su finalidad es garantizar que las futuras campañas de medición (Piloto en S7 y Campaña Oficial en S8) se ejecuten bajo condiciones científicamente rigurosas, reproducibles y equitativas entre las cuatro versiones del software:
* `c_secuencial`: Referencia secuencial en C compilada con MSVC x64 sin OpenMP ni MPI.
* `c_paralelo`: Implementación híbrida en C con MS-MPI para memoria distribuida y OpenMP para memoria compartida.
* `go_secuencial`: Referencia secuencial en Go windows/amd64.
* `go_paralelo`: Implementación concurrente en Go con pool acotado de workers, canales tipados y `sync.WaitGroup`.

> [!IMPORTANT]
> Siguiendo el contrato del proyecto, las ejecuciones actuales devuelven código `2` (`MATRIX_PENDING`). Ninguna prueba de instalación o smoke test se reporta como medición de rendimiento. Las mediciones reales se habilitarán únicamente cuando los algoritmos de multiplicación pasen la verificación matemática elemento a elemento ($\text{atol}=10^{-9}, \text{rtol}=10^{-9}$).

---

## 2. Preguntas de Rendimiento e Hipótesis Científicas

La experimentación está diseñada para dar respuesta a cinco preguntas clave de computación paralela:

### P1. Umbral de rentabilidad y sobrecoste de comunicación (Overhead)
* **Pregunta:** ¿A partir de qué dimensión $N$ el cómputo paralelo supera el sobrecoste fijo de inicialización, distribución (`MPI_Scatterv`), recolección (`MPI_Gatherv`) y sincronización de goroutines/canales en Go?
* **Métricas asociadas:**
  $$\text{Overhead} = T_{\text{total}} - T_{\text{kernel}}$$
  $$\% \text{ Cómputo Útil} = \frac{T_{\text{kernel}}}{T_{\text{total}}} \times 100$$
* **Hipótesis:** Para matrices pequeñas ($N \le 256$), las referencias secuenciales superarán a las paralelas debido a la latencia de comunicación ($\mathcal{O}(N^2)$). A partir de $N \ge 512$, el costo computacional cúbico ($\mathcal{O}(N^3)$) dominará, haciendo rentable la paralelización.

### P2. Sensibilidad topológica en C híbrido ($P$ procesos MPI vs. $T$ hilos OpenMP)
* **Pregunta:** Para un presupuesto fijo de trabajadores $W = P \times T$ (ej. $W = 4$), ¿qué configuración maximiza el rendimiento y minimiza el sobrecoste?
  * Dominada por procesos: $4 \times 1$
  * Balanceada: $2 \times 2$
  * Dominada por hilos: $1 \times 4$
* **Hipótesis:** Basado en Quintin et al. (ICPP 2013) y en la arquitectura de memoria compartida de Windows 11, las configuraciones con mayor número de hilos OpenMP ($1 \times 4$ o $2 \times 2$) superarán a las dominadas por procesos ($4 \times 1$), ya que evitan la duplicación de la matriz $B$ y el copiado interproceso de memoria en un único nodo físico.

### P3. Eficiencia y contención de Go paralelo vs. OpenMP
* **Pregunta:** ¿Cómo se compara la eficiencia del modelo de concurrencia de Go (pool acotado de workers sobre canales y `sync.WaitGroup`) frente a los hilos de OpenMP en C al escalar en núcleos físicos?
* **Hipótesis:** OpenMP logrará mayor eficiencia en núcleos físicos debido al acceso a memoria contigua sin la sobrecarga del planificador de Go (*runtime scheduler*) ni la sincronización de canales, pero Go paralelo mostrará una escalabilidad estable sin condiciones de carrera gracias al particionado disjunto de filas.

### P4. Impacto de la jerarquía de memoria (Caché L1/L2/L3 vs. RAM)
* **Pregunta:** ¿En qué dimensión $N$ se observa un decremento abrupto en GFLOPS atribuible a fallos de caché (*cache misses*) al exceder la capacidad de la caché L3 del procesador?
* **Hipótesis:** Al superar los $N=1024$ (donde las 3 matrices ocupan $\approx 24 \text{ MB}$, saturando la caché L3 típica de 16–32 MB), la tasa de operaciones caerá drásticamente debido a la saturación del bus de memoria RAM.

### P5. Equidad algorítmica entre lenguajes (C vs. Go)
* **Pregunta:** Manteniendo idéntico recorrido de bucles ($i, k, j$) y la misma representación contigua por filas, ¿cuál es la diferencia intrínseca de rendimiento entre el código generado por MSVC x64 y el compilador de Go?

---

## 3. Delimitación Estricta de Intervalos de Tiempo (`kernel_s` vs. `total_s`)

Para garantizar comparaciones estrictas y equitativas entre tecnologías, se define formalmente la frontera de los cronómetros.

```
[Inicio de Ejecución]
  │  1. Parseo y validación de argumentos (--n, --seed, --workers, etc.)
  │  2. Asignación de memoria en Heap para matrices completas A, B, C
  │  3. Generación PRNG determinista o lectura desde archivo fixture
  ├────────────────────────────────────────────────────────────────────────► [T0] INICIO total_s
  │  4. Distribución de datos:
  │     - En C híbrido: MPI_Bcast(matriz B) + MPI_Scatterv(filas locales de A)
  │     - En Go paralelo: Envío de rangos de filas a canal de tareas
  │  ├─────────────────────────────────────────────────────────────────────► [K0] INICIO kernel_s
  │  │  5. Multiplicación de matrices:
  │  │     - C secuencial: Bucle i, k, j sobre A y B
  │  │     - C paralelo: #pragma omp parallel for schedule(static) sobre filas locales
  │  │     - Go secuencial: Bucle i, k, j sobre matrices contiguas
  │  │     - Go paralelo: Ejecución de bloques de filas por workers en memoria compartida
  │  └─────────────────────────────────────────────────────────────────────► [K1] FIN kernel_s
  │  6. Recolección y sincronización:
  │     - En C híbrido: MPI_Gatherv(filas locales de C en rank 0) + MPI_Barrier
  │     - En Go paralelo: Cierre de canal de tareas + wg.Wait()
  ├────────────────────────────────────────────────────────────────────────► [T1] FIN total_s
  │  7. Verificación de tolerancias matemáticas (atol=1e-9, rtol=1e-9)
  │  8. Liberación de memoria en Heap (free / runtime Go)
  │  9. Formateo y escritura de la fila en el archivo CSV
[Fin de Ejecución]
```

### 3.1. Tabla de Eventos por Tecnología

| Versión | Inicio `total_s` ($T_0$) | Inicio `kernel_s` ($K_0$) | Fin `kernel_s` ($K_1$) | Fin `total_s` ($T_1$) | Mecanismo de Reloj |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`c_secuencial`** | Inmediatamente antes de inicializar $C$ en ceros. | Inicio del bucle externo $i$. | Fin del bucle $j$ (última acumulación). | Inmediatamente tras finalizar la multiplicación. | `QueryPerformanceCounter` de Win32 API. |
| **`c_paralelo`** | Previo a `MPI_Bcast` de matriz $B$ (sincronizado con barrera). | Inicio de la región `#pragma omp parallel for`. | Fin de la región `#pragma omp parallel for`. | Posterior a `MPI_Gatherv` de matriz $C$ en rank 0. | `MPI_Wtime()`, recolectando el máximo entre procesos con `MPI_Reduce(..., MPI_MAX)`. |
| **`go_secuencial`** | Inmediatamente antes de inicializar slice de $C$. | Inicio del bucle externo $i$. | Fin de la última acumulación. | Inmediatamente tras finalizar el cálculo secuencial. | `time.Now()` y `time.Since()` (reloj monotónico de Go). |
| **`go_paralelo`** | Previo al despacho de bloques de filas al canal de tareas. | Inicio del cálculo del primer worker activo. | Fin del cálculo del último worker activo. | Posterior a `wg.Wait()` tras sincronizar a todos los workers. | `time.Now()` y `time.Since()`. |

### 3.2. Matriz de Exclusiones Explícitas

Quedan **estrictamente excluidas** de ambos cronómetros (`kernel_s` y `total_s`):
1. **I/O de disco:** Lectura de fixtures de entrada y escritura de matrices de salida.
2. **Generación de datos:** Ejecución del algoritmo congruencial lineal (PRNG) para llenar $A$ y $B$.
3. **Validación matemática:** Recorrido celda a celda para comparar $|C_{i,j} - C_{\text{ref}}| \le 10^{-9} + 10^{-9}|C_{\text{ref}}|$.
4. **Reserva y liberación de memoria:** Llamadas a `malloc`, `free` o alocaciones de slices en Go para las matrices de entrada completas.
5. **Generación de reportes:** Formateo y escritura de registros en stdout o en el archivo CSV.

---

## 4. Diccionario de Datos del Archivo CSV

Los scripts de automatización (`bench_windows.ps1` en S7/S8) exportarán las observaciones en formato UTF-8 sin BOM, con coma (`,`) como separador y punto (`.`) como separador decimal. La primera línea contendrá obligatoriamente la cabecera.

### Estructura de Columnas

| N° | Columna | Tipo de Dato | Rango / Formato | Descripción | Ejemplo |
| :---: | :--- | :---: | :--- | :--- | :--- |
| 1 | `timestamp` | String | ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) | Momento exacto de inicio de la medición. | `2026-10-15T14:32:05Z` |
| 2 | `version` | String | `c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo` | Identificador de la versión bajo prueba. | `c_paralelo` |
| 3 | `commit` | String | Hash hexadecimal (7 caracteres) | Commit Git del código compilado en Release. | `87fd548` |
| 4 | `hostname` | String | Alfanumérico | Nombre del nodo/computadora de prueba. | `PC-ANDRES` |
| 5 | `cpu_model` | String | Texto descriptivo | Modelo comercial de la CPU del equipo. | `AMD Ryzen 7 8845HS` |
| 6 | `ram_gb` | Float | Decimal $\ge 1.0$ | Capacidad de memoria RAM instalada en GB. | `8.0` |
| 7 | `os_version` | String | Texto descriptivo | Edición y compilación de Windows 11. | `Win11_26200` |
| 8 | `configuration` | String | Texto estructurado | Etiqueta canónica de la configuración de ejecución. | `c_paralelo_P2_T2` |
| 9 | `n` | Integer | Entero positivo $\ge 1$ | Dimensión de las matrices cuadradas ($N \times N$). | `1024` |
| 10 | `seed` | Integer | Entero sin signo 32 bits ($0$ a $2^{32}-1$) | Semilla utilizada para la generación pseudoaleatoria. | `42` |
| 11 | `processes` | Integer | Entero $\ge 1$ | Procesos MPI solicitados ($P$). Vale 1 en versiones no MPI. | `2` |
| 12 | `threads` | Integer | Entero $\ge 1$ | Hilos OpenMP solicitados ($T$). Vale 1 en versiones no OpenMP. | `2` |
| 13 | `observed_threads` | Integer | Entero $\ge 1$ | Hilos reales reportados por `omp_get_num_threads()`. | `2` |
| 14 | `workers` | Integer | Entero $\ge 1$ | Número de goroutines de cálculo. Vale 1 en secuenciales. | `4` |
| 15 | `gomaxprocs` | Integer | Entero $\ge 1$ | Valor de `runtime.GOMAXPROCS`. | `4` |
| 16 | `repetition` | Integer | $0, 1, 2, 3, 4, 5$ | Índice de la repetición ($0$ = precalentamiento/warmup). | `1` |
| 17 | `is_warmup` | Boolean | `true`, `false` | Indica si la corrida es de precalentamiento descartada. | `false` |
| 18 | `kernel_s` | Float | Flotante $\ge 0.0$ (9 decimales) | Tiempo exclusivo del cómputo puro en segundos. | `0.485123901` |
| 19 | `total_s` | Float | Flotante $\ge 0.0$ (9 decimales) | Tiempo total de cómputo y coordinación en segundos. | `0.521894210` |
| 20 | `validation_status` | String | `OK`, `PENDING`, `MISMATCH`, `OOM`, `TIMEOUT`, `ERROR` | Estado de verificación matemática y ejecución. | `OK` |

---

## 5. Matriz Completa de Experimentos y Espacio de Parámetros

El plan experimental define de manera determinista todas las combinaciones que formarán parte de las campañas.

### 5.1. Dimensiones de Matriz ($N$)
* **Piloto (S7):** $N \in \{256, 512, 1024\}$.
* **Campaña Oficial (S8):** $N \in \{512, 1024, 2048\}$.
* **Extensión Condicional (S8):** $N = 4096$ (sujeto a memoria disponible y tiempo secuencial admisible).
* **Semilla determinista:** `seed = 42` como caso canónico oficial; semillas complementarias $\{101, 2024\}$ para pruebas de robustez.

### 5.2. Presupuestos de Trabajadores ($W$) y Configuraciones

| Presupuesto ($W$) | Versión | Configuración ($P \times T$ o Workers) | Justificación Arquitectural |
| :---: | :--- | :---: | :--- |
| **Línea Base** | `c_secuencial` | Secuencial puro (1 núcleo) | Referencia fundamental para calcular Speedup en C. |
| **Línea Base** | `go_secuencial` | Secuencial puro (1 núcleo) | Referencia fundamental para calcular Speedup en Go. |
| **$W = 1$** | `c_paralelo` | $P=1, T=1$ | Medición del sobrecoste intrínseco del runtime MPI/OpenMP vs. C puro. |
| **$W = 1$** | `go_paralelo` | $\text{workers}=1, \text{GOMAXPROCS}=1$ | Medición del sobrecoste de goroutines y canales vs. Go puro. |
| **$W = 2$** | `c_paralelo` | $P=1, T=2$ | Evaluación de OpenMP puro en 2 hilos. |
| **$W = 2$** | `c_paralelo` | $P=2, T=1$ | Evaluación de MS-MPI puro en 2 procesos. |
| **$W = 2$** | `go_paralelo` | $\text{workers}=2, \text{GOMAXPROCS}=2$ | Concurrencia en 2 núcleos físicos. |
| **$W = 4$** | `c_paralelo` | $P=1, T=4$ | OpenMP dominante (memoria compartida pura). |
| **$W = 4$** | `c_paralelo` | $P=2, T=2$ | Topología balanceada (híbrido óptimo en 4 núcleos). |
| **$W = 4$** | `c_paralelo` | $P=4, T=1$ | MPI dominante (distribución intensiva entre procesos). |
| **$W = 4$** | `go_paralelo` | $\text{workers}=4, \text{GOMAXPROCS}=4$ | Concurrencia en 4 trabajadores. |
| **$W = 8$** *(PCs $\ge 8$ hilos)* | `c_paralelo` | $P=1, T=8$ | OpenMP puro en 8 hilos. |
| **$W = 8$** *(PCs $\ge 8$ hilos)* | `c_paralelo` | $P=2, T=4$ | Híbrido 2 procesos $\times$ 4 hilos. |
| **$W = 8$** *(PCs $\ge 8$ hilos)* | `c_paralelo` | $P=4, T=2$ | Híbrido 4 procesos $\times$ 2 hilos. |
| **$W = 8$** *(PCs $\ge 8$ hilos)* | `c_paralelo` | $P=8, T=1$ | MPI puro en 8 procesos. |
| **$W = 8$** *(PCs $\ge 8$ hilos)* | `go_paralelo` | $\text{workers}=8, \text{GOMAXPROCS}=8$ | Concurrencia en 8 trabajadores. |

### 5.3. Volumen de Mediciones por Campaña

Para una máquina con procesador de 8 núcleos/16 hilos (como el AMD Ryzen 7 8845HS de Andrés):
* Total de configuraciones por dimensión $N$: 2 secuenciales + 11 paralelas = **13 configuraciones**.
* Para 3 dimensiones de matriz ($N \in \{512, 1024, 2048\}$): $13 \times 3 = 39$ combinaciones.
* Con el protocolo de **1 precalentamiento + 5 repeticiones oficiales** (6 corridas por combinación):
  $$\text{Total corridas oficiales} = 39 \times 6 = 234 \text{ ejecuciones}$$

---

## 6. Protocolo de Ejecución y Mitigación de Sesgos

Para garantizar la fiabilidad estadística y evitar distorsiones originadas por el sistema operativo o el hardware:

### 6.1. Protocolo de 1 Precalentamiento + 5 Repeticiones
* **Corrida 0 (Warmup descartado):** Carga los módulos binarios en RAM, calienta la memoria caché, estabiliza la frecuencia boost del procesador y descarta latencias iniciales de paginación del sistema de archivos. Se registra con `is_warmup = true` y no se utiliza en el cálculo de medianas ni speedup.
* **Corridas 1 a 5 (Mediciones oficiales):** Cinco observaciones consecutivas registradas con `is_warmup = false`.

### 6.2. Orden Intercalado (*Round-Robin*)
Para evitar el **sesgo por estrangulamiento térmico (*thermal throttling*)**, las pruebas no se ejecutarán en ráfagas idénticas consecutivas. Se empleará un ciclo intercalado:
```
Ronda 1: [c_sec, N=512] -> [c_par_1x4, N=512] -> [go_par_4, N=512] -> [c_sec, N=1024] ...
Ronda 2: [c_sec, N=512] -> [c_par_1x4, N=512] -> [go_par_4, N=512] -> [c_sec, N=1024] ...
...
```
Esto distribuye la carga térmica de manera homogénea en el tiempo.

### 6.3. Justificación del Uso de la Mediana y Rango Intercuartílico (IQR)
En entornos Windows 11 de escritorio, procesos en segundo plano (antivirus, indexador de búsqueda, telemetría) provocan picos asimétricos (*jitter* o ruido de cola). Por tanto:
* **Medida de tendencia central:** Se adopta estrictamente la **Mediana** ($\widetilde{T}$) en lugar de la media aritmética, por ser un estimador robusto no influenciado por valores atípicos (*outliers*).
* **Medida de dispersión:** Se reportará el **Rango Intercuartílico** ($\text{IQR} = Q_3 - Q_1$) junto con los valores mínimo ($T_{\min}$) y máximo ($T_{\max}$).

### 6.4. Condiciones de Entorno Obligatorias
Antes de iniciar una campaña de medición:
1. Compilar todas las versiones en modo **Release** mediante `build_windows.ps1 -Version all -Configuration Release`.
2. Fijar el plan de energía de Windows en **Alto Rendimiento** o **Equilibrado** (documentado en `docs/entorno/`).
3. Cerrar navegadores web, clientes de mensajería y servicios de sincronización en la nube (OneDrive, Google Drive).
4. Verificar que no haya tareas automáticas de Windows Update activas.
5. Ejecutar los scripts de medición de forma aislada (un único benchmark activo a la vez).

---

## 7. Fórmulas Matemáticas para el Análisis de Rendimiento

El análisis de datos en el Sprint 9 empleará las siguientes formulaciones canónicas:

### 7.1. Speedup ($S$)
Calculado de forma estricta respecto a la referencia secuencial nativa del **mismo lenguaje**:
$$S_{\text{C}}(N, P, T) = \frac{\widetilde{T}_{\text{total, c\_secuencial}}(N)}{\widetilde{T}_{\text{total, c\_paralelo}}(N, P, T)}$$

$$S_{\text{Go}}(N, W) = \frac{\widetilde{T}_{\text{total, go\_secuencial}}(N)}{\widetilde{T}_{\text{total, go\_paralelo}}(N, W)}$$

### 7.2. Eficiencia Paralela ($E$)
Mide el aprovechamiento por núcleo/hilo asignado:
$$E_{\text{C}}(N, P, T) = \frac{S_{\text{C}}(N, P, T)}{P \times T}$$

$$E_{\text{Go}}(N, W) = \frac{S_{\text{Go}}(N, W)}{W}$$

Una eficiencia $E \approx 1.0$ representa escalabilidad lineal ideal; $E < 0.5$ evidencia predominio del sobrecoste de comunicación o contención de memoria.

---

## 8. Rutas de Almacenamiento y Versionamiento de Datos

Los resultados se aislarán rigurosamente para prevenir la contaminación entre fases experimentales:
* **Datos Piloto (Sprint 7):** `resultados/piloto/mediciones_piloto.csv`
* **Datos Oficiales (Sprint 8):** `resultados/raw/mediciones_oficiales.csv`
* **Resúmenes Estadísticos (Sprint 9):** `resultados/resumen/resumen_estadistico.csv`
* **Gráficas e Ilustraciones (Sprint 9):** `resultados/graficos/*.png`

El repositorio de Git versionará únicamente los archivos finales de resumen estadístico y los gráficos generados para el informe; los archivos crudos extensos se preservarán localmente o mediante anexos para no sobrecargar el historial de Git.
