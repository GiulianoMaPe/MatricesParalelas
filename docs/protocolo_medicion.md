# Protocolo futuro de medición

No hay mediciones en esta entrega. `bench_windows.ps1 -Version all -N 512 -Seed 42
-Workers 2 -Processes 2 -Threads 2 -Repetitions 5` es una interfaz reservada;
devuelve 2 y no crea archivos mientras los algoritmos estén pendientes. Aun cambiando
los estados, falta implementar el lanzador real y la validación: no existe un atajo
para presentar el smoke test como benchmark.

Antes de medir: implementar y validar los cuatro algoritmos contra todos los fixtures,
compilar Release y congelar commit, hardware, versiones y parámetros. No medir `go run`,
compilación, pruebas de instalación ni ejecuciones con instrumentación de depuración.

- `kernel_s`: intervalo de multiplicación pura sobre buffers preparados.
- `total_s`: entradas ya disponibles; incluye vaciado de C, distribución,
  coordinación/sincronización, cálculo y reunión. Excluye generación, lectura,
  validación y escritura. MPI incluye Bcast, Scatterv y Gatherv y registra máximo
  entre procesos con MPI_Reduce/MPI_MAX, con inicio sincronizado.
- C secuencial: QueryPerformanceCounter/Frequency; híbrido: MPI_Wtime;
  Go: time.Now/time.Since. El arranque de mpiexec es una métrica adicional separada.
- Una repetición de calentamiento descartada y cinco medidas, en serie; alternar
  configuraciones entre rondas. Piloto de memoria antes de tamaños grandes.
- CSV futuro: versión, commit, equipo, CPU, RAM, Windows, herramientas, configuración,
  N, seed, P, T, hilos observados, workers, GOMAXPROCS, repetición, kernel_s, total_s
  y validación. UTF-8 y punto decimal. Conservar fallos y exclusiones justificadas.
- Mediana y dispersión; speedup respecto de la referencia secuencial del mismo
  lenguaje, eficiencia respecto de P*T o workers. No mezclar equipos ni plataformas.

Guardar el piloto de S7 en `resultados/piloto/` y los originales oficiales de S8 en
`resultados/raw/`. Guardar agregados reproducibles en `resultados/resumen/` y gráficos
derivados en `resultados/graficos/`. No hay CSV de ejemplo que puedan confundirse con
datos experimentales. En S7 se implementará `scripts/summarize_results.ps1` para
medianas, dispersión, speedup y eficiencia; su validación usará datos de control
identificados como tales y separados de las observaciones experimentales.
