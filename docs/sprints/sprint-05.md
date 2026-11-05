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

## Registro individual · I5 Fernando

- **Entregable:** [Informe de validación numérica](../validacion_numerica.md).
- **Pruebas:** `tests/compare_results_test.ps1`, Go secuencial Debug y Go paralelo Debug reproducidos; cinco fixtures por versión, todos con código 0 y `max_abs=max_rel=0`.
- **Criterio:** `atol=rtol=1e-9`; añadida cobertura explícita de esperado cero, diferencia aceptada por `atol` y `max_rel=Infinity`.
- **Evidencia C:** se recopilaron en el informe resultados previos del reporte de equivalencia y del reporte de particionado; la compilación local queda pendiente porque no se dispone de MSVC configurado. No se instaló software.
- **Revisión cruzada, coordinación, horas reales e issue/PR:** pendientes de registrar por el equipo.
- **Reproducción de C completada por I4 (Eva) · 04/11/2026:** sobre el commit `6c76be6`, con MSVC x64 14.43.34808, Windows SDK 10.0.26100.0, MS-MPI Runtime y SDK 10.1.12498.52 y Go 1.27.1. `test_windows.ps1` terminó con código 0 para `c_secuencial` y `c_paralelo` en Debug y Release, y para `-Version all` en Debug y Release (24 comparaciones por compilación). Todas dieron `max_abs=0` y `max_rel=0`. El detalle está en el [informe](../validacion_numerica.md#reproducción-de-c-y-ejecución-conjunta).
- **Revisión cruzada de I4 (Eva) a I5 · 04/11/2026:** el criterio documentado coincide con [docs/contrato.md](../contrato.md) (`1e-9 + 1e-9·|esperado|`) y con `scripts/compare_results.ps1` (`atol=rtol=1e-9`). El caso nuevo de esperado cero es correcto: `tests/compare_results_test.ps1` pasa con código 0. Para comprobar que detecta errores reales, fijé temporalmente `atol=0` en el comparador y el caso falló, como corresponde; después restauré el comparador. Completé el informe con la reproducción de C y la ejecución conjunta. Revisión conforme para el alcance de I5. Quedan pendientes el pull request, las horas reales y la aceptación del equipo.
