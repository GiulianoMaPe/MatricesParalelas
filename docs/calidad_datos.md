# Reporte de calidad de datos — Sprint 8

Dictamen final: **33 grupos completos, 198 corridas OK y cero exclusiones** en [la campaña integrada](../resultados/raw/s08_oficial_integrada_03/mediciones.csv). Se verificaron el host `PCG1UL14N0`, la candidata congelada, la semilla 42, las 20 columnas canónicas y las repeticiones únicas 0 a 5 por configuración.

| Versión | Grupos | Calentamientos | Mediciones válidas |
| --- | ---: | ---: | ---: |
| C secuencial | 3 | 3 | 15 |
| C paralelo | 18 | 18 | 90 |
| Go secuencial | 3 | 3 | 15 |
| Go paralelo | 9 | 9 | 45 |
| **Total** | **33** | **33** | **165** |

El verificador cruzó los datos con el plan, el stdout preservado, los códigos de salida, los ranks y los manifiestos Release. La [extracción de C paralelo](../resultados/raw/c_paralelo.manifest.json) comprueba procesos, hilos observados, entorno OpenMP y reparto de filas. El entorno hijo de Go coincide con los workers de cada grupo.

El [resumen](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv) usa únicamente los datos de esta campaña. La [auditoría de dispersión](../resultados/resumen/s08_oficial_integrada_03/auditoria_dispersion.md) registra 3 grupos por encima del 10 % de IQR/mediana y conserva las cinco mediciones de cada grupo. Los intentos parciales de Go secuencial se conservan en [diagnóstico](../resultados/diagnostico/).


## Auditoría previa de Go paralelo

- Origen: `PCG1UL14N0`.
- Commit registrado: `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.
- Semilla: 42.
- Tamanos: 512, 1024 y 2048.
- Workers: 1, 2 y 4.
- Cada combinacion tiene cinco mediciones y un calentamiento.
- Las 45 mediciones tienen `validation_status=OK`.
- Las 9 configuraciones están completas.
- No se encontraron exclusiones ni filas inválidas en el CSV entregado.
- El resumen estadístico existe en `resultados/resumen/go_paralelo_resumen.csv`.
- El manifiesto conserva el SHA-256 del CSV y la procedencia de la extracción.

Avisos retenidos sin borrar datos:

- `N=1024/W=2`: dispersión IQR/mediana superior al 10 %.
- `N=1024/W=4`: dispersión IQR/mediana superior al 10 %.
- Configuraciones `N=512/W=2` y `N=512/W=4`: tiempos inferiores al umbral corto documentado de 100 ms.

Estos avisos no justifican descartar observaciones. Cada advertencia debe conservarse en el dictamen final.

## Verificación y procedencia

- Los lotes de C y Go secuenciales coinciden con las filas correspondientes de sus campañas fuente y con los SHA-256 publicados. Cada uno contiene un calentamiento y cinco mediciones válidas por N.
- El verificador común confirmó las 72 corridas y los 12 grupos de la subcampaña I3, incluidos plan, orden, logs, procesos, ranks y manifiestos de compilación.
- El [control de C secuencial](entorno/6-gerardo.md#control-independiente-disponible) se conserva en otra carpeta. Los speedups del cierre se calcularán con la referencia secuencial del mismo lenguaje y de la misma campaña integrada.
