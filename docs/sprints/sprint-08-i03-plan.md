# Sprint 8 · Plan I3 · Giuliano · Go secuencial

**Estado:** planificación preparada; no se han ejecutado mediciones de S8.
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
| Timeout inicial | 300 s por corrida |
| Salida fuente | `resultados/raw/s08_oficial_01/mediciones.csv` |
| Entregable derivado I3 | `resultados/raw/go_secuencial.csv` |

Se esperan 3 combinaciones Go secuencial y 18 filas en su extracción: 3
calentamientos y 15 medidas. La campaña oficial completa incluye además las
configuraciones asignadas a I1, I2 e I4, en una sola tabla y con un único
`campaign_id`.

## Secuencia de trabajo

1. **Preflight y trazabilidad · 3 h de ejecución/supervisión.** Desde la copia
   congelada, confirmar HEAD exacto, árbol limpio, cuatro manifiestos Release
   válidos y hashes de binarios; comprobar PC oficial, RAM disponible,
   alimentación y plan de energía; anotar sensores disponibles y límites.
2. **Campaña oficial.** Coordinar con I1/I2/I4/I5 la ventana compartida y lanzar
   una sola campaña integrada desde la copia congelada:

   ```powershell
   Set-Location .\.cache\s08-candidata-97ccc98
   git rev-parse HEAD
   git status --short
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version all -Fase oficial -CampaignId s08_oficial_01 -Seed 42 -TimeoutSeconds 300
   ```

   `-Fase oficial` usa por defecto N=512/1024/2048, exige Release y árbol
   limpio, y guarda la evidencia bajo `resultados/raw/s08_oficial_01/`.
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

- La campaña oficial queda `COMPLETE/VERIFIED`; se preserva cada archivo fuente.
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
  (Lima); reconfirmar disponibilidad antes de iniciar S8.
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

Completar después de la campaña: `campaign_id`, hashes, ruta/hash de extracción,
conteos por N, incidencias, resultado de revisión I2, horas reales y enlace al
PR de esta rama.
