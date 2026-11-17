# Sprint 8 · Plan I3 · Giuliano · Go secuencial

**Estado:** entrega técnica I3 completa y verificada; revisión humana I2 pendiente.
Se preservan todos los intentos y sus incidencias.
**Rama:** `feature/s08-i03-go-secuencial`.

## Objetivo y alcance

Ejecutar y supervisar la parte de Go secuencial dentro de la campaña oficial
integrada. Revisar que sus entradas, binario, semilla y condiciones coincidan con
la candidata congelada y con el plan común. Conservar la campaña original y
publicar una extracción identificada de las filas Go secuencial.

La campaña integrada escribe el CSV fuente en
`resultados/raw/<campaign_id>/mediciones.csv`. El archivo solicitado por el
reparto, `resultados/raw/go_secuencial.csv`, será una vista derivada con solo las
filas `version=go_secuencial`; no reemplazará ni alterará el CSV fuente.

## Parámetros congelados

| Parámetro | Valor previsto |
| --- | --- |
| Candidata | `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` |
| Directorio de ejecución | `.cache/s08-candidata-97ccc98` |
| Versión | `go_secuencial` |
| Dimensiones | N=512, 1024 y 2048 |
| Semilla | 42 |
| Calentamiento | 1 por combinación |
| Medidas | 5 por combinación |
| Configuración secuencial | `workers=1`, `GOMAXPROCS=1` |
| Timeout vigente | 900 s por corrida; inicial de 300 s conservado en los intentos previos |
| Salida fuente I3 | `resultados/raw/s08_i03_go_secuencial_03/mediciones.csv` |
| Entregable derivado I3 | `resultados/raw/go_secuencial.csv` |

Se esperan 3 combinaciones Go secuencial y 18 filas en su extracción: 3
calentamientos y 15 medidas. La corrida I3 usa un plan integrado reducido para
validar su secuencial junto con las referencias C/Go y un control paralelo por
lenguaje. No sustituye la campaña completa de S8 que coordina el equipo.

## Preflight ejecutado · 17/11/2026

| Comprobación | Resultado |
| --- | --- |
| Candidata y árbol | HEAD `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`; limpio |
| Manifiestos Release | Los cuatro binarios presentes; commit, arquitectura x64 y hashes coinciden |
| Recursos | 10030 MiB RAM libre; plan Equilibrado; huella matricial estimada 288 MiB |
| GPU antes del lote | GTX 1070, 44 °C, utilización 2% |
| Lock/procesos de medición | Sin lock ni ejecutables del proyecto activos |
| Dry-run completo inicial | 198 filas, 33 grupos, 0 exclusiones; Go secuencial: 3 grupos/18 filas |
| Dry-run del subplan I3 | 72 filas, 12 grupos, 0 exclusiones; Go secuencial: 3 grupos/18 filas |
| Evidencia | `resultados/diagnostico/s08_i03_preflight/s08_i03_preflight/` |
| Evidencia filtrada | `resultados/diagnostico/s08_i03_preflight_filtrado/s08_i03_preflight_filtrado/` |

El dry-run no ejecutó matrices. CPU no tiene lectura térmica; el preflight no
afirma que el equipo esté aislado de otras cargas.

## Incidente del primer intento · 17/11/2026

El intento `s08_oficial_01` produjo 25 filas y se detuvo al exceder 300 s el
warmup de `c_paralelo_P1_T1`, N=2048. La fila fallida, los logs y las otras 24
filas OK están archivados en
`resultados/diagnostico/s08_i03_oficial_inicial_timeout/`. El archivo se comparó
por SHA-256 y es idéntico al original; la copia duplicada se retiró de la
candidata para restaurar su limpieza. Las filas Go secuencial solo incluyen
warmups, así que aún no son entregables.

## Recuperación del entorno · 17/11/2026

El primer subplan, `s08_i03_go_secuencial_01`, quedó interrumpido con 9 filas
OK de warmup, sin `estado.json` y sin procesos de medición activos al recuperar
el acceso. Se archivaron sus 40 archivos y se compararon por SHA-256 antes de
retirar la copia duplicada de la candidata. Evidencia:
`resultados/diagnostico/s08_i03_interrumpido_01/`. No se usa como dato medido.

Se retiró el lock huérfano solo después de confirmar la ausencia de su PID y
de procesos de medición. La candidata volvió a pasar la verificación de sus
cuatro builds oficiales y fuentes limpias. Preflight del intento nuevo:
10206300 KiB RAM libre; GPU GTX 1070 a 46 °C y 2% de utilización.

La repetición completa usa `s08_i03_go_secuencial_03`, con el mismo plan de
72 corridas, semilla y binarios. La GPU se muestrea cada 30 s desde después
del inicio, en un archivo complementario separado del lote original; CPU
permanece sin lectura térmica. El permiso del responsable permite empezar y
terminar en la franja real de ejecución, sin fijar una hora futura.

## Ajuste de timeout del control MPI · 17/11/2026

El intento `s08_i03_go_secuencial_02` se detuvo correctamente con estado
`INCOMPLETE`: 11 observaciones OK y un timeout del warmup C paralelo P4/T1,
N=2048, a los 300.135338 s. Evidencia original preservada por SHA-256 en
`resultados/diagnostico/s08_i03_timeout_02/`, con muestras GPU complementarias.
No llegó a las rondas medidas; no aporta filas a la entrega final.

La repetición `s08_i03_go_secuencial_03` amplía el límite a 900 s para observar
la terminación del control MPI, con idéntica candidata, binarios, plan, N y
semilla. El acta permite ajustar el timeout con ID nuevo y sin sustituir filas.
La duración de pared incluye preparación y validación de referencia fuera de
los cronómetros internos y no se usa como `kernel_s` ni `total_s`.

## Secuencia de trabajo

1. **Preflight y trazabilidad · 3 h de ejecución/supervisión.** Desde la copia
   congelada, confirmar HEAD exacto, árbol limpio, cuatro manifiestos Release
   válidos y hashes de binarios; comprobar PC oficial, RAM disponible,
   alimentación y plan de energía; anotar sensores disponibles y límites.
2. **Subcampaña I3.** Coordinar con I5 el registro y lanzar en una carpeta nueva
   una captura de control que incluye las referencias secuenciales y una sola
   configuración paralela de cada lenguaje. El intento completo previo está
   preservado; usar un `campaign_id` nuevo:

   ```powershell
   Set-Location .\.cache\s08-candidata-97ccc98
   git rev-parse HEAD
   git status --short
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version all -Fase oficial -CampaignId s08_i03_go_secuencial_03 -Seed 42 -Configurations P4_T1 -GoWorkers 1 -TimeoutSeconds 900
   ```

   `-Fase oficial` usa N=512/1024/2048, exige Release y árbol limpio, y guarda
   evidencia bajo `resultados/raw/s08_i03_go_secuencial_03/`. El subplan tiene
   4 configuraciones (72 filas); Go secuencial aporta 18. No marcarlo como la
   campaña integral del equipo.
3. **Revisión de I3 · 3 h.** Conservar intactos CSV, plan, entorno, manifiestos
   y logs originales. Filtrar únicamente las filas Go secuencial a
   `resultados/raw/go_secuencial.csv`, anotando su `campaign_id` fuente y hash.
   Comprobar 18 filas más cabecera, N/semilla/configuración esperadas,
   calentamiento 0 y repeticiones 1–5 por N, validación OK, timestamps UTC,
   commit compatible con el manifiesto y tiempos finitos con
   `0 < kernel_s <= total_s`.
4. **Revisión cruzada · 1 h.** Solicitar a I2 la revisión asignada a I3; guardar
   el resultado, observaciones y cambios solicitados en el registro de S8.
5. **Coordinación · 1 h.** Confirmar con I5 la extracción y el esquema común;
   con I6, las condiciones de máquina; con I7/I8, trazabilidad y congelación de
   datos. Registrar horas reales y bloqueos sin atribuir trabajo no declarado.

## Criterios de aceptación de I3

- La subcampaña I3 queda `COMPLETE/VERIFIED`; se preserva cada archivo fuente y
  no se declara completa la campaña integral S8.
- La candidata, los binarios Release, los parámetros y la semilla corresponden
  al manifiesto congelado.
- Cada N tiene 1 warmup y 5 medidas únicas válidas, sin filas duplicadas ni
  descartes silenciosos.
- La extracción contiene solo filas Go secuencial, conserva los 20 campos y
  permite rastrear su CSV fuente por campaña y hash.
- Cualquier fallo o repetición se conserva con ID nuevo y razón documentada;
  nunca se sobrescribe una campaña ni se seleccionan los mejores tiempos.
- La revisión I2 y las 8 horas declaradas quedan registradas con el desglose
  real; no se presume una conformidad de otra persona.

## Bloqueos y límites previstos

- El piloto S7 reservó provisionalmente esta PC para el 18/11/2026, 09:00–12:00
  (Lima); reconfirmar disponibilidad antes de iniciar la campaña integral S8.
- La estimación S7 para la campaña completa fue de tres horas y 288 MiB para
  matrices N=2048, sin runtime ni stacks. Volver a medir RAM/carga antes de
  empezar; excluir dimensiones solo con la regla común del protocolo y dejar
  motivo en el plan.
- S7 midió temperatura GPU, pero no dispone de lectura térmica CPU. Registrar
  el estado real de sensores y cualquier throttling; no afirmar estabilidad
  térmica de CPU sin lectura.
- No ejecutar el runner standalone `-Version go_secuencial` como campaña S8:
  su salida por defecto es diagnóstica S7. Para conservar el contexto oficial,
  usar el runner integrado y derivar de él la vista Go secuencial.

## Registro de cierre I3

Entrega técnica completa: `s08_i03_go_secuencial_03`, **72/72 corridas válidas**,
12 grupos completos y 0 exclusiones. La extracción I3 contiene **18/18 filas
válidas: 3 warmups y 15 medidas**. [Resultados, hashes y verificación](../../resultados/raw/s08_i03_go_secuencial_03/README.md).

| N | Warmups | Medidas OK | Mediana kernel (s) | Mediana total (s) | Mín.–máx. total (s) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 512 | 1 | 5 | 0.090260100 | 0.090260100 | 0.089870700–0.095034000 |
| 1024 | 1 | 5 | 0.711943000 | 0.712950300 | 0.694328800–0.730602200 |
| 2048 | 1 | 5 | 6.172516400 | 6.177566100 | 6.117811500–6.266355400 |

- CSV I3: `resultados/raw/go_secuencial.csv`; fuente y hashes en `revision_i3.json`.
- Se preservan los cuatro intentos y sus incidencias, sin mezclar filas ni seleccionar tiempos.
- Revisión I2→I3: pendiente; revisor asignado Sebastián (`@SebastianMalca`); seguimiento en el PR #58.
- Coordinación humana con I5–I8: pendiente de confirmación; no atribuida a la auditoría automática.
- Horas: 8 h presupuestadas (3+3+1+1); no se presume un desglose real no declarado para S8.
- Esta entrega individual con controles no cierra la campaña integral ni el sprint del equipo.
- PR: [#58](https://github.com/GiulianoMaPe/MatricesParalelas/pull/58).

Después de archivar y subir la evidencia, se retiró la copia duplicada del lote
de la candidata tras comparar sus 296 archivos contra el archivo preservado.
La candidata volvió a verificar fuentes limpias y cuatro builds oficiales;
`revision_i3.json` registra `post_archive_candidate_verification`.
