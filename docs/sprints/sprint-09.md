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

## Registro individual · I6 Gerardo · 26/11/2026

- **Participantes y horas:** Gerardo (I6). Plan: 3 h de comparación C/Go en tiempos absolutos, 3 h de amenazas a la validez y separación de fuentes, 1 h de revisión a I7 y 1 h de coordinación. **Horas reales: por confirmar por Gerardo.**
- **Issues y pull requests:** pendiente de abrir el PR del entregable.
- **Entregable:** [Discusión comparativa y limitaciones](../comparacion.md), redactada con asistencia de Claude. Cada tabla se generó por script a partir del [resumen oficial](../../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv). Antes de usar ese resumen, lo recalculé de forma independiente desde el [CSV crudo](../../resultados/raw/s08_oficial_integrada_03/mediciones.csv): los 33 grupos coinciden en mediana de `kernel_s`, mediana de `total_s`, speedup y GFLOPS, con una diferencia relativa máxima de 7×10⁻⁷.
- **Pruebas y evidencias:** las 198 filas oficiales tienen `validation_status=OK` y cumplen `0 ≤ kernel_s ≤ total_s`. Las conclusiones C1–C6 citan la sección, los datos y las condiciones que las sostienen. Las fuentes de otras PCs y configuraciones están en la tabla de separación (§5) y no intervienen en las conclusiones. El control Go de I6 (§6) solo se usa para comprobar consistencia.
- **Bloqueos y decisiones:** no hay contadores de caché, temperatura de CPU ni perfiles de instrucciones. Las causas de la caída de GFLOPS de C en N=2048 y del coste de P1/T1 frente a C secuencial quedan como hipótesis explícitas, no como resultados. Los grupos Go por debajo de 100 ms (N=512) se muestran, pero no sostienen conclusiones.
- **Coordinación:** dejo a Andrés (I7) las tablas y las conclusiones C1–C6 para integrarlas en el informe, y a Fernando (I5) la indicación de que los gráficos usen `total_s` con IQR y no mezclen PCs. Para Roberto (I8), cada afirmación remite a un archivo de datos trazable.
- **Revisión a I7 (Andrés):** su entregable de S9, `docs/informe_final.docx`, todavía no existe en el repositorio. La revisión queda **pendiente hasta que lo entregue**. Comprobaré que la metodología cite el protocolo v1.3, que las tablas coincidan con el resumen oficial, que no se mezclen PCs y que haya al menos un artículo IEEE vinculado.
- **Revisión recibida de I5:** pendiente de Fernando (I5).
