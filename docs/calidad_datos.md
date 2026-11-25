# Reporte parcial de calidad de datos — Sprint 8

Estado: tres lotes oficiales verificados. La campaña integrada completa se está repitiendo en un nuevo intento tras interrumpirse el primero.

## Inventario de entregables

| Entregable | Estado | Observaciones |
|---|---|---|
| [C secuencial](../resultados/raw/c_secuencial.csv) | Verificado · `s08_i04_go_paralelo_01` | 18 filas: 3 calentamientos y 15 mediciones |
| C paralelo | Campaña integrada en curso | 18 grupos previstos: 18 calentamientos y 90 mediciones |
| [Go secuencial](../resultados/raw/go_secuencial.csv) | Verificado · `s08_i03_go_secuencial_03` | 18 filas: 3 calentamientos y 15 mediciones |
| [Go paralelo](../resultados/raw/go_paralelo.csv) | Verificado · `s08_i04_go_paralelo_01` | 54 filas: 9 calentamientos y 45 mediciones |

## Auditoría de Go paralelo

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

## Pendientes para dictamen final

Verificar el estado de `s08_oficial_integrada_01`, sus 33 grupos y la trazabilidad de procesos e hilos de C paralelo. El resumen y los dictámenes de dispersión abarcarán las cuatro versiones dentro de esa campaña.
