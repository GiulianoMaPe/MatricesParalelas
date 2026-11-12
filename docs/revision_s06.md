# Revisión de integración del Sprint 6

Revisión por Codex encargada expresamente por el responsable el 12/11/2026.
Sustituye para este cierre la revisión humana cruzada solicitada en el flujo;
no se atribuyen conformidades personales a integrantes que no las emitieron.
La revisión comprende las ramas I4/I7 recibidas y la base I8 ya integrada.
La aceptación final depende de los códigos y datos enlazados en el
[acta](sprints/sprint-06.md); este documento no sustituye una ejecución fallida.

## Hallazgos y resolución

| Hallazgo | Resolución | Comprobación |
| --- | --- | --- |
| I4 mezcla QPC en total con el reloj de worker en kernel; 189/720 filas históricas infringen kernel<=total. | Conservar los CSV originales, limitar su interpretación y corregir el arnés: total/kernel monotónicos; QPC auxiliar; rechazo explícito de tiempos inválidos. | Auditoría histórica y 72 corridas pequeñas del arnés corregido en `verification/`. |
| I4 generaliza la resolución observada en otro Windows/toolchain. | Atribuir el resultado a su equipo y medir resolución local de nuevo. | `verification/clock-resolution.json`; S7 repetirá en su equipo final. |
| I7 presenta porcentajes de tiling/orden de bucles sin las observaciones originales para reconstruirlos. | Conservar la entrega atribuida como antecedente; usar solo los originales trazables del cierre para decisiones cuantitativas. | Registro vigente en `optimizaciones.md`, anexo original I7 y resumen Windows. |
| I7 exige igualdad por bits o error absoluto fijo, y llama significativo al 5%. | Mantener tolerancia absoluta+relativa por celda y considerar dispersión/consistencia sin inventar pruebas estadísticas. | Contrato, pruebas comunes, originales por corrida. |
| I7 declara canal fuera de T0, ausencia de GC y cero false sharing. | Corregir la interpretación: matrices/slots antes de T0; pool/canal/despacho/cierre/espera dentro; no garantizar fenómenos no instrumentados. | Inspección de `execute`, `multiplyParallelKernelBlocks` y `worker`. |
| I7 atribuye a la transposición un aumento fijo del 50% y una violación necesaria de inmutabilidad. | Excluirla como decisión de alcance/equidad; una copia a otro buffer no modifica necesariamente la entrada y su coste depende de los buffers de referencia. | Modelo de cuatro matrices y `memoria.md`. |
| El CSV MPI contiene un agregado, insuficiente para observar filas/hilos por rank. | Diagnóstico optativo por rank/PID después de tiempos y validación colectiva, con afinidad y kernel local; vacío = cero hilos de cálculo. | Perfiles MPI y verificación con resto y P>N. |
| La afinidad predeterminada de un lanzador puede restringir OpenMP. | Desactivarla explícitamente en exploraciones y comprobar la máscara real de cada rank. | `-affinity_layout 0`; archivos `rank-*.json`. |
| Solo existía captura exploratoria Linux. | Añadir captura Windows S6 con plan previo, archivos separados, timeout, hashes, fuentes archivadas y perfiles aparte. | `sprint06_windows.ps1/.py`, plan y evidencia original. |
| No estaba probado que los timeouts dejaran cero ranks activos. | Probar timeout nativo y externo, identificando la ruta exacta del ejecutable y los PID de esa corrida. | `verification/checks.json` y memorias originales de timeout. |
| La carpeta transferida provoca el bloqueo de propiedad de Git. | Excepción temporal por proceso, limitada al repositorio; sin cambiar confianza global ni desactivar metadatos VCS. | Wrapper de pruebas y manifiesto con commit completo. |

## Inspección del código finalmente conservado

Se revisaron representación row-major y float64/double, orden i,k,j,
generación LCG común, A/B inmutables, buffers C independientes y un propietario
por fila. C conserva la comprobación de solapamiento antes del kernel;
`restrict_c` permanece aislado y no cambia la API de campaña.

El refactor de I4 conserva `computeBlockSize(N,W)` en el camino canónico,
canal con capacidad W, exactamente W consumidores, cierre único y espera
completa. `worker` cronometra solo el cálculo de cada tarea, escribe su slot
antes de Done y la recepción queda fuera del kernel. No se crean tareas por celda.

En MPI se conserva `MPI_THREAD_FUNNELED`, MPI fuera de regiones OpenMP,
partición con restos/ranks vacíos, preparación de referencia en raíz y errores
colectivos. El diagnóstico nuevo no ejecuta MPI adicional ni cambia T0/T1;
solo escribe archivos distintos por rank cuando se solicita explícitamente.
El código de producción sin la variable no publica ese diagnóstico.

La evidencia de rendimiento se obtiene sin perfilador ni detector de carreras.
Los perfiles separados distinguen PeakWorkingSetSize, Private Bytes y sumas
simultáneas. Las sumas de máximos individuales no se presentan como pico conjunto.
Las limitaciones de muestreo y runtime están en el informe de memoria.

## Evidencia para aceptar la revisión

La [aceptación Windows](cierre_s06_windows.md) enlaza logs Debug/Release,
estabilidad Go, candidatos C, auditoría de datos, reloj, agrupación y limpieza
de MPI. Las observaciones inválidas se preservan como errores o antecedentes;
no se recortan tiempos ni se rellenan ceros para aceptarlas.

El intento local de `go test -race` requiere cgo/GCC y se informa con su resultado
real. Si ese toolchain no está disponible se registra la limitación, conservando
por separado las ejecuciones race previas Linux y de I4. No se simula un PASS.

No se detectaron razones para cambiar los núcleos canónicos durante esta
integración. Las candidatas permanecen en pruebas y los límites entregados a
S7 son candidatos al piloto, no parámetros de campaña oficial ya congelados.
