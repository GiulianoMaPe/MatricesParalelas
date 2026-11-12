# Resultados

Las cuatro versiones implementan el producto y su validación. La automatización
completa del piloto corresponde a S7 y la campaña oficial a S8; consultar
[protocolo](../docs/protocolo_medicion.md).

| Carpeta | Contenido |
| --- | --- |
| `diagnostico/s06/` | Ensayos Linux de núcleos y candidatas, memoria RSS y regresión portable. Esquema `s06-laboratory-v1`, separado del CSV Windows. |
| `piloto/<campaign_id>/` | Piloto Windows S7, con entorno, plan, mediciones y bitácora. |
| `raw/<campaign_id>/` | Datos oficiales Windows S8. |
| `resumen/` y `graficos/` | Derivados trazables de las observaciones correspondientes. |

No mezclar plataformas, revisiones, compilaciones o intentos. Las salidas lentas
y los fallos se conservan. El tiempo de un smoke test no es rendimiento matricial.
Los builds y cachés son regenerables y permanecen ignorados por Git.

Los diagnósticos S6 conservan `entorno.json`, `plan.json`,
`observaciones.jsonl`, `resumen.json` y `resumen.csv`. Cada observación incluye
stdout, stderr, lectura original del pico RSS, comando y estado. Las fuentes
exactas se guardan en `sources/` con hashes, porque el experimento puede preceder
al commit de la entrega. El resumen no publica speedup de campaña.
