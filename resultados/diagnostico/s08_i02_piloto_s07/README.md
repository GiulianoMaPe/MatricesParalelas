# Diagnóstico I2 S8 · extracción `c_paralelo` del piloto S7

**Estado:** evidencia de diagnóstico. **No es la campaña oficial de S8** y no
acredita el entregable `resultados/raw/c_paralelo.csv`.

Este directorio conserva una vista derivada del lote `c_paralelo` del piloto
integrado de Sprint 7, generada con el extractor de I2 para comprobar que la
herramienta de cierre funciona sobre datos reales antes de la campaña oficial.

## Procedencia

| Campo | Valor |
| --- | --- |
| Campaña fuente | `resultados/piloto/s07_windows_20261117_reproduccion_06` |
| Fase de la fuente | `piloto` |
| Commit medido | `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` |
| PC | `PCG1UL14N0` (Ryzen 5 3600, 6 núcleos físicos / 12 lógicos) |
| Tamaños | N = 256, 512, 1024 |
| Semilla | 42 |
| Configuraciones | `P1_T1`, `P1_T2`, `P2_T1`, `P1_T4`, `P2_T2`, `P4_T1` |
| Repeticiones | 1 calentamiento + 5 medidas por grupo |
| Filas `c_paralelo` | 108 (18 grupos × 6 filas) |
| Filas de otras versiones | 90 (ignoradas, no se copian) |
| Estado del árbol fuente | `dirty=true` (el piloto S7 no es oficial) |

La campaña fuente fue un piloto de S7; sus metadatos, logs y verificación están
en la carpeta citada. Aquí solo se copian las filas `version=c_paralelo` byte a
byte, sin recalcular tiempos ni completar filas ausentes.

## Contenido

| Archivo | Descripción |
| --- | --- |
| `c_paralelo_piloto.csv` | Cabecera canónica de 20 campos + 108 filas `c_paralelo` |
| `revision_i02.json` | Manifiesto: hashes, grupos, controles y anomalías |
| `README.md` | Este documento |

SHA-256 de la vista: `0903455ED7A4162D101682D7B47B20B56F84BED3EB55DE8D3A798054C303DAA2`.

## Resultado de la revisión

`VERIFIED_PILOT`: 108 filas, 18 grupos, **0 anomalías críticas**.

Controles aplicados por el extractor:

- Esquema de 20 campos, orden del plan y rondas alternadas.
- `processes=P`, `threads=T`, `observed_threads=T` y `OMP_DYNAMIC=FALSE`.
- Un calentamiento y repeticiones 1..5 únicas y `OK` por grupo.
- Igualdad byte a byte entre `mediciones.csv` y la vista derivada.
- Commit, hostname y tamaños coherentes con `entorno.json`.
- Bitácora en estado `OK` y reparto de ranks completo.

Única anomalía, **no crítica** (`os_heredado`): la fila original etiqueta el
sistema como `Windows 10 Pro build 26300.9711` mientras `entorno.json` declara
`Microsoft Windows 11 Pro build 26300`. Se conserva el valor original; no se
reescribe evidencia histórica.

## Comando de reproducción

Desde la raíz del repositorio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\piloto\s07_windows_20261117_reproduccion_06 `
    -Phase piloto -ExpectedSizes 256,512,1024 `
    -OutputPath .\resultados\diagnostico\s08_i02_piloto_s07\c_paralelo_piloto.csv `
    -ManifestPath .\resultados\diagnostico\s08_i02_piloto_s07\revision_i02.json
```

## Qué falta para el entregable oficial

La campaña oficial de S8 debe ejecutarse en la PC oficial con N = 512, 1024,
2048, árbol limpio sobre la candidata congelada y el lote completo de
configuraciones. Solo entonces el extractor puede escribir
`resultados/raw/c_paralelo.csv` en fase `oficial`. Ver
[`docs/sprints/sprint-08-i02-plan.md`](../../../docs/sprints/sprint-08-i02-plan.md).
