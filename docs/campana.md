# Acta de Congelación Experimental y Definición de Parámetros de Campaña

**Sprint: 7** Automatizar los experimento

---

## 1. Objeto y Alcance del Acta

El propósito de la presente acta es formalizar la **congelación experimental del código** y la **definición exhaustiva de los parámetros de medición** que regirán la campaña oficial de recolección de datos del **Sprint 8**. Asimismo, se documenta la **reproducción empírica del piloto automatizado** ejecutado sobre el hardware de evaluación del integrante 8, validando la integridad del arnés central `scripts/bench_windows.ps1` y su compatibilidad con el esquema canónico CSV de 20 columnas.

Con este documento se garantiza que:

1. No se introducirán alteraciones algorítmicas, estructurales ni sintácticas en los núcleos de cómputo durante la fase de medición masiva.
2. La totalidad de las ejecuciones experimentales respetará un espacio de parámetros uniforme, exhaustivo y libre de asimetrías metodológicas.
3. El arnés automatizado detecta fallos, preserva los 20 campos del protocolo y respeta el aislamiento cronométrico.

---

## 2. Versión Candidata y Congelamiento de Código

De conformidad con los dictámenes de arquitectura ([`docs/arquitectura.md`](arquitectura.md)) y evaluación de optimizaciones ([`docs/optimizaciones.md`](optimizaciones.md)) aprobados en el Sprint 6:

### 2.1. Identificación del Commit Base

- **Commit Oficial de Congelación:** `aba95790f0b9eb793a014ec6b69c09cd2ff6b249` (HEAD consolidado de `main` integrando los medidores de Sprint 7).
- **Regla de Inmutabilidad del Núcleo:** Queda estrictamente vedado realizar modificaciones sobre:
  - El orden de bucles canónico $i \to k \to j$.
  - La estructura contigua _row-major_ plana de una sola dimensión (`N * N`).
  - Los métodos de acumulación: `matrix_accumulate` y `matrix_accumulate_rows` en C; `multiplyKernel` y `multiplyBlock` en Go.
  - La semántica de reparto de carga 1D por bloques contiguos de filas en OpenMP, MPI y Go.

### 2.2. Política de Compilación de Binarios

Toda medición oficial debe ejecutarse obligatoriamente sobre binarios compilados en configuración **`Release`** con optimizaciones del compilador habilitadas:

- **C (`c_secuencial` y `c_paralelo`):** Compilación MSVC 64-bit con directivas `/std:c11 /O2 /fp:precise /MD`, añadiendo `/openmp` para la versión híbrida y enlace con `msmpi.lib`. Se prohíbe el uso de opciones no portables como `/GL` (Whole Program Optimization), `/fp:fast` o intrínsecos AVX manuales asimétricos.
- **Go (`go_secuencial` y `go_paralelo`):** Compilación mediante `go build` en Go 1.27.x para `windows/amd64` con optimizaciones predeterminadas (`-gcflags` estándar, sin banderas de depuración ni instrumentación de profiling).

---

## 3. Matriz Oficial de Parámetros Aceptados para Medir

Para asegurar la validez estadística y la comparabilidad entre todas las referencias, se fija la siguiente matriz de parámetros para la campaña experimental:

```
                    MATRIZ EXPERIMENTAL OFICIAL (SPRINT 8)
 ┌────────────────────────────────────────────────────────────────────────┐
 │ Dimensiones (N)        : 512, 1024, 2048 (Piloto: 256, 512, 1024)      │
 │ Semilla canónica       : 42 (fija para todas las corridas)             │
 │ Calentamiento (Warmup) : 1 corrida (repetition=0, is_warmup=true)      │
 │ Repeticiones medidas   : 5 corridas (repetition=1..5, is_warmup=false) │
 │ Configuración binaria  : Release (estricta)                            │
 │ Protocolo de salida    : Esquema CSV unificado de 20 columnas (stdout) │
 └────────────────────────────────────────────────────────────────────────┘
```

### 3.1. Dimensiones de Matriz ($N$)

- **Piloto de Validación / Calibración:** $N \in \{256, 512, 1024\}$.
- **Campaña Oficial de Rendimiento (Sprint 8):** $N \in \{512, 1024, 2048\}$.
  - $N=512$: Carga moderada (~$2 \text{ MB}$ por matriz). Las tres matrices caben en la caché L3 combinada del procesador.
  - $N=1024$: Carga media (~$8 \text{ MB}$ por matriz). Supera la caché L2 individual, generando tráfico sistemático a L3 y DRAM.
  - $N=2048$: Carga masiva (~$32 \text{ MB}$ por matriz; ~$96 \text{ MB}$ el conjunto $A, B, C$). Desborda holgadamente la memoria caché L3, evaluando el ancho de banda del controlador de memoria DRAM.
- **Límite Seguro de Estrés ($N=4096$):** Conforme al análisis de capacidad en `docs/memoria.md`, $N=4096$ requiere ~$128 \text{ MB}$ por matriz en secuencial y $\le 1.5 \text{ GB}$ en el proceso raíz MPI. Se reserva como punto exploratorio condicional, sujeto a estabilidad de RAM física.

### 3.2. Semilla Pseudoaleatoria Canónica

- Se estipula el valor **`--seed 42`** para la totalidad de las mediciones de la campaña.
- La implementación idéntica del generador congruencial lineal (LCG) en C y Go garantiza la igualdad bit a bit de los operandos $A$ y $B$, descartando cualquier variabilidad debida a valores numéricos o condicionamiento de matrices.

### 3.3. Protocolo de Calentamiento y Repeticiones

- **1 Calentamiento (`is_warmup=true`, `repetition=0`):** Permite inicializar páginas de memoria en el sistema operativo (_page faults_ iniciales), calentar las líneas de caché y estabilizar el planificador de Go/OpenMP. Se registra en el CSV pero se descarta en el cálculo de medianas y speedups.
- **5 Repeticiones Medidas (`is_warmup=false`, `repetition=1..5`):** Proporcionan la muestra estadística requerida para el cálculo de mediana, desviación estándar y rango intercuartílico conforme a `scripts/summarize_results.ps1`.

### 3.4. Grados de Concurrencia y Paralelismo por Versión

| Versión                        | Procesos ($P$) |    Hilos ($T$)    |     Workers ($W$)     | `GOMAXPROCS` | Propósito Experimental                                                       |
| :----------------------------- | :------------: | :---------------: | :-------------------: | :----------: | :--------------------------------------------------------------------------- |
| **`c_secuencial`**             |       1        |         1         |           1           |      -       | Línea base secuencial en lenguaje nativo C.                                  |
| **`go_secuencial`**            |       1        |         1         |           1           |      1       | Línea base secuencial en Go (`runtime.GOMAXPROCS(1)`).                       |
| **`go_paralelo`**              |       1        |         1         | 1, 2, 4, 6, 8, 12, 16 |    $= W$     | Escalabilidad con pool de goroutines y canales CSP.                          |
| **`c_paralelo` (OpenMP puro)** |       1        | 1, 2, 4, 6, 8, 12 |           -           |      -       | Escalabilidad de memoria compartida sin sobrecoste MPI.                      |
| **`c_paralelo` (MPI puro)**    |   1, 2, 4, 6   |         1         |           -           |      -       | Escalabilidad de memoria distribuida por paso de mensajes.                   |
| **`c_paralelo` (Híbrido)**     |      2, 4      |       2, 4        |           -           |      -       | Escalabilidad jerárquica multinivel ($P \times T \le \text{hilos lógicos}$). |

---

## 4. Reproducción del Piloto Automatizado en PC Candidata

En cumplimiento de las tareas del Integrante 8, se procedió a reproducir la ejecución automatizada del piloto mediante el script oficial `scripts/bench_windows.ps1` sobre la estación de trabajo física del integrante 8

### 4.1. Caracterización del Hardware de Medición

- **Procesador (CPU):** AMD Ryzen 5 7600X 6-Core Processor
  - Microarquitectura: Zen 4 (5 nm)
  - Núcleos / Hilos: 6 núcleos físicos, 12 subprocesos lógicos
  - Frecuencia base: 4.70 GHz · Frecuencia turbo: hasta 5.30 GHz
  - Jerarquía de caché: L1 384 KB (64 KB/core), L2 6 MB (1 MB/core), L3 32 MB compartida
- **Memoria RAM:** 16.0 GB DDR5 a 5200 MT/s (15.148 GB visible para el SO)
- **Sistema Operativo:** Microsoft Windows 11 Pro 64-bit (build 26300.9974)
- **Herramientas de Ejecución:** Windows PowerShell 5.1.26100.9974, Go 1.27.1 windows/amd64, MinGW GCC 6.3.0

### 4.2. Ejecución Automatizada: Caso Go Secuencial (`go_secuencial`)

- **Comando ejecutado:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version go_secuencial -N 256 -Repetitions 5
  ```
- **Resultado del lote:** 6 ejecuciones completadas (1 warmup + 5 repeticiones).
- **Observaciones recolectadas (CSV oficial de 20 columnas):**

```csv
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status
"2026-11-16T17:21:52Z","go_secuencial","aba95790f0b9eb793a014ec6b69c09cd2ff6b249","PC-PETEL","AMD Ryzen 5 7600X 6-Core Processor","15.148","Windows 11 Pro build 26300.9974","go_secuencial","256","42","1","1","1","1","1","0","true","0.008641000","0.008641000","OK"
"2026-11-16T17:21:52Z","go_secuencial","aba95790f0b9eb793a014ec6b69c09cd2ff6b249","PC-PETEL","AMD Ryzen 5 7600X 6-Core Processor","15.148","Windows 11 Pro build 26300.9974","go_secuencial","256","42","1","1","1","1","1","1","false","0.009545300","0.009545300","OK"
"2026-11-16T17:21:52Z","go_secuencial","aba95790f0b9eb793a014ec6b69c09cd2ff6b249","PC-PETEL","AMD Ryzen 5 7600X 6-Core Processor","15.148","Windows 11 Pro build 26300.9974","go_secuencial","256","42","1","1","1","1","1","2","false","0.009228800","0.009228800","OK"
"2026-11-16T17:21:52Z","go_secuencial","aba95790f0b9eb793a014ec6b69c09cd2ff6b249","PC-PETEL","AMD Ryzen 5 7600X 6-Core Processor","15.148","Windows 11 Pro build 26300.9974","go_secuencial","256","42","1","1","1","1","1","3","false","0.009264600","0.009264600","OK"
"2026-11-16T17:21:52Z","go_secuencial","aba95790f0b9eb793a014ec6b69c09cd2ff6b249","PC-PETEL","AMD Ryzen 5 7600X 6-Core Processor","15.148","Windows 11 Pro build 26300.9974","go_secuencial","256","42","1","1","1","1","1","4","false","0.009191000","0.009191000","OK"
"2026-11-16T17:21:52Z","go_secuencial","aba95790f0b9eb793a014ec6b69c09cd2ff6b249","PC-PETEL","AMD Ryzen 5 7600X 6-Core Processor","15.148","Windows 11 Pro build 26300.9974","go_secuencial","256","42","1","1","1","1","1","5","false","0.009218700","0.009218700","OK"
```

- **Análisis de estabilidad:**
  - Mediana de `kernel_s` medido: $0.0092288 \text{ s}$.
  - Dispersión relativa: $< 3.8\%$, demostrando una altísima estabilidad de cronometraje en Windows 11.
  - Correctitud numérica: `validation_status = OK` en el 100% de las repeticiones.

### 4.3. Ejecución Automatizada: Caso Go Paralelo (`go_paralelo`)

- **Comando ejecutado:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version go_paralelo -N 256 -Workers 2 -Repetitions 5
  ```
- **Resultado del lote:** 6 ejecuciones completadas (1 warmup + 5 repeticiones).
- **Observaciones recolectadas (CSV oficial de 20 columnas):**

```csv
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status
2026-11-16T17:22:12Z,go_paralelo,aba95790f0b9eb793a014ec6b69c09cd2ff6b249,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9974,go_paralelo_W2,256,42,1,1,1,2,2,0,true,0.005021400,0.005021400,OK
2026-11-16T17:22:12Z,go_paralelo,aba95790f0b9eb793a014ec6b69c09cd2ff6b249,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9974,go_paralelo_W2,256,42,1,1,1,2,2,1,false,0.006115000,0.006115000,OK
2026-11-16T17:22:12Z,go_paralelo,aba95790f0b9eb793a014ec6b69c09cd2ff6b249,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9974,go_paralelo_W2,256,42,1,1,1,2,2,2,false,0.005586000,0.005586000,OK
2026-11-16T17:22:12Z,go_paralelo,aba95790f0b9eb793a014ec6b69c09cd2ff6b249,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9974,go_paralelo_W2,256,42,1,1,1,2,2,3,false,0.006223200,0.006223200,OK
2026-11-16T17:22:12Z,go_paralelo,aba95790f0b9eb793a014ec6b69c09cd2ff6b249,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9974,go_paralelo_W2,256,42,1,1,1,2,2,4,false,0.005167100,0.005167100,OK
2026-11-16T17:22:12Z,go_paralelo,aba95790f0b9eb793a014ec6b69c09cd2ff6b249,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9974,go_paralelo_W2,256,42,1,1,1,2,2,5,false,0.005097700,0.005097700,OK
```

- **Análisis de speedup y escalabilidad:**
  - Mediana de `kernel_s` con $W=2$: $0.0055860 \text{ s}$.
  - Speedup empírico preliminar ($S_2 = T_{\text{sec}} / T_{W=2}$):
    $$
    S_2 = \frac{0.0092288}{0.0055860} \approx 1.65\times
    $$
  - Eficiencia paralela preliminar: $E_2 = 1.65 / 2 \approx 82.5\%$, plenamente coherente para un tamaño de matriz pequeño ($N=256$) donde la creación del pool de workers y la sincronización representan una fracción perceptible del tiempo.

---

## 5. Criterios de Validez Experimental y Rechazo de Mediciones

Para el desarrollo del Sprint 8, se estipulan los siguientes filtros automáticos de descarte y control de calidad:

1. **Invariante Temporal Monotónico:**
   - Se exige estrictamente:
     $$
     0.0 < \text{kernel}_s \le \text{total}_s
     $$
   - Cualquier corrida donde $\text{kernel}_s > \text{total}_s$ o donde cualquiera de los dos sea menor o igual a cero se considerará anomalía de temporizador y será descartada inmediatamente.
2. **Conformidad Estricta del Esquema CSV:**
   - La salida debe contener exactamente las 20 columnas canónicas con los nombres y tipos definidos en `docs/protocolo_medicion.md`. Filas con campos nulos o desplazados provocarán el aborto del lote (`FailFast`).
3. **Condiciones de Máquina y Aislamiento Térmico:**
   - **Carga de fondo:** El uso de CPU previo al inicio de una batería debe ser inferior al $5\%$.
   - **Alimentación:** Plan de energía de alto rendimiento con la estación conectada permanentemente a la red eléctrica; desactivar reposo y ahorro energético.
   - **Monitoreo Térmico:** Si el procesador entra en estrangulamiento térmico (_thermal throttling_, $> 95^\circ\text{C}$), la campaña debe pausarse automáticamente para permitir la disipación térmica.
4. **Verificación Numérica Categórica:**
   - El campo `validation_status` debe ser incondicionalmente `OK`. Registros con `FAIL`, `NaN` o discrepancias superiores a la tolerancia universal ($10^{-9}$) descalifican el experimento.

---

## 6. Dictamen de Aprobación y Visto Bueno

Habiendo comprobado que:

1. Las especificaciones algorítmicas se encuentran formalmente congeladas y alineadas con la literatura científica.
2. La versión candidata del código base (`aba9579`) ejecuta de forma reproducible, estable y determinista en la plataforma Windows 11.
3. El arnés de automatización `scripts/bench_windows.ps1` emite el formato estándar sin intervención manual y maneja correctamente el flujo de calentamiento y repeticiones.
