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

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

### Entrega de I3 · Giuliano

- **Entregable** · Sección Go secuencial para el informe, con tiempos y dispersión, crecimiento al aumentar N, asignaciones y límites del runtime. [Análisis de Go secuencial](../analisis_go_secuencial.md).
- **Evidencia** · Se verificó el SHA-256 del CSV oficial contra el manifiesto S8 y se recalcularon los estadísticos de sus 15 mediciones Go secuencial. El resumidor del repositorio reprodujo los 33 grupos del CSV publicado. Las asignaciones citadas provienen del diagnóstico de laboratorio S6 en N=17. [Campaña integrada](../../resultados/raw/s08_oficial_integrada_03/mediciones.csv) · [Resumen integrado](../../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv).
- **Rama** · `feature/s09-i03-analisis-go-secuencial`. Issue y PR pendientes.
- **Revisión cruzada** · Pendiente la revisión de I2 (Sebastián) a esta entrega. I3 revisará la sección de Go paralelo de I4 (Eva) cuando esté disponible. La revisión comprobará referencias secuenciales de la misma campaña, el cálculo de speedup y eficiencia por workers, y los límites de la interpretación.
- **Coordinación y horas** · Entregable listo para integración por I7. Las horas reales, la coordinación con I1 y la aceptación quedan pendientes de registro.
