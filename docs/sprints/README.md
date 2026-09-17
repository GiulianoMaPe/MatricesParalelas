# Diez sprints, ocho integrantes

Los archivos sprint-01.md a sprint-10.md corresponden a la
[guía vigente extraída](../guia-extraida.txt):
dos subtareas de 3 h por integrante, 1 h de revisión y 1 h de coordinación por semana.
Son 8 h/persona/sprint, 64 h/equipo/sprint, 80 h/persona y 640 h/equipo en total.
La preparación técnica previa del responsable queda fuera de estas 640 horas.
Las horas son estimaciones; registrar horas reales y reajustar alcance. Las fechas
se asignarán al acordar la semana de inicio. Las esperas de mediciones consumen
tiempo de máquina y no necesariamente horas activas.

Los identificadores corresponden a los registros existentes de docs/entorno/:

| Identificador | Integrante |
| --- | --- |
| I1 | Yessly |
| I2 | Sebastian |
| I3 | Giuliano |
| I4 | Eva |
| I5 | Fernando |
| I6 | Gerardo |
| I7 | Andres |
| I8 | Roberto |

I1 revisa I2,
I2 revisa I3, hasta I8 que revisa I1. Coordina I1 en S1, I2 en S2, etc.; I1 en S9
e I2 en S10. Cada issue debe tener objetivo, entregable y criterio de aceptación.

| Sprint | Resultado esperado |
| --- | --- |
| 1 | Diagnóstico funcional y requisitos de las cuatro versiones |
| 2 | Interfaces y casos de prueba revisados y completados |
| 3 | Referencias secuenciales correctas |
| 4 | MPI/OpenMP y workers Go correctos |
| 5 | Validación integral y manejo de errores |
| 6 | Optimización con evidencia y estabilidad |
| 7 | Mediciones automatizadas y piloto validado |
| 8 | Campaña oficial con datos completos |
| 9 | Análisis, gráficos e informe |
| 10 | Reproducción y entrega |

Cada sprint depende del anterior; S1 parte de la base recibida. Días 1 y 2:
acuerdos y avance inicial; días 3 y 4: desarrollo y pruebas; día 5: revisión y cierre.
Si una tarea ya está completa, sustituirla por revisión funcional, casos límite o
documentación del mismo módulo. No duplicar trabajo previo para cumplir la lista.

## Entregables y rutas pendientes

Los documentos de cada sprint incluyen las ocho asignaciones y sus ubicaciones
exactas. Los archivos siguientes se completan o crean durante el plan; que aún no
existan los futuros entregables no significa que falte instalar herramientas.

| Sprint | Rutas clave |
| --- | --- |
| S1 | `docs/diagnostico_c_secuencial.md`, `docs/diagnostico_c_paralelo.md`, `docs/diagnostico_go_secuencial.md`, `docs/diagnostico_go_paralelo.md`, `docs/requisitos.md` |
| S1–S2 | `docs/formato_datos.md`, `docs/protocolo_medicion.md`, `tests/fixtures/` |
| S2 | `docs/arquitectura.md`, `docs/bibliografia.md` |
| S3 | Núcleos secuenciales, generadores, `scripts/compare_results.ps1`, `docs/validacion_secuencial.md` |
| S4–S5 | Núcleos paralelos, equivalencia y validación integral |
| S6 | Optimización, memoria y equidad algorítmica |
| S7 | Ampliar `scripts/bench_windows.ps1`, crear `scripts/summarize_results.ps1`, guardar `resultados/piloto/` y documentar `docs/campana.md` |
| S8–S10 | Datos oficiales, análisis, informe y actas de reproducción y entrega |

## Cierre y evidencias

Los registros de cierre continúan pendientes hasta que cada entregable cumpla el
contrato, pase sus pruebas y otra persona lo revise. Conservar evidencias individuales
en `sprint-NN.md`. Una prueba de instalación no valida un algoritmo ni cierra S1;
el nuevo S1 exige diagnósticos funcionales, pendientes priorizados y casos de
referencia comprobados. No aceptar tiempos con salidas matemáticas incorrectas.
