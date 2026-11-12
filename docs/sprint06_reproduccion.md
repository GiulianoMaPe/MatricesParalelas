# Reproducir el trabajo del Sprint 6

La [aceptación actual](sprints/sprint-06.md) distingue la parte Linux autorizada
de la comprobación Windows que sigue pendiente. Este procedimiento no habilita
`bench_windows.ps1`, cuya implementación corresponde a S7.

## Diagnóstico Linux

Requisitos: Python 3.9+, Go compatible con los módulos, GCC con OpenMP y GNU time
en `/usr/bin/time`. No se requiere instalar paquetes Python ni modificar Windows.

Desde la raíz:

```bash
python3 -B tests/sprint06_lab_test.py
python3 -B scripts/sprint06_lab.py --go /ruta/a/go --sizes 256 512 1024 --workers 1 2 4
```

El número de workers no puede superar los núcleos físicos accesibles a la sesión.
El runner enlaza las candidatas C desde `tests/sprint06_candidates.c` como
unidad independiente, igual que el núcleo base, sin LTO. Esto impide atribuir
a `restrict` una ventaja causada solo por inlining junto al harness.

El runner rechaza N fuera de 1..4096, más del 50% de RAM disponible estimada
para matrices o un directorio de salida ya existente. `--timeout` fija el límite
por proceso; su valor predeterminado es 180 segundos. Un bloqueo por repositorio
impide ejecutar dos laboratorios a la vez. Si un corte abrupto deja el archivo
`.cache/s06-laboratory.lock`, comprobar su PID antes de retirarlo manualmente.

Para probar rápidamente la infraestructura con dimensiones pequeñas, usando
otro directorio de salida:

```bash
python3 -B scripts/sprint06_lab.py --go /ruta/a/go --sizes 3 17 --workers 1 2 --output .cache/s06-comprobacion-nueva
```

Para repetir únicamente C con el mismo diseño y un intento nuevo, añadir
`--versions c_secuencial c_openmp_local`. No mezclar observaciones individuales
de distintos intentos; cada grupo base/candidata debe conservar sus seis corridas.

No usar esas matrices diminutas para concluir aceleración. Las pruebas Go de
producto e invariantes se ejecutan con los comandos habituales desde cada módulo:

```bash
go test -count=1 ./...
go vet ./...
go test -race -count=1 ./...
```

La observación `TestSprint06Observation` se omite normalmente y solo se activa
mediante las variables `S06_*` que prepara el runner. Así no se introducen
mediciones en cada ejecución ordinaria de pruebas.

Cada laboratorio conserva fuentes exactas y sus hashes, entorno, plan, todas
las observaciones y resumen. Los binarios/builds quedan ignorados. Los datos
de tiempo y memoria son diagnósticos de núcleos Linux, con el alcance descrito
en [memoria](memoria.md) y [equidad](equidad_algoritmica.md).

## Qué queda por ejecutar en Windows

Arrancar Windows 11 x64 y abrir el repositorio con MSVC, Windows SDK, MS-MPI
Runtime/SDK y Go configurados. Una partición Windows montada desde Linux no
equivale a ejecutar esa plataforma; Wine no acredita los tiempos de la campaña.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Debug
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all -Configuration Release
```

Después de validar los productos, preparar ejecutables Release, guardar revisión,
diff si procede, hashes, herramientas, RAM disponible y energía. Ejecutar el plan
exploratorio de S6 con semilla 42 y N=256,512,1024, un calentamiento y cinco rondas
intercaladas. Comparar las candidatas aisladas antes de decidir cualquier cambio
en el algoritmo de producción.

- C secuencial: comparar base y `restrict_c` del harness con MSVC, sin MPI/OpenMP.
- C híbrido: comprobar P/T de presupuesto igual (1×2 frente a 2×1; 1×4,2×2,4×1
  si la CPU lo admite), hilos observados, afinidad y comportamiento con resto/P>N.
  La candidata `static1` del laboratorio local no reemplaza esa comparación MPI.
- Go secuencial: comparar base y `row_slices` con Go windows/amd64, incluyendo
  asignaciones separadas de API/kernel y GOMAXPROCS=1.
- Go paralelo: comparar base, `block16` y `unbuffered` por separado, con workers
  y GOMAXPROCS iguales. No crear tareas por celda ni reducir workers en silencio.
- Memoria: medir raíz/resto de ranks y el máximo de la suma simultánea de procesos,
  identificando contador y frecuencia de muestreo; no usar los picos Linux como
  sustitutos de esos datos.

El lanzador actual `run_hybrid_windows.ps1` no expone repetición. Para registrar
la repetición contractual, invocar directamente el ejecutable MPI con
`--repetition R`, P y variables `OMP_NUM_THREADS=T`, `OMP_DYNAMIC=FALSE`, y
restaurar las variables al terminar. Capturar stdout y stderr por separado.
No lanzar el smoke test por omitir accidentalmente N/entrada.

Conservar las veinte columnas de CSV de programas, sus códigos y metadatos.
Las métricas propias de los harnesses (`s06-laboratory-v1`) se etiquetan aparte;
no se convierten en observaciones de programa cambiando solo la cabecera.

Si no hay mejora consistente o falta evidencia Windows, conservar la base y
dejar la candidata separada. Actualizar decisiones, memoria, equidad y acta con
los resultados realmente obtenidos antes de declarar cerrado S6.
