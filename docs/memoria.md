# Memoria y capacidad — Sprint 6

Actualización del 12/11/2026: se completó la aceptación Windows; las tablas
Windows y los límites entregados a S7 están al final. El modelo y los picos RSS
Linux siguientes se conservan separados como antecedentes.
Los datos concretos y el método están en [diagnóstico S6](../resultados/diagnostico/s06/).

## Modelo comprobado contra las reservas

Sea `S=8*N*N` bytes por matriz y `r_p=floor(N/P)+(p<N%P ? 1 : 0)`.

| Implementación/proceso | Buffers matriciales principales | Bytes |
| --- | --- | --- |
| C secuencial | A, B, C, referencia completa | 4S |
| Go secuencial | A, B, C, referencia completa | 4S |
| Go paralelo | A, B, C, referencia completa compartidas | 4S |
| MPI raíz | A/B/C/referencia completas y A/C locales separados | 4S + 16*r_0*N |
| MPI rank no raíz | B completa y A/C locales | S + 16*r_p*N |
| MPI conjunto en una PC | Raíz + demás ranks + todos los bloques A/C | (P+5)S |

Los ranks sin filas usan buffers mínimos de un double para A/C: añadir 16 bytes
por rank vacío al modelo ideal. Cada rank necesita también cuatro vectores int de
P elementos (aproximadamente 16P bytes por proceso y 16P² para el conjunto); Go prepara W slots `time.Duration` de
8 bytes, además de metadatos. No confundir el límite aritmético con RAM real.

El modelo excluye ejecutables, bibliotecas MPI/Go, stacks, canales, goroutines,
allocators, buffers de texto y temporales. `Multiply` y la CLI no tienen por qué
tener el mismo pico: la CLI conserva la referencia independiente al medir.

| N | Matriz S, MiB | 4S, MiB | MPI P=1, MiB | MPI P=2, MiB | MPI P=4, MiB | MPI P=8, MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 256 | 0.5 | 2 | 3 | 3.5 | 4.5 | 6.5 |
| 512 | 2 | 8 | 12 | 14 | 18 | 26 |
| 1024 | 8 | 32 | 48 | 56 | 72 | 104 |
| 2048 | 32 | 128 | 192 | 224 | 288 | 416 |
| 4096 | 128 | 512 | 768 | 896 | 1152 | 1664 |

`MiB=2^20` bytes. Incluso P=1 del híbrido conserva buffers locales además de
los globales; no debe contabilizarse como si fuera C secuencial.

## Método del diagnóstico Linux

`scripts/sprint06_lab.py` comprueba RAM disponible antes de empezar, identifica
núcleos físicos dentro de la afinidad disponible y ejecuta cada observación en
un proceso distinto. GNU time `%M` registra el pico RSS de cada proceso en KiB,
convertido a bytes en `peak_rss_bytes`. Se conservan la lectura original,
stdout/stderr y comando junto a cada observación.

El pico comprende preparación, referencia, cálculo, validación y los pequeños
diagnósticos de asignaciones Go, no únicamente el intervalo de cálculo. En Go
incluye el ejecutable de pruebas/runtime; C usa un harness aislado. No es memoria
privada comprometida, ni un pico Windows, ni una observación MPI distribuida.

Se informan mediana y máximo de los cinco picos medidos por configuración;
los calentamientos se conservan separados. No se obtiene un pico de todos los
procesos MPI sumando máximos individuales de otras corridas.

## Picos RSS observados en Linux

Origen **A**: [Go](../resultados/diagnostico/s06/20261112T033150Z_fedora/resumen.csv). Origen **B**: [C controlado](../resultados/diagnostico/s06/20261112T035217Z_fedora/resumen.csv).
Se muestran las bases y se mantienen separados los intentos; todos los picos
por variante están en sus respectivos resúmenes.

| Núcleo/proceso diagnóstico | Origen | N | W/T | Modelo 4S, MiB | RSS mediano, MiB | RSS máximo, MiB |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| c_secuencial | B | 256 | 1 | 2.0 | 3.86 | 4.05 |
| c_openmp_local | B | 256 | 4 | 2.0 | 4.12 | 4.53 |
| go_secuencial | A | 256 | 1 | 2.0 | 6.81 | 6.93 |
| go_paralelo | A | 256 | 4 | 2.0 | 6.81 | 6.94 |
| c_secuencial | B | 512 | 1 | 8.0 | 9.83 | 9.89 |
| c_openmp_local | B | 512 | 4 | 8.0 | 9.96 | 10.32 |
| go_secuencial | A | 512 | 1 | 8.0 | 12.93 | 13.06 |
| go_paralelo | A | 512 | 4 | 8.0 | 13.19 | 13.19 |
| c_secuencial | B | 1024 | 1 | 32.0 | 33.45 | 33.68 |
| c_openmp_local | B | 1024 | 4 | 32.0 | 33.96 | 34.15 |
| go_secuencial | A | 1024 | 1 | 32.0 | 36.81 | 37.06 |
| go_paralelo | A | 1024 | 4 | 32.0 | 36.94 | 37.06 |

RAM disponible inicial: **933.57 MiB en A** y **2765.14 MiB en B**, con 15.51 GiB visibles.
El escritorio estaba activo. N=1024 usa 32 MiB de buffers, por debajo del
filtro inicial del 50%. Esto admite cada lote local, sin habilitar N=2048/4096
ni una configuración MPI Windows. El harness OpenMP local tiene cuatro matrices
completas y no es la raíz MPI; no aplicar a esa fila el modelo (P+5)S.

## Límites de capacidad para preparar S7

- Comparar la estimación matricial con como máximo el 50% de la RAM disponible
  al inicio, no de la RAM instalada. El margen no garantiza evitar paginación.
- Confirmar el pico total del proceso y la carga del sistema antes de habilitar
  un tamaño de campaña. No ensayar agotamiento real para demostrar robustez.
- Respetar N<=4096 en C secuencial y counts/desplazamientos int de MPI; esos
  límites son independientes del criterio de RAM.
- En la PC Linux observada hay seis núcleos físicos y doce lógicos; se exploran
  W=1,2,4 y se excluye W=8. No se infiere la capacidad de la futura PC Windows.
- N=256,512,1024 son los tamaños diagnósticos/piloto. La campaña N=2048 y la
  extensión N=4096 requieren además un límite de duración contrastado.
- La preparación de la referencia i,j,k cuesta O(N^3) y ocurre fuera de los
  tiempos internos. Para reservar la máquina se debe usar tiempo de pared real.

## Requisito Windows original (resuelto en la sección de cierre)

Registrar herramienta, contador, unidades e intervalo de muestreo; medir
raíz y no raíces por PID/rank, máximo observado de la suma simultánea y picos
individuales. Separar working set de memoria privada comprometida. Conservar
RAM disponible, P/T/N, revisión, flags, hashes y los errores/timeout.

Solo después de estas comprobaciones se habilitan tamaños y P/T definitivos en
Windows. El [registro de optimización](optimizaciones.md) y el [acta S6](sprints/sprint-06.md)
recogen las decisiones; no se presenta el modelo anterior como memoria medida.

## Cierre Windows del 12/11/2026

Se completaron perfiles separados de los ensayos de rendimiento. Método:
`GetProcessMemoryInfo(PROCESS_MEMORY_COUNTERS_EX)`, bytes, intervalo solicitado
20 ms; cada archivo registra muestras y separación máxima real. Peak WS es el
contador del sistema por proceso, conservando el handle hasta después de salir.
Private Bytes es memoria comprometida privada: se informa su máximo muestreado,
no se llama a ese valor RSS ni pico exacto. La suma simultánea se calcula entre
procesos vivos en la misma muestra; no es la suma de máximos individuales.
El lanzador y los servicios MPI no se suman a la huella de ranks de la aplicación.

Revisión, RAM disponible inicial y hashes están en el
[manifiesto Windows](../resultados/piloto/s06_windows_20261112/environment.json).
Los originales por PID y rank están en
[perfiles](../resultados/piloto/s06_windows_20261112/memory/).
Cada fila es una corrida de capacidad, no una estimación de dispersión.
Picos individuales de raíz/resto = PeakWorkingSetSize; conjunto = máximo observado
de suma simultánea de WS; privados = máximo observado de suma simultánea Private Bytes.
Valores MiB (2^20 bytes); el modelo no incluye el runtime.

| Programa | N | P/T/W | Modelo conjunto | WS raíz/proceso | Mayor WS no raíz | WS conjunto simultáneo | Privados conjunto simultáneo |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| c_paralelo | 1024 | 1/1/1 | 48.00 | 56.18 | 0.00 | 48.11 | 49.83 |
| c_paralelo | 1024 | 1/2/2 | 48.00 | 56.19 | 0.00 | 56.14 | 49.91 |
| c_paralelo | 1024 | 1/4/4 | 48.00 | 56.25 | 0.00 | 48.18 | 49.99 |
| c_paralelo | 1024 | 2/1/2 | 56.00 | 48.27 | 24.23 | 68.33 | 59.61 |
| c_paralelo | 1024 | 2/2/4 | 56.00 | 48.29 | 24.25 | 64.33 | 59.72 |
| c_paralelo | 1024 | 4/1/4 | 72.00 | 44.28 | 20.26 | 96.56 | 79.22 |
| c_paralelo | 256 | 1/1/1 | 3.00 | 11.17 | 0.00 | 9.46 | 4.80 |
| c_paralelo | 256 | 1/2/2 | 3.00 | 11.20 | 0.00 | 9.41 | 4.81 |
| c_paralelo | 256 | 1/4/4 | 3.00 | 11.23 | 0.00 | 9.46 | 4.80 |
| c_paralelo | 256 | 2/1/2 | 3.50 | 10.76 | 9.52 | 17.59 | 7.11 |
| c_paralelo | 256 | 2/2/4 | 3.50 | 10.77 | 9.41 | 17.50 | 7.09 |
| c_paralelo | 256 | 4/1/4 | 4.50 | 10.52 | 9.28 | 37.27 | 11.66 |
| c_paralelo | 512 | 1/1/1 | 12.00 | 20.16 | 0.00 | 18.09 | 13.80 |
| c_paralelo | 512 | 1/2/2 | 12.00 | 20.22 | 0.00 | 18.14 | 13.86 |
| c_paralelo | 512 | 1/4/4 | 12.00 | 20.24 | 0.00 | 18.16 | 13.90 |
| c_paralelo | 512 | 2/1/2 | 14.00 | 18.26 | 12.24 | 28.29 | 17.52 |
| c_paralelo | 512 | 2/2/4 | 14.00 | 18.28 | 12.27 | 28.34 | 17.67 |
| c_paralelo | 512 | 4/1/4 | 18.00 | 17.31 | 11.27 | 50.88 | 25.18 |
| c_secuencial | 1024 | 1/1/1 | 32.00 | 36.48 | 0.00 | 36.47 | 32.88 |
| c_secuencial | 256 | 1/1/1 | 2.00 | 6.49 | 0.00 | 6.31 | 2.84 |
| c_secuencial | 512 | 1/1/1 | 8.00 | 12.48 | 0.00 | 12.46 | 8.84 |
| go_paralelo | 1024 | 1/1/1 | 32.00 | 39.44 | 0.00 | 39.24 | 44.32 |
| go_paralelo | 1024 | 1/1/2 | 32.00 | 39.64 | 0.00 | 39.43 | 44.51 |
| go_paralelo | 1024 | 1/1/4 | 32.00 | 39.79 | 0.00 | 39.59 | 44.90 |
| go_paralelo | 256 | 1/1/1 | 2.00 | 8.25 | 0.00 | 8.03 | 13.51 |
| go_paralelo | 256 | 1/1/2 | 2.00 | 8.48 | 0.00 | 7.71 | 13.45 |
| go_paralelo | 256 | 1/1/4 | 2.00 | 8.54 | 0.00 | 8.54 | 14.04 |
| go_paralelo | 512 | 1/1/1 | 8.00 | 15.02 | 0.00 | 14.83 | 19.92 |
| go_paralelo | 512 | 1/1/2 | 8.00 | 15.23 | 0.00 | 15.04 | 20.11 |
| go_paralelo | 512 | 1/1/4 | 8.00 | 15.16 | 0.00 | 14.95 | 20.83 |
| go_secuencial | 1024 | 1/1/1 | 32.00 | 39.38 | 0.00 | 39.19 | 44.29 |
| go_secuencial | 256 | 1/1/1 | 2.00 | 8.28 | 0.00 | 7.56 | 13.02 |
| go_secuencial | 512 | 1/1/1 | 8.00 | 14.95 | 0.00 | 14.76 | 19.89 |

El modelo individual se contrasta con `4S+16*r0*N` en raíz y `S+16*rp*N`
en los demás ranks; las filas exactas y bytes por proceso están en los JSON.
Las muestras incluyen generación, referencia, cálculo y validación; los picos
pequeños pueden subestimarse por muestreo y no prueban ausencia de paginación.
El máximo de WS y privados simultáneos puede corresponder a instantes distintos.

### Capacidad entregada a S7

- N=256,512,1024: viables en memoria y duración en los casos medidos; P/T
  1/1,1/2,2/1,1/4,2/2,4/1 y Go W=1,2,4. El límite se compara con la RAM
  disponible inicial, sin habilitar W=8 por superar seis núcleos físicos.
- N=2048: candidato condicionado al piloto S7. Modelo máximo P=4: 288 MiB,
  bajo el filtro inicial del 50%; la referencia O(N^3) exige contrastar la
  duración antes de fijar timeout/campaña. No se afirma que este tamaño se midió aquí.
- N=4096: no habilitado para campaña por duración; máximo matricial P=4 de
  1152 MiB cabe en el filtro inicial de esta sesión, pero extrapolar memoria
  no acredita el tiempo real ni su estabilidad. No se ejecutó por obligación.
- Mantener N<=4096 en C secuencial y límites int/counts de MPI. Consultar RAM
  disponible de nuevo antes de cada piloto; 50% es un filtro, no una garantía.

No se confunde esta capacidad candidata con la campaña congelada de S7.

La suma de working sets por rank puede contar páginas compartidas de DLL varias
veces: no equivale a RAM física única consumida por el conjunto. Los máximos
individuales son los máximos observados del contador del sistema; una salida
entre muestras puede limitar la última lectura. Private Bytes se informa aparte.
