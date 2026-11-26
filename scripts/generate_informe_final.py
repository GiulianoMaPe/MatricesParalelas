# -*- coding: utf-8 -*-
"""
Script generador del Informe Técnico Final Integrado - Sprint 9
Proyecto: Multiplicación de Matrices Densas en C y Go
Responsable: Integrante 7 · Andrés
Entregables:
  - docs/informe_final.md
  - docs/informe_final.docx
"""

import os
import sys
import csv
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DOCS_DIR = os.path.join(REPO_ROOT, "docs")
MD_OUTPUT = os.path.join(DOCS_DIR, "informe_final.md")
DOCX_OUTPUT = os.path.join(DOCS_DIR, "informe_final.docx")
CSV_RESUMEN = os.path.join(REPO_ROOT, "resultados", "resumen", "s08_oficial_integrada_03", "resumen_estadistico.csv")

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def set_table_borders(table, color="D3D3D3"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'  <w:top w:val="single" w:sz="6" w:space="0" w:color="{color}"/>'
        f'  <w:bottom w:val="single" w:sz="8" w:space="0" w:color="{color}"/>'
        f'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{color}"/>'
        f'  <w:insideV w:val="none"/>'
        f'  <w:left w:val="none"/>'
        f'  <w:right w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def load_data():
    rows = []
    with open(CSV_RESUMEN, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)
    return rows

def generate_report():
    data = load_data()
    print(f"Cargadas {len(data)} filas oficiales de la campaña.")

    # Generamos docs/informe_final.md
    with open(MD_OUTPUT, "w", encoding="utf-8") as md:
        md.write("""# Informe Técnico Final: Evaluación Experimental y Comparativa de Rendimiento en Multiplicación de Matrices Densas Cuadradas: Híbrido C (MPI + OpenMP) vs. Concurrente Go (Goroutines + Canales)

**Curso:** Computación Paralela y Distribuida  
**Semestre:** 2026-II · Sprint 9  
**Fecha:** 26 de Noviembre de 2026  
**Equipo de Trabajo:**
- **Integrante 1:** C Secuencial y Gobernanza
- **Integrante 2 (Sebastián Malca):** Rendimiento C Paralelo Híbrido
- **Integrante 3 (Giuliano):** Rendimiento Go Secuencial
- **Integrante 4 (Eva Moreno):** Rendimiento Go Paralelo
- **Integrante 5 (Fernando Saire):** Gráficos Reproducibles y Visualización
- **Integrante 6 (Gerardo Cuadros):** Discusión Comparativa y Limitaciones
- **Integrante 7 (Andrés):** Integración Metodológica, Tablas, Referencias IEEE e Informe Final
- **Integrante 8 (Roberto):** Guion de Exposición, Manifiesto y Trazabilidad

---

## Resumen Ejecutivo (Abstract)

Este estudio presenta una evaluación empírica rigurosa del rendimiento, escalabilidad y sobrecostes de coordinación en la multiplicación de matrices densas cuadradas ($A \times B = C$), contrastando una implementación nativa en lenguaje C compilado (modelo híbrido de memoria distribuida con MPI y memoria compartida con OpenMP) frente a una implementación administrada en lenguaje Go (modelo CSP con goroutines y canales). Todas las evaluaciones se llevaron a cabo bajo un estricto protocolo determinista (Protocolo v1.3) con generación pseudoaleatoria sincronizada (semilla 42) y tamaños de matriz $N \in \\{512, 1024, 2048\\}$ en una plataforma de cómputo homogénea y controlada (AMD Ryzen 5 3600 de 6 núcleos físicos, Windows 11 Pro).

La campaña oficial congelada (`s08_oficial_integrada_03`), compuesta por 198 ejecuciones válidas distribuidas en 33 grupos experimentales (con 5 réplicas medidas y 1 corrida previa de calentamiento descartada), permitió obtener conclusiones no paramétricas sólidas sustentadas en medianas y rangos intercuartílicos (IQR). Los hallazgos principales revelan que:
1. **Rendimiento Absoluto:** C supera a Go en tiempo total en todas las dimensiones y configuraciones paralelas equivalentes (ratios Go/C de 1.11× a 3.80×).
2. **Impacto de la Jerarquía de Memoria:** La ventaja de C decrece marcadamente al aumentar $N$ (Go/C pasa de 3.80× en $N=512$ a 1.65× en $N=2048$), como consecuencia de una severa caída en los GFLOPS de C (de 11.3 a 4.5 GFLOPS), atribuible al desbordamiento de las cachés L1/L2/L3 frente al tamaño de los datos ($128\\text{ MiB}$ totales para $N=2048$).
3. **Escalabilidad y Eficiencia:** Go demuestra una escalabilidad paralela más consistente ($E$ entre 0.60 y 0.71 para $W \\in \\{1, 2, 4\\}$) que C ($E$ entre 0.25 y 0.75), aunque Go opera sobre una base secuencial de menor rendimiento computacional.
4. **Topología de Procesos en C:** Con un presupuesto de 4 unidades de ejecución ($P \\times T = 4$), la configuración puramente de memoria compartida ($P=1, T=4$) resulta óptima frente a la de memoria distribuida pura ($P=4, T=1$), confirmando la penalización por paso de mensajes inter-proceso mediante memoria compartida emulada en un único nodo.

---

## 1. Introducción y Motivación

La multiplicación de matrices densas es un núcleo fundamental en computación científica, procesamiento de señales y aprendizaje automático. Si bien el algoritmo clásico posee una complejidad temporal asintótica $O(N^3)$, su rendimiento práctico en procesadores multicore modernos depende drásticamente de la localidad espacial y temporal, el aprovechamiento de la jerarquía de memoria caché, la vectorización SIMD y el sobrecoste (*overhead*) introducido por los mecanismos de concurrencia y comunicación.

Tradicionalmente, la computación de alto rendimiento (HPC) ha estado dominada por C/C++ y Fortran, combinando **OpenMP** para paralelismo en memoria compartida y **MPI** para memoria distribuida. Sin embargo, lenguajes modernos de sistemas como **Go**, diseñados sobre el modelo formal de Procesos Secuenciales Comunicados (CSP) con *goroutines* ligeras multiplexadas en tiempo de ejecución (*runtime scheduler*) y canales de sincronización, han ganado tracción en servicios backend y procesamiento masivo de datos.

Este informe tiene como propósito responder de manera cuantitativa y verificable:
- ¿Cuál es la penalización de rendimiento absoluto que introduce el entorno administrado de Go frente al código nativo C compilado en arquitecturas x86-64 modernas?
- ¿Cómo se comporta la escalabilidad en C al variar la partición entre procesos MPI ($P$) e hilos OpenMP ($T$) bajo un presupuesto idéntico de núcleos ($P \\times T \\le 4$)?
- ¿En qué medida el tiempo de coordinación (comunicación inter-proceso y sincronización de hilos/canales) degrada la aceleración lineal teórica?

---

## 2. Marco Teórico y Vínculo con la Literatura IEEE

Para fundamentar las decisiones de diseño del software y la interpretación de los resultados experimentales, este trabajo se vincula formalmente con dos investigaciones publicadas en la literatura IEEE conservadas en el repositorio institucional:

### 2.1 Quintin, Hasanov y Lastovetsky (IEEE ICPP 2013)
*Referencia:* M. Quintin, A. Hasanov, and A. Lastovetsky, "Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms," in *Proceedings of the 42nd International Conference on Parallel Processing (ICPP)*, 2013, pp. 754–762. DOI: [10.1109/ICPP.2013.89](https://doi.org/10.1109/ICPP.2013.89).

**Vínculo y adaptación metodológica:**
Quintin et al. demuestran que los algoritmos clásicos de multiplicación matricial distribuida (como SUMMA o Cannon) sufren una degradación severa de rendimiento cuando se ejecutan sobre plataformas jerárquicas con nodos multinúcleo, debido a que no distinguen la latencia y ancho de banda heterogéneos entre comunicaciones intra-nodo (memoria compartida) e inter-nodo (red física). Los autores proponen HSUMMA, organizando la comunicación en dos niveles jerárquicos virtuales sobre una malla bidimensional.

En nuestro proyecto, la arquitectura implementada en C adopta un enfoque híbrido de dos niveles:
1. **Nivel Superior (MPI):** Particionado 1D por bloques contiguos de filas mediante `MPI_Scatterv` y difusión de la matriz $B$ completa mediante `MPI_Bcast`.
2. **Nivel Inferior (OpenMP):** Distribución de las filas locales asignadas entre $T$ hilos mediante `#pragma omp parallel for schedule(static)`.

Nuestros hallazgos experimentales validan empíricamente el modelo de costes de Quintin et al.: dentro de un único nodo con presupuesto $P \\times T = 4$, la variante $P=1, T=4$ (cero sobrecoste MPI, pura memoria compartida) supera sistemáticamente a $P=4, T=1$ (4 procesos MPI independientes), debido a que $P=4$ incurre en transferencias redundantes de $B$ y llamadas colectivas de sincronización que degradan la eficiencia.

### 2.2 Hérault, Robert, Bosilca y Dongarra (IEEE ScalA 2019)
*Referencia:* T. Hérault, Y. Robert, G. Bosilca, and J. Dongarra, "Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC," in *Proceedings of the Workshop on Exascale Multi/Many Core Computing Systems (ScalA)*, 2019, pp. 33–41. DOI: [10.1109/ScalA49573.2019.00010](https://doi.org/10.1109/ScalA49573.2019.00010).

**Vínculo y adaptación metodológica:**
El trabajo de Hérault et al. aborda el producto de matrices en sistemas acelerados donde los datos exceden la memoria de los dispositivos de cálculo, formulando dos principios arquitectónicos clave:
1. **Propiedad Estricta de Escritura:** Cada proceso o hilo actualiza exclusivamente su propio conjunto de datos de salida $C$, evitando condiciones de carrera y sincronizaciones finas con cerrojos (*locks*).
2. **Reutilización de Datos y Contigüidad Espacial:** Organización del almacenamiento en bloques contiguos para maximizar la tasa de aciertos (*cache hits*) en las transferencias de memoria.

En nuestro diseño, ambas plataformas (C y Go) implementan fielmente estos principios:
- **Almacenamiento lineal por filas:** Matrices densas almacenadas en buffers unidimensionales continuos de tipo `double` (C) y `float64` (Go) indexados mediante la fórmula aritmética `i * N + j`.
- **Recorrido canónico $i \\to k \\to j$:** El bucle más interno varía el índice de columnas $j$, permitiendo que $B[k, j]$ y $C[i, j]$ sean accedidos secuencialmente a lo largo de las líneas de caché de 64 bytes (8 flotantes de doble precisión consecutivos), mientras que el escalar $A[i, k]$ se mantiene en un registro de CPU durante toda la iteración interna.
- **Principio de único escritor:** En C, cada hilo OpenMP escribe en filas disjuntas; en Go, un pool fijo de *workers* recibe fragmentos de filas a través de un canal seguro y escribe de forma independiente en su sección asignada sin colisiones de memoria.

---

## 3. Metodología Experimental y Protocolo de Medición (Protocolo v1.3)

Para asegurar la reproducibilidad, equivalencia y validez de constructo, el equipo diseñó y aplicó rigurosamente el **Protocolo de Medición v1.3**.

### 3.1 Entorno Homogéneo y Plataforma Oficial
Todas las mediciones oficiales fueron capturadas en un equipo dedicado en reposo, garantizando que ninguna tarea externa interfiriera con las mediciones:
- **Identificador de Host:** `PCG1UL14N0`
- **Procesador (CPU):** AMD Ryzen 5 3600 (Microarquitectura Zen 2, 7 nm, 6 núcleos físicos, 12 hilos lógicos vía SMT, reloj base 3.6 GHz, boost hasta 4.2 GHz, caché L3 unificada de 32 MiB).
- **Memoria Principal (RAM):** 16.0 GB DDR4 (15.912 GiB visibles).
- **Sistema Operativo:** Microsoft Windows 11 Pro build 26300.9711.
- **Herramientas de Compilación:**
  - C: Microsoft Visual C++ Compiler (MSVC) en configuración `Release` con optimizaciones `/O2 /Oi /Ot`.
  - MPI: Microsoft MPI v10.1 (MS-MPI).
  - Go: Go Compiler versión `1.27.4 windows/amd64` en configuración optimizada.
- **Versión de Código (Commit):** `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.

### 3.2 Generación Pseudoaleatoria Determinista
Para evitar que las diferencias en los datos afectaran el cómputo, se implementó en ambos lenguajes un generador congruencial lineal (LCG) idéntico bit a bit:
$$\\text{state}_{t+1} = (1664525 \\times \\text{state}_t + 1013904223) \\pmod{2^{32}}$$
Partiendo de una semilla compartida `seed = 42`, las entradas se normalizan al rango $(-1.0, 1.0)$:
$$\\text{val} = \\frac{(\\text{state} \\pmod{2001}) - 1000}{1000.0}$$
Se genera secuencialmente la matriz $A$ por filas y luego la matriz $B$. El cálculo de control se valida mediante comparación celda por celda frente a una referencia independiente con una tolerancia estricta $|C_{\\text{calc}} - C_{\\text{ref}}| < 10^{-9}$.

### 3.3 Cronometría Segregada
Se aislaron estrictamente dos intervalos de tiempo en segundos:
- **`kernel_s` (Tiempo de Cómputo Puro):** Cronometra exclusivamente los bucles anidados de multiplicación matemática una vez que las matrices están asignadas y la matriz de salida $C$ ha sido inicializada a cero. En C paralelo corresponde al máximo observado entre los rangos MPI; en Go paralelo corresponde al tiempo de acumulación efectivo del trabajador.
- **`total_s` (Tiempo Total de Extremo a Extremo):** Incluye el vaciado de memoria de $C$, el tiempo de cómputo y la sincronización/comunicación completa (llamadas colectivas MPI y sincronización de *goroutines* con `sync.WaitGroup`). Excluye explícitamente lectura/generación de datos en disco y reservas iniciales de memoria.
- **Regla de Consistencia:** En todas las ejecuciones se comprueba la invariante matemática:
$$0 \\le \\text{kernel\\_s} \\le \\text{total\\_s}$$

### 3.4 Procedimiento Estadístico No Paramétrico
Cada configuración experimental fue ejecutada 6 veces consecutivas:
1. **Calentamiento (`repetition = 0`):** Se descarta sistemáticamente para evitar penalizaciones iniciales por fallos de página (*page faults*), carga de librerías DLL o arranque del runtime de Go.
2. **Muestra Válida:** Se analizan las 5 repeticiones oficiales posteriores (`repetition = 1` a `5`).
3. **Métricas Centrales y Dispersión:** Debido a que el ruido del sistema operativo Windows introduce asimetría en los tiempos de respuesta, se emplean estimadores no paramétricos robustos:
   - **Mediana ($\\widetilde{T}$):** El valor central $x_3$ de la muestra ordenada $x_1 \\le x_2 \\le x_3 \\le x_4 \\le x_5$.
   - **Rango Intercuartílico ($IQR$):** $IQR = Q_3 - Q_1 = x_4 - x_2$.
   - **Dispersión Relativa ($RSD_{IQR}$):** $RSD_{IQR} = \\frac{IQR}{\\widetilde{T}} \\times 100\\%$.
   - **Detección de Atípicos (Vallas de Tukey):** $[Q_1 - 1.5 \\cdot IQR, Q_3 + 1.5 \\cdot IQR]$. La auditoría formal realizada en Sprint 8 confirmó que todas las observaciones oficiales son válidas y reproducibles sin requerir el descarte forzado de mediciones.

### 3.5 Política de Separación de Fuentes
Siguiendo las directrices de integridad de datos del proyecto, este informe se sustenta **exclusivamente en la campaña oficial congelada `s08_oficial_integrada_03`**. Los ensayos piloto anteriores (S6, S7) y las pruebas de control realizadas en otras computadoras personales (como la máquina Intel Core i3 de I6 o la máquina Ryzen 7 de I7) se mantienen en carpetas de diagnóstico segregadas y no intervienen en las cifras ni conclusiones de este informe.

---

## 4. Resultados Experimentales y Análisis por Implementación

A continuación se presentan y analizan los datos cuantitativos obtenidos a partir de las 198 ejecuciones oficiales.

### 4.1 C Secuencial (Línea Base en C · Responsable: I1)
La implementación secuencial en C representa la cota superior teórica de optimización para un único hilo de ejecución nativo.

| Dimensión ($N$) | Mediana `kernel_s` (s) | Mediana `total_s` (s) | $IQR$ `total_s` (s) | $RSD_{IQR}$ | GFLOPS (`total_s`) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 512 | 0.023503 | 0.023780 | 0.000108 | 0.46% | 11.29 |
| 1024 | 0.201906 | 0.202934 | 0.020517 | 10.11% | 10.58 |
| 2048 | 3.812337 | 3.816785 | 0.099579 | 2.61% | 4.50 |

**Análisis técnico:**
- El orden $i \\to k \\to j$ permite que el compilador MSVC aplique autovectorización SIMD mediante instrucciones AVX2 de 256 bits, alcanzando 11.29 GFLOPS en $N=512$.
- Al incrementar la dimensión a $N=2048$, el tiempo se multiplica por un factor de **18.8×** (muy por encima del factor teórico de 8.0× propio de $O(N^3)$), provocando una caída estrepitosa del rendimiento a **4.50 GFLOPS** (una pérdida de más del 60% de eficiencia computacional).
- Este fenómeno se explica por la capacidad de la memoria caché: mientras que para $N=512$ las tres matrices suman $6\\text{ MiB}$ (ajustándose holgadamente a la caché L3 unificada de $32\\text{ MiB}$ del Ryzen 5), para $N=2048$ las matrices suman $96\\text{ MiB}$, saturando la caché y degradando el cómputo al ancho de banda de la memoria DRAM.

### 4.2 C Paralelo Híbrido MPI + OpenMP (Responsable: I2)
La versión paralela en C evalúa la partición 1D entre $P$ procesos MPI y $T$ hilos OpenMP, con combinaciones dentro del presupuesto de $P \\times T \\in \\{1, 2, 4\\}$.

| $N$ | Configuración ($P \\times T$) | Mediana `kernel_s` (s) | Mediana `total_s` (s) | Speedup ($S$) | Eficiencia ($E$) | GFLOPS (`total_s`) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 512 | $1 \\times 1$ | 0.057867 | 0.058819 | 0.404 | 0.404 | 4.56 |
| 512 | $1 \\times 2$ | 0.029230 | 0.030147 | 0.789 | 0.394 | 8.90 |
| 512 | $1 \\times 4$ | 0.015556 | 0.016608 | **1.432** | **0.358** | **16.16** |
| 512 | $2 \\times 1$ | 0.029075 | 0.030477 | 0.780 | 0.390 | 8.81 |
| 512 | $2 \\times 2$ | 0.015275 | 0.016879 | 1.409 | 0.352 | 15.90 |
| 512 | $4 \\times 1$ | 0.015473 | 0.017173 | 1.385 | 0.346 | 15.63 |
| 1024 | $1 \\times 1$ | 0.446648 | 0.450073 | 0.451 | 0.451 | 4.77 |
| 1024 | $1 \\times 2$ | 0.273214 | 0.276510 | 0.734 | 0.367 | 7.77 |
| 1024 | $1 \\times 4$ | 0.139293 | 0.142718 | **1.422** | **0.355** | **15.05** |
| 1024 | $2 \\times 1$ | 0.300950 | 0.306335 | 0.662 | 0.331 | 7.01 |
| 1024 | $2 \\times 2$ | 0.157901 | 0.162847 | 1.246 | 0.312 | 13.19 |
| 1024 | $4 \\times 1$ | 0.195153 | 0.202205 | 1.004 | 0.251 | 10.62 |
| 2048 | $1 \\times 1$ | 5.063523 | 5.077604 | 0.752 | 0.752 | 3.38 |
| 2048 | $1 \\times 2$ | 2.515322 | 2.528858 | 1.509 | 0.755 | 6.79 |
| 2048 | $1 \\times 4$ | 1.799022 | 1.813955 | **2.104** | **0.526** | **9.47** |
| 2048 | $2 \\times 1$ | 2.850907 | 2.871511 | 1.329 | 0.665 | 5.98 |
| 2048 | $2 \\times 2$ | 2.037532 | 2.058840 | 1.854 | 0.463 | 8.34 |
| 2048 | $4 \\times 1$ | 2.221400 | 2.248153 | 1.698 | 0.424 | 7.64 |

**Análisis técnico:**
- **Penalización por Sobrecoste en $1 \\times 1$:** La versión híbrida con un solo proceso y un solo hilo es notablemente más lenta que la referencia secuencial pura (speedup de 0.404 a 0.752, es decir, entre $1.33\\times$ y $2.47\\times$ más lenta). Esto ocurre porque la infraestructura paralela realiza reservas adicionales, chequeos de rango y llamadas a funciones de coordinación de MS-MPI aun cuando sólo interviene un único rango.
- **Topología de Cómputo para $P \\times T = 4$:** En todos los tamaños analizados, la configuración puramente de memoria compartida ($P=1, T=4$) obtiene el mejor rendimiento:
  - En $N=1024$, $1 \\times 4$ alcanza $S=1.422$, superando a $2 \\times 2$ ($S=1.246$) y a $4 \\times 1$ ($S=1.004$).
  - En $N=2048$, $1 \\times 4$ logra $S=2.104$ ($9.47\\text{ GFLOPS}$), frente a $S=1.698$ ($7.64\\text{ GFLOPS}$) de $4 \\times 1$.
- **Tiempo fuera del Kernel (`total_s - kernel_s`):** La diferencia absoluta entre el tiempo total y el de cómputo oscila entre $0.8\\text{ ms}$ y $26.8\\text{ ms}$. Si bien representa un porcentaje pequeño del tiempo en matrices grandes ($<1.5\\%$ en $N=2048$), en $N=512$ representa hasta un $10.9\\%$ del tiempo total, justificando por qué las ganancias de paralelización se diluyen en tamaños pequeños.

### 4.3 Go Secuencial (Línea Base en Go · Responsable: I3)
La referencia secuencial en Go implementa el mismo algoritmo $i \\to k \\to j$ sobre un slice contiguo `[]float64` unidimensional.

| Dimensión ($N$) | Mediana `kernel_s` (s) | Mediana `total_s` (s) | $IQR$ `total_s` (s) | $RSD_{IQR}$ | GFLOPS (`total_s`) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 512 | 0.090294 | 0.090451 | 0.000407 | 0.45% | 2.97 |
| 1024 | 0.725234 | 0.726238 | 0.012752 | 1.76% | 2.96 |
| 2048 | 6.292360 | 6.296919 | 0.042857 | 0.68% | 2.73 |

**Análisis técnico:**
- **Estabilidad Impecable:** La dispersión relativa es extraordinariamente baja en todas las pruebas ($RSD_{IQR} < 1.76\\%$), lo que demuestra que el recolector de basura (*garbage collector*) de Go no interfirió en el intervalo de cronometraje al no existir asignaciones dinámicas en el bucle interior.
- **Consistencia de GFLOPS:** A diferencia de C, donde los GFLOPS cayeron más del 60%, Go mantiene un rendimiento casi constante de **2.73 a 2.97 GFLOPS** a través de todas las dimensiones. Esto se debe a que el código generado por el compilador de Go no realiza vectorización AVX2 agresiva como MSVC, manteniéndose limitado por la tasa de instrucciones escalares y no por la saturación de ancho de banda de la caché.
- **Sobrecoste de Vaciado:** La diferencia `total_s - kernel_s` fue de $0.0\\text{ ms}$ en $N=512$, $1.0\\text{ ms}$ en $N=1024$ y $4.6\\text{ ms}$ en $N=2048$, confirmando que la inicialización de la matriz de salida tiene un impacto despreciable.

### 4.4 Go Paralelo con Workers (Responsable: I4)
La versión paralela en Go implementa un pool fijo de $W$ *workers* coordinados mediante un canal de bloques de tareas y un `sync.WaitGroup`.

| $N$ | Workers ($W$) | Mediana `kernel_s` (s) | Mediana `total_s` (s) | Speedup ($S_{seq}$) | Speedup ($S_{W1}$) | Eficiencia ($E$) | GFLOPS |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 512 | 1 | 0.133892 | 0.134006 | 0.675 | 1.000 | 0.675 | 2.00 |
| 512 | 2 | 0.067399 | 0.067705 | 1.336 | 1.979 | 0.668 | 3.96 |
| 512 | 4 | 0.034783 | 0.034783 | **2.600** | **3.853** | **0.650** | **7.72** |
| 1024 | 1 | 1.080834 | 1.081840 | 0.671 | 1.000 | 0.671 | 1.99 |
| 1024 | 2 | 0.550923 | 0.552446 | 1.315 | 1.958 | 0.657 | 3.89 |
| 1024 | 4 | 0.302682 | 0.303688 | **2.391** | **3.562** | **0.598** | **7.07** |
| 2048 | 1 | 8.857431 | 8.861957 | 0.711 | 1.000 | 0.711 | 1.94 |
| 2048 | 2 | 4.562354 | 4.566879 | 1.379 | 1.940 | 0.689 | 3.76 |
| 2048 | 4 | 2.492050 | 2.497084 | **2.522** | **3.549** | **0.630** | **6.88** |

**Análisis técnico:**
- **Escalabilidad Cuasi-Lineal respecto a $W=1$:** Al evaluar el speedup relativo respecto a la versión de 1 worker ($S_{W1}$), Go alcanza un excelente factor de **1.94× a 1.98×** con 2 workers, y de **3.55× a 3.85×** con 4 workers (eficiencias relativas entre 88% y 96%).
- **El Coste de la Firma con Punteros:** Respecto a la referencia secuencial, $W=1$ exhibe un speedup de solo 0.671 a 0.711 (es un 41% a 49% más lento). El diagnóstico exhaustivo de desensamblado realizado por I4 reveló la causa raíz: la firma de la función en Go paralelo recibía punteros a la estructura de la matriz en lugar de copias por valor del descriptor de slice, provocando que el compilador introduzca cuatro recargas redundantes de cabecera en cada iteración del bucle, impidiendo optimizaciones avanzadas de registros.

---

## 5. Discusión Comparativa Directa C vs. Go (Responsable: I6)

### 5.1 Tabla Consolidada Oficial
La siguiente tabla sintetiza la comparación directa entre C y Go bajo condiciones estrictamente idénticas (campaña oficial `s08_oficial_integrada_03`, máquina `PCG1UL14N0`, semilla 42).

| $N$ | Configuración | Mediana `total_s` C (s) | Mediana `total_s` Go (s) | Ratio de Tiempo (Go / C) | GFLOPS C | GFLOPS Go | Diferencia GFLOPS |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **512** | Secuencial | 0.023780 | 0.090451 | **3.80×** | 11.29 | 2.97 | +8.32 en C |
| 512 | Paralelo 1 W / 1×1 | 0.058819 | 0.134006 | **2.28×** | 4.56 | 2.00 | +2.56 en C |
| 512 | Paralelo 2 W / 1×2 | 0.030147 | 0.067705 | **2.25×** | 8.90 | 3.96 | +4.94 en C |
| 512 | Paralelo 4 W / 1×4 | 0.016608 | 0.034783 | **2.09×** | 16.16 | 7.72 | +8.44 en C |
| **1024** | Secuencial | 0.202934 | 0.726238 | **3.58×** | 10.58 | 2.96 | +7.62 en C |
| 1024 | Paralelo 1 W / 1×1 | 0.450073 | 1.081840 | **2.40×** | 4.77 | 1.99 | +2.78 en C |
| 1024 | Paralelo 2 W / 1×2 | 0.276510 | 0.552446 | **2.00×** | 7.77 | 3.89 | +3.88 en C |
| 1024 | Paralelo 4 W / 1×4 | 0.142718 | 0.303688 | **2.13×** | 15.05 | 7.07 | +7.98 en C |
| **2048** | Secuencial | 3.816785 | 6.296919 | **1.65×** | 4.50 | 2.73 | +1.77 en C |
| 2048 | Paralelo 1 W / 1×1 | 5.077604 | 8.861957 | **1.75×** | 3.38 | 1.94 | +1.44 en C |
| 2048 | Paralelo 2 W / 1×2 | 2.528858 | 4.566879 | **1.81×** | 6.79 | 3.76 | +3.03 en C |
| 2048 | Paralelo 4 W / 1×4 | 1.813955 | 2.497084 | **1.38×** | 9.47 | 6.88 | +2.59 en C |

### 5.2 Conclusiones Verificables Consolidadas (C1 a C6)
A partir de los datos trazables de la campaña oficial, se establecen seis conclusiones científicas fundamentales:

1. **C1 (Supremacía en Tiempo Absoluto):** El lenguaje C es sistemáticamente más rápido que Go en tiempo total en todas las configuraciones evaluadas (los ratios de tiempo Go/C oscilan entre **1.11×** y **3.80×**). No existe ninguna configuración donde Go supere a C en velocidad bruta de cálculo.
2. **C2 (Erosión de la Ventaja con el Tamaño):** La brecha de rendimiento entre C y Go disminuye drásticamente a medida que la matriz crece: en secuencial, el ratio cae de **3.80×** ($N=512$) a **3.58×** ($N=1024$) y finalmente a **1.65×** ($N=2048$). La causa fundamental radica en que C sufre un cuello de botella por ancho de banda de memoria al desbordar la caché L3 ($96\\text{ MiB}$ en $N=2048$), mientras que Go, al operar a una tasa de instrucciones escalares más contenida, mantiene una demanda de memoria más uniforme.
3. **C3 (Eficiencia Paralela Relativa):** Go paralelizado con goroutines escala con una eficiencia interna mayor ($E$ entre 0.60 y 0.71) que el híbrido C ($E$ entre 0.25 y 0.75). Sin embargo, este mayor escalamiento relativo ocurre sobre una base secuencial considerablemente más lenta.
4. **C4 (Topología Óptima en C):** Con un presupuesto constante de 4 unidades de ejecución ($P \\times T = 4$), la configuración de pura memoria compartida ($P=1, T=4$) es estrictamente superior en los tres tamaños a la partición por procesos MPI ($P=4, T=1$). El paso de mensajes inter-proceso en una sola máquina añade sobrecostes que no se amortizan con la carga de trabajo asignada.
5. **C5 (Sobrecoste Inicial de Concurrencia):** Ejecutar la versión paralela con un único recurso de cómputo ($P=1, T=1$ en C; $W=1$ en Go) resulta paradójicamente más lento que ejecutar la versión secuencial nativa (penalizaciones de $1.33\\times$ a $2.47\\times$ en C, y de $1.41\\times$ a $1.49\\times$ en Go). En C, el tiempo de comunicación (`total_s - kernel_s`) representa menos del 2%, demostrando que la degradación procede de la inicialización de estructuras del framework y pérdida de optimizaciones del compilador, no del paso de mensajes.
6. **C6 (Impacto Crítico de la Generación de Código):** Las diferencias absolutas observadas responden en gran medida a la capacidad de vectorización SIMD del compilador (MSVC AVX2 en C vs código escalar en Go) y a patrones de bajo nivel en el uso de memoria (recargas de cabecera de slice en Go paralelo), más que a una limitación intrínseca del paradigma de concurrencia.

---

## 6. Gráficos Oficiales y Visualización (Responsable: I5)

El equipo generó cuatro visualizaciones reproducibles a partir del script [`scripts/graficar_resultados_s09.py`](../scripts/graficar_resultados_s09.py), utilizando los datos oficiales validados.

1. **Figura 1: Tiempo Total por Configuración (`tiempo_total.png`):**
   Muestra en escala logarítmica la mediana y el rango intercuartílico (IQR) de `total_s`. Permite apreciar visualmente la brecha constante entre C y Go en $N=512$ y $N=1024$, y la convergencia relativa observada en $N=2048$.
2. **Figura 2: Tiempo del Núcleo de Cómputo (`tiempo_kernel.png`):**
   Aísla el cómputo puro del bucle de acumulación. La similitud casi perfecta entre la Figura 1 y la Figura 2 confirma que el tiempo de cómputo domina de manera abrumadora sobre el tiempo de coordinación tanto en C como en Go.
3. **Figura 3: Aceleración (*Speedup*) frente al Secuencial (`speedup.png`):**
   Compara la aceleración respecto al secuencial del mismo lenguaje. Se aprecia con claridad que $P=1, T=4$ en C y $W=4$ en Go alcanzan las máximas aceleraciones en sus respectivos entornos.
4. **Figura 4: Eficiencia por Trabajador Nominal (`eficiencia.png`):**
   Ilustra el rendimiento por núcleo asignado. Go exhibe una banda de eficiencia mucho más compacta y estable (alrededor del 65%) en comparación con la alta dispersión de C (que varía entre el 25% y el 75% según la combinación de procesos e hilos).

---

## 7. Amenazas a la Validez y Limitaciones Metodológicas

Para mantener el rigor académico del estudio, se reconocen explícitamente las siguientes limitaciones:

### 7.1 Validez Interna
- **Resolución Temporal en Tiempos Cortos:** Para $N=512$, las ejecuciones con 4 hilos en C concluyen en menos de $17\\text{ ms}$. Si bien el temporizador de alta resolución de Windows (`QueryPerformanceCounter`) ofrece una precisión sub-microsegundo, la interferencia del planificador del sistema operativo puede introducir variaciones porcentuales visibles en muestras pequeñas.
- **Ausencia de Contadores de Hardware:** Las hipótesis sobre saturación de caché L3 y ancho de banda de memoria se deducen a partir de los tiempos de ejecución y tamaños teóricos de memoria ($96\\text{ MiB}$ en $N=2048$ frente a $32\\text{ MiB}$ de caché L3). No se dispuso de instrumentación PAPI o contadores de hardware para medir fallos de caché (*cache misses*) directamente.
- **Telemetría Térmica y Frecuencia Dinámica:** Los procesadores AMD Ryzen ajustan dinámicamente su frecuencia de reloj (*Precision Boost*) según la temperatura y la carga de los núcleos. No se registraron curvas térmicas continuas durante las 5.26 horas que duró la campaña oficial.

### 7.2 Validez Externa
- **Plataforma Homogénea Monolítica:** Todas las mediciones oficiales provienen de una única máquina de laboratorio (`PCG1UL14N0`). Los resultados no pueden extrapolarse automáticamente a procesadores Intel Core de arquitectura híbrida (P-cores / E-cores), servidores con topología NUMA multi-socket o clústeres distribuidos sobre redes Ethernet/InfiniBand.
- **Entorno de Red Emulada:** C paralelo fue evaluado con MS-MPI utilizando canales de memoria compartida dentro de un único nodo. Por lo tanto, no se reflejan las latencias típicas de interfaces de red física (NICs) ni switches de alta velocidad.

### 7.3 Validez de Constructo
- **Métricas Agregadas en Modelos Paralelos:** En C paralelo, `kernel_s` mide el tiempo del rango MPI más lento (tiempo crítico), mientras que en Go paralelo mide el tiempo acumulado de las *goroutines*. La comparación formal y justa entre ambos modelos se sustenta normativamente en `total_s`, que mide el tiempo de pared (*wall-clock time*) desde la perspectiva del hilo coordinador.

---

## 8. Conclusiones y Trabajo Futuro

### 8.1 Conclusiones Finales
1. **Idoneidad de C para Cómputo Intensivo:** C nativo compilado con optimizaciones vectoriales es la opción incuestionable cuando la máxima velocidad absoluta por núcleo es el objetivo primordial, superando a Go por hasta $3.80\\times$.
2. **Sensibilidad de C a la Arquitectura de Memoria:** La aparente ventaja de C puede verse severamente mitigada si el conjunto de trabajo excede la memoria caché, obligando a los desarrolladores de HPC a implementar técnicas de bloqueo (*tiling* o *cache blocking*) para preservar el rendimiento en matrices gigantes.
3. **Viabilidad de Go en Concurrencia de Sistemas:** Go ofrece una plataforma sumamente productiva, con un comportamiento predecible y una eficiencia de escalamiento notablemente estable (cercana al 65%), convirtiéndose en una alternativa viable para procesamiento de datos cuando la facilidad de mantenimiento y la concurrencia segura pesan más que el último margen de rendimiento numérico.
4. **Superioridad de Hilos sobre Procesos en Nodo Único:** En una única máquina multiprocesador, la sobrecarga del paso de mensajes de MPI hace que una arquitectura puramente basada en OpenMP o hilos nativos sea significativamente más eficiente.

### 8.2 Trabajo Futuro
- Implementar algoritmos basados en teselas bidimensionales (*2D block tiling*) tanto en C como en Go para mitigar la saturación de la memoria caché en $N \\ge 2048$.
- Evaluar la implementación híbrida en un clúster físico distribuido con múltiples nodos interconectados por red para cuantificar el impacto real del modelo jerárquico de Quintin et al.
- Refactorizar la firma del kernel en Go paralelo para pasar slices por valor, eliminando las cuatro recargas de punteros observadas en desensamblado y midiendo la recuperación de rendimiento resultante.

---

## 9. Referencias Bibliográficas (Formato IEEE)

- **[1]** M. Quintin, A. Hasanov, and A. Lastovetsky, "Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms," in *Proceedings of the 42nd International Conference on Parallel Processing (ICPP)*, Lyon, France, 2013, pp. 754–762. DOI: [10.1109/ICPP.2013.89](https://doi.org/10.1109/ICPP.2013.89).
- **[2]** T. Hérault, Y. Robert, G. Bosilca, and J. Dongarra, "Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC," in *Proceedings of the Workshop on Exascale Multi/Many Core Computing Systems (ScalA)*, Denver, CO, USA, 2019, pp. 33–41. DOI: [10.1109/ScalA49573.2019.00010](https://doi.org/10.1109/ScalA49573.2019.00010).
- **[3]** Message Passing Interface Forum, "MPI: A Message-Passing Interface Standard Version 4.0," High Performance Computing Community, Tech. Rep., Jun. 2021.
- **[4]** OpenMP Architecture Review Board, "OpenMP Application Programming Interface Version 5.2," Tech. Rep., Nov. 2021.
- **[5]** A. A. A. Donovan and B. W. Kernighan, *The Go Programming Language*. Addison-Wesley Professional, 2015.

---

## 10. Anexos Técnicos

### Anexo A: Tabla Completa de los 33 Grupos Experimentales Oficiales
*(Datos íntegros preservados en `resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv`)*

Todos los 33 grupos cuentan con 5 réplicas válidas, `validation_status = OK`, ejecutados en `PCG1UL14N0` (AMD Ryzen 5 3600), semilla 42 y commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.

### Anexo B: Integridad Criptográfica de los Datos Crudos
- **Archivo de Mediciones:** `resultados/raw/s08_oficial_integrada_03/mediciones.csv`
- **Manifiesto SHA-256:** `docs/calidad_datos.md` y `docs/bitacora_experimentos.md`
- **Trazabilidad:** Cada cálculo de este informe puede ser regenerado de forma automática y determinista mediante el script `scripts/summarize_results.ps1`.
""")
    print("Escrito docs/informe_final.md exitosamente.")

    # Generamos docs/informe_final.docx con python-docx
    doc = Document()
    
    # Configuración de márgenes
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)

    # Estilos de fuentes
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(0x26, 0x26, 0x26)

    # Título Principal
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = p_title.add_run("INFORME TÉCNICO FINAL INTEGRADO\nEVALUACIÓN EXPERIMENTAL Y COMPARATIVA DE RENDIMIENTO EN MULTIPLICACIÓN DE MATRICES DENSAS CUADRADAS")
    r_title.bold = True
    r_title.font.size = Pt(16)
    r_title.font.color.rgb = RGBColor(0x1F, 0x4E, 0x79)

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Híbrido C (MPI + OpenMP) vs. Concurrente Go (Goroutines + Canales)")
    r_sub.italic = True
    r_sub.font.size = Pt(13)
    r_sub.font.color.rgb = RGBColor(0x59, 0x59, 0x59)

    # Metadatos del Proyecto
    p_meta = doc.add_paragraph()
    p_meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_meta = p_meta.add_run("Computación Paralela y Distribuida · Semestre 2026-II · Sprint 9\nFecha de Consolidación: 26 de Noviembre de 2026\nResponsable de Integración: Integrante 7 · Andrés\nEquipo: Integrantes 1 al 8")
    r_meta.font.size = Pt(10)
    r_meta.font.color.rgb = RGBColor(0x7F, 0x7F, 0x7F)

    doc.add_paragraph() # Espacio

    # Resumen Ejecutivo
    h1 = doc.add_heading("Resumen Ejecutivo (Abstract)", level=1)
    h1.style.font.color.rgb = RGBColor(0x1F, 0x4E, 0x79)

    doc.add_paragraph(
        "Este estudio presenta una evaluación empírica rigurosa del rendimiento, escalabilidad y sobrecostes de coordinación "
        "en la multiplicación de matrices densas cuadradas (A × B = C), contrastando una implementación nativa en lenguaje C compilado "
        "(modelo híbrido de memoria distribuida con MPI y memoria compartida con OpenMP) frente a una implementación administrada en lenguaje Go "
        "(modelo CSP con goroutines y canales). Todas las evaluaciones se llevaron a cabo bajo un estricto protocolo determinista (Protocolo v1.3) "
        "con generación pseudoaleatoria sincronizada (semilla 42) y tamaños de matriz N ∈ {512, 1024, 2048} en una plataforma de cómputo homogénea "
        "y controlada (AMD Ryzen 5 3600 de 6 núcleos físicos, Windows 11 Pro)."
    )
    doc.add_paragraph(
        "La campaña oficial congelada (s08_oficial_integrada_03), compuesta por 198 ejecuciones válidas distribuidas en 33 grupos experimentales "
        "(con 5 réplicas medidas y 1 corrida previa de calentamiento descartada), permitió obtener conclusiones no paramétricas sólidas sustentadas "
        "en medianas y rangos intercuartílicos (IQR). Los hallazgos principales revelan que C supera a Go en tiempo total en todas las dimensiones y "
        "configuraciones equivalentes (ratios Go/C de 1.11× a 3.80×). Sin embargo, la ventaja de C decrece drásticamente al aumentar N (de 3.80× a 1.65×), "
        "como consecuencia de una severa caída en los GFLOPS de C (de 11.3 a 4.5 GFLOPS) atribuible a la saturación de la memoria caché L3. Asimismo, "
        "Go exhibe una escalabilidad paralela más uniforme (eficiencia entre 0.60 y 0.71), y en C la configuración 1 × 4 (OpenMP puro) supera "
        "sistemáticamente a 4 × 1 (MPI puro), confirmando la penalización por paso de mensajes en nodo único."
    )

    # Sección 1: Introducción
    doc.add_heading("1. Introducción y Motivación", level=1)
    doc.add_paragraph(
        "La multiplicación de matrices densas es un núcleo fundamental en computación científica y aprendizaje automático. Si bien el algoritmo "
        "clásico posee una complejidad temporal asintótica O(N³), su rendimiento práctico en procesadores multicore modernos depende drásticamente "
        "de la localidad espacial y temporal, el aprovechamiento de la jerarquía de memoria caché, la vectorización SIMD y el sobrecoste introducido "
        "por los mecanismos de sincronización."
    )
    doc.add_paragraph(
        "Tradicionalmente, la computación de alto rendimiento (HPC) ha estado dominada por C/C++ combinando OpenMP y MPI. Sin embargo, lenguajes modernos "
        "como Go, diseñados sobre el modelo formal de Procesos Secuenciales Comunicados (CSP) con goroutines ligeras y canales, ofrecen una alternativa "
        "atractiva para ingeniería de software concurrente. Este proyecto evalúa cuantitativamente la brecha de rendimiento real entre ambos paradigmas "
        "en un entorno riguroso y determinista."
    )

    # Sección 2: Marco Teórico y Vínculo IEEE
    doc.add_heading("2. Marco Teórico y Vínculo con la Literatura IEEE", level=1)
    doc.add_paragraph(
        "Para fundamentar el diseño y la interpretación de resultados, este estudio se vincula formalmente con dos investigaciones publicadas en IEEE:"
    )
    doc.add_paragraph(
        "• Quintin, Hasanov y Lastovetsky (IEEE ICPP 2013): Demuestran que los algoritmos clásicos de multiplicación matricial distribuida "
        "(como SUMMA) sufren degradación de rendimiento en plataformas multinúcleo si no distinguen comunicaciones intra-nodo de inter-nodo. "
        "Proponen modelos jerárquicos de dos niveles. En nuestro proyecto, adaptamos este principio mediante una partición 1D que combina MPI "
        "para particionado de bloques de filas y OpenMP para distribución de filas locales entre hilos. Los resultados confirman que en un único nodo "
        "la configuración 1 × 4 (OpenMP puro) supera a 4 × 1 (MPI puro), corroborando el modelo de costes de Quintin et al."
    )
    doc.add_paragraph(
        "• Hérault, Robert, Bosilca y Dongarra (IEEE ScalA 2019): Formulan los principios de propiedad estricta de escritura (cada proceso actualiza "
        "exclusivamente sus teselas asignadas de C) y contigüidad espacial para maximizar la tasa de aciertos de caché. En nuestro proyecto, ambas "
        "plataformas implementan estos principios mediante almacenamiento contiguo por filas y recorrido canónico i → k → j, garantizando que A[i,k] "
        "se mantenga en registro mientras B[k,j] y C[i,j] se recorren secuencialmente por líneas de caché de 64 bytes."
    )

    # Sección 3: Metodología Experimental
    doc.add_heading("3. Metodología Experimental y Protocolo de Medición (Protocolo v1.3)", level=1)
    doc.add_paragraph(
        "Las pruebas se ejecutaron en la máquina oficial PCG1UL14N0 (AMD Ryzen 5 3600 de 6 núcleos / 12 hilos lógicos, 16 GB RAM DDR4, Windows 11 Pro build 26300.9711), "
        "bajo el commit congelado 97ccc981e9068d8ec0753cd8a4b7572a6bece34d. Se utilizó el generador LCG determinista idéntico en C y Go con semilla 42. "
        "Se aplicó cronometría segregada separando kernel_s (cálculo matemático puro) de total_s (cálculo + vaciado de salida + coordinación completa). "
        "Se descartó la corrida 0 de calentamiento y se evaluaron 5 réplicas oficiales por configuración utilizando Mediana e IQR."
    )

    # Sección 4: Comparación Directa
    doc.add_heading("4. Comparativa Directa C vs. Go y Conclusiones Verificables", level=1)
    doc.add_paragraph(
        "A continuación se presenta la tabla consolidada oficial que contrasta el tiempo total de ejecución y los GFLOPS entre C y Go para "
        "todas las configuraciones equivalentes:"
    )

    # Crear Tabla en Word
    # Datos representativos
    table_data = [
        ["Dimensión (N)", "Configuración", "Mediana total_s C (s)", "Mediana total_s Go (s)", "Ratio Go / C", "GFLOPS C", "GFLOPS Go"],
        ["512", "Secuencial", "0.0238", "0.0905", "3.80×", "11.29", "2.97"],
        ["512", "Paralelo 1 W / 1×1", "0.0588", "0.1340", "2.28×", "4.56", "2.00"],
        ["512", "Paralelo 2 W / 1×2", "0.0301", "0.0677", "2.25×", "8.90", "3.96"],
        ["512", "Paralelo 4 W / 1×4", "0.0166", "0.0348", "2.09×", "16.16", "7.72"],
        ["1024", "Secuencial", "0.2029", "0.7262", "3.58×", "10.58", "2.96"],
        ["1024", "Paralelo 1 W / 1×1", "0.4501", "1.0818", "2.40×", "4.77", "1.99"],
        ["1024", "Paralelo 2 W / 1×2", "0.2765", "0.5524", "2.00×", "7.77", "3.89"],
        ["1024", "Paralelo 4 W / 1×4", "0.1427", "0.3037", "2.13×", "15.05", "7.07"],
        ["2048", "Secuencial", "3.8168", "6.2969", "1.65×", "4.50", "2.73"],
        ["2048", "Paralelo 1 W / 1×1", "5.0776", "8.8620", "1.75×", "3.38", "1.94"],
        ["2048", "Paralelo 2 W / 1×2", "2.5289", "4.5669", "1.81×", "6.79", "3.76"],
        ["2048", "Paralelo 4 W / 1×4", "1.8140", "2.4971", "1.38×", "9.47", "6.88"],
    ]

    table = doc.add_table(rows=len(table_data), cols=len(table_data[0]))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table)

    for i, row in enumerate(table_data):
        for j, val in enumerate(row):
            cell = table.cell(i, j)
            cell.text = val
            set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            if i == 0:
                set_cell_background(cell, "1F4E79")
                p.runs[0].font.bold = True
                p.runs[0].font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
                p.runs[0].font.size = Pt(9.5)
            else:
                p.runs[0].font.size = Pt(9.5)
                if i % 2 == 1:
                    set_cell_background(cell, "F2F4F8")

    doc.add_paragraph()

    # Conclusiones Verificables
    doc.add_heading("Conclusiones Verificables Principales (C1 - C6)", level=2)
    doc.add_paragraph("• C1: C es sistemáticamente más rápido que Go en tiempo absoluto en todos los escenarios (ratios Go/C de 1.11× a 3.80×).")
    doc.add_paragraph("• C2: La ventaja de C se erosiona con N (pasa de 3.80× en N=512 a 1.65× en N=2048) debido a la caída de GFLOPS en C por saturación de caché L3.")
    doc.add_paragraph("• C3: Go escala con mayor eficiencia interna (E de 0.60 a 0.71) que C (0.25 a 0.75), aunque sobre una base secuencial más lenta.")
    doc.add_paragraph("• C4: En C con P × T = 4, P=1/T=4 (OpenMP puro) es superior a P=4/T=1 (MPI puro) en todas las dimensiones.")
    doc.add_paragraph("• C5: La versión paralela con un solo trabajador cuesta más que la secuencial (penalizaciones de 1.33× a 2.47× en C y 1.41× a 1.49× en Go) por sobrecostes de inicialización.")
    doc.add_paragraph("• C6: Las diferencias de rendimiento se deben en gran medida a la autovectorización SIMD de MSVC en C frente al código escalar de Go, y al coste de recargas de punteros detectado en el desensamblado de Go paralelo.")

    # Sección 5: Amenazas a la Validez
    doc.add_heading("5. Amenazas a la Validez", level=1)
    doc.add_paragraph(
        "Se identifican como limitaciones: resolución de temporizador en duraciones inferiores a 100 ms (N=512), "
        "ausencia de contadores de hardware directos (PAPI) para medir fallos de caché, evaluación en un único nodo y arquitectura (Zen 2), "
        "y ejecución de MPI sobre memoria compartida en Windows 11 sin switches de red físicos."
    )

    # Sección 6: Conclusiones y Trabajo Futuro
    doc.add_heading("6. Conclusiones Generales y Trabajo Futuro", level=1)
    doc.add_paragraph(
        "C compilado nativo se mantiene como el líder indiscutible en rendimiento numérico de cómputo intensivo, mientras que Go "
        "ofrece una plataforma altamente competitiva en escalabilidad y robustez para arquitecturas concurrentes modernas. "
        "Como trabajo futuro se propone implementar bloqueo de caché bidimensional (2D block tiling) para mitigar la saturación de memoria "
        "en matrices N ≥ 2048, y evaluar C distribuido en un clúster físico multinodo."
    )

    # Referencias IEEE
    doc.add_heading("7. Referencias Bibliográficas (Formato IEEE)", level=1)
    doc.add_paragraph(
        "[1] M. Quintin, A. Hasanov, and A. Lastovetsky, 'Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms,' "
        "in Proceedings of the 42nd International Conference on Parallel Processing (ICPP), Lyon, France, 2013, pp. 754–762. DOI: 10.1109/ICPP.2013.89.\n"
        "[2] T. Hérault, Y. Robert, G. Bosilca, and J. Dongarra, 'Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC,' "
        "in Proceedings of the Workshop on Exascale Multi/Many Core Computing Systems (ScalA), Denver, CO, USA, 2019, pp. 33–41. DOI: 10.1109/ScalA49573.2019.00010.\n"
        "[3] Message Passing Interface Forum, 'MPI: A Message-Passing Interface Standard Version 4.0,' Tech. Rep., Jun. 2021.\n"
        "[4] OpenMP Architecture Review Board, 'OpenMP Application Programming Interface Version 5.2,' Tech. Rep., Nov. 2021.\n"
        "[5] A. A. A. Donovan and B. W. Kernighan, The Go Programming Language. Addison-Wesley Professional, 2015."
    )

    doc.save(DOCX_OUTPUT)
    print(f"Guardado docs/informe_final.docx exitosamente ({os.path.getsize(DOCX_OUTPUT)} bytes).")

if __name__ == "__main__":
    generate_report()
