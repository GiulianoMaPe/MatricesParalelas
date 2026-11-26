# Resumen de Resultados Experimentales — Sprint 8

**Responsable:** Integrante 7 — Andrés  
**Marco:** docs/protocolo_medicion.md §8 y docs/sprints/sprint-08.md  

Este directorio contiene los resúmenes estadísticos provisionales y definitivos, así como los reportes de auditoría de dispersión generados a partir de las observaciones crudas depositadas en `resultados/raw/`.

## Contenido

1. [`resumen_provisional.csv`](resumen_provisional.csv):
   Consolidado provisional con 31 columnas estándar (medianas, cuartiles $Q_1$ y $Q_3$, rango intercuartílico IQR, mínimo, máximo, speedup, eficiencia y rendimiento en GFLOPS) generado mediante [`scripts/summarize_results.ps1`](../../scripts/summarize_results.ps1).
2. [`dispersion_report.csv`](dispersion_report.csv):
   Reporte cuantitativo de dispersión relativa ($\text{RSD}_{\text{IQR}}$), rango extremo, coeficiente de variación paramétrico, detección de valores atípicos (vallas de Tukey) y clasificación de estabilidad (`EXCELENTE`, `ESTABLE`, `MODERADA`, `ALTA`).
3. [`../../docs/auditoria_dispersion_s08.md`](../../docs/auditoria_dispersion_s08.md):
   Informe técnico formal de auditoría de variabilidad y dictamen sobre propuestas de repeticiones justificadas conforme al protocolo §6.3.

## Procedencia y trazabilidad

- Host de evaluación oficial: `PCG1UL14N0` (AMD Ryzen 5 3600 6-Core Processor, 15.912 GB RAM, Windows 11 Pro build 26300.9711).
- Candidata de código congelada: Commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.
- Protocolo: 1 calentamiento (repetition=0, descartado) + 5 observaciones medidas en rondas alternadas.

## Campaña integrada de cierre

El [resumen integrado de 33 grupos](s08_oficial_integrada_03/resumen_estadistico.csv), el [CSV de dispersión](s08_oficial_integrada_03/dispersion.csv) y su [dictamen](s08_oficial_integrada_03/auditoria_dispersion.md) se generan exclusivamente a partir de la [campaña oficial única](../raw/s08_oficial_integrada_03/mediciones.csv). Las tablas anteriores conservan el análisis de la subcampaña de Go paralelo.
