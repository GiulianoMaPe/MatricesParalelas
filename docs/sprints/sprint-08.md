# Sprint 8 Ejecutar la campaña oficial

Estado: entrega técnica I3 (Giuliano/Go secuencial) completa y verificada; revisión I2 pendiente. La campaña integral y las demás entregas del equipo siguen pendientes. Plan de desarrollo de la [guía vigente](../guia-extraida.txt).

Semana 8 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Reunir todos los datos medidos con una versión fija y condiciones registradas.

Cierre: Cada configuración prevista tiene cinco observaciones válidas o una exclusión justificada; los CSV originales están preservados.

## Trabajo de cada integrante

Integrante 1  Ejecutar y supervisar los lotes de C secuencial (3 h). Revisar integridad y metadatos y repetir solo fallos justificados (3 h). Entregable: CSV originales de C secuencial. Ubicación: resultados/raw/c_secuencial.csv.

Integrante 2  Ejecutar y supervisar las combinaciones del híbrido C (3 h). Verificar participación de procesos e hilos y registrar anomalías (3 h). Entregable: CSV originales de C paralelo. Ubicación: resultados/raw/c_paralelo.csv.

Integrante 3 (Giuliano/I3)  Ejecutar y supervisar la campaña Go secuencial (3 h). Revisar equivalencia de entradas y condiciones de ejecución (3 h). Entregable: CSV de Go secuencial derivado sin modificar el CSV original de la campaña integrada. Ubicación: `resultados/raw/go_secuencial.csv`; conservar como fuente `resultados/raw/<campaign_id>/mediciones.csv`. Véase el [plan I3 de S8](sprint-08-i03-plan.md).

Integrante 4  Ejecutar y supervisar los lotes de Go paralelo (3 h). Revisar workers efectivos y estabilidad de las repeticiones (3 h). Entregable: CSV originales de Go paralelo. Ubicación: resultados/raw/go_paralelo.csv.

Integrante 5  Auditar completitud y validez numérica de los cuatro lotes (3 h). Clasificar fallos sin borrar datos y generar inventario de observaciones (3 h). Entregable: Reporte de calidad de datos. Ubicación: docs/calidad_datos.md.

Integrante 6  Registrar hardware, carga del sistema y configuración de cada sesión (3 h). Repetir un subconjunto de control en otra PC con etiqueta separada (3 h). Entregable: Metadatos y control independiente. Ubicación: docs/entorno/.

Integrante 7  Generar resúmenes provisionales y detectar dispersión anormal (3 h). Proponer y documentar repeticiones justificadas sin seleccionar solo los mejores tiempos (3 h). Entregable: Resumen provisional auditado. Ubicación: resultados/resumen/.

Integrante 8  Verificar trazabilidad desde commit hasta cada archivo CSV (3 h). Congelar la carpeta raw y actualizar bitácora de experimentos (3 h). Entregable: Manifiesto de resultados y bitácora. Ubicación: docs/bitacora_experimentos.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-08.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

### I3 · Giuliano · 17/11/2026

- Entrega técnica: [Go secuencial y resultados tabulados](../../resultados/raw/s08_i03_go_secuencial_03/README.md),
  18 observaciones válidas (3 warmups + 15 medidas), cinco medidas únicas por
  N=512/1024/2048, semilla 42, workers=GOMAXPROCS=1.
- Fuente oficial: `s08_i03_go_secuencial_03`, candidata `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`,
  subplan con **72/72 corridas OK**, 12 grupos completos y 0 exclusiones.
  Se preservan CSV, plan, entorno, manifiestos, fuentes/hashes y logs/ranks.
- [Plan y registro individual](sprint-08-i03-plan.md): intentos previos conservados;
  timeout ampliado de 300 a 900 s sin cambiar los binarios ni sustituir filas.
- Verificador común y revisión I3: COMPLETE/VERIFIED; extracción idéntica a
  sus líneas fuente, veinte columnas, parámetros, UTC, tiempos y entorno hijo válidos.
- GPU medida; CPU sin lectura. Rango térmico y límites documentados junto a los resultados.
- Revisión I2→I3: pendiente; revisor asignado `@SebastianMalca`; [PR #58](https://github.com/GiulianoMaPe/MatricesParalelas/pull/58).
- Horas reales/coordinación: no confirmadas para S8; presupuesto I3 de 8 h.
- Duración de los controles N=2048 superior al timeout inicial: revisar presupuesto de máquina y reserva de la campaña integral con I5/I6.
- El alcance es I3 con controles: el resto de combinaciones, la auditoría y la
  congelación del equipo y su cierre de sprint siguen pendientes.
