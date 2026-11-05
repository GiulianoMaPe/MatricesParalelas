# Sprint 5 Integrar y fortalecer la corrección

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 5 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Eliminar diferencias de formato, manejo de errores y validación entre las cuatro carpetas.

Cierre: La batería común pasa en las cuatro versiones, los fallos esperados terminan sin bloqueos y existe un reporte reproducible.

## Trabajo de cada integrante

Integrante 1  Revisar desbordamientos y errores de asignación en C secuencial (3 h). Corregir límites de dimensión y asegurar limpieza en cada error (3 h). Entregable: C secuencial robusto y casos negativos. Ubicación: c_secuencial/src/ y tests/.

Integrante 2  Revisar errores colectivos y finalización del híbrido (3 h). Probar procesos sin filas y fallos controlados sin esperas indefinidas (3 h). Entregable: C paralelo robusto y registro de fallos. Ubicación: c_paralelo/src/ y tests/.

Integrante 3  Revisar formatos, índices y errores en Go secuencial (3 h). Corregir compatibilidad de entrada y salida frente a C (3 h). Entregable: Go secuencial consistente. Ubicación: go_secuencial/input.go.

Integrante 4  Revisar límites de workers y propiedad de buffers Go (3 h). Probar repeticiones largas y corregir bloqueos o resultados variables (3 h). Entregable: Go paralelo estable. Ubicación: go_paralelo/workers.go.

Integrante 5  Completar casos negativos del comparador y tolerancias (3 h). Calcular error máximo por versión y documentar el criterio numérico (3 h). Entregable: Informe de validación numérica. Ubicación: docs/validacion_numerica.md.

Integrante 6  Ampliar test_windows.ps1 con las pruebas matemáticas completas (3 h). Detectar fallos mediante códigos de salida y reportar el caso exacto (3 h). Entregable: Batería integral automatizada. Ubicación: scripts/test_windows.ps1.

Integrante 7  Verificar que las cuatro mediciones usan límites equivalentes (3 h). Separar validación y escritura de los intervalos medidos (3 h). Entregable: Auditoría del protocolo de tiempo. Ubicación: docs/protocolo_medicion.md.

Integrante 8  Reproducir los casos de validación en una segunda PC preparada (3 h). Analizar diferencias funcionales y resolver errores del programa (3 h). Entregable: Acta de validación independiente. Ubicación: docs/validacion_independiente.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-05.md.

## Registro de cierre

- Participantes y horas reales: pendiente.
- Issues y pull requests: pendiente.
- Pruebas y evidencias: pendiente.
- Bloqueos y decisiones: pendiente.
- Revision y criterio de aceptacion: pendiente.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h reproducción de la batería de pruebas en segunda PC física independiente, 3 h análisis de casos negativos, códigos de salida y elaboración del acta, 1 h coordinación general, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s05-i08-validacion-independiente`.
- Pruebas y evidencias: Entregable `docs/validacion_independiente.md` completado con evidencia empírica en Windows 11 (AMD Ryzen 5 7600X, 16 GB DDR5, host `PC-PETEL`). Se ejecutaron las suites de equivalencia (`test_equivalencia.ps1` en Debug y Release: 25 casos OK con $max\_abs = 0.0$ y $max\_rel = 0.0$), pruebas unitarias Go (`go_secuencial` y `go_paralelo` PASS), pruebas de invariantes de partición C (`partition_test.c` y `verify_partition_design.ps1` PASS con 0 fallos), y matriz de inyección de errores (ERR-01 a ERR-10) confirmando que entradas inválidas terminan limpiamente con código 1 en < 50 ms.
- Bloqueos y decisiones: Se certifica que las cuatro referencias cumplen los contratos numéricos y de cronometría monotónica. La lógica algorítmica de C se comprobó de forma independiente con GCC C11 ante la falta de enlace con MSVC en esta máquina.
- Revision y criterio de aceptacion: Entregable de I8 finalizado y conforme; listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly pendiente a la publicación de su PR de C secuencial.

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (I7). Total: 8 h reales (3 h verificación y auditoría comparativa de límites de cronometría en las cuatro versiones; 3 h verificación de aislamiento estricto de I/O, generación y validación matemática, y elaboración del informe técnico en `docs/protocolo_medicion.md`; 1 h revisión cruzada formal a Roberto I8 sobre `docs/validacion_independiente.md`; 1 h coordinación de acuerdos del equipo).
- **Issues y pull requests:** rama de trabajo `feature/s05-i07-auditoria-protocolo-tiempo`. Pull request listo para apertura.
- **Entregable principal:** [`docs/protocolo_medicion.md`](../protocolo_medicion.md) actualizado a versión 1.3 con la Sección 9 ("Informe de Auditoría del Protocolo de Tiempo").
- **Pruebas y evidencias:**
  - Se auditó exhaustivamente la instrumentación temporal en el código fuente de los cuatro módulos (`c_secuencial/src/main.c`, `c_paralelo/src/main.c`, `go_secuencial/main.go`, `go_paralelo/main.go` y `go_paralelo/workers.go`).
  - Se comprobó que `kernel_s` mide exclusivamente la acumulación aritmética canónica $i \to k \to j$: directa en las referencias secuenciales, región OpenMP local reducida con `MPI_Reduce(..., MPI_MAX)` en C híbrido, y suma de intervalos por bloque en workers Go agregados por el máximo individual (`maxKernel`).
  - Se verificó que `total_s` inicia estrictamente en T0 (antes de vaciar C / tras la barrera inicial en MPI) y finaliza en T1 (al terminar el cómputo o en `wg.Wait()` / `MPI_Gatherv`).
  - Se certificó que el parseo de argumentos, generación LCG, lectura de matrices, cálculo desacoplado de la referencia ($i \to j \to k$), validación matemática ($atol=10^{-9}, rtol=10^{-9}$), escritura de archivos de salida (`--output`) y emisión del CSV de 20 columnas se ejecutan **estrictamente fuera** de los intervalos cronometrados.
  - Se confirmó en hardware real (Windows 11 x64, AMD Ryzen 7 8845HS) el cumplimiento sistemático del invariante $0.0 \le \text{kernel\_s} \le \text{total\_s}$ y el rechazo inmediato de duraciones negativas o no finitas.
- **Bloqueos y decisiones:** Se constató que las barreras iniciales (`MPI_Barrier`) y el setup de canales de Go están adecuadamente delimitados sin distorsionar el tiempo de kernel, garantizando condiciones de comparación homogéneas y equitativas para las campañas futuras (S7/S8).
- **Revisión a I8 (Roberto):** Revisé exhaustivamente el acta [`docs/validacion_independiente.md`](../validacion_independiente.md). La reproducción empírica sobre hardware independiente (`PC-PETEL`, AMD Ryzen 5 7600X, DDR5) confirma la estabilidad, equivalencia numérica ($max\_abs = 0.0$, $max\_rel = 0.0$) y terminación limpia con código 1 ante inyección de fallos (ERR-01 a ERR-10). La verificación de cronometría monotónica coincide punto por punto con los hallazgos de la auditoría de I7. El entregable de I8 queda **CONFORME**.
- **Revisión y criterio de aceptación:** Mi entregable técnico (`docs/protocolo_medicion.md` v1.3), las evidencias de auditoría y la revisión cruzada quedan completados y conformes al Sprint 5.


