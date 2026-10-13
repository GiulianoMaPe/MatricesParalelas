# Matriz de Requisitos y Pendientes Priorizados

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)
**Curso:** Programación Concurrente y Paralela — UNMSM
**Sprint:** 1 (Semana 1)
**Autor:** Integrante 8 — Roberto
**Estado:** Entregable S1 conforme. La evaluación asistida de la versión actual, en la voz de Andrés (I7), está registrada en [Sprint 1](sprints/sprint-01.md).

---

## 1. Introducción y Propósito

El presente documento formaliza el marco de requerimientos técnicos y criterios de calidad académica para el desarrollo, validación y evaluación experimental de cuatro programas de multiplicación de matrices cuadradas densas ($A \times B = C$):

1. **`c_secuencial`**: Referencia monocore en lenguaje C nativo (sin OpenMP ni MPI).
2. **`c_paralelo`**: Implementación paralela híbrida en C con memoria distribuida (MS-MPI) y memoria compartida multinúcleo (OpenMP).
3. **`go_secuencial`**: Referencia secuencial en lenguaje Go con un único hilo lógico de cómputo.
4. **`go_paralelo`**: Implementación concurrente/paralela en Go mediante _worker pools_ acotados (goroutines) y canales de sincronización.

El objetivo central es transformar la guía técnica del repositorio en **entregables verificables, contratos funcionales y un backlog priorizado**. Antes de aceptar mediciones, la salida matemática debe cumplir la tolerancia acordada. Esta revisión no coteja un sílabo o una rúbrica docente que no estén incluidos en el proyecto.

---

## 2. Criterios Académicos a Entregables Verificables

A continuación se traduce cada criterio de evaluación del curso en un mecanismo de prueba concreto y medible en el proyecto:

| Criterio Académico del Curso                       | Definición Pedagógica                                                                                 | Implementación Técnica y Verificación en el Proyecto                                                                                                                                                                                                                                                                                                                                                                          |
| :------------------------------------------------- | :---------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Corrección Matemática Estricta**                 | El cálculo numérico debe ser exacto frente a una solución de referencia comprobada.                   | Comparación celda por celda de toda la matriz$C$ ($N \times N$) aplicando tolerancia numérica combinada:`abs(C_calc[i] - C_esp[i]) <= atol + rtol * abs(C_esp[i])`con `atol = 1e-9` y `rtol = 1e-9`.**Invariante:** Se rechazan terminantemente _checksums_ o sumas de control como sustituto de validación completa. NaN o $\pm\infty$ generan aborto inmediato con error.                                                   |
| **Rigor en la Cronometría de Rendimiento**         | Medir únicamente el tiempo algorítmico, excluyendo I/O, generación de datos y reservas de memoria.    | Se diferencian dos intervalos de tiempo estrictos:1.`kernel_s`: Intervalo exclusivo del triple bucle de multiplicación matricial.2. `total_s`: Incluye vaciado de $C$, reparto de datos (`Scatterv`/canales), cálculo y recolección de resultados (`Gatherv`/`WaitGroup`).**Invariante:** Toda lectura de disco, generación pseudoaleatoria, validación numérica e impresión en terminal/CSV quedan **fuera** de la medición. |
| **Monotonicidad y Precisión del Reloj**            | Uso de temporizadores de alta resolución inmunes a desajustes de reloj de pared (_wall-clock drift_). | • En C:`QueryPerformanceCounter` y `QueryPerformanceFrequency` de la API Win32.• En Go: `time.Now()` y `time.Since()` apoyados en reloj monotónico nativo del runtime.• En MPI: `MPI_Wtime()` con sincronización de inicio y agregación final del máximo global entre procesos mediante `MPI_Reduce(..., MPI_MAX)`.                                                                                                           |
| **Control de Procesos y Concurrencia Limpia** | Evitar bloqueos (_deadlocks_), procesos zombies o hilos desbocados. | En C híbrido: `MPI_THREAD_FUNNELED`, con llamadas MPI desde el hilo inicial de cada proceso y fuera de OpenMP; rank 0 prepara entradas y emite resultados. En Go: pool fijo de W trabajadores, canal de bloques y WaitGroup. Prohibido crear goroutines por celda. |
| **Gestión Robusta de Errores y Códigos de Salida** | Interfaz CLI uniforme que informe fallos por`stderr` con códigos de terminación consistentes.         | Códigos de salida universales en las 4 versiones:•`0`: Ejecución exitosa y validada.• `1`: Error de entorno, argumentos inválidos, fallo de reserva de memoria o archivo malformado.• `2`: Operación pendiente o no implementada (estado de esqueleto).**Invariante:** En caso de error crítico en un proceso MPI, se invoca decisión colectiva o `MPI_Abort` para evitar que otros nodos queden bloqueados indefinidamente.  |
| **Reproducibilidad Experimental**                  | Conclusiones sustentadas en réplicas estadísticas en condiciones homogéneas de hardware.              | Campaña oficial compuesta por: 1 ejecución de calentamiento (_warm-up_) descartada + 5 repeticiones medidas por configuración. Cálculo de mediana, valor mínimo, valor máximo e intervalo intercuartílico (IQR). Registro exhaustivo de metadatos de CPU, RAM, SO y commit Git.                                                                                                                                               |

---

## 3. Matriz de Requisitos del Sistema

### 3.1. Requisitos Funcionales (RF)

| ID        | Nombre                                           | Descripción Técnica                                                                                                                                                                                                                                                                                                                          | Prioridad      |
| :-------- | :----------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------- |
| **RF-01** | **Interfaz de Línea de Comandos (CLI) Estándar** | Los 4 ejecutables deben aceptar de forma uniforme los argumentos obligatorios:`--n <dim>` (dimensión entera positiva) y `--seed <uint32>` (semilla entre 0 y $4294967295$). `go_paralelo` añade `--workers <W>`. Las 4 versiones deben responder a `--smoke-test` para verificación de entorno.                                              | **Alta (P0)**  |
| **RF-02** | **Generador Determinista Portable**              | Implementar un generador congruencial lineal (LCG) idéntico de 32 bits en C y Go para matrices$A$ y $B$, evitando la discrepancia entre el `rand()` de C y `math/rand` de Go. Regla de transición: `state = (1664525 * state + 1013904223) mod 2^32`. Normalización flotante: `(int64(state % 2001) - 1000) / 1000.0` (rango $[-1.0, 1.0]$). | **Alta (P0)**  |
| **RF-03** | **Cálculo Matricial Canónico ($i, k, j$)** | Implementar el producto denso $C = A \times B$ con bucles i,k,j y C inicialmente a cero. En el bucle j se recorren B y C por filas contiguas; el efecto de esa localidad se evaluará experimentalmente. | **Alta (P0)** |
| **RF-04** | **Soporte de Fixtures de Archivo**               | Soporte de flags`--input <archivo>` para leer matrices de prueba predefinidas y `--output <archivo>` para exportar la matriz resultante $C$. El formato de archivo consta de una primera línea con $N$, seguida de $N$ filas para $A$ y $N$ filas para $B$ (valores separados por espacios y punto decimal).                                 | **Media (P1)** |
| **RF-05** | **Emisión Limpia de Métricas** | Salida por `stdout` con las 20 columnas CSV de `docs/protocolo_medicion.md`, sección 4; las matrices usan `docs/formato_datos.md`. Errores y diagnósticos por `stderr`. No imprimir matrices durante el benchmark. | **Media (P1)** |

### 3.2. Requisitos No Funcionales (RNF)

| ID         | Nombre                                       | Descripción Técnica                                                                                                                                                                                                                                                                                    | Prioridad      |
| :--------- | :------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------- |
| **RNF-01** | **Precisión de Punto Flotante**              | Uso homogéneo de doble precisión de 64 bits:`double` en C y `float64` en Go para todas las celdas de las matrices $A$, $B$ y $C$.                                                                                                                                                                      | **Alta (P0)**  |
| **RNF-02** | **Disposición Contigua de Memoria**          | Almacenamiento contiguo en el heap mediante vector unidimensional plano (_row-major order_), mapeando $(i, j)$ mediante la indexación aritmética `i * N + j`. Prohibido el uso de punteros a punteros (`double**`) que fragmenten la memoria.                                                          | **Alta (P0)**  |
| **RNF-03** | **Paralelismo Híbrido C (MPI + OpenMP)**     | Reparto de filas entre$P$ procesos mediante `MPI_Scatterv` para $A$, difusión completa de $B$ mediante `MPI_Bcast`, paralelización multinúcleo en cada nodo mediante `#pragma omp parallel for schedule(static)` sobre las filas locales, y reunión en el proceso raíz con `MPI_Gatherv`.              | **Alta (P0)**  |
| **RNF-04** | **Balanceo de Carga con Resto No Divisible** | Distribución matemática de$N$ filas entre $P$ procesos: cociente $q = \lfloor N/P \rfloor$ y resto $r = N \pmod P$. Los primeros $r$ procesos reciben $q+1$ filas y los $P-r$ restantes reciben $q$ filas. El cálculo de `counts` y `displs` debe admitir $N < P$ (procesos con 0 filas).              | **Alta (P0)**  |
| **RNF-05** | **Concurrencia Segura en Go**                | Un único trabajador (goroutine) será propietario de la escritura de cada fila de$C$ asignada. Matrices $A$ y $B$ serán de estricta solo lectura en memoria compartida. Comunicación mediante canal de bloques de tareas y sincronización limpia sin _data races_ (validable mediante `go test -race`). | **Alta (P0)**  |
| **RNF-06** | **Gestión de Memoria y Prevención de Fugas** | Validación explícita de retornos de`malloc` usando tipos de tamaño `size_t` para evitar desbordamientos enteros al dimensionar $N \times N \times \text{sizeof(double)}$. Liberación de todos los buffers locales y globales antes de la terminación.                                                  | **Media (P1)** |
| **RNF-07** | **Compatibilidad Nativa Windows 11 x64**     | Compilación transparente en Windows 11 de 64 bits mediante scripts de PowerShell (`scripts/build_windows.ps1`), integrando MSVC (Hostx64/x64), MS-MPI SDK v10.1 y Go 1.22+ sin dependencias de entornos emulados (WSL o Cygwin).                                                                       | **Alta (P0)**  |

---

## 4. Diagnóstico del Repositorio y Backlog Priorizado

La siguiente lista conserva la fotografía de la base recibida al preparar S1; no describe los cambios posteriores de S2:

- Las 4 carpetas de versión (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`) poseen su estructura de compilación lista, pero sus módulos contienen únicamente esqueletos que devuelven código `2` ante llamadas de cálculo (`algorithm: pending`, `validation: pending`).
- El entorno base está verificado para compilación (`smoke-test`), pero carece de la lógica de multiplicación, generador común y fixtures ampliados.

A continuación se conserva el **Backlog Priorizado** del plan. Al 2026-10-01, los generadores y lectores están implementados, los fixtures incluyen N impar y existen validaciones e interfaces C/Go; los multiplicadores siguen pendientes. Las revisiones y el cierre se consultan en `docs/sprints/`. Una tarea implementada anticipadamente se dedica a revisión y pruebas en el sprint previsto, según la guía.

|    Prioridad     | Tarea / Módulo                               | Descripción del Entregable Requerido                                                                                                                       | Sprint Asignado | Responsable Primario |
| :--------------: | :------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------: | :------------------: |
| **P0 (Crítica)** | **Definición de Contratos e Interfaces**     | Completar`c_secuencial/include/`, `c_paralelo/include/partition.h` y `go_secuencial/matrix.go` con prototipos formales de particionado, memoria y errores. |    Sprint 2     |      I1, I2, I3      |
| **P0 (Crítica)** | **Especificación de Fixtures y Tolerancias** | Ampliar`tests/fixtures/` con casos conocidos ($2\times 2$, identidad, ceros, negativos) y definir políticas para rechazo de NaN e infinitos.               |    Sprint 2     |          I5          |
| **P0 (Crítica)** | **Contrato de Generación Determinista**      | Especificar formalmente en`docs/formato_datos.md` las constantes del LCG y generar vectores de prueba numéricos de control.                                |    Sprint 2     |          I6          |
| **P0 (Crítica)** | **Fundamentación Científica del Reparto**    | Analizar artículos IEEE y justificar la arquitectura de particionado por filas frente a alternativas en bloque 2D (`docs/bibliografia.md`).                |    Sprint 2     |   **I8 (Roberto)**   |
|  **P1 (Alta)**   | **Implementación Núcleos Secuenciales**      | Programar el producto$i, k, j$ en `c_secuencial/src/matrix.c` y `go_secuencial/matrix.go`, integrando temporizadores de alta resolución.                   |    Sprint 3     |    I1, I2, I3, I4    |
|  **P1 (Alta)**   | **Implementación Generadores C y Go**        | Codificar la rutina de generación LCG idéntica en C (`input.c`) y Go (`input.go`) y comprobar igualdad de matrices generadas.                              |    Sprint 3     |        I6, I7        |
|  **P1 (Alta)**   | **Construcción de Comparador Automatizado**  | Desarrollar`scripts/compare_results.ps1` para validar salidas matriciales completas con doble tolerancia relativa/absoluta.                                |    Sprint 3     |          I5          |
|  **P1 (Alta)**   | **Implementación del Híbrido MPI + OpenMP**  | Programar`c_paralelo/src/main.c` y `matrix.c` con `MPI_Scatterv`, `MPI_Bcast`, `MPI_Gatherv` y directivas OpenMP multihilo.                                |    Sprint 4     |        I1, I2        |
|  **P1 (Alta)**   | **Implementación de Workers y Canales Go**   | Programar`go_paralelo/workers.go` distribuyendo bloques de filas a través de canales tipados con sincronización `sync.WaitGroup`.                          |    Sprint 4     |        I3, I4        |
|  **P2 (Media)**  | **Batería de Pruebas de Esquinas y Estrés**  | Probar$N < P$, matrices impares, $N=1$, límites de memoria RAM y comprobación de hilos con `go test -race` y MSVC.                                         |    Sprint 5     |       I1 a I8        |
|  **P2 (Media)**  | **Automatización y Medición Oficial**        | Automatizar`scripts/bench_windows.ps1` y `scripts/summarize_results.ps1` para captura y consolidación estadística de CSV.                                  |   Sprint 7–8    |       I1 a I8        |

---

## 5. Mapeo y Localización de la Literatura Científica del Curso

La lista inicial citaba `Articulos_IEEE_Proyectos_UNMSM_PConcurrenteyParalela.docx`; ese documento no está incluido en este clon y no se verificó aquí su contenido. Para S2 se contrastaron los dos PDF locales seleccionados y sus metadatos con fuentes de los autores, documentadas en [bibliografia.md](bibliografia.md).

Las referencias seleccionadas son Quintin et al. y Hérault et al. Las fuentes complementarias listadas abajo conservan su identificación inicial, pendiente de verificar; no se usan como evidencia en los dos resúmenes de S2.

### 5.1. Artículos IEEE del Proyecto 2 (Multiplicación de Matrices)

1. **Fuente complementaria pendiente de verificar:** Huang, H., & Chow, E. (2024), *Exploring the Design Space of Distributed Parallel Sparse Matrix–Multiple Vector Multiplication*. Identificación inicial: TPDS, 35(11), 1977–1988, DOI 10.1109/TPDS.2024.3458921. No se certifican esos metadatos ni sus hallazgos en esta actualización.
2. **Hérault, T., Robert, Y., Bosilca, G., & Dongarra, J. (2019).** *Generic Matrix Multiplication for Multi-GPU Accelerated Distributed-Memory Platforms over PaRSEC*, ScalA 2019, pp. 33–41. DOI: [10.1109/ScalA49573.2019.00010](https://doi.org/10.1109/ScalA49573.2019.00010). Estudia bloques, teselas y control de dependencias en plataformas multi-GPU; su adaptación a CPU/Go se distingue de los resultados del artículo en la bibliografía.
3. **Quintin, J.-N., Hasanov, K., & Lastovetsky, A. (2013).**
   _Hierarchical Parallel Matrix Multiplication on Large-Scale Distributed Memory Platforms._
   _Proc. 2013 42nd International Conference on Parallel Processing (ICPP)_, 754–762. DOI: [10.1109/ICPP.2013.89](https://doi.org/10.1109/ICPP.2013.89).
   _Aporte al proyecto:_ Introduce HSUMMA (variante jerárquica de dos niveles de SUMMA), proporcionando la base matemática para optimizar la comunicación colectiva cuando se escala el número de procesos.

### 5.2. Literatura complementaria Go · verificación pendiente

- **Dilley, N., & Lange, J. (2019).** Identificación inicial: *An Empirical Study of Messaging Passing Concurrency in Go Projects*, SANER, 377–387, DOI 10.1109/SANER.2019.8668036. Título, metadatos y hallazgos pendientes de verificar; no se usa para afirmar superioridad de un patrón Go.
- **Yuan, T., et al. (2021).**
  _GoBench: A Benchmark Suite of Real-World Go Concurrency Bugs._
  _Proc. 2021 IEEE/ACM International Symposium on Code Generation and Optimization (CGO)_. DOI: [10.1109/CGO51591.2021.9370317](https://doi.org/10.1109/CGO51591.2021.9370317).

### 5.3. Textos complementarios · edición y capítulos pendientes de verificar

- **Pacheco, P. (2021).** _An Introduction to Parallel Programming_ (2nd ed.). Morgan Kaufmann / Elsevier. (Capítulos 3 y 5: descomposición por bloques de filas con `MPI_Scatterv`/`MPI_Gatherv` y regiones paralelas OpenMP).
- **Cox-Buday, K. (2017).** _Concurrency in Go: Tools and Techniques for Developers_. O'Reilly Media.

> **Entregable de Sprint 2:** [bibliografia.md](bibliografia.md) resume los dos artículos seleccionados y distingue sus hallazgos del reparto 1D propio del proyecto. El reparto se justifica por el alcance y el almacenamiento contiguo; no se afirma su superioridad universal frente a 2D.

---

## 6. Criterio de Aceptación del Entregable

El contenido técnico de S1 queda conforme; la evaluación de la versión actual está registrada en el cierre:

- [x] Traduce los criterios académicos en exigencias técnicas medibles (tolerancias, timers, códigos de salida).
- [x] Formaliza la matriz completa de Requisitos Funcionales y No Funcionales.
- [x] Contiene un backlog priorizado (P0, P1, P2) basado en el estado real del repositorio.
- [x] Localiza los dos PDF seleccionados y corrige sus referencias; la relación con el documento de la cátedra no se certifica sin esa fuente.
- [x] Revisión de la versión anterior por I7 registrada en `docs/sprints/sprint-01.md`.
- [x] Evaluación asistida de las correcciones del 01/10/2026, en la voz de I7, registrada en el sprint.

Las evaluaciones de I7 a I8 y de I8 a I1 están en [S1](sprints/sprint-01.md); las correspondientes a interfaces y bibliografía están en [S2](sprints/sprint-02.md). Los cierres distinguen las horas declaradas de las distribuciones estimadas.
