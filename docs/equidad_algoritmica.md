# Equidad algorítmica y regresión — Sprint 6

Actualización del 12/11/2026: aceptación Windows completada sobre la integración
de I4/I7 y la base I8. La tabla siguiente describe los invariantes conservados;
la evidencia Linux se mantiene diferenciada de la nueva aceptación Windows.

## Comparación de las cuatro implementaciones

| Propiedad | C secuencial | C híbrido | Go secuencial | Go paralelo |
| --- | --- | --- | --- | --- |
| Tipo y disposición | double, filas contiguas | double, bloques de filas | float64, slice contiguo | float64, slice contiguo |
| Acumulación | i,k,j | i,k,j por bloque local | i,k,j | i,k,j por tarea |
| Entradas | LCG común, A/B lectura | Raíz genera/lee; B completa por rank | LCG común, A/B lectura | LCG común, A/B lectura |
| Propietario de C | Hilo único | Rank y fila OpenMP disjuntos | Flujo único | Intervalos disjuntos por tarea |
| Vaciado de C | Dentro de total, fuera de kernel | Igual, por bloque local | Igual | Igual |
| Kernel | Duración directa | Máximo de regiones locales OpenMP | Duración directa | Máximo de sumas de cálculo por worker |
| Total | Vaciado y cálculo | Bcast, Scatterv, vaciado, cálculo, Gatherv | Vaciado y cálculo | Vaciado, creación, despacho, cierre, espera |
| Preparación de referencia | i,j,k antes de T0 | i,j,k en raíz antes de T0 | i,j,k antes de T0 | i,j,k antes de T0 |
| Medición/validación de salida | Fuera de I/O y validación | Reducciones fuera de T1 | Fuera de I/O y validación | Máximo calculado después de la espera |

El presupuesto comparable es P×T en C y workers en Go, hasta los núcleos físicos
disponibles. Las referencias son C puro y Go con GOMAXPROCS=1, respectivamente.
Los runtimes y compiladores son distintos: no se debe atribuir toda diferencia
de tiempos al lenguaje ni interpretar P×T como afinidad garantizada.

El generador conserva una secuencia uint32, primero A y después B; se compara
cada celda con `1e-9 + 1e-9*abs(esperado)` y se rechazan NaN/Inf. La igualdad
por bits observada en ciertos fixtures no reemplaza este contrato.

## Revisión de oportunidades equivalentes

- C ya reutiliza punteros de fila y A[i,k] tanto en secuencial como en OpenMP.
  No se presenta esa implementación previa como una mejora nueva.
- La candidata de C solo restringe alias de C en el laboratorio; la API de
  producción sigue admitiendo A/B compartidas y rechazando solapamiento de C.
- La candidata Go de slices por fila conserva i,k,j y se prueba con semillas
  0,42,101,2024 y UINT32_MAX y dimensiones impares. No cambia la representación.
  Si se promoviera, habría que evaluar también el acceso equivalente en el
  kernel de bloques paralelo.
- Los experimentos `block16` y `unbuffered` usan el worker aritmético existente.
  Cada experimento cambia únicamente bloque o canal frente a la base.
- OpenMP `static1` cambia únicamente granularidad estática del kernel local.
  No representa un experimento P/T con comunicación MPI.
- No se han promovido candidatas a los núcleos de producción. La paridad de
  las cuatro versiones no depende de una supuesta mejora medida en otra plataforma.

## Qué verifica la evidencia local

La [evidencia de S6](../resultados/diagnostico/s06/) conserva comandos, salidas y
códigos. El [acta](sprints/sprint-06.md) identifica los directorios exactos.

- Go: pruebas completas de ambos módulos, fixtures, contratos de CLI con
  metadatos inyectados por las pruebas, `go vet` y `go test -race`.
- C secuencial: contratos de dimensión/memoria, fallos simulados, generador,
  lectores, productos conocidos, preservación de A/B, repetición y errores.
- C paralelo: pruebas del kernel OpenMP y lectores, 4480 pares de partición,
  ejemplos con resto, ranks sin filas y límites. No se lanza MPI.
- Candidatas: productos contra referencia independiente i,j,k, repetición,
  inmutabilidad de entradas y ejecución con uno o varios workers/hilos.
- Comparador: batería existente ejecutada con PowerShell Linux y un alias
  temporal de `powershell.exe` a pwsh. Esto verifica lógica/formatos del
  comparador, sin convertir la batería Windows en una ejecución nativa.
- Agregación del laboratorio: calentamientos excluidos, IQR inclusivo,
  comparación antes/después y rechazo de grupos incompletos o duplicados.

`go_paralelo/environment_other.go` permite compilar pruebas aritméticas en Linux,
igual que la versión secuencial. Devuelve un error explícito al solicitar
metadatos de campaña; no añade una CLI experimental Linux ni altera Windows.

La compilación cruzada de los tests Go windows/amd64 comprueba que la selección
de archivos por plataforma sigue compilando. No prueba su ejecución ni el SDK
MSVC/MS-MPI. Los intentos ASan fallaron por falta de libasan y sus diagnósticos
se conservaron; los mismos contratos se ejecutaron con GCC -O0/-g y -O2.

## Criterios Windows originales (resueltos en el cierre)

1. Ejecutar `test_windows.ps1 -Version all` en Debug y Release sobre la revisión
   final y conservar los logs. La evidencia histórica de S5 no acredita S6.
2. Medir antes/después con MSVC y Go windows/amd64, mismas entradas, PC y flags.
3. Registrar P, T, hilos observados por rank, GOMAXPROCS y capacidad/afinidad
   real; cubrir P>N, reparto con resto y fallos colectivos sin bloqueos.
4. Medir memoria de raíz, otros ranks y pico simultáneo del conjunto MPI.
5. Revisar externamente las evidencias cuando corresponda al cierre formal.

No se traslada generación, validación, vaciado o coordinación fuera de su
intervalo contractual para aparentar una mejora. `total_s-kernel_s` sigue
siendo un indicador, no una medida causal exacta de comunicaciones o canal.


## Auditoría de cierre Windows

Los cinco criterios anteriores se comprobaron en la
[aceptación Windows](cierre_s06_windows.md) y la
[revisión de integración](revision_s06.md). Debug y Release pasan en las cuatro
versiones, con MPI real, perfiles rank/PID, filas/hilos, afinidad, errores y
timeouts sin procesos restantes. El refactor de I4 conserva el bloque canónico;
ninguna candidata aislada reemplaza el cálculo de producción.

No cambian representación, orden aritmético, generador, vaciado ni tolerancias.
El diagnóstico MPI optativo se ejecuta después de tiempos y validación
colectiva. La corrección del arnés I4 afecta solo al laboratorio: conserva QPC
auxiliar y compara total/kernel con el mismo reloj de los workers.
El responsable encargó a Codex la revisión de este cierre; no se inventan
conformidades personales ni se llama humana a esa revisión.
