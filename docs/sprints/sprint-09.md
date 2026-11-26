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

## Registros individuales

### Integrante 7 (Andrés) · 26/11/2026

- **Participantes y horas:** Andrés (I7). Plan: 3 h de integración de metodología, tablas y anexos en el informe, 3 h de comprobación de referencias y vínculo con artículo IEEE, 1 h de revisión cruzada (recibe revisión de I6 Gerardo y revisa el guion de I8 Roberto) y 1 h de coordinación (coordina I1). Total: 8 h.
- **Issues y pull requests:** rama de trabajo `feature/s09-i07-informe-final`.
- **Entregable:** [Informe técnico integrado (Markdown)](../informe_final.md) y [Informe técnico integrado (Word)](../informe_final.docx), generados con el script reproducible [`scripts/generate_informe_final.py`](../../scripts/generate_informe_final.py).
  - **Metodología y datos:** Cita y aplica rigurosamente el protocolo v1.3. Se sustenta al 100% en la campaña oficial congelada `s08_oficial_integrada_03` (198 mediciones válidas, 33 grupos, máquina `PCG1UL14N0`, commit `97ccc98`), sin mezclar fuentes de otras PCs ni ensayos piloto anteriores.
  - **Vínculo formal con artículos IEEE:** Vinculación directa con Quintin et al. (IEEE ICPP 2013, DOI: 10.1109/ICPP.2013.89) sobre modelos jerárquicos de comunicación de dos niveles y sobrecoste de procesos vs hilos en un solo nodo, y con Hérault et al. (IEEE ScalA 2019, DOI: 10.1109/ScalA49573.2019.00010) sobre contigüidad espacial, recorrido i,k,j y principio de único escritor en C.
  - **Síntesis integral:** Consolida los análisis de C secuencial (I1), C paralelo híbrido (I2), Go secuencial (I3), Go paralelo con workers (I4), los 4 gráficos reproducibles (I5) y la discusión comparativa y conclusiones verificables C1–C6 (I6).
- **Pruebas y evidencias:**
  - Script [`scripts/generate_informe_final.py`](../../scripts/generate_informe_final.py) genera tanto el Markdown como el documento Word `.docx` con tablas estilizadas, formato IEEE y trazabilidad completa.
  - Todas las cifras de las tablas del informe coinciden bit a bit con [`resumen_estadistico.csv`](../../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv).
- **Bloqueos y decisiones:** Se optó por mantener la redacción en Markdown y compilar a DOCX usando `python-docx` para permitir tanto control de versiones en Git como entrega académica en formato Word/Office.
- **Revisión y criterio de aceptación:** El entregable cumple plenamente con los criterios de aceptación del sprint: integra metodología, tablas oficiales, anexos y doble vínculo IEEE. Queda disponible para la revisión cruzada de I6 (Gerardo).

