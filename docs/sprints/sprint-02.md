# Sprint 2 Completar interfaces y casos de prueba

Estado: los ocho entregables y sus revisiones están conformes. Integración y acuerdos documentados; las horas sin parte real se distinguen como estimaciones.

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

### Cómo sabré que mi parte está lista

- Las reglas de `Matrix` y `Multiply` están escritas junto a las funciones.
- Las validaciones distinguen una entrada incorrecta de una función pendiente.
- Las pruebas de las validaciones cubren los errores acordados y las pruebas existentes siguen pasando.
- Los argumentos y errores son coherentes con el contrato común; los acuerdos y resultados reales quedan registrados aquí.
- I2 revisó mi entregable y registré mi revisión a I4.

La multiplicación se implementará en Sprint 3. Las interfaces de Go secuencial se integraron mediante el PR #18; el cierre documental toma como base `df22fc5`.

## Registro de cierre

Cierre redactado en primera persona, en la voz de cada integrante, a partir de las comprobaciones del proyecto. Las revisiones son evaluaciones asistidas y el ciclo va de I1 a I2 hasta I8 a I1. Las horas añadidas para I1, I2, I4, I5 e I6 son una distribución estimada de 8 h por sprint; se conservan las 8 h declaradas anteriormente por I3, I7 e I8. Este registro distingue la asignación de horas de un parte de trabajo real.

#### Integrante 1 (Yessly)

- **Issues y pull requests:** Las interfaces de C secuencial quedaron integradas en `df22fc5`. Los acuerdos C/Go también se integraron en el PR #18 (`fa44c72`). No hay un número de issue registrado.

- **Distribución estimada de horas:** Asigné 8 h: 3 h para revisar las estructuras y reglas de memoria de C secuencial, 3 h para completar las validaciones, la liberación de memoria y sus pruebas, 1 h para revisar a Sebastian (I2) y 1 h para coordinar los acuerdos con el equipo.
- **Tiempo del registro previo:** El desglose original suma 5 h (3 h de interfaces, 1 h de revisión y 1 h de coordinación). Este tiempo se conserva separado de las 8 h estimadas del plan.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Completé las interfaces de [C secuencial](../../c_secuencial/include/matrix.h): definí las reglas de las matrices, la reserva y liberación de memoria y los errores. Añadí pruebas para tamaños inválidos, datos incompletos, NaN, infinitos y uso incorrecto de la memoria. El 01/10/2026 ejecuté `scripts/test_windows.ps1 -Version c_secuencial` en Debug y con `-Configuration Release`; ambas ejecuciones terminaron con código 0. También contrasté las validaciones de matrices con Go y pasaron. Dejé las reglas de uso en el [README de C secuencial](../../c_secuencial/README.md).
- **Bloqueos y decisiones:** Adapté C a la [propuesta común con I3](../especificaciones_c_go_secuencial.md) para mantener las mismas reglas de datos y los códigos de salida: 0 para éxito, 1 para error y 2 para pendiente. Dejé la multiplicación para el Sprint 3; con entradas válidas, la función todavía indica que el cálculo está pendiente.
- **Criterio de aceptación:** Mi entregable técnico queda conforme según la revisión de I8. La distribución de horas de este cierre suma 8 h.
- **Coordinación:** Coordiné con Giuliano las reglas de matrices, errores y memoria de C y Go. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I2 (Sebastian):** Revisé el reparto de filas de Sebastian. Los ocho ejemplos y los 4480 casos comprobados salieron bien, incluidos los casos con más procesos que filas. El diseño queda conforme; su implementación corresponde al Sprint 4.

#### Integrante 2 (Sebastian)

- **Issues y pull requests:** PR #13 (`2af6097`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Distribución estimada de horas:** Asigné 8 h: 3 h para diseñar el reparto de filas y los desplazamientos MPI, 3 h para comprobar los ejemplos, los límites y los procesos sin filas, 1 h para revisar a Giuliano (I3) y 1 h para coordinar los acuerdos con el equipo.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
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
  - Compilación y pruebas de C paralelo completadas: pasaron las entradas, el smoke test MPI con dos procesos y dos hilos y el rechazo del cálculo con código 2. La evidencia está en «Unificación técnica del contrato» de este sprint.
- Bloqueos y decisiones: (1) `counts` y desplazamientos se expresan en **elementos `double`** (filas locales × N), no en filas; los desplazamientos son la suma acumulada de los `counts`. (2) **P > N es legal**: con `q = 0` y `r = N`, los primeros N procesos reciben 1 fila y los `P − N` restantes `count = 0` con desplazamiento N·N; MPI admite counts nulos y nadie queda esperando. (3) Se diseñan **dos funciones puras sin llamadas a MPI** —`partition_split` (filas e índice inicial) y `partition_rows` (elementos MPI)— para poder probarlas sin `MPI_Init` y para dar a `main.c` el límite del bucle OpenMP. (4) Sin VLA (MSVC no los admite en C11) e índice entero con signo en `parallel for`, según la guía §«Memoria y errores». (5) La implementación de `partition.c` queda para **S4** (I1 e I2); mientras tanto ambas funciones devuelven `PARTITION_PENDING` (2) y `status.json` no se modifica. (6) Diseño alineado con `docs/requisitos.md` RNF-04 y con la decisión de reparto 1D de `docs/bibliografia.md` (I8).

- **Aclaración que dejé:** el reparto todavía no está implementado. `partition_rows` devuelve pendiente y `partition_split` solo está declarada; ambas se completarán en S4.
- **Coordinación:** Como coordinador de S2, reuní las interfaces, los dos diseños paralelos, los fixtures y el contrato común.
- **Revisión a I3 (Giuliano):** Revisé las interfaces y los errores de Go secuencial de Giuliano. Las pruebas pasaron y las reglas coinciden con las acordadas para C. Su trabajo de este sprint queda conforme.

#### Integrante 3 (Giuliano)

- **Issues y pull requests:** PR #18 (`fa44c72`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Participantes y horas reales:** Dediqué 8 h: 3 h a revisar datos y validaciones, 3 h al contrato y las pruebas, 1 h a revisar el diseño de Eva y 1 h a coordinar el acuerdo con Yessly.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Corregí los errores de tamaño de `Generate` y las cinco pruebas que fallaban. El 01/10/2026 ejecuté `test_windows.ps1 -Version go_secuencial` desde la raíz; compilación y pruebas terminaron con código 0.
- **Bloqueos y decisiones:** Comprobé que el generador ya entrega matrices válidas. Dejé documentado el [acuerdo C/Go](../especificaciones_c_go_secuencial.md) y revisé la adaptación de Yessly. La multiplicación y los argumentos siguen para S3.
- **Criterio de aceptación:** Mis interfaces y sus pruebas quedan conformes según la revisión de I2.
- **Coordinación:** Coordiné con Yessly la equivalencia de validaciones, errores y tamaño de matrices. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I4 (Eva):** Revisé el diseño de Eva: el reparto de filas, el cierre del canal, la espera de los trabajadores y las reglas de tiempos y errores están claros y coinciden con el contrato común. Las observaciones anteriores quedaron resueltas en el diseño. Su entregable de este sprint queda conforme.

#### Integrante 4 (Eva)

- **Issues y pull requests:** PR #10 (`5056d1b`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Entregable:** Mi parte está documentada en el [diseño de Go paralelo](../arquitectura.md).
- **Entrega y trazabilidad:** Mi documento está incluido en la base `df22fc5`; el cierre reúne sus evidencias y revisiones.
- **Distribución estimada de horas:** Asigné 8 h: 3 h para diseñar los trabajadores y el reparto por bloques, 3 h para definir la propiedad de filas, el cierre del canal y la espera, 1 h para revisar a Fernando Saire (I5) y 1 h para coordinar los acuerdos con el equipo.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I3.
- **Coordinación:** Alineé el diseño de Go paralelo con el formato de Gerardo y los límites de tiempos de Andrés. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I5 (Fernando Saire):** Revisé los cinco casos de Fernando, incluido el de tamaño 3 por 3. Los resultados son correctos y las reglas de comparación dejan claras las tolerancias y el rechazo de NaN e infinitos. Su entregable queda conforme.
- **Pruebas y evidencias:** Revisé el diseño de bloques de filas, canal y espera en [arquitectura.md](../arquitectura.md). Las reglas quedaron claras; el cálculo paralelo se implementará en S4.

#### Integrante 5 (Fernando Saire)

- **Issues y pull requests:** PR #15 (`a7aa64d`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Distribución estimada de horas:** Asigné 8 h: 3 h para ampliar los casos de referencia con el ejemplo de tamaño impar, 3 h para comprobar los resultados y definir tolerancias y valores no admitidos, 1 h para revisar a Gerardo (I6) y 1 h para coordinar los acuerdos con el equipo.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Se añadió el caso de dimensión impar [`tests/fixtures/impar3.input.txt`](../../tests/fixtures/impar3.input.txt) con su resultado [`tests/fixtures/impar3.expected.txt`](../../tests/fixtures/impar3.expected.txt). El cálculo manual de sus nueve celdas y el criterio de comparación están documentados en [`tests/fixtures/README.md`](../../tests/fixtures/README.md).
- **Cobertura y criterio numérico:** Los fixtures recibidos ya cubrían identidad, matriz cero y valores negativos, por lo que no se duplicaron. Se añadió el caso 3 por 3 con ceros y negativos. Se adoptó el contrato común `atol = 1e-9`, `rtol = 1e-9`, comparación completa celda por celda y rechazo de NaN e infinitos.
- **Criterio de aceptación:** Mis casos de referencia quedan conformes según la revisión de I4. Mi distribución de 8 h y los acuerdos están registrados en este cierre.
- **Coordinación:** Relacioné los fixtures y las tolerancias con el formato de Gerardo y los diseños paralelos. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I6 (Gerardo):** Revisé el formato definitivo y los valores de control de Gerardo. Los lectores de C y Go siguen las mismas reglas y sus pruebas pasaron. La generación con la misma semilla está bien definida. Su entregable queda conforme.

#### Integrante 6 (Gerardo)

- **Issues y pull requests:** PR #12 (`fc14a0a`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Entregable:** Mi parte está documentada en el [formato de datos](../formato_datos.md).
- **Entrega y trazabilidad:** Mi documento está incluido en la base `df22fc5`; el cierre reúne sus evidencias y revisiones.
- **Distribución estimada de horas:** Asigné 8 h: 3 h para completar el formato común y las reglas del generador, 3 h para preparar y comprobar los valores de control y los casos de lectura, 1 h para revisar a Andrés (I7) y 1 h para coordinar los acuerdos con el equipo.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I5.
- **Coordinación:** Alineé el generador y los archivos de C y Go con las semillas y los valores de control acordados. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I7 (Andrés):** Revisé el protocolo de Andrés. Los tiempos, los campos del CSV, las repeticiones y el uso de memoria están definidos. Comprobé el plan completo de 288 ejecuciones y los planes reducidos; los conteos son correctos. Su entregable queda conforme.
- **Pruebas y evidencias:** Dejé definidos el formato por líneas, el generador común y sus valores de control en [formato_datos.md](../formato_datos.md). Las pruebas de entradas de los cuatro módulos pasaron; la evidencia está en la unificación del contrato de este sprint.

#### Integrante 7 (Andrés)

- **Issues y pull requests:** PR #4 (`ad24f9d`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Participantes y horas reales:** Andrés (8 h: 3 h delimitación estricta de cronómetros `kernel_s`/`total_s` y diseño del esquema CSV, 3 h diseño de la matriz exhaustiva de experimentos y protocolo de mitigación de sesgos, 1 h revisión cruzada de I8 Roberto sobre [`docs/bibliografia.md`](../bibliografia.md), 1 h coordinación de acuerdos).
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Pruebas y evidencias:** Entregable [`docs/protocolo_medicion.md`](../protocolo_medicion.md) actualizado a 1.2 el 01/10/2026. Incluye fronteras comunes de tiempos, CSV de 20 campos con reglas para fallos, plantilla de metadatos reproducibles, estimación de memoria y planes condicionados por hardware. El plan completo contiene 16 configuraciones por N y 288 corridas para tres N (48 warmups y 240 medidas); sustituye el conteo incorrecto del registro original. La extensión a 4096 añade 96 corridas.
- **Bloqueos y decisiones:** Una ronda por repetición, con orden directo/inverso alternado; mediana, IQR, mínimo y máximo de cinco observaciones válidas. Se conservan fallos y tiempos desfavorables. Un grupo incompleto no produce speedup oficial; una repetición justificada conserva el intento original y registra un lote completo nuevo con su referencia. No se habilitan mediciones mientras falten núcleos y validación matemática.
- **Criterio de aceptación:** Mi entregable queda conforme según la revisión de I6.
- **Coordinación:** Alineé los tiempos y los campos CSV con las interfaces y los diseños de C y Go. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I8 (Roberto):** Revisé los dos artículos y la decisión de diseño de Roberto. Las referencias corregidas y su relación con el reparto por filas están claras. El documento distingue lo que dicen los artículos de las decisiones del equipo. Su entregable queda conforme.

#### Integrante 8 (Roberto)

- **Issues y pull requests:** PR #2 (`2b0bac7`), integrado en `main`. Las correcciones posteriores quedaron en `df22fc5`. No hay un número de issue registrado.

- **Horas declaradas en el registro previo:** Roberto, 8 h: 3 h análisis de artículos, 3 h selección y diseño, 1 h coordinación y 1 h revisión asignada a I1. Se conserva esa declaración; no se añaden horas personales por esta actualización asistida.
- **Entrega y trazabilidad:** Mi entregable está incluido en la base `df22fc5`. Las referencias comunes de integración están en el cierre del equipo.
- **Entregable y actualización del 01/10/2026:** [`bibliografia.md`](../bibliografia.md) corregida con asistencia de Codex a solicitud de I8. Se consultaron ambos PDF locales, con páginas/secciones de respaldo, y fuentes de los autores para los metadatos: Quintin DOI `10.1109/ICPP.2013.89`; Hérault DOI `10.1109/ScalA49573.2019.00010`, pp. 33–41.
- **Decisión de diseño:** se mantiene el reparto 1D por filas por su continuidad y simplicidad dentro del alcance de la guía. HSUMMA usa una jerarquía virtual sobre una malla 2D y no equivale a nuestra combinación MPI/OpenMP. Se distinguen hallazgos de las fuentes y decisiones propias; se retiraron cifras de ancho de banda no medidas y garantías de eficiencia o caché. El rendimiento queda como objeto de las campañas futuras.
- **Criterio de aceptación:** Mi entregable queda conforme en esta evaluación según la revisión de I7. El resumen del equipo reúne las horas y los acuerdos de este cierre.
- **Coordinación:** Relacioné los artículos seleccionados con las decisiones de reparto y el alcance de las mediciones. Los acuerdos comunes se reúnen con Sebastian (I2).
- **Revisión a I1 (Yessly):** Revisé las interfaces de Yessly: las reglas de tamaño, los errores y la reserva y liberación de memoria están claras. Las pruebas en Debug y Release pasaron y las reglas coinciden con Go. Su entregable técnico queda conforme. También revisé las referencias de integración y los acuerdos documentados. Su registro distingue las horas declaradas de la distribución estimada.

## Cierre del equipo

| Integrante | Horas asignadas en el cierre | Origen |
| --- | ---: | --- |
| I1 · Yessly | 8 h | Distribución estimada |
| I2 · Sebastian | 8 h | Distribución estimada |
| I3 · Giuliano | 8 h | Declaración previa |
| I4 · Eva | 8 h | Distribución estimada |
| I5 · Fernando Saire | 8 h | Distribución estimada |
| I6 · Gerardo | 8 h | Distribución estimada |
| I7 · Andrés | 8 h | Declaración previa |
| I8 · Roberto | 8 h | Declaración previa |
| **Total asignado** | **64 h** | **48 h de trabajo, 8 h de revisión y 8 h de coordinación; incluye estimaciones** |

El plan asigna 16 h por integrante entre S1 y S2, 128 h de equipo. Estas cifras incluyen estimaciones y no representan el total de horas reales.

- **Coordinación del cierre:** Como Sebastian (I2), dejo reunidas las interfaces C/Go, los diseños MPI y Go paralelo, los casos ampliados, el formato común, el protocolo y la bibliografía.
- **Acuerdos:** Las cuatro versiones compartirán entradas, errores, tolerancias y límites de medición. Los diseños quedan preparados para implementar la multiplicación en S3/S4.
- **Entrega y trazabilidad:** Base de código y entregables `df22fc5` (`docs: corrige finales sprints 1 y 2`); antecedentes de integración PR #17 y PR #18. Este cierre documental organiza los registros sobre esa base.
- **Pruebas y evidencias:** Pruebas de los cuatro módulos conformes, C secuencial en Debug/Release, diseño MPI comprobado en 4480 casos, cinco fixtures verificados y protocolo de 288 ejecuciones comprobado. Los detalles están en las secciones individuales y los apartados de verificación.
- **Revisión y aceptación:** Las ocho evaluaciones del ciclo están registradas en este documento y resultan conformes al alcance del sprint. Son revisiones asistidas redactadas en la voz de los integrantes.
- **Estado final:** Entregables y evaluaciones conformes, con integración y acuerdos documentados. Para completar el parte real se necesitan los tiempos de I2, I4, I5 e I6. El cálculo y la medición permanecen en sus sprints.

## Unificación técnica del contrato · 2026-10-01

Las reglas de errores, archivos y límites de medición están unificadas. Las
evaluaciones del ciclo y el cierre documental están registrados arriba.

- `docs/contrato.md` fija los códigos del ejecutable: 0 éxito, 1 cualquier error
  y 2 solo pendiente. Los estados internos C se convierten por categoría;
  `INPUT_IO_ERROR` vale 2 internamente y debe convertirse a salida 1.
- Los generadores Go comparten `ErrInvalidDimension` y `ErrSizeOverflow`; con
  entradas válidas generan matrices. Los lectores Go diferencian formato incorrecto
  (`ErrInvalidFixture`) y fallo de lectura (`ErrFixtureIO`).
- Los cuatro lectores aplican la guía: N en línea propia, N filas de A y N de B,
  exactamente N valores por fila. Aceptan LF/CRLF y salto final opcional; rechazan
  filas fusionadas/divididas, blanco interno, BOM, NUL, CR aislado y valores no finitos.
  C y Go aceptan subnormales y underflow finito redondeado a cero.
- El protocolo 1.1 y la arquitectura sitúan el vaciado y la coordinación dentro
  de total_s y fuera de kernel_s. Go acumulará cálculo por worker y tomará el máximo;
  MPI reducirá máximos locales después de detener sus relojes. Validación e I/O
  quedan fuera. Los cronómetros reales siguen pendientes para S3/S4.
- La tabla completa de experimentos tiene 16 configuraciones por N: 288 corridas
  para tres dimensiones, con 48 warmups y 240 mediciones. Se alterna el orden
  directo/inverso entre rondas.

Verificación desde la raíz, configuración Debug:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all
```

Resultado final: **código 0 en los cuatro módulos**, incluyendo compilación,
pruebas de entradas/formato, go vet, pruebas Go, smoke tests y rechazo del cálculo
pendiente. Se añadieron 22 casos de gramática a cada lector, con resultados
esperados equivalentes en C y Go y sin salidas parciales ante error.

La primera ejecución dentro del entorno restringido no pudo lanzar MPI (acceso
denegado). La verificación final se ejecutó fuera de esa restricción y pasó
también la prueba 2 procesos × 2 hilos. Estas pruebas no validan multiplicación
ni generan mediciones. Las entradas anteriores conservan su contexto histórico;
la cifra 234 del protocolo 1.0 queda sustituida por 288 en la versión 1.1.

## Corrección del entregable de I7 · 2026-10-01

Se completó el diseño técnico de Andrés para S1/S2 en el protocolo **1.2** y
se corrigió su registro individual. La evaluación de I6 está registrada en su
sección de este sprint; se mantienen las horas declaradas previamente.

- Preguntas P1–P5 vinculadas a métricas y comparaciones concretas; umbrales de
  rentabilidad, superioridad de topologías y efectos de caché quedan como
  hipótesis por comprobar, no resultados de artículos ni mediciones realizadas.
- CSV: reglas entre parámetros, estados y tiempos vacíos ante fallo; metadatos
  completos mediante [entorno_medicion.json](../plantillas/entorno_medicion.json),
  con versiones de herramientas, opciones de compilación, hashes de ejecutables
  y carpetas separadas por campaña/PC/intento.
- Plan según capacidad: 72, 126, 198 o 288 corridas para W máximo 1, 2, 4 u 8,
  respectivamente, con tres N. Con W=8, añadir N=4096 lleva el total a 384.
  Se incluyen los bloques locales y las B por proceso en la estimación MPI,
  más la referencia completa de validación. Los 8 GB visibles de Andrés no se
  confunden con memoria libre ni con una comprobación actual de sus dependencias.
- Estadística: cuartiles inclusivos definidos para cinco medidas; grupos completos
  de la misma campaña/configuración/N/semilla, referencia del mismo lenguaje,
  tratamiento de ceros, fallos y repetición justificada sin elegir mejores tiempos.

**Comprobación ejecutada desde la raíz:** lectura del Markdown y JSON con Python
3.12.11, sin modificar los programas ni producir tiempos. Resultado: **código 0**.
Se comprobaron las 16 configuraciones únicas de la tabla; los cuatro conteos por
capacidad; 12 planes (piloto, oficial y extendido para cuatro capacidades), sin
duplicados y con warmup + repeticiones 1..5 por combinación; las cinco filas de
memoria y la suma por rank para P=1/2/4/8; las 20 columnas CSV contra arquitectura;
la plantilla JSON, los enlaces locales y un control de mediana/IQR.
`git diff --check` también terminó con código 0. Las pruebas de los cuatro módulos
del apartado anterior corresponden a la unificación de código; este ajuste modifica
el diseño y sus registros, sin generar datos experimentales.
