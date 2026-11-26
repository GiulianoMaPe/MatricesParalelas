# Go paralelo · Análisis de rendimiento del Sprint 9

**Responsable:** Eva Moreno (Integrante 4)
**Tabla reproducible:** [`resultados/resumen/s09_i04_go_paralelo/analisis_go_paralelo.csv`](../resultados/resumen/s09_i04_go_paralelo/analisis_go_paralelo.csv), generada por [`scripts/analisis_go_paralelo.ps1`](../scripts/analisis_go_paralelo.ps1)

## Resumen

- **El pool de goroutines escala casi linealmente frente a su propia versión con un worker.** Frente a W=1, el speedup es de 1,94–1,98 con W=2 y de 3,55–3,85 con W=4, con eficiencias de 0,89 a 0,99 (C1).
- **El speedup frente a `go_secuencial` es menor:** 1,32–1,38 con W=2 y 2,39–2,60 con W=4. Con W=1, Go paralelo es más lento que el secuencial (0,67–0,71) (C2).
- **La causa de esa brecha está dentro del kernel, no en la sincronización.** Con W=1, `kernel_s` es 1,41–1,49 veces mayor que en `go_secuencial`, aunque los dos ejecutan el mismo bucle `i,k,j`. El kernel paralelo recibe las matrices por puntero, y el compilador recarga las cabeceras de los slices en cada iteración del bucle interno. Un diagnóstico de laboratorio reproduce el factor (C3).
- **La coordinación (canal, goroutines, `WaitGroup`) no es medible con el reloj de la campaña.** `total_s − kernel_s` es igual en Go paralelo y en Go secuencial, y sus valores son múltiplos del paso de ~0,5 ms de `time.Now()` (C4).
- **Con W=4, cada worker trabaja entre un 4 % y un 17 % más lento que en solitario.** Es la principal pérdida de eficiencia interna; los datos no permiten atribuirla a una causa concreta (C5).
- **Los resultados se reproducen en dos campañas oficiales independientes.** Las medianas cambian como máximo un 1,7 % en Go secuencial y en W=1, y hasta un 9,1 % en W=2/W=4 (C6).

## Condiciones y datos

| Campo | Valor |
| --- | --- |
| Campaña principal | [`s08_oficial_integrada_03`](../resultados/raw/s08_oficial_integrada_03/mediciones.csv), la misma que usan el resumen común de I7 y el análisis de Go secuencial |
| Campaña de reproducción | [`s08_i04_go_paralelo_01`](../resultados/raw/s08_i04_go_paralelo_01/mediciones.csv), fuente de [`go_paralelo.csv`](../resultados/raw/go_paralelo.csv) |
| PC | `PCG1UL14N0`: AMD Ryzen 5 3600 (6 núcleos físicos, 12 lógicos), 15,9 GiB, Windows 11 Pro build 26300, AC y plan Equilibrado |
| Código | Candidata congelada `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, Release, Go 1.27.4 windows/amd64 |
| Diseño | N=512/1024/2048, semilla 42, W=1/2/4 con `GOMAXPROCS=W` (W=8 excluido por tener 6 núcleos físicos), 1 calentamiento y 5 medidas por grupo |
| Referencia | `go_secuencial` de la **misma campaña**, con `GOMAXPROCS=1`; nunca se cruzan archivos |
| Estadística | Mediana de cinco medidas, Q1=x2 y Q3=x4 (definición de `summarize_results.ps1`); speedup = cociente de medianas de `total_s` |

En las dos campañas, todos los grupos tienen cinco medidas válidas. La [auditoría de dispersión de I7](../resultados/resumen/s08_oficial_integrada_03/auditoria_dispersion.md) dictaminó `CONSERVAR_CONFORME` para los 12 grupos Go de la campaña integrada, y el [manifiesto de I4](../resultados/raw/go_paralelo.manifest.json) verificó que los workers efectivos coinciden con los pedidos. Las medianas, Q1, Q3, `kernel_s` y speedups de la tabla reproducible coinciden exactamente con el [resumen de I7](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv).

## Speedup según workers y dimensión

Campaña `s08_oficial_integrada_03`. *S(seq)* es el speedup frente a `go_secuencial`; *S(W1)* y *E(W1)* son el speedup y la eficiencia frente a `go_paralelo` con W=1.

| N | Versión | Mediana `total_s` (s) | Mín.–máx. (s) | IQR/mediana | S(seq) | S(W1) | E(W1) | GFLOPS |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 512 | go_secuencial | 0,090451 | 0,089682–0,090862 | 0,5 % | 1,000 | | | 2,968 |
| 512 | W=1 | 0,134006 | 0,133991–0,137307 | 0,3 % | 0,675 | 1,000 | 1,000 | 2,003 |
| 512 | W=2 | 0,067705 | 0,067399–0,067826 | 0,5 % | 1,336 | 1,979 | 0,990 | 3,965 |
| 512 | W=4 | 0,034783 | 0,034197–0,036881 | 2,2 % | 2,600 | 3,853 | 0,963 | 7,717 |
| 1024 | go_secuencial | 0,726238 | 0,712951–0,759172 | 1,8 % | 1,000 | | | 2,957 |
| 1024 | W=1 | 1,081840 | 1,046014–1,097980 | 2,4 % | 0,671 | 1,000 | 1,000 | 1,985 |
| 1024 | W=2 | 0,552446 | 0,540463–0,631675 | 9,5 % | 1,315 | 1,958 | 0,979 | 3,887 |
| 1024 | W=4 | 0,303688 | 0,290614–0,320877 | 5,3 % | 2,391 | 3,562 | 0,891 | 7,071 |
| 2048 | go_secuencial | 6,296919 | 6,167931–6,460557 | 0,7 % | 1,000 | | | 2,728 |
| 2048 | W=1 | 8,861957 | 8,702274–9,025311 | 2,2 % | 0,711 | 1,000 | 1,000 | 1,939 |
| 2048 | W=2 | 4,566879 | 4,542206–4,634124 | 0,9 % | 1,379 | 1,940 | 0,970 | 3,762 |
| 2048 | W=4 | 2,497084 | 2,432433–2,584070 | 5,0 % | 2,522 | 3,549 | 0,887 | 6,880 |

- **C1 · Escalabilidad del pool.** Duplicar W casi duplica el rendimiento: S(W1) es 1,94–1,98 con W=2 en los tres tamaños. Con W=4, la eficiencia baja de 0,963 (N=512) a 0,891 (N=1024) y 0,887 (N=2048). *Fuente:* columnas `speedup_w1` y `efficiency_w1`, campaña integrada.
- **C2 · Speedup frente al secuencial.** Con W=4, Go paralelo es 2,39–2,60 veces más rápido que Go secuencial; con W=2, 1,32–1,38 veces; con W=1, más lento (0,67–0,71). El techo práctico es S(seq) ≈ S(W1) / 1,45, por lo que se explica en C3. *Fuente:* `speedup_seq`, campaña integrada.
- **Efecto de la dimensión.** S(seq) no crece con N: con W=4 da 2,60, 2,39 y 2,52. A diferencia del híbrido C, Go no reparte ni recoge datos entre procesos, de modo que no hay un coste de comunicación que se amortice al crecer N. El coste fuera del kernel es el mismo que en el secuencial (C4).

## Granularidad

El reparto es el canónico de S4, conservado en S6 ([comparativa de granularidad](granularidad_go.md)):
- Cada tarea es un bloque contiguo de `ceil(N/W)` filas. Con N=512/1024/2048 y W=1/2/4 la división es exacta, así que los bloques tienen entre 128 y 2048 filas, todos del mismo tamaño.
- Se crean exactamente W tareas por corrida, nunca una por celda ni por fila. Cada fila de C tiene un único escritor y no hay mutex por celda.
- El canal tiene capacidad W: el productor envía todos los bloques sin bloquearse y cierra el canal una vez. El reparto es estático en la práctica, igual que `Scatterv` y `schedule(static)` en C paralelo, lo que mantiene la comparación equitativa.

En esta configuración la granularidad implica W envíos y W recepciones por corrida. La comparativa de S6, medida en otra PC y con carácter exploratorio, estimó 0,15–0,25 µs por tarea en el canal y menos de 10 µs de coordinación fija por corrida. Con W ≤ 4 eso suma unos 11 µs, alrededor de 3000 veces menos que la menor mediana de esta campaña (34,8 ms). La misma comparativa observó que bloques más finos reducían `total_s` entre un 4 y un 12 % con W=4 y W=8 en esa PC, por balance dinámico. No se aplicó, por equidad con el reparto estático de C y por el congelamiento algorítmico. Sus filas de tiempo mezclan relojes y se conservan solo como exploración ([cierre S6](cierre_s06_windows.md)).

## Sincronización y sobrecostes

### C3 · Sobrecoste del kernel por la firma con punteros

| N | `kernel_s` go_secuencial (s) | `kernel_s` W=1 (s) | W=1 / secuencial (integrada) | W=1 / secuencial (reproducción) |
| ---: | ---: | ---: | ---: | ---: |
| 512 | 0,090294 | 0,133892 | 1,483 | 1,472 |
| 1024 | 0,725234 | 1,080834 | 1,490 | 1,469 |
| 2048 | 6,292360 | 8,857431 | 1,408 | 1,421 |

Con W=1 y `GOMAXPROCS=1`, los dos programas ejecutan el mismo bucle `i,k,j` con el mismo número de operaciones. El tiempo fuera del kernel es el mismo (C4), así que la diferencia está dentro de `kernel_s`.

Los cuerpos de [`multiplyKernel`](../go_secuencial/matrix.go) y [`multiplyBlock`](../go_paralelo/workers.go) son idénticos; solo cambia la firma. El secuencial recibe `Matrix` por valor y el paralelo recibe `*Matrix`, porque varios workers comparten las mismas matrices. El diagnóstico de laboratorio ([`resultados/diagnostico/s09_i04_go_paralelo/`](../resultados/diagnostico/s09_i04_go_paralelo/README.md)) muestra:

- **Ensamblador.** En el bucle interno, la versión por puntero hace cuatro cargas adicionales por iteración (`MOVQ 8(reg)` y `MOVQ 16(reg)`): el puntero y la longitud de `b.Data` y de `c.Data`. Como no puede probar que la escritura en `c.Data[...]` no modifica esas cabeceras, el compilador las vuelve a leer en cada iteración. La copia de laboratorio por valor no tiene ninguna. Ambas tienen las mismas tres comprobaciones de límites (`-d=ssa/check_bce`), así que la diferencia no está en ellas.
- **Tiempo.** En una sola goroutine, la versión por puntero tardó 1,51 veces más con N=1024 (1085,6 frente a 718,7 ms) y 1,63 veces más con N=512. Rinde ~2,0 GFLOPS por puntero y ~3,0 por valor, los mismos niveles que `go_paralelo` W=1 y `go_secuencial` en la campaña oficial.
- **Corrección.** El resultado es idéntico bit a bit con ambas firmas.

El laboratorio se ejecutó en otra PC de la misma familia (Ryzen 7 3700X, Zen 2) y con Go 1.27.1. Explica el mecanismo, pero no sustituye a la campaña. **El sobrecoste viene de cómo el compilador trata la firma del kernel paralelo, no del modelo de concurrencia de Go ni del canal.**

### C4 · Coordinación: canal, goroutines y `WaitGroup`

Mediana por corrida de `total_s − kernel_s` (campaña integrada):

| N | go_secuencial | W=1 | W=2 | W=4 |
| ---: | ---: | ---: | ---: | ---: |
| 512 | 0,000 ms | 0,502 ms | 0,000 ms | 0,000 ms |
| 1024 | 1,005 ms | 1,526 ms | 1,034 ms | 1,005 ms |
| 2048 | 4,559 ms | 4,648 ms | 4,595 ms | 5,034 ms |

`total_s − kernel_s` contiene el vaciado de C, que también tiene el secuencial, y además, en el paralelo, la creación del canal y de las goroutines, el despacho, el cierre y la espera. Las dos versiones dan valores del mismo orden, y crecen con N² como el vaciado de C (2, 8 y 32 MiB).

Los valores son múltiplos de ~0,5 ms, el paso de `time.Now()` observado en la PC oficial durante el cierre de S6. Por eso la coordinación, de microsegundos según los benchmarks de S6, **no se puede resolver** con el reloj de la campaña: cualquier diferencia menor que un paso queda oculta. Los grupos con mediana por debajo de 100 ms (N=512, y W=2/W=4) se interpretan como diagnóstico de tiempos cortos, según la política del cierre de S6.

### C5 · Pérdida de eficiencia con W=4

`W · kernel_s(N, W) / kernel_s(N, 1)` mide cuánto trabajo total consumen los W workers frente a uno solo. El `kernel_s` de una corrida es el del worker más lento.

| N | W=2 (integrada / reproducción) | W=4 (integrada / reproducción) |
| ---: | ---: | ---: |
| 512 | 1,007 / 1,019 | 1,039 / 1,101 |
| 1024 | 1,019 / 1,116 | 1,120 / 1,172 |
| 2048 | 1,030 / 1,008 | 1,125 / 1,159 |

Con W=2 la inflación es pequeña salvo en un grupo disperso. Con W=4 sube al 4–17 % y explica casi toda la pérdida de E(W1). Hay causas compatibles con los datos:
- competencia por la jerarquía de memoria compartida: las matrices ocupan 6, 24 y 96 MiB frente a los 32 MiB de L3 del procesador;
- menor frecuencia de turbo con más núcleos activos;
- ubicación de hilos en núcleos o CCX distintos;
- desbalance del worker más lento.

**No se midieron** contadores de caché, frecuencias ni tiempos por worker (la campaña solo guarda el máximo), y la temperatura de CPU no estaba disponible. Por eso no se atribuye la pérdida a ninguna de esas causas, conforme al acta de campaña.

### C6 · Reproducibilidad entre campañas oficiales

| N | go_secuencial | W=1 | W=2 | W=4 |
| ---: | ---: | ---: | ---: | ---: |
| 512 | +1,0 % | +0,5 % | +1,7 % | +7,6 % |
| 1024 | +1,3 % | −0,2 % | +9,1 % | +4,4 % |
| 2048 | +0,8 % | +1,7 % | −0,5 % | +4,7 % |

*Cambio de la mediana de `total_s` de la reproducción (`s08_i04_go_paralelo_01`, 19/11) respecto de la campaña integrada (`s08_oficial_integrada_03`, 26/11).*

Las versiones de un solo hilo varían como máximo un 1,7 %. Con varios workers la variación sube hasta el 9,1 %, y coincide con los grupos de dispersión moderada o alta: N=1024/W=2 tiene IQR/mediana de 9,5 % y 10,7 %. Aun así, las conclusiones C1–C5 se mantienen en las dos campañas: con W=4, S(W1) es 3,41–3,85 y S(seq) 2,32–2,60. No se eliminó ni sustituyó ninguna observación.

## Referencia para el informe y límites

- **Qué speedup citar.** Según el protocolo, el speedup oficial de Go es S(seq): mediana de `go_secuencial` sobre mediana de `go_paralelo`, con el mismo N y W, dentro de `s08_oficial_integrada_03`. S(W1) describe la escalabilidad del pool y debe presentarse aparte, con la explicación de C3.
- **Comparación C/Go (I6).** El factor de ~1,45 de C3 es un detalle de implementación del kernel Go paralelo, no una propiedad del lenguaje ni de CSP. Conviene citarlo como amenaza a la validez cuando se comparen tiempos absolutos de `go_paralelo` con C o con `go_secuencial`.
- **Alcance.** Los datos cubren una sola PC, Windows, Go 1.27.4, N ≤ 2048 y W ≤ 4. No se midieron W=8 ni W mayor que los núcleos físicos, porque el protocolo lo excluye con 6 núcleos.
- **Trabajo futuro, fuera de la campaña.** Pasar las matrices por valor o copiar `b.Data` y `c.Data` en variables locales eliminaría las recargas. El algoritmo está congelado, así que el cambio exigiría una modificación justificada y una campaña nueva; no se aplicó.
- **Reloj.** La resolución de ~0,5 ms limita los tiempos cortos y oculta la coordinación (C4); no afecta a las conclusiones con N ≥ 1024.

## Reproducción

Desde la raíz del repositorio, en Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\analisis_go_paralelo.ps1
```

El script lee los `mediciones.csv` de ambas campañas, sin modificarlos, y regenera la tabla con el SHA-256 de cada fuente. El diagnóstico del kernel se repite desde `go_paralelo/`:

```powershell
go test -run 'TestMultiplyBlockByValueBitwise' ./...
go test -run '^$' -bench KernelPointerVsValue -benchtime 3x -count 5 -cpu 1 ./...
```
