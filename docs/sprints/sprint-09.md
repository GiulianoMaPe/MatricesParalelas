# Sprint 9 Analizar y redactar los resultados

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 9 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Transformar datos en conclusiones verificables y preparar el informe técnico.

Cierre: Los gráficos derivan de los CSV preservados y cada conclusión identifica los datos y las condiciones que la sostienen.

## Trabajo de cada integrante

Integrante 1  Analizar tiempos y escalabilidad de la referencia C (3 h). Redactar el apartado de implementación y límites de la base C (3 h). Entregable: Sección C secuencial del informe. Ubicación: docs/analisis_c_secuencial.md.

Integrante 2  Analizar speedup y eficiencia del híbrido según P y T (3 h). Explicar comunicación, localidad y saturación observadas (3 h). Entregable: Sección de rendimiento C paralelo. Ubicación: docs/analisis_c_paralelo.md.

Integrante 3  Analizar tiempos y asignaciones relevantes de Go secuencial (3 h). Redactar decisiones de implementación y límites del runtime (3 h). Entregable: Sección Go secuencial del informe. Ubicación: docs/analisis_go_secuencial.md.

Integrante 4  Analizar speedup de Go según workers y dimensión (3 h). Explicar granularidad, sincronización y posibles sobrecostes (3 h). Entregable: Sección de rendimiento Go paralelo. Ubicación: docs/analisis_go_paralelo.md.

Integrante 5  Generar gráficos finales con unidades y dispersión (3 h). Comprobar que etiquetas y ejes no exageren diferencias (3 h). Entregable: Gráficos reproducibles y pies explicativos. Ubicación: resultados/graficos/.

Integrante 6  Comparar C y Go en tiempos absolutos con condiciones equivalentes (3 h). Redactar amenazas a la validez y separar PCs o configuraciones distintas (3 h). Entregable: Discusión comparativa y limitaciones. Ubicación: docs/comparacion.md.

Integrante 7  Integrar metodología, tablas y anexos en el informe (3 h). Comprobar referencias y vínculo con al menos un artículo IEEE (3 h). Entregable: Informe técnico integrado. Ubicación: docs/informe_final.docx.

Integrante 8  Preparar demostración y guion repartido entre ocho personas (3 h). Revisar trazabilidad de afirmaciones del informe a los datos originales (3 h). Entregable: Guion de exposición y lista de correcciones. Ubicación: docs/guion_exposicion.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-09.md.

## Registro de cierre

- Participantes y horas reales:
  - I1 (Yessly): 3 h — análisis de tiempos, escalabilidad, implementación y límites de c_secuencial en docs/analisis_c_secuencial.md a partir de s08_oficial_integrada_03. Resto de integrantes pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias:
  - Verificación de 18 filas oficiales de `c_secuencial` (1 calentamiento + 5 repeticiones en N=512, 1024, 2048) en `resultados/raw/s08_oficial_integrada_03/mediciones.csv` con estado `OK`.
  - Validación del resumen estadístico (`resumen_estadistico.csv`) y de la auditoría de dispersión (`auditoria_dispersion.md`), confirmando dispersión EXCELENTE en N=512 (0,46 %), ALTA (Alerta) en N=1024 (10,11 %, conservada conforme a protocolo §6.3) y ESTABLE en N=2048 (2,61 %).
  - Comprobación en código congelado (`97ccc981...`) del orden de bucles `i,k,j`, compilación MSVC Release (`/std:c11 /O2 /MD /fp:precise /W4 /WX /MACHINE:X64`) sin OpenMP ni MPI, buffers contiguos row-major en `double`, cronometraje con `QueryPerformanceCounter` y validación de capacidad preventiva para 4 buffers con techo `MATRIX_MAX_N = 4096`.
- Bloqueos y decisiones:
  - Se declaró `s08_oficial_integrada_03` como la única fuente oficial de cómputo para el informe, preservando el lote previo `resultados/raw/c_secuencial.csv` de 2026-11-19 como corrida independiente sin mezclar datos.
  - Se separaron estrictamente los hechos medidos (tiempos, escalabilidad de 8,53× y 18,81×, caída de 11,42 a 4,51 GFLOP/s) de las hipótesis explicativas (saturación de caché L3/ancho de banda DRAM y desplanificación en N=1024), haciendo constar explícitamente que la campaña careció de contadores de hardware (cache misses).
- Revision y criterio de aceptacion: pendiente.
