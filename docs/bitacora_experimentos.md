# Bitácora de experimentos — Sprint 8

## 24/11/2026

- Se completó el inventario técnico local de I6 en `docs/entorno/6-gerardo.md`.
- CPU local: Intel i3-12100F, 4 núcleos físicos y 8 lógicos.
- RAM física: 16 GB.
- Sistema: Windows 10 Pro for Workstations, build 26300.
- Plan activo: Economizador.
- Herramientas disponibles: Go 1.27.1, Git 2.51.2.1 y VS Code 1.147.0.
- No se detectaron cl.exe ni herramientas MS-MPI activas.
- La raíz descargada no contiene metadatos Git; no se pudo verificar un commit local.
- `go test` pasó para los módulos secuencial y paralelo de Go.
- Se generó `resultados/resumen/go_paralelo_resumen.csv` desde el CSV oficial ya recibido.
- No se alteró `resultados/raw/go_paralelo.csv` ni su manifiesto.

## Estado

La campaña Sprint 8 sigue incompleta. Solo el lote Go paralelo de I4 está presente como CSV oficial.
Las campañas C secuencial, C paralelo y Go secuencial, el control independiente de I6 y el congelamiento integral de `raw/` siguen pendientes.
