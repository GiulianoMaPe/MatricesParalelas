# Repetición de S7 en Windows: resultados técnicos

**Estado:** ambas campañas completas y verificadas; falta la revisión y conformidad final del responsable.

Commit medido: `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.

Cada campaña registró 198/198 observaciones válidas y 33 grupos completos. Las 13 comprobaciones cruzadas son verdaderas; los logs de aceptación y verificación están en cada campaña. Los datos se conservan como conjuntos separados, sin filtrar atípicos ni combinarlos.

## Condiciones observadas

El responsable autorizó dejar activas las aplicaciones existentes. Se guardó una instantánea de ventanas al inicio; Zoom/navegadores se supervisaron cada cinco segundos, la carga CPU se registró por corrida y la GPU cada cinco segundos. No se afirma que el equipo estuviera inactivo ni se atribuyen diferencias a una aplicación.

- **s07_windows_20261117_piloto_05:** 198/198, 33 grupos; carga CPU 5.0–40.0%; memoria libre mínima 10323 MiB; GPU 46.0–47.0 °C (142 muestras). Procesos visibles observados: ApplicationFrameHost, Code, SystemSettings, TextInputHost, explorer.
- **s07_windows_20261117_reproduccion_06:** 198/198, 33 grupos; carga CPU 2.0–37.0%; memoria libre mínima 10151 MiB; GPU 46.0–47.0 °C (141 muestras). Procesos visibles observados: ApplicationFrameHost, Code, SystemSettings, TextInputHost, Zoom, explorer.

La CPU no tiene lectura térmica, según la decisión del responsable. La temperatura GPU no determina la temperatura ni estabilidad térmica de la CPU.

## Comparación y reserva S8

Cambio absoluto mediano entre medianas: 1.39%. Mayor cambio: 18.81% (disminuyó) en c_paralelo, N=256, c_paralelo_P4_T1.
Proyección S8 para N=2048: 288 MiB estimados para matrices (sin runtime ni stacks). Reserva provisional por delegación: 2026-11-18T09:00:00-05:00 a 2026-11-18T12:00:00-05:00 (hora de Lima); es una proyección inicial, no una medición de S8.

Intentos previos excluidos del análisis: `_03` se interrumpió al reaparecer Zoom; `_04` no midió porque quedó un lock de prueba huérfano. Ambos se conservaron aparte.

Ver `verificacion_cruzada.json`, `comparacion_reproduccion.csv`, los logs individuales `monitor_externo/`, `aceptacion_responsable.json` y `reserva_maquina.json`.
