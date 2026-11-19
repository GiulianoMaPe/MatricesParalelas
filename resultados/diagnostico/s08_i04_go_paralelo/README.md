# S8 · I4 · Go paralelo · diagnóstico **no oficial**

Esta carpeta **no es el lote oficial** de Go paralelo ni sustituye a
`resultados/raw/go_paralelo.csv`. Contiene la prueba de
[`scripts/extract_s08_go_paralelo.ps1`](../../../scripts/extract_s08_go_paralelo.ps1)
sobre los dos intentos completos del S7 medidos en la PC oficial. El lote oficial
de N=512/1024/2048 sigue pendiente de ejecutarse en esa PC; el traspaso está en
[sprint-08.md](../../../docs/sprints/sprint-08.md).

## Fuentes

| Vista | Campaña fuente | Estado | Filas |
| --- | --- | --- | ---: |
| `go_paralelo_piloto_05.csv` | `resultados/piloto/s07_windows_20261117_piloto_05` | VERIFIED_PILOT, 0 críticas | 54 |
| `go_paralelo_reproduccion_06.csv` | `resultados/piloto/s07_windows_20261117_reproduccion_06` | VERIFIED_PILOT, 0 críticas | 54 |

Ambos intentos usan el commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, los
mismos binarios y el mismo plan, en la PC `PCG1UL14N0` (Ryzen 5 3600, 6 núcleos
físicos). Son N=256/512/1024, semilla 42 y W=1/2/4, con 1 calentamiento y 5
medidas por grupo. Cada vista copia byte a byte la cabecera y las filas
`go_paralelo` de `mediciones.csv`, en el orden del plan. Su `.manifest.json`
guarda los hashes de las fuentes y de la vista, los grupos, las estadísticas y
las anomalías.

## Workers efectivos

En las 108 filas se comprobó:
- `workers = gomaxprocs = W` en el CSV, y `GOMAXPROCS = W` en el entorno hijo de
  `proceso.json`;
- argumentos `--workers W`, `--n`, `--seed` y `--repetition` iguales al plan;
- un proceso y un hilo observado;
- `stdout.txt` idéntico a la fila de `mediciones.csv`;
- código de salida 0 y registro `status=OK` en la bitácora;
- W permitido para 6 núcleos físicos.

Speedup interno de la mediana de `total_s` frente a W=1, en el mismo intento:

| N | W=2 (_05 / _06) | W=4 (_05 / _06) |
| ---: | ---: | ---: |
| 256 | 1,964 / 1,954 | 3,361 / 3,706 |
| 512 | 1,942 / 1,982 | 3,682 / 3,501 |
| 1024 | 1,972 / 1,993 | 3,681 / 3,652 |

Las eficiencias van de 0,84 a 1,00. Este speedup es solo un control de que los
workers trabajan en paralelo; el análisis oficial lo hace I7 con su resumen.

## Estabilidad de las repeticiones

Las medianas, Q1 y Q3 del manifiesto coinciden exactamente con
`resumen_estadistico.csv` de I7 en los 9 grupos del intento `_05`.

| N | W | Mediana `total_s` _05 → _06 | Cambio | IQR/mediana _05 / _06 |
| ---: | ---: | ---: | ---: | ---: |
| 256 | 1 | 0,016809 → 0,016678 s | −0,8 % | 0,028 / 0,003 |
| 256 | 2 | 0,008559 → 0,008534 s | −0,3 % | 0,082 / 0,057 |
| 256 | 4 | 0,005001 → 0,004500 s | −10,0 % | 0,100 / 0,146 |
| 512 | 1 | 0,134404 → 0,135605 s | +0,9 % | 0,008 / 0,003 |
| 512 | 2 | 0,069212 → 0,068411 s | −1,2 % | 0,015 / 0,004 |
| 512 | 4 | 0,036502 → 0,038731 s | +6,1 % | 0,071 / 0,080 |
| 1024 | 1 | 1,081363 → 1,091995 s | +1,0 % | 0,021 / 0,027 |
| 1024 | 2 | 0,548466 → 0,547884 s | −0,1 % | 0,069 / 0,040 |
| 1024 | 4 | 0,293806 → 0,299012 s | +1,8 % | 0,029 / 0,099 |

La mediana del cambio absoluto entre intentos es 0,98 % y el máximo, 10,0 %
(N=256, W=4). Esa diferencia, de 0,5 ms, es del orden de un paso del reloj de
Go en Windows (entre 0,3 y 0,5 ms en las mediciones de S6 y S7). El grupo está marcado como `tiempo_corto` (mediana menor de
100 ms, política de reloj del cierre S6) y, en ambos intentos, como
`dispersion_alta` (IQR/mediana > 10 %). Son avisos: **no se eliminó ni se
reordenó ninguna observación**. No se atribuye la dispersión a una causa sin
medirla.

## Control oficial de Giuliano (PR #58)

La subcampaña oficial `s08_i03_go_secuencial_03` (PR #58, todavía sin integrar)
incluye `go_paralelo_W1` como control con N=512/1024/2048. Con el extractor:
- en fase `diagnostico` da DIAGNOSTIC, 18 filas y 0 críticas (medianas 0,1339,
  1,0751 y 8,7873 s);
- en fase `oficial` da INCOMPLETE por `serie_incompleta`, porque solo mide W=1 y
  un lote completo con 6 núcleos exige W=1/2/4.

Ese comportamiento es el esperado. No se copian aquí sus archivos; el CSV fuente
tiene SHA-256 `6C972DC764BB3AEF41E3C1A3CD3F091A7FC69F8925C7C0660E1CC14FE61849DC`.

## Reproducción

Desde la raíz del repositorio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_go_paralelo.ps1 -CampaignDirectory .\resultados\piloto\s07_windows_20261117_piloto_05 -Phase piloto -OutputPath .\resultados\diagnostico\s08_i04_go_paralelo\go_paralelo_piloto_05.csv
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_go_paralelo.ps1 -CampaignDirectory .\resultados\piloto\s07_windows_20261117_reproduccion_06 -Phase piloto -OutputPath .\resultados\diagnostico\s08_i04_go_paralelo\go_paralelo_reproduccion_06.csv
```

Los manifiestos se regeneran con una nueva marca `generated_at_utc`; las vistas y
sus hashes no cambian.
