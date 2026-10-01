# Sprint 2 Completar interfaces y casos de prueba

Estado: pendiente de ejecución y revisión por el equipo. Plan de desarrollo de la [guía vigente](../guia-extraida.txt); no es evidencia de tareas realizadas.

Semana 2 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Revisar los contratos recibidos y completar interfaces, formatos y casos antes de desarrollar el núcleo.

Cierre: Hay un contrato único aprobado, fixtures con resultados conocidos y diseños que otros integrantes pueden explicar.

## Trabajo de cada integrante

Integrante 1 Revisar estructuras y funciones iniciales de C secuencial (3 h). Completar contrato de memoria, validación de N y liberación de buffers (3 h). Entregable: Interfaces C secuencial revisadas. Ubicación: c_secuencial/include/.

Integrante 2 Diseñar reparto de filas y counts y desplazamientos MPI (3 h). Resolver en papel N no divisible entre P y procesos sin filas (3 h). Entregable: Diseño MPI con ejemplos verificables. Ubicación: c_paralelo/include/partition.h.

Integrante 3 Revisar los datos y funciones iniciales de Go secuencial (3 h). Completar contrato de errores y argumentos equivalente al de C (3 h). Entregable: Interfaces Go secuencial revisadas. Ubicación: go_secuencial/matrix.go.

Integrante 4 Diseñar workers, canal de tareas y propiedad de las filas (3 h). Definir cierre del canal y espera sin bloqueos ni escritura compartida (3 h). Entregable: Diseño Go paralelo con invariantes. Ubicación: docs/arquitectura.md.

Integrante 5 Ampliar los fixtures recibidos con identidad, cero y negativos (3 h). Definir tolerancias y política para NaN e infinitos (3 h). Entregable: Fixtures ampliados y criterio de comparación. Ubicación: tests/fixtures/.

Integrante 6 Completar el formato y generador determinista propuestos (3 h). Preparar vectores de control que C y Go deberán reproducir (3 h). Entregable: Contrato de entradas definitivo. Ubicación: docs/formato_datos.md.

Integrante 7 Definir límites de kernel_s y total_s y campos del CSV (3 h). Diseñar matriz de experimentos y criterios de repetición (3 h). Entregable: Protocolo de medición versión inicial. Ubicación: docs/protocolo_medicion.md.

Integrante 8 Leer y resumir dos candidatos de literatura científica (3 h). Seleccionar al menos uno y asociar sus hallazgos al reparto por filas (3 h). Entregable: Bibliografía verificada y decisión de diseño. Ubicación: docs/bibliografia.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-02.md.

## Plan de trabajo de I3 (Giuliano)

**Estado:** plan inicial; tareas todavía pendientes. Mi entregable será `go_secuencial/matrix.go` con las interfaces y sus reglas claras.

1. **Revisar cómo se guardan las matrices (3 h).** Mantener `Matrix` con `N` y `Data`. Dejar claro que `N` debe ser positivo, que debe haber exactamente `N*N` valores y que se guardan fila por fila. Revisar también los límites de tamaño antes de calcular `N*N` o reservar memoria.
2. **Completar las reglas de las funciones y los errores (3 h).** Definir qué error corresponde a dimensiones inválidas, datos incompletos o sobrantes, matrices de distinto tamaño y valores NaN o infinitos. Aclarar que `Multiply` recibe dos matrices del mismo tamaño y no modifica sus entradas. Mientras el cálculo siga pendiente, una entrada válida debe seguir devolviendo `ErrPending`.
3. **Acordar los argumentos con el equipo (parte de la coordinación, 1 h).** Comparar estas reglas con I1, que revisa las interfaces de C. Usar lo que ya pide `docs/contrato.md`: `--n` positivo y `--seed` entre 0 y 4294967295; cuando se use `--input`, no combinarlo con `--n` ni `--seed`. Los mensajes de error deben ir a `stderr` y la ejecución fallida debe devolver un código distinto de cero. Coordinar con I4 e I7 antes de cambiar `main.go` o `input.go`, porque sus tareas de Sprint 3 usan esos archivos.
4. **Revisión cruzada (1 h).** Pedir a I2 que revise mi entregable y revisar el diseño de I4 en `docs/arquitectura.md`, siguiendo el reparto del equipo.

### Cómo sabré que mi parte está lista

- Las reglas de `Matrix` y `Multiply` están escritas junto a las funciones.
- Las validaciones distinguen una entrada incorrecta de una función pendiente.
- Las pruebas de las validaciones cubren los errores acordados y las pruebas existentes siguen pasando.
- Los argumentos y errores son coherentes con el contrato común; los acuerdos y resultados reales quedan registrados aquí.
- I2 revisó mi entregable y registré mi revisión a I4.

La multiplicación se implementará en Sprint 3. La rama propuesta para trabajar Sprint 2 es `feature/s02-i03-interfaces-go-secuencial`, después de integrar los cambios de Sprint 1 y actualizar `main`.

## Registro de cierre

#### Integrante 7 (Andrés)

- **Participantes y horas reales:** Andrés (8 h: 3 h delimitación estricta de cronómetros `kernel_s`/`total_s` y diseño del esquema CSV, 3 h diseño de la matriz exhaustiva de experimentos y protocolo de mitigación de sesgos, 1 h revisión cruzada de I8 Roberto sobre [`docs/bibliografia.md`](../bibliografia.md), 1 h coordinación de acuerdos).
- **Issues y pull requests:** Rama de trabajo `feature/s02-i07-protocolo-inicial`.
- **Pruebas y evidencias:** Entregable [`docs/protocolo_medicion.md`](../protocolo_medicion.md) finalizado en su versión 1.0 (versión inicial aprobada). Incluye: delimitación formal de eventos de reloj por tecnología, matriz de exclusiones de I/O y memoria, diccionario con las 20 columnas del archivo CSV, espacio de parámetros con 234 ejecuciones planificadas para CPUs de 8 núcleos, protocolo 1 warmup + 5 repeticiones en round-robin y formulación de Speedup/Eficiencia mediante medianas.
- **Bloqueos y decisiones:** Se adopta formalmente la mediana y el rango intercuartílico (IQR) para mitigar el jitter de Windows 11. Se prohíbe el uso de corridas consecutivas idénticas para evitar sesgo de estrangulamiento térmico (*thermal throttling*).
- **Revisión y criterio de aceptación:** Entregable de I7 completado satisfactoriamente; pendiente revisión cruzada por Integrante 6 (Gerardo). Revisión cruzada realizada a I8 (Roberto): entregable [`docs/bibliografia.md`](../bibliografia.md) revisado y aprobado formalmente (los modelos de Quintin et al. fundamentan adecuadamente el reparto 1D por bloques de filas y la topología híbrida).

#### Integrante 8 (Roberto)

- Participantes y horas reales: Roberto (8 h: 3 h análisis y resumen de los dos artículos IEEE en `docs/referencias/`, 3 h selección de artículo y justificación técnica del reparto 1D por bloques de filas, 1 h coordinación de equipo, 1 h revisión cruzada asignada a I1).
- Issues y pull requests: Rama de trabajo `feature/integrante-8-roberto`.
- Pruebas y evidencias: Entregable `docs/bibliografia.md` finalizado con análisis de Quintin et al. (ICPP 2013) y Herault et al. (ScalA 2019 / Jack Dongarra), justificación del orden $i, k, j$, `MPI_Bcast` y arquitectura de Go. PDFs de referencia resguardados en `docs/referencias/`.
- Bloqueos y decisiones: Se adopta formalmente el reparto 1D por bloques de filas con `MPI_Scatterv`/`MPI_Gatherv` en memoria continua para evitar sobrecostes de empaquetamiento 2D en memoria compartida emulada.
- Revision y criterio de aceptacion: Entregable de I8 finalizado; pendiente revisión cruzada formal por Integrante 7 (Andres).

#### Integrante 2

- Participantes y horas reales: Sebastian (8 h planificadas: 3 h diseño del reparto de filas y de los `counts` y desplazamientos MPI, 3 h resolución en papel de N no divisible entre P y de procesos sin filas, 1 h de coordinación del Sprint 2 (la rotación de coordinación asigna S2 a I2), 1 h de revisión cruzada asignada a I3). Las horas reales se anotan con el integrante al cierre del sprint.
- Issues y pull requests: Rama de trabajo `feature/integrante-2-sebastian`.
- Pruebas y evidencias: Entregable `c_paralelo/include/partition.h` reescrito el 30/09/2026 como diseño verificable, en ASCII y conservando la firma de `partition_rows` para no romper `src/partition.c`. Contiene: algoritmo de cociente y resto en forma cerrada `primera[i] = i*q + min(i,r)`; invariantes I1–I8 (suma de filas = N, bloques contiguos, `counts[i] = filas[i]*N`, suma de `counts` = N·N, `displs[i]+counts[i] = displs[i+1]`); unidades en elementos `double` conforme a la guía §2 y a `docs/contrato.md`; límite `N*N ≤ INT_MAX` (`PARTITION_MAX_N` = 46340) comprobado una vez porque el último desplazamiento más su count es N·N; códigos 0/1/2 (`PARTITION_OK`, `PARTITION_INVALID`, `PARTITION_PENDING`); esquema de uso con `MPI_Bcast`/`MPI_Scatterv`/`parallel for schedule(static)`/`MPI_Gatherv`; restricciones de MSVC (sin VLA, índice entero con signo en el bucle OpenMP, memoria en el heap); y los ejemplos (a)–(i), incluidos N=10/P=4 y N=7/P=3 (no divisible) y N=3/P=5 y N=4/P=8 (procesos sin filas).

  Verificación aritmética ejecutada el 30/09/2026 (PowerShell, sin MPI):

  - Recorrido de los 4480 pares (N, P) con N ∈ [1, 64] y P ∈ [1, 70] comprobando las invariantes I1–I8: **0 fallos**.
  - Fronteras: N=46340 → 2147395600 ≤ INT_MAX → `PARTITION_OK`; N=46341 → 2147488281 > INT_MAX → `PARTITION_INVALID` (nunca truncado).
  - Reproducción de los ejemplos (a)–(h) con el comando PowerShell incluido en el propio `partition.h`:

    ```text
    N=10 P=4 filas=[3 3 2 2] ini=[0 3 6 8] counts=[30 30 20 20] sum=100 displs=[0 30 60 80]
    N=7 P=3 filas=[3 2 2] ini=[0 3 5] counts=[21 14 14] sum=49 displs=[0 21 35]
    N=5 P=2 filas=[3 2] ini=[0 3] counts=[15 10] sum=25 displs=[0 15]
    N=8 P=4 filas=[2 2 2 2] ini=[0 2 4 6] counts=[16 16 16 16] sum=64 displs=[0 16 32 48]
    N=2 P=2 filas=[1 1] ini=[0 1] counts=[2 2] sum=4 displs=[0 2]
    N=1 P=1 filas=[1] ini=[0] counts=[1] sum=1 displs=[0]
    N=3 P=5 filas=[1 1 1 0 0] ini=[0 1 2 3 3] counts=[3 3 3 0 0] sum=9 displs=[0 3 6 9 9]
    N=4 P=8 filas=[1 1 1 1 0 0 0 0] ini=[0 1 2 3 4 4 4 4] counts=[4 4 4 4 0 0 0 0] sum=16 displs=[0 4 8 12 16 16 16 16]
    ```

    La salida reproduce exactamente los valores de los ejemplos (a)–(h) documentados en la cabecera de `partition.h` (que allí se presentan en forma de tablas).
  - Compilación con MSVC **pendiente**: este equipo no tiene MSVC, MS-MPI ni Go (comprobado el 30/09/2026), así que la evidencia de S2 es aritmética y estática. Reproducción en una PC con el entorno: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version c_paralelo -Configuration Debug -Tests`.
- Bloqueos y decisiones: (1) `counts` y desplazamientos se expresan en **elementos `double`** (filas locales × N), no en filas; los desplazamientos son la suma acumulada de los `counts`. (2) **P > N es legal**: con `q = 0` y `r = N`, los primeros N procesos reciben 1 fila y los `P − N` restantes `count = 0` con desplazamiento N·N; MPI admite counts nulos y nadie queda esperando. (3) Se diseñan **dos funciones puras sin llamadas a MPI** —`partition_split` (filas e índice inicial) y `partition_rows` (elementos MPI)— para poder probarlas sin `MPI_Init` y para dar a `main.c` el límite del bucle OpenMP. (4) Sin VLA (MSVC no los admite en C11) e índice entero con signo en `parallel for`, según la guía §«Memoria y errores». (5) La implementación de `partition.c` queda para **S4** (I1 e I2); mientras tanto ambas funciones devuelven `PARTITION_PENDING` (2) y `status.json` no se modifica. (6) Diseño alineado con `docs/requisitos.md` RNF-04 y con la decisión de reparto 1D de `docs/bibliografia.md` (I8).
- Revision y criterio de aceptacion: Entregable de I2 finalizado en la ruta asignada `c_paralelo/include/partition.h`, con ejemplos resueltos y comando de reproducción; pendiente la revisión cruzada formal por Integrante 1 (Yessly) y la revisión del diseño por Integrante 1, que es quien implementará `MPI_Scatterv`/`MPI_Gatherv` con este reparto en S4. Como revisor asignado de I3, `docs/diagnostico_go_secuencial.md` sigue sin existir en el repositorio, por lo que su revisión formal queda pendiente de que I3 lo publique.
- **Participantes y horas reales:** Roberto (8 h: 3 h análisis y resumen de los dos artículos IEEE en `docs/referencias/`, 3 h selección de artículo y justificación técnica del reparto 1D por bloques de filas, 1 h coordinación de equipo, 1 h revisión cruzada asignada a I1).
- **Issues y pull requests:** Rama de trabajo `feature/integrante-8-roberto`.
- **Pruebas y evidencias:** Entregable [`docs/bibliografia.md`](../bibliografia.md) finalizado con análisis de Quintin et al. (ICPP 2013) y Herault et al. (ScalA 2019 / Jack Dongarra), justificación del orden $i, k, j$, `MPI_Bcast` y arquitectura de Go. PDFs de referencia resguardados en `docs/referencias/`.
- **Bloqueos y decisiones:** Se adopta formalmente el reparto 1D por bloques de filas con `MPI_Scatterv`/`MPI_Gatherv` en memoria continua para evitar sobrecostes de empaquetamiento 2D en memoria compartida emulada.
- **Revisión y criterio de aceptación:** Entregable de I8 revisado y aprobado formalmente con verificación técnica por Integrante 7 (Andrés).
