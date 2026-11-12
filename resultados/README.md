# Resultados

Las cuatro versiones implementan el producto y su validación. La automatización
completa del piloto corresponde a S7 y la campaña oficial a S8; consultar
[protocolo](../docs/protocolo_medicion.md).

S7 guarda ensayos en `piloto/`; S8 conserva la campaña oficial en `raw/`. Los
resúmenes y gráficos deben derivarse de observaciones reales y trazables.

`experimentos/` guarda mediciones de optimización del S6 que no forman parte de
la campaña; por ejemplo, `granularidad_go/` es la evidencia de
[docs/granularidad_go.md](../docs/granularidad_go.md).

## Evidencia del cierre S6

- `diagnostico/s06/`: núcleos Linux, intentos A/B separados; no son MPI Windows.
- `experimentos/granularidad_go/`: entrega histórica I4 en otro equipo; 189 filas
  mezclan relojes e infringen kernel<=total. Se conservan intactas como exploración,
  sin incorporarlas al CSV contractual de campaña.
- `piloto/s06_windows_20261112/`: aceptación exploratoria Windows S6, con plan,
  fuentes/hashes, 540 corridas, 33 perfiles separados, diagnóstico MPI y regresión.
  No equivale al piloto completo de S7 ni a datos oficiales S8.

Véanse [aceptación Windows](../docs/cierre_s06_windows.md) y
[revisión](../docs/revision_s06.md).
