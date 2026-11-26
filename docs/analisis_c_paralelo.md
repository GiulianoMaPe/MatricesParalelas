# Rendimiento de C paralelo (integrante 2 · Sebastián Malca)

## Alcance y procedencia

Este análisis estudia el híbrido C con MPI y OpenMP respecto de la referencia C
secuencial. Se usan como evidencia las campañas piloto completas y verificadas
`s07_windows_20261117_piloto_05` y
`s07_windows_20261117_reproduccion_06`. Cada una conserva 198 observaciones y
33 grupos; incluye N=256, 512 y 1024, semilla 42, seis versiones y cinco
repeticiones medidas por configuración. La candidata registrada es el commit
`97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.

Los CSV, resúmenes y verificaciones originales están en [piloto 05](../resultados/piloto/s07_windows_20261117_piloto_05/)
y [reproducción 06](../resultados/piloto/s07_windows_20261117_reproduccion_06/).
Los dos intentos se analizan por separado; sus filas no se agrupan como si
fueran una sola muestra. No se encontró una campaña oficial S8 en
`resultados/raw`, así que los resultados y conclusiones de este apartado son
evidencia piloto, no resultados oficiales finales.

La PC registrada es un Ryzen 5 3600 con 6 núcleos físicos y 12 lógicos,
Windows 11, MSVC/MS-MPI y configuración Release. La campaña comparó P=1, 2 y 4
procesos con T=1, 2 y 4 hilos por proceso, dentro del presupuesto de seis
núcleos físicos (no todas las combinaciones P×T se midieron). El protocolo define
speedup sobre la mediana de `total_s` respecto de `c_secuencial` de igual N,
semilla, PC, commit y compilación; eficiencia es `speedup/(P×T)`. Se excluye el
calentamiento y se usan cinco repeticiones. Por ello eficiencia expresa mejora
por trabajador nominal, no porcentaje de utilización de CPU.

## Speedup y eficiencia observados

La tabla muestra el speedup de cada piloto y, entre paréntesis, su eficiencia.
Los valores se recalcularon como cociente de las medianas de `total_s` dentro de
cada campaña. Las diferencias entre intentos se conservan, en particular para
N=1024; no se promediaron para ocultar variabilidad.

| N | P×T | Piloto 05: S (E) | Reproducción 06: S (E) |
| ---: | ---: | ---: | ---: |
| 256 | 1×1 | 0.375 (0.375) | 0.376 (0.376) |
| 256 | 1×2 | 0.684 (0.342) | 0.675 (0.338) |
| 256 | 1×4 | 1.023 (0.256) | 1.131 (0.283) |
| 256 | 2×1 | 0.700 (0.350) | 0.689 (0.345) |
| 256 | 2×2 | 0.960 (0.240) | 1.135 (0.284) |
| 256 | 4×1 | 0.741 (0.185) | 0.920 (0.230) |
| 512 | 1×1 | 0.405 (0.405) | 0.404 (0.404) |
| 512 | 1×2 | 0.784 (0.392) | 0.778 (0.389) |
| 512 | 1×4 | 1.405 (0.351) | 1.377 (0.344) |
| 512 | 2×1 | 0.766 (0.383) | 0.776 (0.388) |
| 512 | 2×2 | 1.388 (0.347) | 1.378 (0.344) |
| 512 | 4×1 | 1.255 (0.314) | 1.331 (0.333) |
| 1024 | 1×1 | 0.494 (0.494) | 0.429 (0.429) |
| 1024 | 1×2 | 0.849 (0.424) | 0.700 (0.350) |
| 1024 | 1×4 | 1.601 (0.400) | 1.288 (0.322) |
| 1024 | 2×1 | 0.770 (0.385) | 0.626 (0.313) |
| 1024 | 2×2 | 1.416 (0.354) | 1.124 (0.281) |
| 1024 | 4×1 | 1.123 (0.281) | 0.901 (0.225) |

Con P=1, T=1, el híbrido es más lento que C secuencial en las tres dimensiones
(S entre 0.375 y 0.494). Esto es coherente con pagar inicialización y
coordinación MPI aunque solo exista un rango, además del reparto y la
recolección de datos. El programa está diseñado para la ejecución híbrida; esta
configuración no es una segunda implementación secuencial optimizada.

Al aumentar T con P=1, el speedup mejora de forma consistente. T=4 supera la
referencia en N=512 y N=1024 en ambos intentos, pero no en N=256 de forma
reproducible: allí los cocientes quedan entre 1.02 y 1.13 y el IQR relativo de
`total_s` llegó a 27.8% y 9.6%. En N=512, P=1/T=4 obtiene S=1.38–1.41; P=2/T=2,
S=1.38–1.39; y P=4/T=1, S=1.26–1.33. El paso de un rango a cuatro rangos no
mejora ese resultado de forma estable. E queda entre 0.31 y 0.39 en esos casos,
muy por debajo de escalabilidad lineal.

Para N=1024, las dos campañas conservan la tendencia favorable a más hilos con
P=1, pero divergen en magnitud: S con P=1/T=4 pasa de 1.60 a 1.29; con P=2/T=2,
de 1.42 a 1.12; y con P=4/T=1, de 1.12 a 0.90. La reproducción fue más rápida
en el baseline secuencial (0.1968 s frente a 0.2409 s de mediana), mientras que
los tiempos totales del híbrido cambiaron menos. Esto cambia los cocientes y
recomienda no afirmar una ventaja estable de una configuración para N=1024
basándose solo en el primer piloto.

La eficiencia decrece al aumentar el número nominal de trabajadores en muchas
configuraciones: por ejemplo, en N=512, P=1 pasa de E≈0.40 con T=1 a E≈0.35 con
T=4; en P=2/T=2, E≈0.34; y P=4/T=1, E≈0.31–0.33. Más recursos reducen tiempo
absoluto en varios casos, pero el beneficio es sublineal. La eficiencia no
permite identificar por sí sola qué fracción se debe a comunicación, carga
desbalanceada o límites de memoria.

## Comunicación, localidad y saturación

El código distribuye bloques contiguos de filas de A con `MPI_Scatterv`, replica
B en todos los rangos con `MPI_Bcast` y reúne bloques de C mediante
`MPI_Gatherv`. Dentro de cada rango, OpenMP divide las filas locales en bloques
contiguos. El núcleo usa el orden `i,k,j` sobre arreglos row-major: para cada
fila de A y fila de resultado se recorre contiguamente la fila correspondiente
de B y la fila de C. Esa organización favorece el acceso secuencial y el uso
repetido de `B[k,*]` al acumular en distintas filas de A.

El costo de comunicación y coordinación sí forma parte de `total_s`: empieza
antes del broadcast y concluye al volver de la recolección. `kernel_s` solo
cronometría la región OpenMP y se reduce con el máximo entre rangos. Así,
`total_s - kernel_s` aproxima el tiempo fuera del kernel, aunque también incluye
vaciado de C y diferencias entre fronteras/agregaciones; no es una medición
aislada de MPI. En P=1/T=1, `total_s` supera `kernel_s` aproximadamente 0.8%
para N=1024, 1.6–1.7% para N=512 y 3.2–3.4% para N=256. En todos los grupos C
paralelo de los dos pilotos, la diferencia relativa va de 0.75% a 60.4%; los
extremos pequeños reflejan que componentes fijos pueden ser grandes frente a un
kernel corto. Para N=1024/P=4/T=1, `total_s` supera `kernel_s`
aproximadamente 3.3%. Estos datos son compatibles con el costo adicional de
orquestar la ejecución, pero no separan el tiempo de `Bcast`, `Scatterv`,
`Gatherv` ni barreras.

La división por filas da a cada rango trabajo de tamaño similar (diferencia
máxima de una fila), por lo que no hay un desbalance grueso intencional. Sin
embargo, al aumentar P se reducen las filas por proceso y se replica B; los
mensajes colectivos y la coordinación pesan más frente al cálculo local. En
una sola máquina también compiten por la jerarquía de caché y el ancho de banda
de memoria. La caída de eficiencia y la falta de mejora consistente de P=2 a
P=4 son señales compatibles con sobrecoste y rendimientos decrecientes, no una
prueba causal de saturación de DRAM o de una caché concreta.

El comportamiento con T sugiere que la región OpenMP aprovecha paralelismo
dentro de cada rango, sobre todo al crecer N: P=1/T=4 supera C secuencial para
N≥512 en ambos pilotos. El resultado no escala linealmente y para matrices
pequeñas la creación/sincronización de hilos y el trabajo limitado por fila
pueden pesar mucho. Los pilotos no incluyen contadores de hardware, perfiles
por fase ni medición térmica de CPU; por tanto, la saturación de cómputo, caché o
memoria queda como explicación plausible que requiere instrumentación adicional,
no como hecho medido. Además, `kernel_s` usa el rango más lento y `total_s` el
tiempo global hasta Gatherv: son métricas con alcances distintos.

## Dictamen y trabajo pendiente para cierre

La evidencia piloto muestra que el híbrido tiene una penalización apreciable
con P=1/T=1, que OpenMP ofrece mejoras útiles para N medianas y grandes y que
incrementar P no garantiza acelerar más. En N=512 los resultados son estables
entre intentos; en N=1024 la magnitud del speedup cambia materialmente, por lo
que el cierre debe apoyarse en la campaña oficial y conservar las dispersiones.
Las ganancias observadas son sublineales respecto de P×T.

Para completar el análisis final de Sprint 9 con la campaña oficial, actualizar
las tablas usando sus CSV y resúmenes, comparar intentos oficiales válidos sin
mezclarlos, añadir gráficos reproducibles con dispersión y reemplazar las
inferencias sobre saturación solo si existen mediciones que las sostengan. No
se inventan horas reales, revisión cruzada ni coordinación: esos datos deben
incorporarse al registro de cierre del sprint por el equipo.
