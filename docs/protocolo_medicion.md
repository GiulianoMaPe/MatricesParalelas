# Protocolo de medición y diseño experimental

**Versión:** 1.2 (Correcciones del entregable de I7 · 2026-10-01; base de Andrés)
**Estado:** Diseño técnico de S1/S2 conforme y verificado. Las evaluaciones asistidas en la voz de Gerardo (I6) están registradas en [S1](sprints/sprint-01.md) y [S2](sprints/sprint-02.md). Los núcleos y las mediciones corresponden a los sprints posteriores.
**Documentos relacionados:** `docs/Guia_Sprints.md`, [`docs/contrato.md`](contrato.md), [`docs/bibliografia.md`](bibliografia.md)

---

## 1. Propósito y Marco Metodológico

Este documento establece el **Protocolo de Medición Versión Inicial** del proyecto, en cumplimiento de los objetivos del Sprint 2 para el **Integrante 7**. Su finalidad es garantizar que las futuras campañas de medición (Piloto en S7 y Campaña Oficial en S8) se ejecuten bajo condiciones científicamente rigurosas, reproducibles y equitativas entre las cuatro versiones del software:
* `c_secuencial`: Referencia secuencial en C compilada con MSVC x64 sin OpenMP ni MPI.
* `c_paralelo`: Implementación híbrida en C con MS-MPI para memoria distribuida y OpenMP para memoria compartida.
* `go_secuencial`: Referencia secuencial en Go windows/amd64.
* `go_paralelo`: Implementación concurrente en Go con pool acotado de workers, canales tipados y `sync.WaitGroup`.

> [!IMPORTANT]
> Siguiendo el contrato del proyecto, las solicitudes de cálculo actuales devuelven código `2` (operación pendiente); los smoke tests correctos devuelven 0. Los errores se convierten a 1. Ninguna prueba de instalación o smoke test se reporta como medición de rendimiento. Las mediciones reales se habilitarán únicamente cuando los algoritmos de multiplicación pasen la verificación matemática elemento a elemento ($\text{atol}=10^{-9}, \text{rtol}=10^{-9}$).

---

## 2. Preguntas de rendimiento e hipótesis por comprobar

Estas hipótesis son propuestas del equipo, no resultados medidos ni conclusiones
demostradas por la bibliografía. Un resultado desfavorable también se conserva.

| Pregunta | Comparación y métricas | Hipótesis que se contrastará |
| --- | --- | --- |
| P1. ¿En qué tamaños y presupuestos mejora el paralelo? | Medianas de total_s y speedup contra el secuencial del mismo lenguaje, para cada N/W; mínimo, máximo e IQR. | Un trabajo mayor puede amortizar la coordinación. No se fija de antemano un umbral N=512 ni se garantiza speedup mayor que 1. |
| P2. ¿Cómo influye P frente a T con igual W? | C: 1×4, 2×2 y 4×1 con W=4, mismos N/semilla/PC/compilación; total_s, kernel_s y memoria estimada. | Menos procesos podrían reducir copias de B; se comprobará en esta PC. La literatura no demuestra cuál de estas configuraciones será superior. |
| P3. ¿Cómo cambia la escalabilidad de cada implementación? | Curvas S y E de C y Go respecto a sus propias referencias, por W. Comparar también tiempos absolutos. | La coordinación puede limitar la mejora al aumentar W. Las curvas no aíslan el coste del planificador ni prueban ausencia de carreras. |
| P4. ¿Cómo cambia el rendimiento al crecer la huella matricial? | GFLOPS estimados (§7.3), tiempos y bytes matriciales (§5.4), para cada N/configuración. | La localidad podría influir en las variaciones; sin contadores de caché o ancho de banda no se atribuirá una caída a fallos de caché o saturación de RAM. |
| P5. ¿Qué diferencias absolutas hay entre C y Go bajo condiciones equivalentes? | Medianas de total_s/kernel_s con entradas, orden i,k,j, representación, PC y presupuesto iguales. | Las diferencias pueden depender del compilador, opciones, runtime, coordinación y hardware. No se atribuyen únicamente al lenguaje. |

Por corrida se pueden presentar los indicadores `total_s - kernel_s` y
`100 * kernel_s / total_s` cuando total_s > 0. No representan una medición
exacta de comunicación ni utilización de CPU; su interpretación depende de las
agregaciones de §3. No usar MPI_Init ni el lanzamiento del proceso para explicar
total_s, pues están fuera de sus fronteras.

---

## 3. Límites comunes de `kernel_s` y `total_s`

Estas reglas son la referencia única para los cuatro programas y para
`docs/arquitectura.md`. Los relojes miden duraciones, no timestamps de pared.

### 3.1 Preparación y tiempo total

Antes de T0: procesar argumentos, validar dimensiones/capacidad, reservar todos
los buffers matriciales, leer o generar A/B y preparar la referencia de validación.
Reservar también los vectores de instrumentación. En MPI, todos los procesos
preparan sus buffers y sincronizan el inicio con una barrera fuera del intervalo.

| Versión | T0: inicio de `total_s` | Trabajo incluido | T1: fin de `total_s` |
| --- | --- | --- | --- |
| C secuencial | Antes de vaciar C. | Vaciado y bucles i,k,j. | Después del cálculo. |
| Go secuencial | Antes de vaciar C ya reservada. | Vaciado y bucles i,k,j. | Después del cálculo. |
| C híbrido | Después de la barrera inicial, antes de Bcast. | Bcast de B, Scatterv de A, vaciado de C local, cálculo OpenMP y Gatherv de C. | En cada rank inmediatamente después de Gatherv. |
| Go paralelo | Antes de vaciar C ya reservada y de crear canales/workers. | Vaciado, creación/lanzamiento, envío de tareas, cálculo, cierre del canal y WaitGroup. | Inmediatamente después de `wg.Wait()`. |

No añadir validación, escritura ni liberación de matrices antes de T1. El coste
de crear canales/workers es coordinación y sí pertenece a total_s; la reserva
de A/B/C queda fuera. Incluso si una reserva nueva ya entrega C a cero, cada
corrida realiza un vaciado explícito dentro de total_s para usar la misma frontera.

### 3.2 Tiempo de cálculo

`kernel_s` mide la acumulación i,k,j con C ya vaciada. Excluye el vaciado,
comunicación MPI, despacho/recepción del canal, cierre y espera del coordinador.

| Versión | Intervalo local | Agregación | Reloj |
| --- | --- | --- | --- |
| C secuencial | Antes del bucle i y después de la última acumulación. | Duración directa. | QueryPerformanceCounter/Frequency. |
| Go secuencial | Antes del bucle i y después de la última acumulación. | Duración directa. | time.Now/Since. |
| C híbrido | Región OpenMP de acumulación de filas locales ya vaciadas. Sin llamadas MPI dentro. | Máximo de duraciones locales con MPI_Reduce/MPI_MAX. Rank sin filas: 0. | MPI_Wtime. |
| Go paralelo | En cada tarea, desde justo antes de multiplyBlock hasta justo después. Cada worker suma sus intervalos; no cronometra la espera de tareas. | Máximo de los acumulados por worker. Worker sin tareas: 0. | time.Now/Since. |

La región OpenMP conserva su planificación y barrera implícita de terminación;
eso pertenece a la región local medida. No se incluyen colectivas MPI. En Go
no se usa un cronómetro desde el primer envío hasta WaitGroup: ese intervalo
incluye reparto/espera y no cumple la definición de cálculo.

Después de T1 se obtiene el máximo de los tiempos Go. En MPI, los ranks reducen
los tiempos kernel y total con MPI_MAX **después** de detener sus relojes; solo
rank 0 emite la medición. Nunca restar timestamps de procesos distintos.

Go reporta un máximo de tiempos acumulados, no la distancia entre el inicio del
primer worker y el fin del último. C híbrido reporta el máximo de su región local.
Por ello, total_s - kernel_s es un indicador del coste fuera del kernel y no una
descomposición exacta del sobrecoste cuando cálculo y despacho se solapan.
Los relojes de pared monotónicos también incluyen la desplanificación del sistema.

### 3.3 Exclusiones y aceptación

Fuera de ambos tiempos quedan argumentos, lectura de fixtures, generación,
reserva/liberación de buffers de matrices, validación numérica y escritura de
matrices/CSV. El arranque de mpiexec y MPI_Init/Finalize se registra aparte si se
estudia latencia de extremo a extremo.

Aceptar solo duraciones finitas y no negativas con validación matemática OK.
Para una misma ejecución, kernel_s no debe superar total_s. Una diferencia por
resolución de reloj se conserva como ERROR para revisar la instrumentación;
no se corrigen ni recortan los tiempos para aceptarlos.
Un fallo/pending termina con el código común (1/2), sin fila de medición válida.
Los scripts pueden registrar el fallo con un estado y tiempos vacíos; no inventar
ceros como si fueran observaciones reales ni incluirlos en medianas/speedup.

El vaciado de C se repite en calentamiento y mediciones. Las fronteras serán
implementadas en S3/S4; este acuerdo no produce tiempos ni habilita benchmarks.

---

## 4. Diccionario de Datos del Archivo CSV

Los scripts de automatización (`bench_windows.ps1` en S7/S8) exportarán las observaciones en formato UTF-8 sin BOM, con coma (`,`) como separador y punto (`.`) como separador decimal. La primera línea contendrá obligatoriamente la cabecera. Usar LF o CRLF de forma consistente; los campos con comas, comillas o saltos de línea se encierran entre comillas dobles y cada comilla interna se duplica. La salida de matrices usa el formato de `formato_datos.md`, no CSV. No confundir `version` (programa) con la versión del compilador; las herramientas se identifican en los metadatos de §4.2.

### Estructura de Columnas

| N° | Columna | Tipo de Dato | Rango / Formato | Descripción | Ejemplo |
| :---: | :--- | :---: | :--- | :--- | :--- |
| 1 | `timestamp` | String | ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) | Momento exacto de inicio de la medición. | `2026-10-15T14:32:05Z` |
| 2 | `version` | String | `c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo` | Identificador de la versión bajo prueba. | `c_paralelo` |
| 3 | `commit` | String | Hash hexadecimal de 7 a 40 caracteres | Prefijo del commit completo de los metadatos; código compilado en Release. | `87fd548` |
| 4 | `hostname` | String | Nombre del equipo, incluidos guiones | Nombre del nodo/computadora de prueba. | `PC-ANDRES` |
| 5 | `cpu_model` | String | Texto descriptivo | Modelo comercial de la CPU del equipo. | `AMD Ryzen 7 8845HS` |
| 6 | `ram_gb` | Float | Decimal positivo | RAM visible al sistema dividida entre 2^30 (GiB); nombre de columna conservado. No es memoria disponible. | `8.0` |
| 7 | `os_version` | String | Texto descriptivo | Edición y compilación de Windows 11. | `Win11_26200` |
| 8 | `configuration` | String | Texto estructurado | Etiqueta canónica de la configuración de ejecución. | `c_paralelo_P2_T2` |
| 9 | `n` | Integer | Entero positivo $\ge 1$ | Dimensión de las matrices cuadradas ($N \times N$). | `1024` |
| 10 | `seed` | Integer | Entero sin signo 32 bits ($0$ a $2^{32}-1$) | Semilla utilizada para la generación pseudoaleatoria. | `42` |
| 11 | `processes` | Integer | Entero $\ge 1$ | Procesos MPI solicitados ($P$). Vale 1 en versiones no MPI. | `2` |
| 12 | `threads` | Integer | Entero $\ge 1$ | Hilos OpenMP solicitados ($T$). Vale 1 en versiones no OpenMP. | `2` |
| 13 | `observed_threads` | Integer | Entero $\ge 1$; vacío si no se pudo observar | Hilos reales de la región OpenMP; 1 como valor convencional fuera de C paralelo. | `2` |
| 14 | `workers` | Integer | Entero $\ge 1$ | Workers solicitados de Go paralelo; 1 convencional en las otras versiones. | `4` |
| 15 | `gomaxprocs` | Integer | Entero $\ge 1$ en Go; vacío en C | Valor efectivo de `runtime.GOMAXPROCS(0)`; fijar 1 en Go secuencial y W en Go paralelo. | `4` |
| 16 | `repetition` | Integer | $0, 1, 2, 3, 4, 5$ | Índice de la repetición ($0$ = precalentamiento/warmup). | `1` |
| 17 | `is_warmup` | Boolean | `true`, `false` | Indica si la corrida es de precalentamiento descartada. | `false` |
| 18 | `kernel_s` | Float | Finito $\ge 0.0$, 9 decimales; vacío si falla | Duración del cálculo según §3.2, en segundos. | `0.485123901` |
| 19 | `total_s` | Float | Finito $\ge 0.0$, 9 decimales; vacío si falla | Tiempo de cómputo y coordinación según §3.1, en segundos. | `0.521894210` |
| 20 | `validation_status` | String | `OK`, `PENDING`, `MISMATCH`, `OOM`, `TIMEOUT`, `ERROR` | Estado de verificación matemática y ejecución. | `OK` |

### 4.1 Reglas entre campos y tratamiento de fallos

- `configuration`: `c_secuencial`, `go_secuencial`, `c_paralelo_P{P}_T{T}`
  o `go_paralelo_W{W}`; debe coincidir con version y parámetros de la fila.
- `is_warmup` es true si y solo si repetition=0. Repeticiones 1..5 son medidas.
- Un OK exige salida 0 y validación completa; kernel_s y total_s deben estar
  presentes y cumplir §3.3. Un cero temporal válido se conserva, pero no se divide
  por cero al calcular métricas derivadas.
- Fuera de OK ambos tiempos quedan vacíos. PENDING corresponde a salida 2;
  MISMATCH/OOM/ERROR, a salida 1. TIMEOUT lo registra el script al agotar el
  plazo fijado en los metadatos y detener el proceso o árbol MPI; no se presupone
  un código de salida normal. Conservar código real, stdout/stderr y motivo en
  la bitácora. Los diagnósticos nunca cuentan como observaciones válidas.
- C paralelo solicita OMP_DYNAMIC=FALSE; registrar hilos observados por rank
  en la bitácora. Un OK exige que todos los ranks con filas observen T y que
  `observed_threads=T`. Si difieren, registrar ERROR. Los ranks sin filas no
  necesitan una región OpenMP. Fuera de C paralelo observed_threads=1 es una
  convención de esquema, no una observación de hilos del sistema operativo.

### 4.2 Metadatos reproducibles de cada campaña

Cada carpeta de campaña (§8) contiene `entorno.json`, `plan.csv`,
`mediciones.csv` y `bitacora.txt`. El directorio identifica la campaña sin añadir
columnas al CSV de 20 campos. Copiar y completar la
[plantilla de entorno](plantillas/entorno_medicion.json) antes de medir:

- ID, fase piloto/oficial, versión del protocolo, fecha UTC, operador, hostname
  y commit completo. La campaña oficial usa un árbol limpio; en el piloto,
  cualquier cambio local exige conservar el diff junto a los metadatos.
- CPU, núcleos físicos y lógicos, RAM visible en bytes, RAM disponible al iniciar,
  edición/build de Windows, alimentación y plan de energía constante.
- Versiones exactas de MSVC, Windows SDK, MS-MPI Runtime/SDK y Go, GOOS/GOARCH,
  objetivo x64, modo Release, opciones efectivas de compilación, variables
  OMP/GOMAXPROCS usadas y SHA-256 de los cuatro ejecutables.
- N, semilla, presupuestos habilitados, lista ordenada de configuraciones,
  1 warmup/5 repeticiones, criterio de memoria y timeout por corrida decidido
  con el piloto. `plan.csv` fija el orden, N, configuration, seed, repetition
  e is_warmup de cada corrida; la bitácora conserva incidencias y orden real.

La cabecera de plan.csv es
`execution_order,n,configuration,seed,repetition,is_warmup`, con orden entero
consecutivo desde 1. Primero se listan los warmups en orden L y luego las cinco
rondas de §6.2. Este archivo contiene parámetros planificados, nunca tiempos.
Solo diff_file puede quedar null si el árbol está limpio; para ajustes exclusivos
de C/Go, los mapas de variables de entorno identifican las configuraciones a las
que corresponden, sin inventar valores para las otras versiones.

No copiar versiones de otra PC ni completar datos desconocidos por suposición.
Los null de la plantilla significan pendientes de captura: no habilitan una
campaña. Metadatos de hostname/commit deben coincidir con todas sus filas CSV.

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
| **Línea Base** | `c_secuencial` | Un trabajador de cálculo | Referencia fundamental para calcular Speedup en C. |
| **Línea Base** | `go_secuencial` | Un trabajador de cálculo; GOMAXPROCS=1 | Referencia fundamental para calcular Speedup en Go. |
| **$W = 1$** | `c_paralelo` | $P=1, T=1$ | Medición del sobrecoste intrínseco del runtime MPI/OpenMP vs. C puro. |
| **$W = 1$** | `go_paralelo` | $\text{workers}=1, \text{GOMAXPROCS}=1$ | Medición del sobrecoste de goroutines y canales vs. Go puro. |
| **$W = 2$** | `c_paralelo` | $P=1, T=2$ | Evaluación de OpenMP puro en 2 hilos. |
| **$W = 2$** | `c_paralelo` | $P=2, T=1$ | Evaluación de MS-MPI puro en 2 procesos. |
| **$W = 2$** | `go_paralelo` | $\text{workers}=2, \text{GOMAXPROCS}=2$ | Concurrencia en 2 núcleos físicos. |
| **$W = 4$** | `c_paralelo` | $P=1, T=4$ | OpenMP dominante (memoria compartida pura). |
| **$W = 4$** | `c_paralelo` | $P=2, T=2$ | Topología balanceada; su rendimiento se comprobará. |
| **$W = 4$** | `c_paralelo` | $P=4, T=1$ | MPI dominante (distribución intensiva entre procesos). |
| **$W = 4$** | `go_paralelo` | $\text{workers}=4, \text{GOMAXPROCS}=4$ | Concurrencia en 4 trabajadores. |
| **$W = 8$** *(PCs $\ge 8$ núcleos físicos)* | `c_paralelo` | $P=1, T=8$ | OpenMP puro en 8 hilos. |
| **$W = 8$** *(PCs $\ge 8$ núcleos físicos)* | `c_paralelo` | $P=2, T=4$ | Híbrido 2 procesos $\times$ 4 hilos. |
| **$W = 8$** *(PCs $\ge 8$ núcleos físicos)* | `c_paralelo` | $P=4, T=2$ | Híbrido 4 procesos $\times$ 2 hilos. |
| **$W = 8$** *(PCs $\ge 8$ núcleos físicos)* | `c_paralelo` | $P=8, T=1$ | MPI puro en 8 procesos. |
| **$W = 8$** *(PCs $\ge 8$ núcleos físicos)* | `go_paralelo` | $\text{workers}=8, \text{GOMAXPROCS}=8$ | Concurrencia en 8 trabajadores. |

### 5.3. Volumen de Mediciones por Campaña

La tabla completa tiene 2 secuenciales + 10 híbridas C + 4 paralelas Go =
**16 configuraciones por N**. Con tres dimensiones: 48 combinaciones,
48 calentamientos + 240 medidas = **288 ejecuciones**, tanto para el piloto
como para la campaña oficial, si se habilitan todos los presupuestos.

| W máximo habilitado | Configuraciones C paralelo | Go paralelo | Total por N, incluidos 2 secuenciales | Warmups para 3 N | Medidas para 3 N | Corridas totales |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 4 | 12 | 60 | 72 |
| 2 | 3 | 2 | 7 | 21 | 105 | 126 |
| 4 | 6 | 3 | 11 | 33 | 165 | 198 |
| 8 | 10 | 4 | 16 | 48 | 240 | 288 |

N=4096 añade otras 96 corridas con W máximo 8: 16 warmups y 80 medidas;
total oficial extendido **384**, no 288. Las semillas complementarias son lotes
separados; no están incluidas en estos conteos. Si se omiten configuraciones por
capacidad, recalcular como `número de pares (N, configuración) habilitados × 6`
y conservar las exclusiones justificadas en el plan.

### 5.4 Selección según CPU, memoria y tiempo disponibles

Para la campaña principal habilitar W=1,2,4 y, si hay capacidad, 8 hasta el
número de núcleos físicos disponibles. No excederlo ni confundir hilos lógicos
con núcleos físicos; un estudio de SMT o sobreasignación sería una campaña
separada. P*T o workers es un presupuesto nominal, no una afinidad de CPU.

El [entorno de Andrés](entorno/7-andres.md), registrado el 29/09/2026, indica
8 núcleos físicos, 16 lógicos y **8 GB visibles**, con MSVC y MS-MPI SDK
todavía pendientes en ese registro. Es candidata para W=8; confirmar dependencias
y memoria disponible antes del piloto. Ese registro no prueba que pueda medir hoy.

Sea `S = 8*N*N` bytes por matriz double/float64. El diseño requiere A/B/C y
una referencia completa de C antes del cronómetro. En C híbrido, contar además
una B por rank no raíz y los bloques locales A/C de todos los ranks. Si la raíz
conserva A/B/C completos y reserva bloques locales separados, la estimación
conservadora matricial es `(P+5)*S` para toda la PC. El resto de ranks requiere
`S + 2*filas_locales*N*8` cada uno; la raíz requiere
`4*S + 2*filas_raíz*N*8`. No sumar tres matrices una sola vez para todo MPI.

| N | Una matriz (MiB) | Secuenciales/Go paralelo, A/B/C + referencia (MiB) | C híbrido P=8, todas las matrices + referencia (MiB) |
| --- | --- | --- | --- |
| 256 | 0.5 | 2 | 6.5 |
| 512 | 2 | 8 | 26 |
| 1024 | 8 | 32 | 104 |
| 2048 | 32 | 128 | 416 |
| 4096 | 128 | 512 | 1664 |

MiB=2^20 bytes. Esta tabla no incluye runtime MPI/Go, pilas, canales, metadatos
ni temporales adicionales. Como criterio inicial del protocolo, reservar como
máximo el 50% de la RAM **disponible** al inicio para esta estimación matricial;
el margen no garantiza ausencia de paginación. Confirmar picos reales en S6/S7
y excluir configuraciones que superen la capacidad sin alterar N entre lenguajes.

N=4096 se habilita solo tras comprobar memoria y duración. El coste cúbico del
algoritmo permite una estimación preliminar de 8 veces el tiempo de N=2048,
pero no garantiza esa duración. Usar el piloto para fijar timeout por corrida y
presupuesto de tiempo de máquina; guardar ambos en entorno.json y congelar
el plan antes de la campaña oficial. Excluir 4096 si no cumple esos límites.

---

## 6. Protocolo de Ejecución y Mitigación de Sesgos

Para garantizar la fiabilidad estadística y evitar distorsiones originadas por el sistema operativo o el hardware:

### 6.1. Protocolo de 1 Precalentamiento + 5 Repeticiones
* **Corrida 0 (Warmup descartado):** Primera ejecución de cada combinación, registrada con `is_warmup = true` y excluida de las estadísticas. Puede reducir algunos efectos iniciales; no garantiza estabilizar frecuencias, temperatura o cachés. Si cada corrida lanza un proceso nuevo, el runtime y las matrices también se preparan de nuevo fuera de los cronómetros (§3).
* **Corridas 1 a 5 (Mediciones oficiales):** Cinco observaciones por configuración, intercaladas entre rondas y registradas con `is_warmup = false`.

### 6.2. Orden alternado entre rondas

Mantener la lista L de todas las combinaciones habilitadas de N/configuración,
ordenada por N ascendente y por las filas de la tabla §5.2, y guardarla en el plan.
Ejecutar un calentamiento por combinación y luego cinco rondas completas;
cada ronda toma una observación de cada combinación. Alternar orden directo
en rondas impares e inverso en pares, y conservar el orden real de ejecución:

```text
Lista L: [c_secuencial,N512], [go_secuencial,N512], [c_paralelo_P1_T1,N512], ...
Ronda 1: L
Ronda 2: reverse(L)
Ronda 3: L
Ronda 4: reverse(L)
Ronda 5: L
```

No hacer cinco corridas seguidas de cada configuración ni ejecutar dos benchmarks
a la vez. Para la tabla completa hay 48 warmups y 240 observaciones medidas.


### 6.3. Justificación del Uso de la Mediana y Rango Intercuartílico (IQR)
Usar las cinco corridas OK no warmup de cada grupo campaña/versión/configuración/
N/semilla; no mezclar PCs, commits, compilaciones ni semillas. Para cada tiempo,
ordenar `x1 <= x2 <= x3 <= x4 <= x5`: mediana=x3, Q1=x2, Q3=x4,
IQR=x4-x2, mínimo=x1, máximo=x5 (cuartiles por interpolación inclusiva).
La mediana reduce la influencia de valores extremos; no elimina todos los sesgos.

Conservar observaciones lentas o speedup menor que 1. Si una corrida falla,
el grupo queda incompleto y no participa en speedup oficial. Conservar el fallo,
investigar la causa y, si se repite, ejecutar un lote completo de warmup + 5
medidas en una nueva carpeta de campaña/intento, con la referencia secuencial
correspondiente. No sustituir solo la observación más lenta ni escoger el mejor lote.

### 6.4. Condiciones de Entorno Obligatorias
Antes de iniciar una campaña de medición:
1. Compilar todas las versiones en modo **Release** mediante `build_windows.ps1 -Version all -Configuration Release`.
2. Fijar el plan de energía de Windows en **Alto Rendimiento** o **Equilibrado** (documentado en `docs/entorno/`).
3. Cerrar navegadores web, clientes de mensajería y servicios de sincronización en la nube (OneDrive, Google Drive).
4. Verificar que no haya tareas automáticas de Windows Update activas.
5. Ejecutar los scripts de medición de forma aislada (un único benchmark activo a la vez).
6. Confirmar validación matemática, hardware disponible y plan de §5.4; completar
   metadatos, checksums y orden de ejecución. Mantener alimentación/energía y
   compilación constantes; registrar incidencias de carga o temperatura.

---

## 7. Fórmulas Matemáticas para el Análisis de Rendimiento

El análisis de datos en el Sprint 9 empleará las siguientes formulaciones canónicas:

### 7.1. Speedup ($S$)
Calculado respecto a la referencia secuencial del **mismo lenguaje**, en la misma
campaña/PC/commit/compilación y con iguales N/semilla. Usar cinco medidas OK en
ambos grupos y denominador positivo; si falta la referencia, no publicar speedup:
$$S_{\text{C}}(N, P, T) = \frac{\widetilde{T}_{\text{total, c\_secuencial}}(N)}{\widetilde{T}_{\text{total, c\_paralelo}}(N, P, T)}$$

$$S_{\text{Go}}(N, W) = \frac{\widetilde{T}_{\text{total, go\_secuencial}}(N)}{\widetilde{T}_{\text{total, go\_paralelo}}(N, W)}$$

### 7.2. Eficiencia Paralela ($E$)
Es el speedup por trabajador nominal; no mide utilización efectiva de CPU:
$$E_{\text{C}}(N, P, T) = \frac{S_{\text{C}}(N, P, T)}{P \times T}$$

$$E_{\text{Go}}(N, W) = \frac{S_{\text{Go}}(N, W)}{W}$$

E=1 corresponde a speedup lineal respecto al presupuesto declarado. Una eficiencia
baja indica poca mejora por trabajador; por sí sola no demuestra comunicación,
contención ni saturación. No truncar valores superiores a 1 si aparecen: conservar
los datos y revisar condiciones, dispersión e instrumentación.

### 7.3 Rendimiento aritmético estimado

Para los bucles i,k,j de este proyecto se cuentan N^3 productos y N^3 sumas:
`GFLOPS_kernel = 2*N^3 / (mediana(kernel_s)*10^9)`, únicamente si la mediana
es positiva y el grupo está completo. Es una convención de conteo aritmético,
no un conteo de instrucciones ejecutadas. Se puede reportar la misma fórmula
con total_s como `GFLOPS_total`, identificándola por separado. En paralelo,
la interpretación del denominador sigue la agregación de §3.2.

---

## 8. Rutas de Almacenamiento y Versionamiento de Datos

Cada sesión/PC/intento usa un ID único, por ejemplo
`20261015T143205Z_PC-ANDRES_87fd548_intento01` (ejemplo, no campaña realizada):

* **Piloto (S7):** `resultados/piloto/<campaign_id>/`.
* **Oficial (S8):** `resultados/raw/<campaign_id>/`.
* En cada carpeta: `entorno.json`, `plan.csv`, `mediciones.csv`, `bitacora.txt`
  y, si corresponde en piloto, el diff del código. No sobrescribir intentos.
* **Resúmenes (S9):** `resultados/resumen/<campaign_id>/resumen_estadistico.csv`.
* **Gráficos (S9):** `resultados/graficos/<campaign_id>/*.png`.

Conservar los datos crudos y sus metadatos juntos, localmente o en anexos accesibles;
los resúmenes deben identificar la campaña de origen. Versionar protocolo,
plantillas, manifiestos, resúmenes finales y gráficos. No crear CSV de tiempos
para probar este diseño: los programas y scripts de medición siguen pendientes.
