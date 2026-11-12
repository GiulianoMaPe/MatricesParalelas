# Memoria y capacidad — Sprint 6

Revisión del 11/11/2026. Se separan el modelo del código actual, el pico RSS
diagnóstico medido en Linux y la capacidad aún pendiente de comprobar en Windows.
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

## Comprobación Windows que permanece pendiente

Registrar herramienta, contador, unidades e intervalo de muestreo; medir
raíz y no raíces por PID/rank, máximo observado de la suma simultánea y picos
individuales. Separar working set de memoria privada comprometida. Conservar
RAM disponible, P/T/N, revisión, flags, hashes y los errores/timeout.

Solo después de estas comprobaciones se habilitan tamaños y P/T definitivos en
Windows. El [registro de optimización](optimizaciones.md) y el [acta S6](sprints/sprint-06.md)
recogen las decisiones; no se presenta el modelo anterior como memoria medida.
