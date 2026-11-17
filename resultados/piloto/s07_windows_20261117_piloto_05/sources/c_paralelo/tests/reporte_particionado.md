# Reporte de particionado C · Sprint 4 · I5 Fernando

Validación ejecutada el 22/10/2026 sobre la rama
`feature/s04-i05-pruebas-particionado-c`, commit
`3151e4be0b57f57f53ee695f9cded51420661e98`.

## Entorno y reproducción

- Windows x64; AMD Ryzen 5 3600; 15.912 GiB de RAM informados por el ejecutable.
- MSVC x64 19.51.36257.0, Windows SDK 10.0.26100.0.
- MS-MPI Runtime 10.1.12498.52 y SDK con `mpi.h` y `msmpi.lib` x64.
- Compilación oficial con `/std:c11 /W4 /WX /openmp`; Debug con `/Od /Zi /MDd`
  y Release con `/O2 /MD`.
- Ejecución con `OMP_DYNAMIC=FALSE`; el lanzador configura `OMP_NUM_THREADS`
  según cada caso.

Desde la raíz del repositorio:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_windows.ps1 -Version c_paralelo -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_windows.ps1 -Version c_paralelo -Configuration Release
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify_partition_design.ps1
```

Los tres comandos terminaron con código **0**. Las dos baterías integrales se
ejecutaron fuera del entorno restringido del agente: dentro de este, `mpiexec`
había fallado al iniciar el ejecutable con `Error (5) Acceso denegado` y código
`-4`. No fue necesario modificar el código, los permisos de archivos ni los
scripts para completar la validación. La atribución al entorno restringido se
basa en que los mismos comandos pasaron al ejecutarse fuera de él.

## Pruebas unitarias

En ambas configuraciones pasaron los dos ejecutables independientes:

- `pending_test.exe`: entradas, ocho ejemplos de reparto, 4480 pares N/P y
  núcleo local. Mensaje: `OK: entradas, particion (8 ejemplos + 4480 casos) y nucleo local.`
- `partition_test.exe`: N/P de 10/4 y 7/3 (no divisibles), 3/5 y 4/8 (bloques
  vacíos), límite válido N=46340 y rechazo de N=46341 en `partition_rows`;
  además, rechazo de dimensión cero, procesos cero y punteros nulos.
  Comprueba filas, filas iniciales, counts y desplazamientos en elementos,
  continuidad, cobertura y conservación de buffers en los rechazos comprobados.
  Mensaje: `OK: particionado MPI, bloques vacios, limites y argumentos invalidos.`

El límite N=46340 se valida mediante la aritmética de particionado; no se
reservaron ni multiplicaron matrices de ese tamaño.

También pasó `verify_partition_design.ps1`: ocho ejemplos, 4480 pares N/P,
fronteras 46340/46341 y cero fallos. Este script revisa el diseño aritmético
independiente; la ejecución de `partition.c` la cubren los tests C anteriores.

## Ejecución MPI y OpenMP

El smoke test pasó con dos procesos y dos hilos observados por proceso en Debug
y Release; ambos procesos informaron nivel MPI 1 (`MPI_THREAD_FUNNELED=1`).

Cada fila de la tabla se ejecutó en ambas configuraciones. Las 18 comparaciones
contra los fixtures dieron `max_abs=0` y `max_rel=0`; los CSV emitidos por estas
ejecuciones indicaron `validation_status=OK`.

| Fixture | N | Procesos | Hilos | Cobertura | Debug | Release |
| --- | --- | --- | --- | --- | --- | --- |
| producto2 | 2 | 2 | 2 | Reparto divisible | OK | OK |
| escalar | 1 | 2 | 2 | Un proceso sin filas | OK | OK |
| identidad | 2 | 2 | 2 | Matriz identidad | OK | OK |
| cero | 2 | 2 | 2 | Producto nulo | OK | OK |
| impar3 | 3 | 2 | 2 | Tamaño impar, reparto no divisible | OK | OK |
| impar3 | 3 | 1 | 2 | Un solo proceso | OK | OK |
| impar3 | 3 | 2 | 1 | Un hilo por proceso | OK | OK |
| producto2 | 2 | 3 | 1 | Un proceso sin filas | OK | OK |
| impar3 | 3 | 5 | 1 | Dos procesos sin filas | OK | OK |

Los archivos de salida locales se conservan en
`c_paralelo/build/{Debug,Release}/fixture-results/`, directorios ignorados por Git.

En ambas configuraciones pasó además la comprobación automática del CSV de 20
columnas para N=2, seed=42, P=2 y T=2: una fila, metadatos esperados,
`observed_threads=2`, `validation_status=OK`, tiempos finitos y
`0 <= kernel_s <= total_s`. La batería del comparador también pasó sus cinco
fixtures y comprobaciones de tolerancia y formato estricto.

Mensaje final de ambas baterías:

```text
OK: c_paralelo (smoke, cinco fixtures, P=1, P>N, no divisible y CSV validado).
```

## Estado de aceptación

La validación técnica del entregable de particionado de I5 queda satisfecha
para los casos descritos en Debug y Release con MSVC/MS-MPI. No se detectaron
errores de counts ni desplazamientos en esta batería.

Quedan pendientes la revisión cruzada de I4 (Eva) sobre I5, el registro de horas
reales y los enlaces de issue/PR. I5 debe registrar también su revisión de I6
(Gerardo). Este reporte no constituye la aceptación final del equipo ni el
cierre del Sprint 4.
