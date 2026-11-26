# Go secuencial · Análisis del Sprint 9

**Responsable** · Giuliano (I3)

En la campaña oficial, la mediana de `total_s` de Go secuencial aumentó de **0,090451 s** a **6,296919 s** entre N=512 y N=2048. Al duplicar N, el tiempo se multiplicó por **8,03** y **8,67** en los dos saltos medidos. El IQR relativo de `total_s` fue inferior al 1,8 % en los tres tamaños. Estos tiempos forman la referencia para calcular el speedup de Go paralelo en la misma campaña.

## Condiciones y resultados

Se usó la campaña integrada `s08_oficial_integrada_03` del Sprint 8, ejecutada en `PCG1UL14N0` (AMD Ryzen 5 3600, 15,912 GiB de RAM visible, Windows 11 Pro build 26300.9711) con Go 1.27.4 `windows/amd64` en Release y el commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`. Las tres configuraciones usan semilla 42, `workers=1` y `gomaxprocs=1`. Se comprobó que cada grupo contiene las repeticiones 0 a 5 sin duplicados y con validación `OK`. Se excluyó el calentamiento (`repetition=0`) del cálculo, por lo que la tabla usa las cinco mediciones de cada grupo. [CSV de la campaña](../resultados/raw/s08_oficial_integrada_03/mediciones.csv) · [Entorno y compilación](../resultados/raw/s08_oficial_integrada_03/entorno.json) · [Dictamen de calidad](calidad_datos.md).

| N | Medidas | Mediana `kernel_s` (s) | IQR `kernel_s` (s) | Mediana `total_s` (s) | Mín.–máx. `total_s` (s) | IQR `total_s` (s) | IQR relativo `total_s` |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 512 | 5 | 0,090294 | 0,000143 | 0,090451 | 0,089682–0,090862 | 0,000407 | 0,45 % |
| 1024 | 5 | 0,725234 | 0,012754 | 0,726238 | 0,712951–0,759172 | 0,012752 | 1,76 % |
| 2048 | 5 | 6,292360 | 0,042751 | 6,296919 | 6,167931–6,460557 | 0,042857 | 0,68 % |

Para cada métrica se ordenaron las cinco observaciones. La tercera es la mediana y el IQR es la cuarta menos la segunda. El IQR relativo es `100 × IQR / mediana`. La auditoría señaló uno, uno y dos valores fuera de las vallas de Tukey, respectivamente. Se conservaron todas las observaciones válidas y el dictamen de la campaña mantuvo los tres grupos completos. [Protocolo, §6.3](protocolo_medicion.md#63-justificación-del-uso-de-la-mediana-y-rango-intercuartílico-iqr) · [Resumen estadístico](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv) · [Auditoría de dispersión](../resultados/resumen/s08_oficial_integrada_03/auditoria_dispersion.md).

El orden de los bucles hace `N³` iteraciones de multiplicación y acumulación. Duplicar N multiplica por ocho ese trabajo y por cuatro los bytes de cada matriz. El salto a N=1024 queda cerca de ese factor de ocho. Al pasar a N=2048, la mediana crece 8,67 veces y el rendimiento estimado para `total_s` (`2 × N³ / mediana(total_s) / 10⁹`) pasa de 2,96 a 2,73 GFLOPS. Los datos describen el comportamiento de esta implementación en esta PC. La campaña carece de contadores de caché o ancho de banda para explicar esa diferencia. [Resumen estadístico](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv) · [Protocolo de medición](protocolo_medicion.md).

La mediana de `total_s - kernel_s`, calculada por corrida, fue **0,000 ms**, **1,005 ms** y **4,559 ms**. Esta diferencia recoge el trabajo fuera del kernel dentro del tramo cronometrado, incluido el vaciado de C y la instrumentación. En N=512, todos los `total_s` quedaron por debajo de 100 ms y tres repeticiones registraron ambos tiempos iguales. Por eso, la diferencia observada de 0 ms tiene poca capacidad para caracterizar el coste del vaciado. [CSV de la campaña](../resultados/raw/s08_oficial_integrada_03/mediciones.csv) · [Fronteras temporales](protocolo_medicion.md#3-límites-comunes-de-kernel_s-y-total_s).

## Implementación, asignaciones y límites

- **Almacenamiento y recorrido.** `Matrix` almacena un `[]float64` contiguo por filas. El kernel `i,k,j` reutiliza `A[i,k]` y recorre segmentos contiguos de B y C en el bucle `j`. Usa A y B para lectura, acumula en C ya reservada y evita asignaciones explícitas en los bucles. [Kernel secuencial](../go_secuencial/matrix.go).
- **Trayectoria oficial de la CLI.** El generador reserva A y B. La CLI calcula y guarda una referencia de validación con recorrido `i,j,k` y reserva C antes de cronometrar. `total_s` abarca el vaciado de C y el kernel. `kernel_s` empieza después del vaciado. La comparación de todas las celdas ocurre después de detener los cronómetros. Lectura o generación, reservas, referencia, validación, escritura y arranque quedan fuera de los dos tiempos. [Generador](../go_secuencial/input.go) · [CLI e instrumentación](../go_secuencial/main.go).
- **Memoria matricial.** Cada buffer de datos ocupa `8 × N²` bytes. Los cuatro buffers principales de la CLI suman **8, 32 y 128 MiB** para N=512, 1024 y 2048. Es un cálculo de almacenamiento matricial. El proceso usa memoria adicional para el runtime, pilas y estructuras auxiliares. La comprobación de capacidad usa el modelo de cuatro buffers y la memoria disponible consultada al iniciar la ejecución. [Modelo de memoria](memoria.md#modelo-comprobado-contra-las-reservas) · [Comprobación de capacidad](../go_secuencial/main.go).
- **Asignaciones observadas en laboratorio.** El diagnóstico Windows de S6 usó `testing.AllocsPerRun` con matrices N=17. La variante base registró **0 asignaciones por llamada** al vaciar y ejecutar el kernel con buffers preparados y **1 asignación por llamada** a `Multiply`, que reserva el resultado. La API `Multiply` y la CLI oficial siguen rutas distintas. S8 registró tiempos y validación, sin medir asignaciones, heap ni pausas del recolector en sus tamaños oficiales. [Instrumentación del diagnóstico](../go_secuencial/sprint06_test.go) · [Observaciones Windows de S6](../resultados/piloto/s06_windows_20261112/observations.jsonl).
- **Runtime y alcance.** La CLI fija `runtime.GOMAXPROCS(1)` durante la ejecución. El producto ejecuta un solo flujo de cálculo y el ajuste limita a uno el paralelismo de ejecución de código Go. El proceso puede mantener varios hilos del sistema y cambiar de núcleo. El cronómetro mide tiempo transcurrido, que puede incluir desplanificación u otras interferencias. S8 carece de un perfil para cuantificar el GC, el planificador, la caché o el efecto térmico. Las conclusiones quedan acotadas al binario, host y tamaños documentados. [CLI](../go_secuencial/main.go) · [Entorno de la campaña](../resultados/raw/s08_oficial_integrada_03/entorno.json).

## Referencia para el informe

Para calcular `S(N,W)` en Go, dividir la mediana de `total_s` de la fila secuencial de N por la mediana del grupo `go_paralelo` con ese N y W en `s08_oficial_integrada_03`. Usar cifras sin redondear del resumen para el cociente y dividir `S(N,W)` por W para la eficiencia. Las extracciones de S8 anteriores al cierre integrado pueden consultarse como antecedentes. [Protocolo de medición](protocolo_medicion.md) · [Resumen integrado](../resultados/resumen/s08_oficial_integrada_03/resumen_estadistico.csv).

Desde la raíz del repositorio se pueden regenerar las filas del resumen en la salida estándar. El SHA-256 del CSV de entrada es `afbbbd38c4ee54c3fe8194501538ca542e19a7f5f2f62fc315b3517e960fbd58`. [Manifiesto S8](../resultados/raw/manifiesto_s08.json).

```powershell
$id = 's08_oficial_integrada_03'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\summarize_results.ps1 `
    -InputPath "resultados/raw/$id/mediciones.csv" -CampaignId $id |
    ConvertFrom-Csv | Where-Object version -eq 'go_secuencial'
```
