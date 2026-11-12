# Registro de decisiones de rendimiento — Sprint 6

Revisión del 11/11/2026, rama `feature/s06-optimizacion-evidencia`, base `dd008f7`.
El usuario autorizó ejecutar la parte que no requiere Windows. Se conserva el
algoritmo de producción y se estudian candidatas en archivos de pruebas; no se
declara una optimización MSVC/MS-MPI sin sus observaciones correspondientes.

## Decisiones por hipótesis

| ID | Base y candidata aislada | Qué cambia y cómo se valida | Decisión para producción |
| --- | --- | --- | --- |
| C-01 | `matrix_accumulate` frente a `restrict_c` | Solo la información de no alias de C; mantiene i,k,j y tipos. Cada celda se compara con referencia i,j,k. | Base conservada; candidata experimental, pendiente de Windows. |
| C-02 | Kernel local OpenMP `static` frente a `static,1` | Solo granularidad estática; mismos N y T, región y referencia. No cambia comunicación porque el laboratorio no ejecuta MPI. | Base conservada; P/T híbrido pendiente de MS-MPI. |
| GO-01 | `multiplyKernel` frente a `row_slices` | Slices por fila, sin copiar datos; mismos bucles y producto. Pruebas con cinco semillas, impares, repetición y A/B inmutables. | Base conservada; mejora candidata que debe contrastarse en Windows y también en el kernel paralelo antes de promoverse. |
| GO-02 | Pool actual frente a `block16` | Solo tamaño de tarea: 16 filas frente a ceil(N/W), mismo canal W y worker de producción. | Base conservada; experimento de granularidad. |
| GO-03 | Pool actual frente a `unbuffered` | Solo capacidad del canal: 0 frente a W, mismo bloque ceil(N/W). | Base conservada; experimento de coordinación. |
| MEM-01 | Modelo de buffers y picos RSS | Memoria estimada por implementación y picos del proceso de laboratorio, incluyendo la referencia. | Límites Windows aún sujetos a medición por rank y RAM disponible. |

No se introduce tiling, transposición, precisión reducida, BLAS, intrínsecos SIMD
ni `fast-math`. Tampoco se elimina validación, vaciado o coordinación para
aparentar menor tiempo. C ya utilizaba punteros de fila y Go ya tenía un kernel
sin reservas de datos explícitas: no se presentan como cambios nuevos.

## Método y trazabilidad

El runner [sprint06_lab.py](../scripts/sprint06_lab.py) construye dos harnesses C
y dos ejecutables de pruebas Go. Las candidatas residen exclusivamente en
[el harness C](../tests/sprint06_kernel_bench.c),
[pruebas Go secuenciales](../go_secuencial/sprint06_test.go) y
[pruebas Go paralelas](../go_paralelo/sprint06_test.go).

Se usa semilla 42 y un proceso nuevo para cada observación. Antes del cronómetro
se preparan A/B/C y una referencia independiente i,j,k. Total incluye el vaciado
de C y kernel lo excluye; en Go paralelo también se incluye creación, despacho,
cierre y espera, y se toma el máximo de acumulados por worker.

Por combinación se conserva repetición 0 de calentamiento y cinco rondas
intercaladas, alternando el orden directo/inverso. Solo grupos de seis corridas
OK con repeticiones únicas 0..5 producen resumen. Se calcula mediana=x3 e
IQR=x4−x2 de las cinco medidas ordenadas. La reducción porcentual usa
`100*(mediana_base-mediana_candidata)/mediana_base`; puede ser negativa.

El esquema es `s06-laboratory-v1` y no el CSV de veinte columnas de campaña.
No se comparan tiempos Linux contra Windows ni GCC contra MSVC. No se publica
speedup oficial ni se interpreta `total-kernel` como el coste exacto del canal.

Los datos originales conservan comandos, stdout/stderr, estado, tiempos y RSS.
El entorno incluye revisión, fuentes exactas y sus hashes, herramientas, comandos
de compilación y SHA-256 de binarios. Esto identifica las candidatas aunque se
hayan medido antes del commit de la entrega. Los builds son regenerables.

## Asignaciones y localidad

Las observaciones Go incluyen asignaciones por llamada de kernels/pool con
N=17, fuera de los intervalos de tiempo y del N principal. La API secuencial
`Multiply` se diagnostica aparte porque reserva C y valida entradas/salida.
`testing.AllocsPerRun` fuerza temporalmente GOMAXPROCS=1 para ese diagnóstico;
no se usan sus tiempos para inferir escalabilidad.

En el pool es esperable reservar canal, WaitGroup/closures y goroutines dentro
de total_s. No se impone la falsa condición de cero asignaciones para toda
coordinación ni se desplazan esas reservas fuera del cronómetro.

El recorrido contiguo se comprueba por inspección del código. No hay contadores
de caché disponibles en esta sesión; por tanto no se afirma una tasa de aciertos,
una saturación de memoria o una causa de rendimiento a partir del tiempo solo.

## Límites de la evidencia

- Los kernels C se midieron con GCC y el pool Go con runtime Linux. El híbrido
  se limita al kernel OpenMP local; no ejecuta Bcast/Scatterv/Gatherv.
- El escritorio seguía activo, con memoria disponible registrada en el entorno.
  No se estableció una sesión térmica/energética controlada equivalente a la
  futura PC oficial. Los resultados se consideran exploratorios.
- Los picos RSS incluyen el harness/runtime y pequeñas pruebas de asignaciones;
  no equivalen a bytes matriciales puros ni a memoria privada comprometida.
- Las candidatas pueden presentar variaciones entre N, W y corridas. No se
  selecciona solo el mejor intento ni se elimina una observación lenta.
- Sin batería MSVC/MS-MPI y comparativas Windows, no se promueve ninguna
  candidata ni se declara cerrado el criterio de optimización de la campaña.

## Inspección del compilador C

En las unidades separadas, GCC con `-O2 -ffp-contract=off` informa cero bucles
vectorizados en `matrix_accumulate` y un bucle vectorizado con vectores de
16 bytes en la candidata con C restringida. Los reportes están en
[base](../resultados/diagnostico/s06/verificacion_20261112T032934Z/c_baseline_vectorization.report.txt)
y [candidata controlada](../resultados/diagnostico/s06/verificacion_20261112T032934Z/c_candidate_controlled_vectorization.report.txt).
Esto describe el código que ese compilador genera, no demuestra aciertos de
caché ni garantiza que MSVC tome la misma decisión.

## Paso de aceptación pendiente

Seguir [reproducción S6](sprint06_reproduccion.md), repetir la regresión Windows
en Debug/Release y comparar antes/después en la misma PC con metadatos completos.
Confirmar memoria y equidad antes de aceptar una mejora. La diferencia debe ser
consistente respecto a la dispersión y los tamaños prioritarios; un porcentaje
fijo por sí solo no acredita significación estadística. Si la evidencia es
inconclusa, conservar la base sigue siendo una decisión válida.


## Resultados y corrección metodológica

Se conservan dos intentos completos, con **486 corridas numéricamente válidas**:

- **A:** [primer lote](../resultados/diagnostico/s06/20261112T033150Z_fedora/entorno.json), 342 corridas: 57 calentamientos y 285
  medidas. [Observaciones](../resultados/diagnostico/s06/20261112T033150Z_fedora/observaciones.jsonl) y [resumen](../resultados/diagnostico/s06/20261112T033150Z_fedora/resumen.csv).
- **B:** [control C con compilación separada](../resultados/diagnostico/s06/20261112T035217Z_fedora/entorno.json), 144 corridas:
  24 calentamientos y 120 medidas. [Observaciones](../resultados/diagnostico/s06/20261112T035217Z_fedora/observaciones.jsonl)
  y [resumen](../resultados/diagnostico/s06/20261112T035217Z_fedora/resumen.csv).

La revisión de A detectó que la candidata C se compilaba junto al harness y la
base en otra unidad. Esa diferencia de visibilidad podía influir en el código
generado. Se trasladó la candidata a `tests/sprint06_candidates.c`, con las
mismas comprobaciones y bucles, cambiando solo alias de C o planificación,
y se repitieron todos los grupos C en B, sin LTO y con unidades separadas.

**Las conclusiones C usan solo B; las Go usan solo A.** No se mezclan
observaciones individuales ni se elige el intento más rápido. Los grupos C de
A se conservan como exploración supersedida por esta corrección metodológica.
Cada comparación base/candidata sigue perteneciendo a un único intento.

La suma de pared de A y B fue 1264.5 segundos, distinta del tiempo activo de
trabajo. Se conservaron 45 fuentes exactas en A y 46 en B, con hashes y comandos.
El host es Fedora Linux, Ryzen 5 3600, 6 núcleos físicos/12 lógicos, GCC 16.2.1
y Go 1.27.4. W=8 no se habilitó por superar los núcleos físicos.

Cada celda muestra **mediana total base → candidata en ms (reducción %)**.
La dispersión, los extremos y los tiempos kernel están en los resúmenes enlazados.
Una reducción negativa significa regresión.

| Experimento y presupuesto | N=256 | N=512 | N=1024 |
| --- | --- | --- | --- |
| C secuencial, restrict_c [B] | 7.053 → 4.532 (+35.75%) | 48.186 → 31.481 (+34.67%) | 440.811 → 276.674 (+37.24%) |
| OpenMP local, static1, T=1 [B] | 7.028 → 6.961 (+0.95%) | 51.199 → 49.144 (+4.01%) | 454.018 → 431.646 (+4.93%) |
| OpenMP local, static1, T=2 [B] | 4.025 → 4.888 (-21.44%) | 28.567 → 27.104 (+5.12%) | 204.750 → 208.958 (-2.06%) |
| OpenMP local, static1, T=4 [B] | 2.648 → 2.921 (-10.29%) | 17.923 → 21.658 (-20.84%) | 126.763 → 119.831 (+5.47%) |
| Go secuencial, row_slices [A] | 11.810 → 11.550 (+2.20%) | 90.509 → 73.363 (+18.94%) | 766.346 → 584.716 (+23.70%) |
| Go paralelo, block16, W=1 [A] | 16.845 → 16.687 (+0.94%) | 134.678 → 135.422 (-0.55%) | 1097.177 → 1100.138 (-0.27%) |
| Go paralelo, unbuffered, W=1 [A] | 16.845 → 16.852 (-0.04%) | 134.678 → 132.591 (+1.55%) | 1097.177 → 1143.712 (-4.24%) |
| Go paralelo, block16, W=2 [A] | 8.999 → 9.161 (-1.80%) | 68.424 → 69.449 (-1.50%) | 579.514 → 593.943 (-2.49%) |
| Go paralelo, unbuffered, W=2 [A] | 8.999 → 9.257 (-2.86%) | 68.424 → 69.904 (-2.16%) | 579.514 → 547.640 (+5.50%) |
| Go paralelo, block16, W=4 [A] | 5.238 → 6.031 (-15.14%) | 46.358 → 42.442 (+8.45%) | 306.048 → 305.963 (+0.03%) |
| Go paralelo, unbuffered, W=4 [A] | 5.238 → 6.716 (-28.22%) | 46.358 → 45.315 (+2.25%) | 306.048 → 305.184 (+0.28%) |

Interpretación limitada a estos intentos:

- C: la tabla B es la comparación controlada; A no se utiliza para atribuir
  ganancias a `restrict`. Los reportes de GCC documentan el código generado,
  sin garantizar el resultado en MSVC.
- Go secuencial: `row_slices` reduce la mediana en N=512/1024; en N=256 la
  diferencia es pequeña respecto a la dispersión. Se debe evaluar la oportunidad
  equivalente en el kernel paralelo antes de promover una mejora solo secuencial.
- OpenMP: el resultado depende de N/T; no se cambia la política de producción
  ni se extrapola el kernel local a MPI. Se conservan también las regresiones.
- Go paralelo: las variaciones de bloque/canal no mejoran consistentemente todos
  los presupuestos; en N=1024/W4 la diferencia de medianas es menor al 0.3%.
- Asignaciones N=17: el kernel secuencial base y con slices registra 0 por llamada;
  la API `Multiply` registra 1. La coordinación del pool registra 6/7/9 con
  W=1/2/4 en las variantes comprobadas. No se inventa una reducción donde ya eran cero.

Ninguna candidata se ha promovido al código de campaña. El algoritmo actual
se conserva a la espera de validación y comparativas Windows, como se acordó
para el alcance de esta ejecución.
