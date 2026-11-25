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

## 25/11/2026

- Se incorporaron los lotes de C secuencial y Go secuencial, el extractor de C paralelo y el control realizado en la PC de I1. Los CSV y manifiestos de las subcampañas permanecen en sus rutas de origen.
- Se inició `s08_oficial_integrada_01` a las 14:26 (Lima) en `PCG1UL14N0`, candidata limpia `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, semilla 42, Ryzen 5 3600, 6 núcleos físicos, alimentación AC y plan Equilibrado.
- El plan incluye N=512/1024/2048, W=1/2/4, 33 calentamientos y 165 mediciones en rondas alternadas. El timeout por corrida se fijó en 900 s por la duración observada de los intentos MPI con N=2048.
- El arnés registra carga y memoria disponible por corrida. La temperatura de CPU figura como no disponible. El estado final, la extracción de C paralelo y el inventario SHA-256 quedan sujetos a la verificación de este intento.
