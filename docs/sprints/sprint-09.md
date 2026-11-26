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

#### Integrante 4 (Eva)

- **Participantes y horas reales:** Eva Moreno (I4). El plan contempla 3 h de análisis del speedup de Go según workers y dimensión, 3 h para explicar granularidad, sincronización y sobrecostes, 1 h de revisión cruzada a I5 (Fernando, `resultados/graficos/`) y 1 h de coordinación (coordina I1 en S9). Las horas reales quedan pendientes de confirmar.

- **Issues y pull requests:** rama de trabajo `feature/s09-i04-analisis-go-paralelo`. La revisión corresponde a I3 (Giuliano) según la rotación.

- **Entregable:** [Sección de rendimiento Go paralelo](../analisis_go_paralelo.md).
  - **Datos.** Usa la campaña integrada `s08_oficial_integrada_03` como fuente principal, igual que el resumen de I7 y el análisis de Go secuencial de I3, y el lote `s08_i04_go_paralelo_01` como reproducción. Las dos son de la PC oficial y de la candidata `97ccc98`. Los speedups se calculan siempre dentro de una misma campaña.
  - **Conclusiones**, cada una con sus datos y condiciones:
    - C1: S(W1) de 1,94–1,98 con W=2 y de 3,55–3,85 con W=4.
    - C2: S(seq) de 1,32–1,38 con W=2 y de 2,39–2,60 con W=4; con W=1, 0,67–0,71.
    - C3: el kernel paralelo con W=1 es 1,41–1,49 veces más lento que el secuencial, por la firma con punteros.
    - C4: la coordinación queda bajo la resolución del reloj de ~0,5 ms.
    - C5: inflación de trabajo del 4–17 % con W=4, sin causa atribuida.
    - C6: reproducibilidad entre campañas de ±1,7 % en un hilo y hasta 9,1 % con varios workers.

- **Pruebas y evidencias:**
  - [`scripts/analisis_go_paralelo.ps1`](../../scripts/analisis_go_paralelo.ps1) regenera [`analisis_go_paralelo.csv`](../../resultados/resumen/s09_i04_go_paralelo/analisis_go_paralelo.csv) desde los `mediciones.csv` preservados y registra el SHA-256 de cada fuente. Sus medianas, Q1, Q3, `kernel_s` y speedups coinciden exactamente con [`resumen_estadistico.csv`](../../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv) de I7 en los 12 grupos Go.
  - Cada cifra de las tablas del documento se cotejó con ese CSV. La comprobación detectó tres máximos de `go_secuencial` mal transcritos y una magnitud exagerada; ambos se corrigieron antes de publicar.
  - Diagnóstico C3 (**no oficial**, en el equipo de I4) en [`resultados/diagnostico/s09_i04_go_paralelo/`](../../resultados/diagnostico/s09_i04_go_paralelo/README.md):
    - el ensamblador muestra 4 recargas de cabecera por iteración en la versión por puntero y ninguna en la copia por valor;
    - las comprobaciones de límites son iguales en ambas;
    - el benchmark de una goroutine da un cociente de 1,51 con N=1024 (1,49 en la campaña oficial) y 1,63 con N=512;
    - las dos firmas producen el mismo resultado bit a bit.
  - [`go_paralelo/sprint09_kernel_test.go`](../../go_paralelo/sprint09_kernel_test.go) solo añade pruebas; el código de producción no cambia.

- **Bloqueos y decisiones:**
  - No se modificó el kernel. Pasar las matrices por valor eliminaría las recargas, pero el algoritmo está congelado y el cambio exigiría una modificación justificada y una campaña nueva. Se documenta como trabajo futuro.
  - No se atribuye la inflación con W=4 a caché, frecuencia ni temperatura, porque no se midieron.
  - Para la discusión C/Go de I6: el factor de ~1,45 del kernel Go paralelo es una amenaza a la validez, porque se debe a un detalle de implementación y no al lenguaje ni a CSP.
  - Para los gráficos de I5: la tabla reproducible ya contiene medianas, cuartiles y speedups por campaña.

- **Revisión y criterio de aceptación:** la sección cumple el criterio del sprint. Las conclusiones derivan de los CSV preservados, identifican campaña y condiciones, y se pueden regenerar con un comando. Quedan pendientes la revisión de I3, mi revisión cruzada de los gráficos de I5 cuando se publiquen, las horas reales y la integración en el informe (I7).
