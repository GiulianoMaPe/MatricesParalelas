# S8 · I3 · Giuliano · Go secuencial

Estado técnico: **COMPLETE / VERIFIED**. La subcampaña contiene **72 corridas OK**,
12 grupos completos de control y ninguna exclusión. La entrega Go secuencial
contiene **18 observaciones: 3 warmups y 15 medidas**, cinco medidas por N.
La revisión humana I2→I3 está pendiente; el revisor asignado es @SebastianMalca.
El cierre integral del sprint requiere las entregas y revisiones del equipo.

## Resultados de I3

Los warmups se preservan y se excluyen de estas estadísticas. Los tiempos
`kernel_s` y `total_s` son los internos del contrato. La pared del proceso
incluye preparación y validación de referencia y se conserva en sus logs.

| N | Warmups | Medidas OK | Mediana kernel (s) | Mediana total (s) | Mín.–máx. total (s) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 512 | 1 | 5 | 0.090260100 | 0.090260100 | 0.089870700–0.095034000 |
| 1024 | 1 | 5 | 0.711943000 | 0.712950300 | 0.694328800–0.730602200 |
| 2048 | 1 | 5 | 6.172516400 | 6.177566100 | 6.117811500–6.266355400 |

## Procedencia y trazabilidad

| Campo | Valor |
| --- | --- |
| Campaña | `s08_i03_go_secuencial_03` |
| Fase | oficial; subplan con C/Go secuenciales y controles P4/T1 y W1 |
| Commit medido | `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` |
| Semilla | 42 |
| I3 | P=T=observed_threads=workers=GOMAXPROCS=1 |
| Inicio UTC | 2026-11-17T20:38:56Z |
| Fin UTC | 2026-11-17T21:56:02Z |
| Pared de campaña | 4625.565 s |
| SHA-256 Go secuencial Release | `3C4071ACB70DD028DC808F25EB43600014D36E336D652D2D0544473F8F0C5E11` |
| SHA-256 CSV fuente | `6C972DC764BB3AEF41E3C1A3CD3F091A7FC69F8925C7C0660E1CC14FE61849DC` |
| SHA-256 extracción I3 | `581FB5DB9F78A2790F519473D791886AD18BEB02ADBBFBE0711E088ABB494FD5` |

El CSV fuente es `mediciones.csv`; la vista I3 está en
[`../go_secuencial.csv`](../go_secuencial.csv). `revision_i3.json` guarda origen,
hashes y criterios I3, con el SHA-256 de los 296 archivos copiados de la
campaña. Se comprobó cada copia por SHA-256. La extracción conserva exactamente
la cabecera de veinte campos y las líneas Go secuencial en su orden original.
No combina intentos ni reserializa filas. `gpu_muestras.csv`, `revision_i3.json`
`verificacion_revision_raiz.json` y este README son complementos posteriores;
el inventario distingue los originales.

## Verificación

El verificador común comprobó estado/plan/CSV, parámetros, commit/PC, rondas
alternadas, warmups y repeticiones, stdout/stderr, códigos de salida, procesos,
reparto/hilos por rank MPI y manifiestos de los cuatro builds Release.
El verificador conserva avisos heredados de S7; aquí se usa para auditar datos
del subplan S8, sin atribuir una aceptación humana.
El control I3 verificó además 18 filas, N=512/1024/2048, semilla 42, índices
únicos 0..5 por N, UTC válido, entorno hijo GOMAXPROCS=1 y tiempos finitos
con `0 < kernel_s <= total_s`.

Para repetir la auditoría sin medir desde la raíz:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_campaign.ps1 -CampaignDirectory .\resultados\raw\s08_i03_go_secuencial_03
```

La candidata y los cuatro manifiestos/binarios pasaron el preflight. El runner
comprobó los hashes antes y después de cada proceso. Se conservaron los
algoritmos y las fronteras temporales congelados.

## Entorno y límites

PC oficial: PCG1UL14N0, Ryzen 5 3600, 6 núcleos físicos/12 lógicos, Windows 11
Pro build 26300.9711, AC, plan Equilibrado. `entorno.json` registra herramientas,
memoria, opciones de compilación y huella matricial. La etiqueta Windows 10
emitida por C es heredada; se conserva junto con Windows 11 del entorno y de
Go en la misma PC/build.

GPU GTX 1070: 154 muestras, 42–45 °C. La captura
complementaria consulta `nvidia-smi` cada 30 s desde después del inicio y no
cubre cada instante. CPU permanece sin lectura térmica por decisión del responsable.
No se acredita aislamiento perfecto, ausencia de throttling, estabilidad térmica CPU ni causas de dispersión.

## Intentos preservados y revisión

| Intento | Resultado | Evidencia |
| --- | --- | --- |
| `s08_oficial_01` | 24 OK + 1 timeout C P1/T1 N=2048 | `../../diagnostico/s08_i03_oficial_inicial_timeout/` |
| `s08_i03_go_secuencial_01` | Interrumpido; 9 warmups OK; sin estado final | `../../diagnostico/s08_i03_interrumpido_01/` |
| `s08_i03_go_secuencial_02` | 11 OK + 1 timeout C P4/T1 N=2048 | `../../diagnostico/s08_i03_timeout_02/` |
| `s08_i03_go_secuencial_03` | 72/72 OK; 18/18 I3; COMPLETE/VERIFIED | Esta carpeta |

El intento final amplía el timeout de 300 a 900 s y conserva plan, semilla,
fuentes y binarios. Todos sus tiempos se conservan, sin seleccionar los mejores
entre intentos. La revisión I2→I3 y la coordinación humana con I5–I8 siguen
pendientes de confirmación. I3 tiene 8 h presupuestadas (3+3+1+1); el tiempo
de máquina medido no equivale a horas humanas declaradas. La solicitud y el estado de revisión se consultan en el
[PR #58](https://github.com/GiulianoMaPe/MatricesParalelas/pull/58); la aprobación sigue pendiente.

La copia duplicada del lote en la candidata se retiró después de archivar y subir
los 296 originales, comparados otra vez por SHA-256. La candidata volvió a
verificar fuentes limpias y cuatro builds oficiales; consta en
`revision_i3.json`, campo `post_archive_candidate_verification`.
