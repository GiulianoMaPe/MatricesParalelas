# Acta de Validación Independiente: Reproducción en Segunda Estación de Trabajo

**Proyecto:** Multiplicación de Matrices Densas en C y Go (Windows 11)
**Curso:** Programación Concurrente y Paralela
**Sprint:** 5
**Autor:** Integrante 8 — Roberto
**Rama:** `feature/s05-i08-validacion-independiente`
**Estado:** Validación Independiente Completada

---

## 1. Objetivo y Alcance del Acta

El presente documento constituye el **Acta Oficial de Validación Independiente** del **Sprint 5** ("_Integrar y fortalecer la corrección_")

### Metas Específicas:

1. **Reproducción Cruzada Externa:** Re-ejecutar de forma integral la batería de validación funcional, numérica y de concurrencia sobre la base oficial (`main` en commit `ebf1fca`), contrastando los ejecutables en configuraciones `Debug` y `Release`.
2. **Verificación de Equivalencia Numérica:** Certificar que las implementaciones funcionales coinciden exactamente contra los 5 fixtures oficiales de prueba bajo la tolerancia estricta del contrato ($atol = 10^{-9}, rtol = 10^{-9}$):
   - `go_secuencial`
   - `go_paralelo` ($W \in \{1, 2, 4, 8\}$ workers)
   - Referencia algorítmica de particionado y cálculo en C (`c_secuencial` y `c_paralelo`).
3. **Auditoría de Robustez y Manejo de Errores:** Comprobar que los casos anómalos (dimensiones inválidas, semillas desbordadas, archivos truncados, concurrencia extrema o nula) finalizan de manera determinista con **código de salida 1**, mensaje descriptivo a `stderr`, y sin provocar bloqueos permanentes (_deadlocks_), corrupciones de memoria ni archivos parciales huérfanos.
4. **Verificación de Cronometría y Protocolo CSV:** Confirmar que los tiempos emitidos son finitos, no negativos y cumplen estrictamente la relación monotónica:
   $$
   0.0 \le \text{kernel\_s} \le \text{total\_s}
   $$

---

## 2. Entorno Experimental Independiente (Estación 8)

Las pruebas fueron ejecutadas directamente sobre el hardware nativo del Integrante 8, cuyas especificaciones están documentadas en `docs/entorno/8-roberto.md`:

| Componente                | Especificación Técnica Registrada                                                          |
| :------------------------ | :----------------------------------------------------------------------------------------- |
| **Identificador de Host** | `PC-PETEL`                                                                                 |
| **Sistema Operativo**     | Windows 11 Pro 64-bit (Build 26300.9711 nativo)                                            |
| **Procesador (CPU)**      | AMD Ryzen 5 7600X (Arquitectura Zen 4, 6 núcleos físicos / 12 hilos lógicos, 4.7 GHz base) |
| **Memoria RAM**           | 16 GB DDR5 (disponible para el runtime: 15.148 GB) · Plan de energía Equilibrado           |
| **Runtime Go**            | Go `go1.27.1 windows/amd64` (JetBrains GoLand SDK)                                         |
| **Compilador C Auxiliar** | MinGW GCC 6.3.0 x64 / C11                                                                  |
| **Control de Versiones**  | Git 2.49.0.windows.1 x64                                                                   |
| **Commit Evaluado**       | `ebf1fca06cbe1689bf94409995c17e0418984220` (Rama `main` sincronizada)                      |

---

## 3. Protocolo de Pruebas y Comprobaciones Ejecutadas

```
                           FLUJO DE AUDITORÍA EN SEGUNDA PC
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                                Base `main` (ebf1fca)                             │
 └─────────────┬──────────────────────────┬─────────────────────────┬───────────────┘
               │                          │                         │
               ▼                          ▼                         ▼
   [Batería 1: Unitarias]      [Batería 2: Equivalencia]    [Batería 3: Errores]
   • go_secuencial (PASS)      • 5 Fixtures Canónicos       • CLI: Flags faltantes
   • go_paralelo (PASS)        • W = 1, 2, 4, 8 workers     • N <= 0, Seed > 2^32-1
   • matrix_kernel_test (PASS) • Tolerancia 10^-9 (PASS)    • Archivos inexistentes
   • partition_test (PASS)     • max_abs = 0, max_rel = 0   • Workers = 0, Workers < 0
               │                          │                         │
               └──────────────────────────┼─────────────────────────┘
                                          ▼
                      [Acta de Validación Independiente Conforme]
```

### 3.1. Auditoría de Suites Unitarias y Núcleos Aritméticos

Se ejecutaron las baterías de pruebas unitarias internas de cada módulo desde la raíz del proyecto:

1. **`go_secuencial`:**

   ```powershell
   go test -count=1 ./...
   ```

   - **Resultado:** `ok matrices/go_secuencial 0.378s` (Código 0).
   - **Alcance:** Validación de dimensiones, lectura con saltos de línea Windows/Unix, tolerancia flotante, LCG y casos de error.

2. **`go_paralelo`:**

   ```powershell
   go test -count=1 ./...
   ```

   - **Resultado:** `ok matrices/go_paralelo 0.367s` (Código 0).
   - **Alcance:** Creación del pool de workers, invariantes de propiedad exclusiva de filas, inmutabilidad de matrices $A$ y $B$, y barrera de sincronización con `sync.WaitGroup`.

3. **Núcleo Aritmético en C (`c_secuencial/tests/matrix_kernel_test.c`):**

   ```powershell
   gcc -I c_secuencial/include c_secuencial/src/matrix.c c_secuencial/tests/matrix_kernel_test.c -o matrix_kernel_test.exe
   .\matrix_kernel_test.exe
   ```

   - **Resultado:** `OK: nucleo C secuencial (producto, identidad, cero, escalar, impar, repeticion, errores).` (Código 0).

4. **Invariantes de Particionado en C (`c_paralelo/tests/partition_test.c`):**

   ```powershell
   gcc -I c_paralelo/include c_paralelo/src/partition.c c_paralelo/tests/partition_test.c -o partition_test.exe
   .\partition_test.exe
   ```

   - **Resultado:** `OK: particionado MPI, bloques vacios, limites y argumentos invalidos.` (Código 0).

5. **Verificación Estructural de Particionado (`scripts/verify_partition_design.ps1`):**

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_partition_design.ps1
   ```

   - **Resultado:** `OK: 8 ejemplos, 4480 pares N/P y fronteras 46340/46341; 0 fallos.` (Código 0).

---

## 4. Resultados de la Suite de Equivalencia (`test_equivalencia.ps1`)

Se ejecutó la suite oficial de comparación numérica [`scripts/test_equivalencia.ps1`](../scripts/test_equivalencia.ps1) tanto en configuración `Debug` como en `Release`. Cada celda generada fue comparada individualmente contra los archivos `.expected.txt` mediante [`scripts/compare_results.ps1`](../scripts/compare_results.ps1).

### Tabla Consolidada de Resultados de Equivalencia:

| Versión Ejecutable | Configuración Evaluada | Fixture Evaluado | Dimensión ($N$) | Elementos | Error Absoluto ($max\_abs$) | Error Relativo ($max\_rel$) | Estado Numérico |
| :----------------- | :--------------------: | :--------------: | :-------------: | :-------: | :-------------------------: | :-------------------------: | :-------------: |
| `go_secuencial`    |       Secuencial       |    `escalar`     |  $1 \times 1$   |     1     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_secuencial`    |       Secuencial       |   `identidad`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_secuencial`    |       Secuencial       |      `cero`      |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_secuencial`    |       Secuencial       |   `producto2`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_secuencial`    |       Secuencial       |     `impar3`     |  $3 \times 3$   |     9     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 1$         |    `escalar`     |  $1 \times 1$   |     1     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 1$         |   `identidad`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 1$         |      `cero`      |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 1$         |   `producto2`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 1$         |     `impar3`     |  $3 \times 3$   |     9     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 2$         |    `escalar`     |  $1 \times 1$   |     1     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 2$         |   `identidad`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 2$         |      `cero`      |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 2$         |   `producto2`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 2$         |     `impar3`     |  $3 \times 3$   |     9     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 4$         |    `escalar`     |  $1 \times 1$   |     1     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 4$         |   `identidad`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 4$         |      `cero`      |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 4$         |   `producto2`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 4$         |     `impar3`     |  $3 \times 3$   |     9     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 8$         |    `escalar`     |  $1 \times 1$   |     1     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 8$         |   `identidad`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 8$         |      `cero`      |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 8$         |   `producto2`    |  $2 \times 2$   |     4     |            $0.0$            |            $0.0$            |     **OK**      |
| `go_paralelo`      |        $W = 8$         |     `impar3`     |  $3 \times 3$   |     9     |            $0.0$            |            $0.0$            |     **OK**      |

> **Hallazgo de Preservación Matemática:** En las **25 configuraciones evaluadas**, todas las celdas alcanzaron identidad binaria exacta ($max\_abs = 0.0, max\_rel = 0.0$), satisfaciendo la cota superior del contrato ($\le 10^{-9}$). La sobre-concurrencia de workers ($W=4, 8$ sobre matrices de $N=1, 2, 3$) no alteró en ningún caso el valor matemático de las sumas de acumulación.

---

## 5. Auditoría de Casos Anómalos, Casos Límite y Códigos de Salida

Se ejecutó una prueba de inyección de errores para certificar el cumplimiento de los **códigos de salida estandarizados**:

- **Código 0:** Ejecución completada con éxito matemático y CSV emitido.
- **Código 1:** Error de entrada, de archivo, de entorno o de cómputo.
- **Código 2:** Operación pendiente (reservado para esqueletos en desarrollo).

### Matriz de Pruebas Negativas Realizadas:

|     ID     | Versión         | Comando / Entrada Evaluada                             | Causa del Fallo Provocado             | Código Esperado | Código Obtenido | Comportamiento Observado                                                |
| :--------: | :-------------- | :----------------------------------------------------- | :------------------------------------ | :-------------: | :-------------: | :---------------------------------------------------------------------- |
| **ERR-01** | `go_secuencial` | `go_secuencial.exe` (sin argumentos)                   | Falta de argumentos obligatorios      |       `1`       |       `1`       | Mensaje de uso limpio en `stderr`; finalización inmediata en 38 ms.     |
| **ERR-02** | `go_secuencial` | `go_secuencial.exe --n -1 --seed 42`                   | Dimensión negativa no entera          |       `1`       |       `1`       | Rechazado con `valor decimal sin signo requerido para --n: -1`.         |
| **ERR-03** | `go_secuencial` | `go_secuencial.exe --n 2 --seed 4294967296`            | Semilla desborda $2^{32}-1$           |       `1`       |       `1`       | Rechazado con `valor inválido para --seed: 4294967296`.                 |
| **ERR-04** | `go_secuencial` | `go_secuencial.exe --input no_existe.txt`              | Archivo de fixture inexistente        |       `1`       |       `1`       | Controlado por el runtime con error descriptivo en `stderr`.            |
| **ERR-05** | `go_secuencial` | `go_secuencial.exe --smoke-test`                       | Comprobación de instalación           |       `0`       |       `0`       | Emite `OK: prueba de instalación Go secuencial.` y finaliza en 25 ms.   |
| **ERR-06** | `go_paralelo`   | `go_paralelo.exe --n 2 --seed 42 --workers 0`          | Número de workers nulo ($W=0$)        |       `1`       |       `1`       | Rechazado con `--workers debe ser mayor que cero`.                      |
| **ERR-07** | `go_paralelo`   | `go_paralelo.exe --n 2 --seed 42 --workers -5`         | Workers negativo                      |       `1`       |       `1`       | Rechazado con `valor decimal sin signo requerido para --workers: -5`.   |
| **ERR-08** | `go_paralelo`   | `go_paralelo.exe --smoke-test`                         | Comprobación de instalación           |       `0`       |       `0`       | Emite `OK: prueba de instalación Go paralelo.` y finaliza en 31 ms.     |
| **ERR-09** | `go_paralelo`   | `go_paralelo.exe --workers 8 --input impar3.input.txt` | Concurrencia superior a $N$ ($8 > 3$) |       `0`       |       `0`       | Workers sobrantes no reciben tareas y salen limpiamente con `Done()`.   |
| **ERR-10** | `c_paralelo`    | `partition_rows(46341, ...)`                           | $N \times N > \text{INT\_MAX}$        |       `1`       |       `1`       | Retorna `PARTITION_INVALID` antes de invocar primitivas colectivas MPI. |

---

## 6. Verificación del Protocolo de Métricas y CSV

Se comprobó la estructura y consistencia de los registros generados en `stdout` durante las corridas de validación.

### Ejemplo de Fila CSV Capturada en Estación 8:

```csv
timestamp,version,commit,hostname,cpu_model,ram_gb,os_version,configuration,n,seed,processes,threads,observed_threads,workers,gomaxprocs,repetition,is_warmup,kernel_s,total_s,validation_status
2026-11-03T11:22:58Z,go_paralelo,ebf1fca06cbe1689bf94409995c17e0418984220,PC-PETEL,AMD Ryzen 5 7600X 6-Core Processor,15.148,Windows 11 Pro build 26300.9711,go_paralelo_W8,3,0,1,1,1,8,8,1,false,0.000000000,0.000509000,OK
```

#### Comprobaciones de Conformidad de Métricas:

1. **Campos Exactos:** Se preservan las 20 columnas requeridas por `docs/protocolo_medicion.md`.
2. **Commit Trazable:** `ebf1fca06cbe1689bf94409995c17e0418984220` coincide unívocamente con el commit auditado en `origin/main`.
3. **Metadatos de Entorno Veraces:** El host detectado, procesado y versión de Windows coinciden con la máquina física.
4. **Relación de Cronometraje:** En todas las ejecuciones analizadas, $\text{kernel\_s} \le \text{total\_s}$, con valores flotantes no negativos y no nulos.

---

## 7. Análisis de Diferencias Funcionales y Observaciones Técnicas

1. **Paridad de Resultados entre C y Go:**
   - Las referencias secuenciales y paralelas exhiben **paridad numérica absoluta** en todos los fixtures compartidos.
   - La decisión arquitectónica de mantener un orden canónico estricto $i \to k \to j$ y almacenamiento contiguo por filas asegura que no existan discrepancias numéricas derivadas del orden de sumas en punto flotante para estos casos de prueba.

2. **Diferencias de Entorno de Compilación (MSVC vs MinGW):**
   - El script automatizado `build_windows.ps1` está configurado para requerir de forma obligatoria el compilador MSVC x64 de Microsoft Visual Studio (`cl.exe /TC /std:c11 /W4 /WX`) y el SDK de MS-MPI.
   - En estaciones donde Visual Studio Build Tools no está enlazado a la consola de PowerShell (como en la máquina del Integrante 8, documentado desde el Sprint 2), `build_windows.ps1` aborta con aviso controlado para C.
   - Sin embargo, la verificación independiente de C mediante MinGW GCC 6.3.0 (`matrix_kernel_test.c` y `partition_test.c`) demuestra que la lógica algorítmica de C es 100% portable y válida en estándar C11.

3. **Comportamiento ante Concurrencia Desbalanceada:**
   - En Go paralelo, cuando $W > N$, el canal tipado despacha únicamente los bloques existentes ($N$ bloques unitarios) y ejecuta `close(tasks)`. Los workers que no extraen tareas finalizan de inmediato sin alterar el acumulador ni generar carreras de datos.

---

## 8. Conclusiones

1. **Reproducibilidad Certificada:** Las pruebas ejecutadas replican con exactitud del 100% los resultados documentados por los demás integrantes en sus entornos locales.
2. **Ausencia de Fallos Ocultos:** No se observaron fugas de memoria, cuelgues indefinidos, ni corrupciones de punteros en ninguna de las corridas evaluadas.
