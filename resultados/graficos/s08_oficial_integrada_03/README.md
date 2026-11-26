# Gráficos del Sprint 9 · Fernando Saire (I5)

Las figuras usan el [resumen estadístico oficial](../../resumen/s08_oficial_integrada_03/resumen_estadistico.csv), generado a partir de las [mediciones congeladas](../../raw/s08_oficial_integrada_03/mediciones.csv). La campaña `s08_oficial_integrada_03` se ejecutó en `PCG1UL14N0` con semilla 42 y la candidata `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`. Cada uno de los 33 grupos contiene cinco mediciones válidas y un calentamiento. Las figuras usan las cinco mediciones válidas. [Dictamen de calidad](../../../docs/calidad_datos.md)

`N` es la dimensión de las matrices cuadradas. En C, `P` es el número de procesos MPI y `T` el número de hilos OpenMP por proceso. En Go, `W` es el número de trabajadores.

## Pies de figura

1. [Tiempo total por configuración](tiempo_total.png). Mediana de `total_s` en segundos para cada tamaño y configuración. La marca vertical indica la mediana, la banda gruesa va de Q1 a Q3 y la línea fina cubre el mínimo y el máximo observados. El intervalo cronometrado incluye el cálculo y, según la versión, el vaciado de la salida y la coordinación. Los tres paneles comparten un eje logarítmico, donde distancias iguales representan cocientes iguales. [Protocolo de medición](../../../docs/protocolo_medicion.md#3-límites-comunes-de-kernel_s-y-total_s)
2. [Tiempo del núcleo por configuración](tiempo_kernel.png). Mediana de `kernel_s` en segundos con el intervalo Q1–Q3 y el rango observado. Mide la acumulación con la matriz de salida ya vaciada. C paralelo toma el máximo entre procesos y Go paralelo toma el máximo del tiempo acumulado por trabajador. La figura usa la misma escala logarítmica que el gráfico de tiempo total. Un intervalo estrecho puede quedar visualmente cerca de la marca de mediana. [Definición de tiempo de cálculo](../../../docs/protocolo_medicion.md#32-tiempo-de-cálculo)
3. [Aceleración frente al secuencial](speedup.png). Para cada configuración paralela, se divide la mediana de `total_s` del secuencial del mismo lenguaje y tamaño por la mediana de `total_s` del paralelo. La línea de 1× indica empate. A la izquierda queda el paralelo más lento y a la derecha el más rápido. El eje es lineal y empieza en cero. Cada punto representa un cociente de medianas. La dispersión de los tiempos que intervienen en el cociente figura en el gráfico de tiempo total. [Fórmula de speedup](../../../docs/protocolo_medicion.md#71-speedup-s)
4. [Eficiencia por trabajador nominal](eficiencia.png). Speedup dividido por `P × T` en C y por `W` en Go. La línea en 1 representa aceleración lineal respecto del presupuesto nominal. El eje es lineal y empieza en cero. Esta fracción se interpreta como aceleración por trabajador nominal. [Fórmula de eficiencia](../../../docs/protocolo_medicion.md#72-eficiencia-paralela-e)

## Reproducción

Desde la raíz del repositorio, con Python 3.12 y Matplotlib 3.10.7:

```powershell
python -m pip install matplotlib==3.10.7
python scripts/graficar_resultados_s09.py
```

El script escribe los cuatro PNG junto a este documento. `--salida <carpeta>` permite guardar otra copia para cotejo. Para comprobar la procedencia del resumen, se puede ejecutar el resumidor del repositorio desde los originales y comparar el contenido de ambos CSV:

```powershell
./scripts/summarize_results.ps1 `
    -InputPath resultados/raw/s08_oficial_integrada_03/mediciones.csv `
    -CampaignId s08_oficial_integrada_03 `
    -OutputPath .cache/s09-verificacion/resumen_estadistico.csv
```
