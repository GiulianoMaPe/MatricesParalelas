# Discusión comparativa C/Go y limitaciones — Sprint 9

**Autor:** Integrante 6 — Gerardo (redacción asistida por Claude, 26/11/2026).
**Estado:** entregable de I6 en S9, pendiente de la revisión de I5 (Fernando).
**Fuente única de las conclusiones:** campaña oficial
[`s08_oficial_integrada_03`](../resultados/raw/s08_oficial_integrada_03/mediciones.csv)
(`data_sha256` `AFBBBD38…0FBD58`, estado `VERIFIED`) y su
[resumen estadístico](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv).

Este documento compara C y Go en tiempos absolutos medidos en las mismas
condiciones y separa explícitamente las fuentes medidas en otras PCs o con otras
configuraciones. No introduce mediciones nuevas en la comparación oficial: el
control de I6 (sección 6) se usa solo como comprobación de consistencia.

## 1. Condiciones equivalentes de la comparación

| Condición | Valor común a C y Go |
| --- | --- |
| PC | `PCG1UL14N0`, AMD Ryzen 5 3600 (6 núcleos físicos / 12 lógicos), 15,9 GB, Windows 11 Pro build 26300, plan Equilibrado, alimentación AC |
| Código | Candidata limpia `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, árbol sin cambios |
| Entradas | LCG común, semilla 42, N = 512, 1024 y 2048 |
| Algoritmo | Orden i,k,j sobre `double`/`float64` contiguos por filas; un propietario por fila de C |
| Protocolo | v1.3: un calentamiento y cinco medidas por grupo, rondas alternadas directo/inverso, ejecución serial |
| Validación | Las 198 corridas tienen `validation_status=OK` y cumplen `0 ≤ kernel_s ≤ total_s` |
| Estadístico | Mediana de `total_s` y rango intercuartílico (IQR) de las cinco medidas; speedup respecto a la referencia secuencial **del mismo lenguaje** |
| Presupuesto paralelo | P×T en C y W en Go, con el mismo valor (1, 2 o 4), sin superar los núcleos físicos |

Diferencias inevitables, que no se pueden igualar y condicionan la lectura:

- **Compilador y runtime:** MSVC 19.44 (`/O2 /fp:precise`, OpenMP, MS-MPI 10.1)
  frente a Go 1.27.4 (compilador gc, recolector de basura, planificador de
  goroutines).
- **Contenido de `total_s` en paralelo:** en C incluye `MPI_Bcast`,
  `MPI_Scatterv`, la región OpenMP y `MPI_Gatherv`. En Go incluye la creación del
  canal, el lanzamiento de workers, el despacho y `wg.Wait()`. Ambos miden el
  producto de extremo a extremo de cada modelo, pero no hacen el mismo trabajo
  de coordinación.
- **Relojes:** QueryPerformanceCounter o `MPI_Wtime` en C, y el reloj monotónico
  de Go, con una resolución local cercana a 0,5 ms según S6.

## 2. Referencias secuenciales: tiempos absolutos

Mediana de `total_s` en ms, con el IQR entre corchetes. GFLOPS = 2N³ / mediana de `total_s`.

| N | C secuencial (ms) | Go secuencial (ms) | Go/C | GFLOPS C | GFLOPS Go |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 512 | 23.8 [0.1] | 90.5 [0.4] | 3.80 | 11.29 | 2.97 |
| 1024 | 202.9 [20.5] | 726.2 [12.8] | 3.58 | 10.58 | 2.96 |
| 2048 | 3816.8 [99.6] | 6296.9 [42.9] | 1.65 | 4.50 | 2.73 |

**Lectura.** C secuencial es más rápido que Go secuencial en los tres tamaños.
La ventaja baja de 3,8× a 1,65× en N=2048, no porque Go mejore (su
rendimiento se mantiene entre 2,7 y 3,0 GFLOPS), sino porque C pasa de unos
11 GFLOPS a 4,5 GFLOPS. No hay contadores de caché, así que la causa de esa
caída de C no está medida. Es compatible con que, en N=2048, B (32 MiB) ya no
quepa en la caché, pero no se afirma como demostrado.

## 3. Versiones paralelas con el mismo presupuesto

S = speedup respecto a la referencia secuencial del mismo lenguaje; E = S/(P×T) o S/W.
Go/C es el cociente de las medianas absolutas de `total_s`.

| N | Presup. | C P/T | C (ms) | S C | E C | Go (ms) | S Go | E Go | Go/C |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 512 | 1 | 1/1 | 58.8 [0.1] | 0.40 | 0.40 | 134.0 [0.4] | 0.67 | 0.67 | 2.28 |
| 512 | 2 | 1/2 | 30.1 [0.2] | 0.79 | 0.39 | 67.7 [0.3] | 1.34 | 0.67 | 2.25 |
| 512 | 2 | 2/1 | 30.5 [0.2] | 0.78 | 0.39 | 67.7 [0.3] | 1.34 | 0.67 | 2.22 |
| 512 | 4 | 1/4 | 16.6 [2.0] | 1.43 | 0.36 | 34.8 [0.7] | 2.60 | 0.65 | 2.09 |
| 512 | 4 | 2/2 | 16.9 [0.4] | 1.41 | 0.35 | 34.8 [0.7] | 2.60 | 0.65 | 2.06 |
| 512 | 4 | 4/1 | 17.2 [0.5] | 1.38 | 0.35 | 34.8 [0.7] | 2.60 | 0.65 | 2.03 |
| 1024 | 1 | 1/1 | 450.1 [8.7] | 0.45 | 0.45 | 1081.8 [26.3] | 0.67 | 0.67 | 2.40 |
| 1024 | 2 | 1/2 | 276.5 [15.6] | 0.73 | 0.37 | 552.4 [52.3] | 1.31 | 0.66 | 2.00 |
| 1024 | 2 | 2/1 | 306.3 [19.1] | 0.66 | 0.33 | 552.4 [52.3] | 1.31 | 0.66 | 1.80 |
| 1024 | 4 | 1/4 | 142.7 [22.0] | 1.42 | 0.36 | 303.7 [16.2] | 2.39 | 0.60 | 2.13 |
| 1024 | 4 | 2/2 | 162.8 [8.1] | 1.25 | 0.31 | 303.7 [16.2] | 2.39 | 0.60 | 1.86 |
| 1024 | 4 | 4/1 | 202.2 [19.7] | 1.00 | 0.25 | 303.7 [16.2] | 2.39 | 0.60 | 1.50 |
| 2048 | 1 | 1/1 | 5077.6 [71.5] | 0.75 | 0.75 | 8862.0 [196.5] | 0.71 | 0.71 | 1.75 |
| 2048 | 2 | 1/2 | 2528.9 [97.3] | 1.51 | 0.75 | 4566.9 [42.9] | 1.38 | 0.69 | 1.81 |
| 2048 | 2 | 2/1 | 2871.5 [77.7] | 1.33 | 0.66 | 4566.9 [42.9] | 1.38 | 0.69 | 1.59 |
| 2048 | 4 | 1/4 | 1814.0 [18.9] | 2.10 | 0.53 | 2497.1 [123.9] | 2.52 | 0.63 | 1.38 |
| 2048 | 4 | 2/2 | 2058.8 [48.1] | 1.85 | 0.46 | 2497.1 [123.9] | 2.52 | 0.63 | 1.21 |
| 2048 | 4 | 4/1 | 2248.2 [78.5] | 1.70 | 0.42 | 2497.1 [123.9] | 2.52 | 0.63 | 1.11 |

**Lectura.**

1. **En tiempo absoluto, C es más rápido en las 18 parejas con el mismo presupuesto.** El
   cociente Go/C va de 1,11 (N=2048, C P4/T1 frente a Go W=4) a 2,40 (N=1024,
   presupuesto 1).
2. **Speedup y eficiencia no sirven para elegir un lenguaje.** Go muestra más
   speedup y más eficiencia en casi todos los casos (E de 0,60 a 0,71, frente a
   0,25 a 0,75 en C), pero cada lenguaje se mide contra su propia referencia, y
   la de C es varias veces más rápida. Un speedup mayor sobre una base más lenta
   no implica un tiempo menor.
3. **Coste de la versión paralela con un solo recurso.** C P1/T1 tarda 2,47×,
   2,22× y 1,33× lo que C secuencial. Go W=1 tarda 1,48×, 1,49× y 1,41× lo que
   Go secuencial. En C, ese coste no procede de la comunicación: con
   P1/T1, `kernel_s` ya supone entre el 98 % y el 99,7 % de `total_s` (57,9 de
   58,8 ms en N=512). Apunta a una diferencia en el código del kernel OpenMP
   local frente al secuencial. En S6, la variante `static1` del kernel local mejoró
   entre un 18 % y un 26 % con T=1, lo que sugiere que la forma del bucle bajo
   OpenMP importa. No se midió con perfiles de instrucciones, así que queda
   como hipótesis.
4. **Distribución del presupuesto en C:** dentro de P×T = 4, la mejor
   configuración en los tres tamaños es P1/T4 (solo hilos) y la peor es P4/T1
   (solo procesos MPI), con la mayor diferencia en N=1024 (142,7 ms frente a
   202,2 ms). Con esta implementación, los hilos de memoria compartida son
   más eficaces que los procesos MPI dentro de una misma PC.
5. **Tamaño:** la ventaja absoluta de C se reduce al crecer N, tanto en
   secuencial como en paralelo, por la caída de GFLOPS de C descrita en la
   sección 2.

## 4. Amenazas a la validez

### 4.1 Validez interna

- **Forma del código frente a lenguaje.** S6 midió dos mejoras que no se
  promovieron para conservar la simetría: `row_slices` en Go secuencial
  (alrededor de +46 % en `total_s`) y `static1` en el kernel OpenMP local
  (+18 % a +26 % con T=1). Las diferencias absolutas dependen, por tanto, de cómo
  cada compilador traduce el mismo algoritmo, y no solo del lenguaje. No deben
  presentarse como un límite intrínseco de Go o de C.
- **Contenido distinto de `total_s` paralelo** (sección 1). Comparar C y Go
  paralelos compara modelos de coordinación completos, no el mismo trabajo.
- **Tiempos cortos.** S6 fijó en 100 ms el umbral para usar un grupo Go en
  comparaciones, por la resolución local de su reloj. Quedan por debajo Go
  secuencial con N=512 (90,5 ms) y Go paralelo con W=2 y W=4 en N=512 (67,7 y
  34,8 ms). Esos grupos se muestran, pero no sostienen conclusiones por sí solos.
  Todos los grupos de C con N=512 duran menos de 60 ms; su reloj tiene más
  resolución, pero los tiempos siguen siendo cortos.
- **Dispersión.** Superan IQR/mediana > 10 %: C P1/T4 con N=512 (12,1 %) y
  N=1024 (15,4 %), y C secuencial con N=1024 (10,1 %). La
  [auditoría de I7](../resultados/resumen/s08_oficial_integrada_03/auditoria_dispersion.md)
  conserva todas las observaciones, sin descartar ninguna. Las diferencias
  menores que esos IQR (por ejemplo, P1/T4 frente a P2/T2 con N=512) no se
  interpretan.
- **Carga y temperatura.** La carga de CPU registrada antes de cada corrida fue
  del 0 % al 39 % (mediana 6 %), con una lectura vacía, y la memoria libre estuvo
  entre 8,7 y 9,7 GiB. No hubo lectura térmica de la CPU, así que no se puede
  descartar una reducción de frecuencia por temperatura en los grupos largos.
- **Afinidad.** No se fijó afinidad (máscara de proceso 4095, es decir, los 12
  lógicos). Con SMT activo, dos hilos o procesos pueden compartir un núcleo
  físico aunque P×T ≤ 6.
- **Metadato `os_version`.** La misma PC aparece como «Windows 10 Pro» en las
  filas C y «Windows 11 Pro» en las filas Go. Es una diferencia en la forma de
  detectar el sistema, no de entorno; se conserva sin modificar el CSV crudo.
- **Validación fuera del cronómetro.** La referencia i,j,k se calcula antes de
  T0 y no afecta a `kernel_s` ni a `total_s`. Sí domina el tiempo de pared en
  C con N=2048: 152 s por corrida en C secuencial y 436 s en C paralelo,
  frente a unos 3–5 s cronometrados. Esto explica que la campaña durara 5,26 h y
  no las 1,6 h estimadas en S7.

### 4.2 Validez externa

- Una sola PC (Zen 2, 6 núcleos), un sistema operativo, un compilador de cada
  lenguaje, una semilla y una campaña. Con cinco medidas por grupo solo se
  describen medianas e IQR, sin inferencia estadística. Los resultados no se
  generalizan a otras CPU, compiladores, N mayores ni más de 4 workers (el plan
  excluyó W=8).
- C paralelo usa MS-MPI en memoria compartida dentro de un nodo. Los costes de
  red de un clúster no están representados.

### 4.3 Validez de constructo

- `kernel_s` paralelo es el máximo de las regiones de cálculo por worker o rank,
  y `total_s` es el tiempo de extremo a extremo del coordinador. Las
  conclusiones de este documento usan `total_s`, la métrica comparable entre
  modelos según el protocolo v1.3.

## 5. Separación de PCs y configuraciones

Solo la campaña oficial sostiene las conclusiones anteriores. Las demás fuentes
se conservan en carpetas separadas y **no se mezclan** con ella ni entre sí.

| Fuente | PC / CPU | Commit | Alcance | Uso permitido |
| --- | --- | --- | --- | --- |
| `s08_oficial_integrada_03` | `PCG1UL14N0`, Ryzen 5 3600 | `97ccc98` | 4 versiones, N=512/1024/2048, 198 corridas | **Única fuente de conclusiones** |
| `s08_i03_go_secuencial_03`, `s08_i04_go_paralelo_01` | `PCG1UL14N0` | `97ccc98` | Subcampañas Go | Extracciones por versión, sin combinarlas con la integrada |
| S7 `_piloto_05` y `_reproduccion_06` | `PCG1UL14N0` | `97ccc98` | N=256/512/1024, 17/11/2026 | Estabilidad entre lotes y estimación de duración; no se combinan con S8 |
| S6 `s06_windows_20261112` | PC de integración S6 | `72417b9` | Candidatas de optimización | Antes/después de S6 |
| S6 Linux y diagnóstico | Fedora | Base S6 | Diagnóstico portable | Antecedente; no son mediciones Windows |
| Control I1 `s08_i01_c_secuencial_control` | `YESSLY-TB14G9`, Ryzen 7 250 | `5a54ede` | C secuencial | Control funcional en otro hardware |
| Control I6 `s08_i06_go_control` | `DESKTOP-LEOFOU4`, Core i3-12100F | Fuentes Go idénticas a `97ccc98` | Go secuencial y paralelo | Consistencia cualitativa (sección 6) |
| Datos de I4 (S6) y de I7 (S5) | Ryzen 7 3700X y Ryzen 7 8845HS | Varios | Exploración | Antecedentes históricos |

## 6. Control independiente de I6 (otra PC)

<!-- CONTROL_I6 -->

## 7. Conclusiones verificables

| # | Conclusión | Datos y condiciones que la sostienen |
| --- | --- | --- |
| C1 | C es más rápido que Go en tiempo absoluto en los 3 tamaños secuenciales y en las 18 parejas paralelas con el mismo presupuesto (Go/C de 1,11 a 3,80). | Secciones 2 y 3; campaña oficial, `PCG1UL14N0`, semilla 42. |
| C2 | La ventaja de C se reduce con N (Go/C secuencial: 3,80 → 3,58 → 1,65) porque C cae de 11,3 a 4,5 GFLOPS mientras Go se mantiene en 2,7–3,0. | Sección 2; la causa (caché) no está medida. |
| C3 | Go escala con más eficiencia relativa (E de 0,60 a 0,71 en W=1–4) que C (0,25 a 0,75), pero sobre una referencia más lenta. | Sección 3; speedup respecto al mismo lenguaje (protocolo §7.1). |
| C4 | En C, con P×T=4, P1/T4 es la mejor configuración y P4/T1 la peor en los tres N. | Sección 3; diferencias mayores que el IQR solo en N=1024 y N=2048. |
| C5 | La versión paralela con un solo recurso cuesta más que la secuencial (C: 1,33–2,47×; Go: 1,41–1,49×). En C, el coste no procede de la comunicación. | Sección 3, punto 3; `kernel_s`/`total_s` de P1/T1 entre 0,98 y 0,997. |
| C6 | Las diferencias absolutas dependen de la generación de código y no solo del lenguaje. | Sección 4.1; candidatas S6 `row_slices` y `static1` no promovidas. |
