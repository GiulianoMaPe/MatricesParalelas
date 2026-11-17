# Repetición de S7 en Windows: resultados técnicos

**Estado:** Cerrado con conformidad del responsable.

Commit medido: `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.

Cada campaña registró 198/198 observaciones válidas y 33 grupos completos. Las 13 comprobaciones cruzadas son verdaderas; los logs de aceptación y verificación están en cada campaña. Los datos se conservan como conjuntos separados, sin filtrar atípicos ni combinarlos.

## Resultados por campaña

La carga CPU se registró por corrida y la GPU cada cinco segundos. No se afirma que el equipo estuviera inactivo.

| Campaña | Resultado | Grupos | Duración | Carga CPU | RAM libre mínima | GPU |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `s07_windows_20261117_piloto_05` | 198/198 OK | 33/33 | 711.317 s | 5.0–40.0% | 10323 MiB | 46.0–47.0 °C, 142 muestras |
| `s07_windows_20261117_reproduccion_06` | 198/198 OK | 33/33 | 702.354 s | 2.0–37.0% | 10151 MiB | 46.0–47.0 °C, 141 muestras |

La CPU no tiene lectura térmica, según la decisión del responsable. La temperatura GPU no determina la temperatura ni estabilidad térmica de la CPU.

## Comparación y reserva S8

| Métrica | Resultado |
| --- | --- |
| Cambio absoluto mediano entre medianas | 1.39% |
| Cambio absoluto máximo | 18.81% (disminuyó), c_paralelo, N=256, c_paralelo_P4_T1 |
| Memoria matricial estimada S8 (N=2048) | 288 MiB, sin runtime ni stacks |
| Reserva S8 provisional | 2026-11-18T09:00:00-05:00 a 2026-11-18T12:00:00-05:00 (Lima), proyección y no medición S8 |

Intentos previos excluidos del análisis: `_03` quedó parcial y `_04` no midió por un lock de prueba huérfano. Ambos se conservaron aparte.

Ver `verificacion_cruzada.json`, `comparacion_reproduccion.csv`, los logs individuales `monitor_externo/`, `aceptacion_responsable.json` y `reserva_maquina.json`.
