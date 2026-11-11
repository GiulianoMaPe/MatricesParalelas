# Sprint 6 Optimizar con evidencia

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 6 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Mejorar el rendimiento sin cambiar la corrección ni introducir comparaciones injustas.

Cierre: Cada cambio conservado tiene medición antes y después y pasa la batería común; se fija el algoritmo para la campaña.

## Trabajo de cada integrante

Integrante 1  Medir localidad y accesos del núcleo C secuencial (3 h). Aplicar como máximo una mejora justificada y documentar su efecto (3 h). Entregable: Comparativa de una optimización C. Ubicación: c_secuencial/src/matrix.c.

Integrante 2  Medir reparto OpenMP y configuraciones iniciales de P y T (3 h). Ajustar granularidad o copias y verificar que no se fuerce un único núcleo (3 h). Entregable: Comparativa del híbrido C. Ubicación: c_paralelo/src/matrix.c.

Integrante 3  Medir asignaciones y acceso a slices del Go secuencial (3 h). Reducir asignaciones evitables y comprobar equivalencia numérica (3 h). Entregable: Comparativa de una optimización Go. Ubicación: go_secuencial/matrix.go.

Integrante 4  Medir tamaño de bloque y coste del canal de Go paralelo (3 h). Ajustar bloques y cantidad de workers sin crear tareas por celda (3 h). Entregable: Comparativa de granularidad Go. Ubicación: go_paralelo/workers.go.

Integrante 5  Estimar memoria del proceso raíz y del resto de procesos (3 h). Medir el pico en tamaños piloto y fijar límites seguros para la campaña (3 h). Entregable: Tabla de memoria y capacidad. Ubicación: docs/memoria.md.

Integrante 6  Ejecutar pruebas de regresión después de cada cambio aceptado (3 h). Revisar diferencias de orden de bucles y oportunidades de optimización desigual (3 h). Entregable: Informe de equidad algorítmica. Ubicación: docs/equidad_algoritmica.md.

Integrante 7  Recopilar mediciones del piloto con metadatos completos (3 h). Descartar cambios sin mejora consistente o mantenerlos como experimento separado (3 h). Entregable: Registro de decisiones de rendimiento. Ubicación: docs/optimizaciones.md.

Integrante 8  Actualizar decisiones de diseño y su relación con la literatura (3 h). Definir qué cambios se conservan y los criterios para congelar el algoritmo (3 h). Entregable: Diseño validado y decisiones de optimización. Ubicación: docs/arquitectura.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-06.md.

## Registro de cierre

- Participantes y horas reales: en ejecución.
- Issues y pull requests: en ejecución.
- Pruebas y evidencias: en ejecución.
- Bloqueos y decisiones: algoritmo congelado para la campaña.
- Revision y criterio de aceptacion: en ejecución.

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h recopilación y análisis de mediciones del piloto en hardware nativo x64; 3 h redacción del informe técnico y registro formal de decisiones en `docs/optimizaciones.md`; 1 h revisión cruzada formal a Roberto I8 sobre `docs/arquitectura.md`; 1 h coordinación de acuerdos del sprint con Gerardo I6).
- **Issues y pull requests:** rama de trabajo `feature/s06-i07-registro-optimizaciones`. Pull request listo para apertura.
- **Entregable principal:** [`docs/optimizaciones.md`](../optimizaciones.md) (Registro de decisiones de rendimiento y evaluación de optimizaciones).
- **Pruebas y evidencias:**
  - Se recopilaron mediciones preliminares de la línea base piloto en hardware AMD Ryzen 7 8845HS (8C/16T, 16 GB RAM DDR5, Windows 11 Build 26300) cubriendo tamaños $N \in \{128, 256, 512, 1024\}$ con metadatos completos y esquema CSV unificado de 20 campos.
  - Se evaluaron formalmente seis propuestas de optimización (OPT-01 a OPT-06), cuantificando su impacto en rendimiento, sobrecostes de memoria y equidad algorítmica.
  - Se ratificó y congeló el orden canónico $i \to k \to j$ por su óptimo aprovechamiento de la jerarquía de memoria (accesos *stride-1* continuos en $B$ y $C$ y compatibilidad con auto-vectorización del compilador).
  - Se descartó el bloqueo/tiling manual por bloques de caché (BMM) tras comprobar que en $N \le 1024$ añade sobrecostes de bifurcación e indexación que degradan entre $4\%$ y $9\%$ el rendimiento y genera asimetría entre compiladores C y Go.
  - Se descartó la pre-transposición de $B$ por requerir $O(N^2)$ memoria adicional y violar el principio de inmutabilidad de solo lectura.
  - Se prohibieron intrínsecos SIMD manuales en C para evitar comparaciones asimétricas contra Go, preservando la equidad algorítmica.
  - Se validaron y congelaron las optimizaciones de pre-asignación en Go (cero alocaciones en el kernel) y particionado 1D en bloques de filas continuas ($N/W$ y $N/P$).
- **Bloqueos y decisiones:** Se formaliza el congelamiento algorítmico definitivo de las cuatro versiones para asegurar que las mediciones de los Sprints 7 y 8 reflejen fielmente el escalamiento de los modelos de paralelismo y no artefactos de sintonización espuria.
- **Revisión a I8 (Roberto):** Revisé exhaustivamente las Secciones 9 a 12 añadidas por Roberto en [`docs/arquitectura.md`](../arquitectura.md). La fundamentación teórica de la jerarquía de memoria (L1/L2/L3), el análisis de saltos en líneas de 64 bytes, la justificación de no empaquetamiento 2D frente a H-SUMMA y la formulación de los 5 Criterios Normativos de Congelamiento Algorítmico son impecables y sustentan con rigor científico las decisiones de rendimiento. El entregable de I8 queda **CONFORME**.
- **Revisión y criterio de aceptación:** Mi entregable técnico (`docs/optimizaciones.md`), la matriz de decisiones y la revisión cruzada quedan completados y conformes al Sprint 6.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h actualización de decisiones de diseño y fundamentación con la literatura científica, 3 h formulación de criterios de congelamiento algorítmico y evaluación de optimizaciones descartadas, 1 h coordinación general, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s06-i08-diseno-optimizaciones`.
- Pruebas y evidencias: Entregable `docs/arquitectura.md` completado y actualizado con las Secciones 9 a 12. Se fundamenta la jerarquía de memoria (L1/L2/L3), líneas de caché de 64 bytes y la superioridad de stride-1 en el orden canónico $i \to k \to j$ frente a $i \to j \to k$ (Dongarra et al., Hennessy & Patterson). Se analiza el particionado jerárquico comparado con H-SUMMA (Quintin & Wagner 2013) y la ausencia de sobrecostes de empaquetado 2D en el reparto 1D continuo por filas. Se fundamenta el modelo CSP de Go (Hoare, Golani et al. 2021). Se formulan las decisiones de diseño para descartar tiling manual y SIMD asimétrico en favor de la auto-vectorización del compilador y la equidad algorítmica. Se formaliza el Marco Normativo de Congelamiento Algorítmico en 5 criterios inviolables para las campañas de los Sprints 7 y 8.
- Bloqueos y decisiones: Se declara oficialmente congelado el algoritmo canónico $i \to k \to j$ en sus cuatro versiones (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`), prohibiendo alteraciones de bucles que distorsionen la comparabilidad de rendimiento.
- Revision y criterio de aceptacion: Entregable de I8 finalizado y conforme; listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly pendiente a la publicación de su PR de Sprint 6.

