# Sprint 8 · I4 · Campaña oficial Go paralelo

La subcampaña oficial `s08_i04_go_paralelo_01` terminó con **108 de 108 corridas válidas**, 18 grupos completos y cero exclusiones. El [CSV de I4](../go_paralelo.csv) conserva **54 filas** de Go paralelo en el orden original, con 9 calentamientos y 45 medidas válidas en 9 grupos. Los calentamientos se conservan en los datos crudos y quedan fuera de las estadísticas.

## Procedencia

| Campo | Valor registrado |
| --- | --- |
| PC y operador del arnés | `PCG1UL14N0`, `giuli` |
| Candidata limpia | `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` |
| Inicio y fin UTC | `2026-11-19T19:37:16Z` y `2026-11-19T21:07:00Z` |
| Tiempo de máquina | 5382,203 s (89,70 min) |
| Alimentación y plan | AC, Equilibrado |
| Go | `go version go1.27.4 windows/amd64` |
| Serie | N=512/1024/2048, semilla 42, W=1/2/4 |
| Controles del arnés | `go_secuencial`, `c_secuencial` y `c_paralelo_P1_T1` en la misma campaña |
| Timeout | 900 s por corrida |
| SHA-256 de `mediciones.csv` | `2D8A9222EC26AE34AAB5ECCCD07D884D2F5D21411A4A04B8AEFD565328776CE4` |
| SHA-256 de `go_paralelo.csv` | `11B68F7EE37979EE35B621F0E03433B3635A1E01C3BAD87F756DC62D0F14BD4C` |

La [bitácora](bitacora.txt) registra carga de CPU por corrida de 1–49 % y memoria libre mínima de 10172148 KiB. El arnés registró la temperatura de CPU como no disponible. El [registro de GPU](monitor_externo/gpu.csv) contiene 1024 muestras completas de 41–50 °C con marcas locales de la PC (Lima, UTC−5), desde `2026/11/19 14:37:10.283` hasta `2026/11/19 16:02:37.436`. El archivo conserva la salida original del monitor.

## Revisión de I4

- El [verificador común](verificacion.json) validó el orden alternado, las repeticiones y la correspondencia entre plan, datos, metadatos y registros de procesos. Se compararon 350 archivos de la candidata y de la copia publicada por SHA-256.
- El [manifiesto de I4](../go_paralelo.manifest.json) registra cero anomalías críticas. En cada corrida coincidieron el W planificado, `--workers`, `workers`, `gomaxprocs` y el `GOMAXPROCS` del proceso hijo. Se verificaron código de salida, estado matemático, `stdout.txt`, bitácora y coherencia de tiempos.
- La cabecera y las filas de Go paralelo del CSV publicado coinciden con las de [mediciones.csv](mediciones.csv). La comprobación del índice Git confirma que los archivos crudos conservan sus bytes.
- Las 21 pruebas del extractor pasaron en Windows, incluidos los rechazos de host y semilla, y la protección de los archivos oficiales ante una extracción incompleta.

## Estabilidad de las repeticiones

Estadísticos de `total_s` en segundos. Las medianas y los cuartiles de los nueve grupos coinciden con el [resumen común](resumen_estadistico.csv).

| N | W | Medidas | Mediana | Q1 | Q3 | IQR | Avisos |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 512 | 1 | 5 | 0,134684400 | 0,134664700 | 0,135094300 | 0,000429600 | — |
| 512 | 2 | 5 | 0,068841200 | 0,067516300 | 0,069577400 | 0,002061100 | `tiempo_corto` |
| 512 | 4 | 5 | 0,037443700 | 0,036606300 | 0,037784600 | 0,001178300 | `tiempo_corto` |
| 1024 | 1 | 5 | 1,079369700 | 1,074187200 | 1,128527200 | 0,054340000 | — |
| 1024 | 2 | 5 | 0,602657700 | 0,560580100 | 0,625122300 | 0,064542200 | `dispersion_alta` |
| 1024 | 4 | 5 | 0,316919100 | 0,301691800 | 0,337814700 | 0,036122900 | `dispersion_alta` |
| 2048 | 1 | 5 | 9,014317200 | 9,002163700 | 9,037581700 | 0,035418000 | — |
| 2048 | 2 | 5 | 4,543911700 | 4,528057100 | 4,546937200 | 0,018880100 | — |
| 2048 | 4 | 5 | 2,614747800 | 2,602654600 | 2,619974200 | 0,017319600 | — |

Se registraron 2 avisos de estabilidad. El manifiesto identifica cada combinación y su motivo. Se conservaron todas las observaciones válidas. El manifiesto de I4 presenta el speedup interno frente a W=1. El resumen común usa la referencia Go secuencial de esta misma campaña para el speedup del protocolo.
