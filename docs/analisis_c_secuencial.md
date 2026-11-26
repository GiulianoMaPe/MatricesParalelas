# C secuencial · Análisis del Sprint 9

**Responsable** · Yessly (I1)

En la campaña oficial integrada, la mediana de `total_s` de la referencia `c_secuencial` aumentó de **0,0237804 s** a **3,8167853 s** entre $N=512$ y $N=2048$. Al duplicar la dimensión de la matriz, el tiempo total medido creció en un factor empírico de **8,53×** en el primer salto ($512 \to 1024$) y de **18,81×** en el segundo salto ($1024 \to 2048$). La dispersión relativa no paramétrica ($\text{RSD}_{\text{IQR}}$) se situó en **0,46 %** (`EXCELENTE`) para $N=512$, **10,11 %** (`ALTA — Alerta`, conservada conforme al protocolo de dispersión) para $N=1024$, y **2,61 %** (`ESTABLE`) para $N=2048$. Estos resultados empíricos establecen la base de comparación canónica y monohilo para computar el *speedup* y la eficiencia paralela de `c_paralelo` en la misma campaña integrada.

## Fuente de datos, condiciones y resultados cuantitativos

### Declaración de procedencia: campaña oficial vs. corrida independiente previa

Se declara formal y explícitamente que los resultados oficiales presentados provienen exclusivamente de la campaña integrada congelada `s08_oficial_integrada_03` ([CSV de mediciones](../resultados/raw/s08_oficial_integrada_03/mediciones.csv)), ejecutada en el host canónico `PCG1UL14N0` (AMD Ryzen 5 3600 6-Core Processor, 15,912 GiB de RAM visible, Windows 11 Pro build 26300.9711 [reportado como build 26300]) con el commit congelado `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, compilador MSVC 19.44.35230.0 (`Release`), semilla pseudoaleatoria 42, y documentada por Roberto en la bitácora ([Bitácora de experimentos](bitacora_experimentos.md)) y en el manifiesto oficial ([Manifiesto S8](../resultados/raw/manifiesto_s08.json)).

El subconjunto de `c_secuencial` en dicha campaña comprende exactamente 18 ejecuciones registradas: 1 corrida de calentamiento (`repetition=0`, `is_warmup=true`) y 5 repeticiones válidas (`repetition=1..5`, `is_warmup=false`) para cada una de las tres dimensiones $N \in \{512, 1024, 2048\}$. Todas las ejecuciones concluyeron con estado `validation_status = OK`.

El lote previo preservado en `resultados/raw/c_secuencial.csv` (18 filas generadas el 2026-11-19 en `PCG1UL14N0` por Yessly, con SHA-256 `0F82F9FDE140C6E928AFB0476392E22181DEDEE534F42D7D20B3271973B3C854` y validado en `resultados/raw/c_secuencial.manifest.json`) se mantiene estrictamente como **corrida independiente de procedencia preservada**. Para salvaguardar la pureza metodológica y evitar contaminación cruzada de sesiones, sus observaciones y medianas previas no se mezclan con las observaciones ni con las tablas de la campaña integrada oficial `s08_oficial_integrada_03`.

### Registro completo de las 18 ejecuciones oficiales (`s08_oficial_integrada_03`)

A continuación se detalla la totalidad de las 18 observaciones de `c_secuencial` en la campaña oficial, discriminando el calentamiento de las réplicas evaluadas:

| Dimensión ($N$) | Repetición | ¿Calentamiento? (`is_warmup`) | Tiempo Kernel `kernel_s` (s) | Tiempo Total `total_s` (s) | Validación |
| ---: | ---: | :---: | ---: | ---: | :---: |
| 512 | 0 | true | 0,0367422 | 0,0370229 | OK |
| 1024 | 0 | true | 0,3786455 | 0,3796989 | OK |
| 2048 | 0 | true | 3,6621907 | 3,6665041 | OK |
| 512 | 1 | false | 0,0235735 | 0,0238592 | OK |
| 1024 | 1 | false | 0,1880740 | 0,1890955 | OK |
| 2048 | 1 | false | 4,0545375 | 4,0592370 | OK |
| 2048 | 2 | false | 3,7825189 | 3,7870772 | OK |
| 1024 | 2 | false | 0,2267833 | 0,2278186 | OK |
| 512 | 2 | false | 0,0234685 | 0,0237370 | OK |
| 512 | 3 | false | 0,0237718 | 0,0240381 | OK |
| 1024 | 3 | false | 0,2019060 | 0,2029335 | OK |
| 2048 | 3 | false | 3,7251289 | 3,7298687 | OK |
| 2048 | 4 | false | 3,8821981 | 3,8866566 | OK |
| 1024 | 4 | false | 0,2132748 | 0,2142932 | OK |
| 512 | 4 | false | 0,0235025 | 0,0237804 | OK |
| 512 | 5 | false | 0,0234831 | 0,0237508 | OK |
| 1024 | 5 | false | 0,1927403 | 0,1937763 | OK |
| 2048 | 5 | false | 3,8123368 | 3,8167853 | OK |

### Resumen estadístico no paramétrico oficial ($n_{\text{válidas}} = 5$)

Excluyendo rigurosamente la repetición de calentamiento `repetition=0`, las estadísticas oficiales se calculan sobre las 5 repeticiones válidas ordenadas. La tercera observación corresponde a la mediana, el rango intercuartílico es $\text{IQR} = Q_3 - Q_1$ (cuarta menos segunda observación), y la dispersión relativa no paramétrica es $\text{RSD}_{\text{IQR}} = 100 \times \frac{\text{IQR}}{\text{mediana}}$.

| Dimensión ($N$) | Muestras ($n$) | Mediana `kernel_s` (s) | IQR `kernel_s` (s) | Mediana `total_s` (s) | Mín.–máx. `total_s` (s) | IQR `total_s` (s) | $\text{RSD}_{\text{IQR}}$ `total_s` | Clasificación Dispersión | GFLOP/s (Kernel) | GFLOP/s (Total) |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: | ---: | ---: |
| 512 | 5 | 0,0235025 | 0,0000904 | 0,0237804 | 0,0237370–0,0240381 | 0,0001084 | 0,46 % | **EXCELENTE** | 11,42 | 11,29 |
| 1024 | 5 | 0,2019060 | 0,0205345 | 0,2029335 | 0,1890955–0,2278186 | 0,0205169 | 10,11 % | **ALTA (Alerta)** | 10,64 | 10,58 |
| 2048 | 5 | 3,8123368 | 0,0996792 | 3,8167853 | 3,7298687–4,0592370 | 0,0995794 | 2,61 % | **ESTABLE** | 4,51 | 4,50 |

*Referencias asociadas:* [Resumen estadístico](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv) · [Auditoría de dispersión](../resultados/resumen/s08_oficial_integrada_03/auditoria_dispersion.md) · [Protocolo de medición, §6.3](protocolo_medicion.md#63-justificación-del-uso-de-la-mediana-y-rango-intercuartílico-iqr).

### Análisis de dispersión y retención conforme a protocolo (§6.3)

La auditoría de dispersión auditó los tres tamaños:
1. En $N=512$, la dispersión es sumamente reducida ($\text{RSD}_{\text{IQR}} = 0,46\ \% \le 1\ \%$), catalogada como `EXCELENTE` a pesar de detectar 1 observación fuera de vallas de Tukey por la extrema estrechez del intervalo intercuartílico ($0,108\text{ ms}$).
2. En $N=1024$, se registró una dispersión $\text{RSD}_{\text{IQR}} = 10,11\ \%$, clasificada como `ALTA — Alerta` (rango $10\text{--}15\ \%$). No se detectaron valores atípicos fuera de las vallas de Tukey ($k=1,5$), reflejando una variabilidad distribuida entre corridas contiguas (recorriendo desde $0,1891\text{ s}$ hasta $0,2278\text{ s}$). Conforme a la regla §6.3 del protocolo, el grupo fue dictaminado como `CONSERVAR_CONFORME`, preservando íntegramente las 5 corridas válidas.
3. En $N=2048$, el comportamiento se mantuvo en régimen `ESTABLE` ($\text{RSD}_{\text{IQR}} = 2,61\ \% \le 5\ \%$) con 1 observación atípica leve conservada conforme a protocolo.

### Escalabilidad empírica frente al modelo teórico cúbico $O(N^3)$

Teóricamente, el algoritmo de multiplicación matricial estándar ejecuta $2N^3$ operaciones de punto flotante ($N^3$ multiplicaciones y $N^3$ sumas). Al duplicar $N$, la carga computacional se multiplica exactamente por un factor teórico de **$8\times$** ($2^3$), mientras que el volumen de datos por matriz se cuadruplica ($4\times$).

Los factores de escalado empírico medidos a partir de las medianas de `total_s` son:
- **Salto $512 \to 1024$:** factor de crecimiento empírico de **8,53×** ($\frac{0,2029335}{0,0237804} = 8,5336$). Este comportamiento es ligeramente superior al factor teórico $8\times$, reflejando una leve pérdida de tasa de cómputo (el rendimiento desciende de 11,29 a 10,58 GFLOP/s).
- **Salto $1024 \to 2048$:** factor de crecimiento empírico de **18,81×** ($\frac{3,8167853}{0,2029335} = 18,8081$). Este escalamiento diverge drásticamente del factor $8\times$ esperado por la complejidad asintótica, provocando una caída abrupta del rendimiento efectivo a menos de la mitad: de 10,58 GFLOP/s a 4,50 GFLOP/s.
- **Salto global $512 \to 2048$:** el tiempo total crece en un factor global de **160,50×** (frente a un factor teórico puro de $64\times$).

### Coste relativo de preparación y vaciado de memoria (`total_s - kernel_s`)

La instrumentación separa con precisión el kernel puro de acumulación (`kernel_s`) del intervalo total cronometrado (`total_s`), el cual incluye la puesta a cero de la matriz de destino $C$ mediante `matrix_clear` (`memset`).

Calculando la diferencia pareada corrida a corrida (`total_s - kernel_s`) y extrayendo su mediana no paramétrica sobre las 5 repeticiones válidas, se obtiene:
- **$N=512$:** mediana de `total_s - kernel_s` = **0,2685 ms** ($0,0002685\text{ s}$). Representa el 1,13 % del tiempo total.
- **$N=1024$:** mediana de `total_s - kernel_s` = **1,0275 ms** ($0,0010275\text{ s}$). Representa el 0,51 % del tiempo total.
- **$N=2048$:** mediana de `total_s - kernel_s` = **4,5583 ms** ($0,0045583\text{ s}$). Representa el 0,12 % del tiempo total.

*Observación técnica:* El coste de `matrix_clear` escala aproximadamente con la cantidad de celdas de $C$ ($N^2$, cuadruplicándose en cada salto: $0,27\text{ ms} \to 1,03\text{ ms} \to 4,56\text{ ms}$), por lo que su impacto porcentual disminuye progresivamente frente al núcleo de cálculo que escala con orden cúbico $O(N^3)$.

---

## Implementación verificada en el código congelado (`97ccc981...`)

La inspección directa de los fuentes y scripts congelados en el commit de referencia `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` comprueba las siguientes especificaciones arquitectónicas:

1. **Cadena de compilación y optimización:**
   - Script de construcción: [build_windows.ps1](../scripts/build_windows.ps1#L32-L40).
   - Estándar y opciones: C11 nativo (`/std:c11`), compilador MSVC en configuración `Release` de 64 bits (`/MACHINE:X64`).
   - Flags efectivas: `/O2` (máxima optimización de velocidad de ejecución), `/MD` (enlace dinámico a CRT multiproceso de MSVC), `/fp:precise` (precisión flotante estricta IEEE-754), advertencias rigurosas `/W4` tratadas como error `/WX`.
   - Aislamiento secuencial: compilado sin directivas `/openmp` ni dependencias de MPI, garantizando un binario puramente monohilo sin interferencias de hilos de soporte de runtime paralelo.

2. **Modelo de memoria y distribución lineal de matrices:**
   - Estructura: [matrix.h](../c_secuencial/include/matrix.h#L19-L27) define el tipo `Matrix` compuesto por `size_t n`, `size_t length` y el apuntador de datos contiguos `double *data`.
   - Distribución: orden mayor por filas (*row-major contiguous layout*), indexado aritméticamente como `data[i * n + j]`. Cada elemento es un `double` de 64 bits (8 bytes según IEEE-754).
   - Constante de cota superior: `MATRIX_MAX_N = 4096` ([matrix.h](../c_secuencial/include/matrix.h#L31-L33)).
   - Validación preventiva: `matrix_validate_dimension` y `matrix_validate_buffer_capacity` ([matrix.c](../c_secuencial/src/matrix.c#L7-L32)) verifican preventivamente antes de cualquier reserva que el recuento de elementos no desborde `SIZE_MAX`, que el volumen en bytes para $k=4$ buffers no supere `PTRDIFF_MAX` (coherente con el límite de direccionamiento de enteros con signo para compatibilidad con Go en Windows x64), y que $n \le \text{MATRIX\_MAX\_N}$.

3. **Arquitectura del núcleo de cálculo (`matrix_accumulate`):**
   - Recorrido de bucles: bucles anidados en orden **`i, k, j`** ([matrix.c](../c_secuencial/src/matrix.c#L118-L131)).
   - Localidad espacial de datos: al fijar el elemento escalar $A[i, k]$ en el bucle medio `k` (`const double a_ik = a_row[k];`), el bucle más interno `j` recorre secuencialmente en memoria contigua los vectores `b_row[j]` y `c_row[j]` con paso unitario (*stride-1*), permitiendo al compilador MSVC emitir vectorización automática SIMD (AVX2/FMA) sobre registros contiguos de 64 bits.
   - Separación estricta de intervalos: `matrix_clear` ejecuta `memset(c, 0, length * sizeof(*c))` antes de medir el kernel; la función `matrix_accumulate` ejecuta puramente la acumulación $C += A \times B$ sin validaciones intermedias ni reinicios de memoria.

4. **Fronteras de cronometraje e instrumentación:**
   - Temporizador: [timer.c](../c_secuencial/src/timer.c#L7-L15) emplea la API de alta precisión de Win32 `QueryPerformanceCounter` y `QueryPerformanceFrequency`, ofreciendo una resolución submicrosegundo monotónica sin deriva de reloj de pared.
   - Validación independiente: [main.c](../c_secuencial/src/main.c#L481-L526) calcula una matriz de referencia idéntica mediante el algoritmo canónico con orden de bucles no optimizado **`i, j, k`** de forma estrictamente previa y **fuera de ambos cronómetros** (`total_s` y `kernel_s`). La comparación celda a celda (`validate_against_reference`) con tolerancia $|c_{ij} - \text{ref}_{ij}| \le 10^{-9} + 10^{-9} |\text{ref}_{ij}|$ se ejecuta tras detener los cronómetros, garantizando que ninguna verificación ni reserva contamine las lecturas temporales.

---

## Separación estricta: hechos medidos frente a hipótesis explicativas

Conforme al rigor metodológico del proyecto, se establece una distinción terminante entre las evidencias fácticas directamente cuantificadas y las hipótesis analíticas que no cuentan con contadores físicos directos:

### Hechos medidos (evidencias empíricas)
1. El tiempo de ejecución del kernel pasa de $0,0235\text{ s}$ en $N=512$, a $0,2019\text{ s}$ en $N=1024$, y a $3,8123\text{ s}$ en $N=2048$.
2. El factor de crecimiento temporal entre $N=1024$ y $N=2048$ es de **18,81×**, alejándose marcadamente del incremento volumétrico cúbico teórico ($8,0×$).
3. La tasa de procesamiento sostenida disminuye drásticamente: de **11,42 GFLOP/s** en $N=512$ y **10,64 GFLOP/s** en $N=1024$, cae a **4,51 GFLOP/s** en $N=2048$ (una degradación de rendimiento de más del 57 %).
4. La dispersión relativa en $N=1024$ exhibió un pico de variabilidad del 10,11 % ($\text{RSD}_{\text{IQR}}$) con una amplitud de $38,7\text{ ms}$ entre el valor mínimo y máximo de las réplicas válidas.

### Hipótesis explicativas (sin instrumentación de contadores de hardware)
> [!IMPORTANT]
> **Aclaración sobre telemetría de hardware:** Durante la campaña oficial `s08_oficial_integrada_03` **no se instrumentaron contadores de rendimiento por hardware** (*Hardware Performance Counters* como eventos PMU de CPU, *cache misses* en L1/L2/L3, o accesos de bus mediante herramientas como Intel VTune o AMD uProf). Por lo tanto, las siguientes explicaciones deben ser consideradas estrictamente como **hipótesis técnicas plausibles**:
- **Hipótesis de saturación de jerarquía de memoria (Caché L3 vs. DRAM):** Cada matriz de $N=2048$ de elementos `double` ocupa exactamente $2048 \times 2048 \times 8\text{ bytes} = 32\text{ MiB}$. Tres matrices activas ($A$, $B$ y $C$) totalizan **96 MiB** de datos, y los 4 buffers de la CLI abarcan **128 MiB**. El procesador de prueba (AMD Ryzen 5 3600) dispone de dos complejos de núcleos (CCX) con un total agregado de $32\text{ MiB}$ de caché L3 compartida ($16\text{ MiB}$ por CCX). En $N=512$ (las 3 matrices ocupan $6\text{ MiB}$) los datos residen cómodamente en L3; en $N=1024$ ($24\text{ MiB}$) aún caben parcialmente; pero en $N=2048$ los conjuntos de trabajo desbordan por completo la caché L3, obligando a desalojos masivos de líneas de caché y forzando accesos continuos a la memoria principal DRAM a través del controlador de memoria infinity fabric. Esta saturación de ancho de banda explicaría la pérdida de GFLOP/s y el factor de escala anómalo de 18,81×.
- **Hipótesis de interferencia de planificación del SO en $N=1024$:** La dispersión relativamente elevada en $N=1024$ ($\text{RSD}_{\text{IQR}} = 10,11\ \%$) podría obedecer a cambios de contexto involuntarios del planificador de Windows 11 o reubicación del hilo entre núcleos físicos durante ejecuciones de $\sim 0,2\text{ s}$, periodo en el cual interrupciones del sistema operativo o tareas en segundo plano generan un retardo proporcionalmente mayor que en ejecuciones de casi 4 segundos.

---

## Límites reales y restricciones de la base C secuencial

La arquitectura y diseño de `c_secuencial` presentan restricciones explícitas que delimitan su alcance operativo:

1. **Monohilo sin concurrencia:** La implementación está diseñada intencionalmente para ejecutarse en un único hilo de ejecución del sistema operativo, sin paralelismo a nivel de hilo (OpenMP o pthreads). No aprovecha la multiplicidad de núcleos del procesador ni la topología NUMA.
2. **Ausencia de bloqueo de bucles (*Cache Tiling* / Bloqueo por bloques):** La función `matrix_accumulate` implementa un recorrido lineal directo `i, k, j`. Aunque el acceso en `j` es contiguo (paso 1), no realiza particionamiento en bloques bidimensionales para ajustarse a los tamaños de línea de las cachés L1/L2/L3. En consecuencia, cuando $N$ sobrepasa la capacidad de las cachés rápidas, la reutilización temporal de filas de $B$ desaparece, quedando atado a la latencia y ancho de banda de niveles inferiores de memoria.
3. **Acoplamiento específico a Windows (Win32 API):** La base actual depende fuertemente de primitivas del sistema operativo Windows (`<windows.h>`, `QueryPerformanceCounter`, `QueryPerformanceFrequency`, `fopen_s`). No es directamente portable a plataformas POSIX (Linux/macOS) sin una capa de compatibilidad o reescritura de `timer.c` y rutinas de E/S.
4. **Techo estructural de dimensión (`MATRIX_MAX_N = 4096`):** La constante de diseño limita la entrada a matrices de como máximo $4096 \times 4096$ elementos ($128\text{ MiB}$ por matriz, $512\text{ MiB}$ para 4 buffers). Cualquier solicitud de dimensión superior es rechazada preventivamente con `MATRIX_INVALID_DIMENSION`.

---

## Directrices para el cómputo de *Speedup* y Eficiencia

Para calcular las métricas canónicas de aceleración en las secciones de paralelismo (`c_paralelo` del Sprint 9):
- **Cálculo de Speedup:** $S(N, P, T) = \frac{\text{mediana}(total\_s_{\text{c\_secuencial}}(N))}{\text{mediana}(total\_s_{\text{c\_paralelo}}(N, P, T))}$.
- **Cálculo de Eficiencia:** $E(N, P, T) = \frac{S(N, P, T)}{P \times T}$.
- Se deben utilizar los valores con precisión total sin redondear extraídos del archivo consolidado [resumen_estadistico.csv](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv).

Para reproducir de manera determinista las filas oficiales de `c_secuencial` desde la raíz del repositorio:
```powershell
$id = 's08_oficial_integrada_03'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\summarize_results.ps1 `
    -InputPath "resultados/raw/$id/mediciones.csv" -CampaignId $id |
    ConvertFrom-Csv | Where-Object version -eq 'c_secuencial'
```
