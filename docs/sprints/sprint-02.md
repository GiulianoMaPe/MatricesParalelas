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

- **Participantes y horas reales:** Roberto (8 h: 3 h análisis y resumen de los dos artículos IEEE en `docs/referencias/`, 3 h selección de artículo y justificación técnica del reparto 1D por bloques de filas, 1 h coordinación de equipo, 1 h revisión cruzada asignada a I1).
- **Issues y pull requests:** Rama de trabajo `feature/integrante-8-roberto`.
- **Pruebas y evidencias:** Entregable [`docs/bibliografia.md`](../bibliografia.md) finalizado con análisis de Quintin et al. (ICPP 2013) y Herault et al. (ScalA 2019 / Jack Dongarra), justificación del orden $i, k, j$, `MPI_Bcast` y arquitectura de Go. PDFs de referencia resguardados en `docs/referencias/`.
- **Bloqueos y decisiones:** Se adopta formalmente el reparto 1D por bloques de filas con `MPI_Scatterv`/`MPI_Gatherv` en memoria continua para evitar sobrecostes de empaquetamiento 2D en memoria compartida emulada.
- **Revisión y criterio de aceptación:** Entregable de I8 revisado y aprobado formalmente con verificación técnica por Integrante 7 (Andrés).

#### Integrante 5 (Fernando Saire)

- **Participantes y horas reales:** Fernando Saire. Falta registrar las horas reales; la estimación del sprint es de 8 h.
- **Issues y pull requests:** Rama de trabajo `feature/s02-i05-fixtures-tolerancias`; issue y pull request pendientes.
- **Pruebas y evidencias:** Se añadió el caso de dimensión impar [`tests/fixtures/impar3.input.txt`](../../tests/fixtures/impar3.input.txt) con su resultado [`tests/fixtures/impar3.expected.txt`](../../tests/fixtures/impar3.expected.txt). El cálculo manual de sus nueve celdas y el criterio de comparación están documentados en [`tests/fixtures/README.md`](../../tests/fixtures/README.md).
- **Cobertura y criterio numérico:** Los fixtures recibidos ya cubrían identidad, matriz cero y valores negativos, por lo que no se duplicaron. Se añadió el caso 3 por 3 con ceros y negativos. Se adoptó el contrato común `atol = 1e-9`, `rtol = 1e-9`, comparación completa celda por celda y rechazo de NaN e infinitos.
- **Revisión cruzada a I6 (Gerardo):** Pendiente hasta que Gerardo publique el contrato definitivo de entradas y sus vectores de control.
- **Coordinación y criterio de aceptación:** La coordinación con I2 (Sebastian) y la revisión asignada a I4 (Eva) quedan pendientes. El entregable técnico queda preparado para revisión; el lector y el comparador se implementarán en sprints posteriores.
