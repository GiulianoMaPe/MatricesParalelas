# Bibliografía Verificada y Justificación de Decisiones de Diseño

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)  
**Curso:** Programación Concurrente y Paralela — UNMSM  
**Sprint:** 2 (Semana 2)  
**Autor:** Integrante 8 — Roberto  
**Estado:** Completado para Sprint 2 · Pendiente de revisión cruzada por Integrante 7 (Andres)  

---

## 1. Introducción y Marco Teórico

El desarrollo de software paralelo de alto rendimiento exige que las decisiones arquitectónicas —como la topología de particionamiento de datos, el protocolo de paso de mensajes y el orden de acceso a memoria— estén fundamentadas en la teoría formal de la computación paralela y respaldadas por literatura científica validada por pares.

Para el **Proyecto 2 (Multiplicación de Matrices Densas)** de la asignatura de Programación Concurrente y Paralela, el presente documento cumple con los objetivos asignados al **Integrante 8** en el Sprint 2:
1. Analizar y resumir en profundidad dos artículos científicos de la literatura IEEE provista por la cátedra, disponibles en el repositorio local bajo `docs/referencias/`:
   * **Candidato 1:** Quintin, Hasanov & Lastovetsky (ICPP 2013) — *Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms*.
   * **Candidato 2:** Herault, Robert, Bosilca & Dongarra (ScalA 2019) — *Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC*.
2. Seleccionar formalmente el artículo de referencia principal.
3. Vincular los modelos teóricos y hallazgos empíricos de los autores con las **decisiones de diseño adoptadas en nuestro proyecto**, particularmente:
   * La elección del **reparto 1D continuo por bloques de filas** (*1D block-row partitioning*) con `MPI_Scatterv` y `MPI_Gatherv` frente a descomposiciones en cuadrícula 2D (Cannon / SUMMA).
   * La optimización de la jerarquía de memoria mediante el orden canónico de bucles $i, k, j$.
   * La arquitectura híbrida de dos niveles (MPI a nivel de procesos y OpenMP a nivel de núcleos con `MPI_THREAD_FUNNELED`).
   * La correspondencia del modelo en Go mediante *worker pools* acotados con canales tipados y particionado de filas sin contención de escritura.

---

## 2. Resumen Técnico de los Artículos Candidatos

### 2.1. Candidato 1: Quintin, Hasanov & Lastovetsky (ICPP 2013)

* **Referencia completa:** J.-N. Quintin, K. Hasanov, and A. Lastovetsky, "Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms," in *Proc. 2013 42nd International Conference on Parallel Processing (ICPP)*, Lyon, France: IEEE, 2013, pp. 754–762. DOI: [10.1109/ICPP.2013.88](https://doi.org/10.1109/ICPP.2013.88).
* **Ubicación en el proyecto:** `docs/referencias/Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms.pdf`.

#### Síntesis y Aportes Teóricos
El artículo aborda el cuello de botella más crítico en la multiplicación de matrices paralelas en arquitecturas de memoria distribuida: **el costo de comunicación entre procesos**. Los autores analizan los algoritmos clásicos basados en mallas 2D:
* **Cannon (1969):** Requiere alineamiento inicial y rotaciones circulares paso a paso (*shifts*) punto a punto de subbloques de matrices $A$ y $B$.
* **SUMMA (van de Geijn & Watts, 1997):** Sustituye las rotaciones por difusiones sucesivas (*broadcasts*) de paneles de filas y columnas a lo largo de las dimensiones de la malla 2D de procesos.

Quintin et al. demuestran que, a medida que el número de procesos $P$ crece en supercomputadores jerárquicos (multinúcleo por nodo conectados mediante red de interconexión), las difusiones globales y la saturación del ancho de banda degradan la eficiencia. Para resolverlo, formulan **HSUMMA** (*Hierarchical SUMMA*), un algoritmo estructurado en dos niveles jerárquicos:
1. **Nivel inter-nodo (memoria distribuida):** Una malla virtual superior que reduce el número de participantes en las operaciones colectivas.
2. **Nivel intra-nodo (memoria compartida / hilos locales):** Aprovecha la velocidad de transferencia del bus de memoria local para multiplicar los subbloques asignados.

Los autores modelan matemáticamente el tiempo total de ejecución $T$ descomponiéndolo en tiempo de cómputo ($T_{comp}$) y tiempo de comunicación ($T_{comm}$):
$$T_{comm} = \lambda \cdot \alpha + V \cdot \beta$$
donde $\alpha$ es la latencia de inicio del mensaje, $\beta$ es el tiempo de transferencia por elemento (inverso del ancho de banda), $\lambda$ es la cantidad de fases de sincronización y $V$ es el volumen total de datos transferidos. Demuestran que minimizar $\lambda$ y simplificar la topología de comunicación es determinante cuando la relación cómputo/comunicación es moderada.

---

### 2.2. Candidato 2: Herault, Robert, Bosilca & Dongarra (ScalA 2019)

* **Referencia completa:** T. Herault, Y. Robert, G. Bosilca, and J. Dongarra, "Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC," in *Proc. 10th IEEE/ACM Workshop on Latest Advances in Scalable Algorithms for Large-Scale Systems (ScalA 2019)*, Denver, CO, USA: IEEE, 2019, pp. 21–28. DOI: [10.1109/ScalA49576.2019.00010](https://doi.org/10.1109/ScalA49576.2019.00010).
* **Ubicación en el proyecto:** `docs/referencias/Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC.pdf`.

#### Síntesis y Aportes Teóricos
Liderado por el pionero del cómputo de alto rendimiento Jack Dongarra (Premio Turing 2021), este trabajo investiga la multiplicación densa $C = A \times B$ en arquitecturas heterogéneas distribuidas. Los autores modelan el producto matricial no como una secuencia rígida y síncrona de bucles, sino como un **Grafo Acíclico Dirigido (DAG) de tareas** gestionado por el entorno de ejecución dinámico PaRSEC.

Puntos clave del artículo:
1. **Tiling y Localidad de Datos:** Las matrices se dividen en teselas o bloques (*tiles*) continuos de tamaño $B_S \times B_S$. Una tesela $C_{i, j}$ se calcula como:
   $$C_{i, j} = \sum_{k=0}^{K-1} A_{i, k} \times B_{k, j}$$
   Al ajustar el tamaño del bloque a la capacidad de las memorias caché (L1/L2/L3), se maximiza la reutilización de datos sin desalojar líneas prematuramente.
2. **Solapamiento Asíncrono Comunicación-Cálculo:** El runtime transfiere las dependencias de datos de la tarea $k+1$ mientras los núcleos de procesamiento calculan la tarea $k$, ocultando la latencia de la red.
3. **Propiedad Exclusiva de Escritura:** Cada bloque $C_{i, j}$ tiene un único dueño de memoria durante la fase de acumulación, evitando bloqueos de sincronización y condiciones de carrera entre tareas concurrentes.

---

## 3. Selección del Artículo Científico Principal

Se selecciona como **referencia científica fundamental** del proyecto a:

> **Quintin, Hasanov & Lastovetsky (ICPP 2013) — *Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms***,  
> complementado metodológicamente con los principios de localidad y propiedad de tareas de **Herault et al. (ScalA 2019 / Jack Dongarra)**.

### Criterio de Selección
1. **Alineación con el contrato técnico:** El artículo de Quintin et al. fundamenta formalmente el modelo híbrido (distribuido con MPI + compartido local con hilos), que es exactamente la arquitectura de dos niveles requerida para nuestra versión `c_paralelo`.
2. **Análisis de la sobrecarga de comunicación:** Proporciona las herramientas analíticas para comparar el coste de transportar filas completas frente a submatrices dispersas, guiando la decisión de distribución de datos.

---

## 4. Vinculación con las Decisiones de Diseño del Proyecto

A partir de los modelos de Quintin et al. y Herault et al., se sustentan las cuatro decisiones de diseño centrales implementadas en el código base:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                 Matriz A (N x N)                        │
                  └─────────────────────────────────────────────────────────┘
                                       │
                      MPI_Scatterv (Reparto 1D por Filas)
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        ▼                              ▼                              ▼
  Proceso 0 (Rank 0)             Proceso 1 (Rank 1)             Proceso P-1 (Rank P-1)
  Recibe q o q+1 filas           Recibe q o q+1 filas           Recibe q filas
  ────────────────────           ────────────────────           ────────────────────
  Bcast(B) completo              Bcast(B) completo              Bcast(B) completo
  #pragma omp parallel for       #pragma omp parallel for       #pragma omp parallel for
  (Hilos OpenMP: bucle i,k,j)    (Hilos OpenMP: bucle i,k,j)    (Hilos OpenMP: bucle i,k,j)
        │                              │                              │
        └──────────────────────────────┼──────────────────────────────┘
                                       │
                       MPI_Gatherv (Reunión de Filas)
                                       │
                                       ▼
                  ┌─────────────────────────────────────────────────────────┐
                  │                 Matriz C (N x N)                        │
                  └─────────────────────────────────────────────────────────┘
```

### 4.1. Decisión 1: Reparto 1D por Bloques de Filas (*1D Block-Row Decomposition*)

#### Fundamentación Técnica
Los algoritmos como Cannon o SUMMA en mallas 2D descomponen $A$ y $B$ en submatrices cuadradas $\frac{N}{\sqrt{P}} \times \frac{N}{\sqrt{P}}$. Aunque teóricamente reducen el volumen asintótico de comunicación a $O(N^2 / \sqrt{P})$, introducen dos desventajas críticas en memorias contiguas:
1. **Pérdida de continuidad espacial:** En un almacenamiento plano por filas (*row-major order*), una submatriz 2D **no es continua en memoria**. Cada fila del bloque local está separada por $N - \frac{N}{\sqrt{P}}$ elementos en el heap. Para transferirla con MPI se requeriría crear tipos derivados complejos (`MPI_Type_vector`) o realizar copias intermedias manuales (*packing/unpacking*), introduciendo un sobrecoste que Quintin et al. identifican como perjudicial en nodos multinúcleo.
2. **Sobrecarga de empaquetamiento frente a ancho de banda local:** En nuestro entorno de ejecución (Windows 11 en una estación mononodo con $P \in \{1, 2, 4, 8\}$ procesos comunicándose mediante memoria compartida emulada por MS-MPI a través de buffers de canal local), el ancho de banda efectivo de copia de memoria es sumamente alto ($>20 \text{ GB/s}$). La sobrecarga de empaquetar bloques 2D supera ampliamente cualquier ahorro teórico de volumen de red.

#### Implementación en el Proyecto
Adoptamos una **descomposición 1D por franjas de filas horizontales contiguas**:
* Cada proceso $p$ recibe un bloque de $F_p$ filas contiguas de la matriz $A$, donde $F_p \in \{q, q+1\}$ con $q = \lfloor N/P \rfloor$ y $r = N \pmod P$.
* Dado que las filas son contiguas en el vector plano unidimensional indexado con $i \times N + j$, el bloque local de $A$ es **un único segmento contiguo de memoria** de tamaño $F_p \times N \times \text{sizeof(double)}$.
* Esto permite usar `MPI_Scatterv` y `MPI_Gatherv` de manera directa, transfiriendo memoria sin búferes temporales de empaquetamiento ni fragmentación.

### 4.2. Decisión 2: Difusión Global de la Matriz B (`MPI_Bcast`)

#### Fundamentación Técnica
Para multiplicar $C_{local} = A_{local} \times B$, cada proceso necesita acceder a todas las columnas de $B$.
En lugar de rotar subpaneles de $B$ en múltiples rondas síncronas de comunicación (como hace SUMMA, incrementando la latencia acumulada $\lambda \cdot \alpha$), el proceso raíz transmite la matriz $B$ completa a todos los rangos al inicio mediante una única llamada colectiva `MPI_Bcast`.

* **Análisis de memoria:** Para las dimensiones experimentales del proyecto ($N=512, 1024, 2048$), una matriz de doubles ocupa:
  * $N=512$: $512^2 \times 8 \text{ bytes} = 2 \text{ MB}$.
  * $N=1024$: $1024^2 \times 8 \text{ bytes} = 8 \text{ MB}$.
  * $N=2048$: $2048^2 \times 8 \text{ bytes} = 32 \text{ MB}$.
* Con $P=4$ procesos, replicar $B$ consume a lo sumo $128 \text{ MB}$ en todo el sistema, lo cual es despreciable frente a los $16 \text{ GB}$ de RAM disponibles en las máquinas de prueba.
* **Beneficio algorítmico:** Se elimina toda comunicación durante la fase de cálculo pura (`kernel_s`), permitiendo que el bucle de multiplicación se ejecute a velocidad de silicio sin interrupciones ni esperas de red.

### 4.3. Decisión 3: Orden de Bucles Canónico $i, k, j$ y Localidad de Caché

#### Fundamentación Técnica
Siguiendo los hallazgos de Herault et al. (2019) sobre la reutilización de teselas y líneas de caché:
* En el bucle tradicional de libros de álgebra lineal ($i, j, k$):
  ```c
  for (i = 0; i < N; i++)
      for (j = 0; j < N; j++)
          for (k = 0; k < N; k++)
              C[i*N + j] += A[i*N + k] * B[k*N + j];
  ```
  El acceso a $B[k \times N + j]$ se produce saltando de fila en fila (paso $N$). Cada acceso a $B$ incurre en un fallo de caché (*cache miss* por zancada), expulsando líneas de caché de 64 bytes antes de utilizarlas por completo.
* En el orden **$i, k, j$** adoptado contractualmente en las cuatro versiones de nuestro proyecto:
  ```c
  for (i = 0; i < local_rows; i++) {
      for (k = 0; k < N; k++) {
          double r = A_local[i*N + k];
          for (j = 0; j < N; j++) {
              C_local[i*N + j] += r * B[k*N + j];
          }
      }
  }
  ```
  * En el bucle más interno sobre $j$, tanto $C_{local}[i \times N + j]$ como $B[k \times N + j]$ se leen y escriben **en riguroso orden secuencial continuo** (paso unitario, *stride-1*).
  * La CPU aprovecha al 100% las líneas de caché de 64 bytes (8 doubles contiguos por línea) y el mecanismo de prebúsqueda por hardware (*hardware prefetcher*), minimizando fallos a memoria principal.
  * La variable $A_{local}[i \times N + k]$ se conserva en un registro del procesador (`r`) durante todas las $N$ iteraciones de $j$.

### 4.4. Decisión 4: Arquitectura Híbrida de Dos Niveles (MPI + OpenMP)

#### Fundamentación Técnica
Quintin et al. señalan que ejecutar un proceso MPI por cada núcleo en una máquina multinúcleo satura los búferes de memoria del runtime y duplica innecesariamente los datos replicados (como la matriz $B$).
Por ello, nuestro diseño establece:
1. **Nivel 1 (Procesos MPI):** Un número reducido de procesos $P$ (por ejemplo, 1, 2 o 4). El hilo inicial gestiona el entorno con nivel `MPI_THREAD_FUNNELED`, asegurando que ninguna llamada de comunicación interfiera con las regiones paralelas.
2. **Nivel 2 (Hilos OpenMP):** Dentro de cada proceso, la región `#pragma omp parallel for schedule(static)` distribuye las $F_p$ filas locales de forma estática y determinista entre $T$ hilos de procesamiento, garantizando afinidad de caché y cero sobrecoste de comunicación entre hilos del mismo proceso.

### 4.5. Decisión 5: Equivalencia Concurrente en Go (*Worker Pools* y Propiedad de Filas)

#### Fundamentación Técnica
En consonancia con el principio de Herault et al. de asignación exclusiva de memoria para evitar contención:
* En `go_paralelo`, se descarta terminantemente crear una goroutine por cada celda ($N^2$ goroutines) o por cada elemento, lo que provocaría una sobrecarga inaceptable en el scheduler de Go y saturación de la recolección de basura (*GC*).
* Se implementa un **conjunto acotado de $W$ trabajadores (*worker pool*)**:
  * Un canal de tareas despacha bloques continuos de filas $[fila_{inicio}, fila_{fin}]$.
  * **Invariante de concurrencia:** Cada fila de $C$ es propiedad de escritura exclusiva de un único trabajador, mientras que $A$ y $B$ son de solo lectura compartida en memoria.
  * Esto garantiza la ausencia total de condiciones de carrera (*data races*) sin requerir primitivas de exclusión mutua (`sync.Mutex`) dentro del bucle de acumulación, logrando una eficiencia de escalado idéntica a OpenMP.
  * La sincronización final se gestiona con `sync.WaitGroup`, asegurando que no se registren métricas de tiempo hasta que el último trabajador haya completado sus filas.

---

## 5. Referencias Bibliográficas en Formato IEEE

```bibtex
[1] J.-N. Quintin, K. Hasanov, and A. Lastovetsky, "Hierarchical Parallel Matrix 
    Multiplication on Large-Scale Distributed Memory Platforms," in Proc. 2013 
    42nd International Conference on Parallel Processing (ICPP), Lyon, France, 
    2013, pp. 754–762, doi: 10.1109/ICPP.2013.88.

[2] T. Herault, Y. Robert, G. Bosilca, and J. Dongarra, "Generic Matrix Multiplication 
    for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC," in Proc. 
    10th IEEE/ACM Workshop on Latest Advances in Scalable Algorithms for Large-Scale 
    Systems (ScalA 2019), Denver, CO, USA, 2019, pp. 21–28, doi: 10.1109/ScalA49576.2019.00010.

[3] H. Huang and E. Chow, "Exploring the Design Space of Distributed Parallel Sparse 
    Matrix–Multiple Vector Multiplication," IEEE Trans. Parallel Distrib. Syst., 
    vol. 35, no. 11, pp. 1977–1988, Nov. 2024, doi: 10.1109/TPDS.2024.3458921.

[4] N. Dilley and J. Lange, "An Empirical Study of Messaging Passing Concurrency 
    in Go Projects," in Proc. 2019 IEEE 26th International Conference on Software 
    Analysis, Evolution and Reengineering (SANER), Hangzhou, China, 2019, pp. 377–387, 
    doi: 10.1109/SANER.2019.8668036.

[5] P. Pacheco, An Introduction to Parallel Programming, 2nd ed. Cambridge, MA, 
    USA: Morgan Kaufmann, 2021.
```

---

## 6. Criterio de Aceptación del Entregable (Definition of Done)

Este documento cumple satisfactoriamente con los criterios de aceptación del **Sprint 2** para el Integrante 8:
- [x] Contiene el resumen analítico y profundo de dos artículos de literatura científica especializada (Quintin et al. 2013 y Herault et al. 2019).
- [x] Selecciona al menos un artículo formal de la IEEE (Quintin et al., ICPP 2013).
- [x] Conecta rigurosamente las conclusiones teóricas con la decisión de diseño de reparto por bloques de filas con `MPI_Scatterv`/`MPI_Gatherv` en memoria continua.
- [x] Justifica el orden de bucles $i, k, j$, el uso de `MPI_Bcast` para $B$ y la arquitectura de *worker pools* sin carreras en Go.
- [x] Provee las citas normalizadas bajo el estándar formal IEEE.
- [ ] Revisión cruzada por Integrante 7 (Andres) registrada en `docs/sprints/sprint-02.md`.
