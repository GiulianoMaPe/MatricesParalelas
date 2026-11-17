# Sprint 6 Optimizar con evidencia

> Acta histórica del alcance Linux, conservada antes de integrar I4/I7.
> Su estado Windows pendiente corresponde a esa fecha. El estado vigente y
> la aceptación de integración están en [sprint-06.md](sprint-06.md).

**Estado al 11/11/2026: alcance Linux autorizado completado; cierre técnico Windows pendiente.**

Se ejecutó el trabajo que no requiere Windows a solicitud del responsable.
Se conserva el algoritmo de producción y se entregan candidatas aisladas,
mediciones de núcleos Linux, memoria, equidad y un procedimiento de reproducción.
No se atribuyen a este entorno pruebas MSVC/MS-MPI ni una congelación experimental
completa. El plan original y la entrega previa se conservan como antecedentes;
el estado actual se detalla en la integración técnica al final de esta acta.

Rama actual: `feature/s06-optimizacion-evidencia`, creada después de actualizar
`main` (`dd008f7`, que integra la entrega de diseño del PR #43).


Semana 6 · 64 horas de equipo · 8 horas por integrante

## Objetivo y aceptación

Mejorar el rendimiento sin cambiar la corrección ni introducir comparaciones injustas.

Cierre: Cada cambio conservado tiene medición antes y después y pasa la batería común; se fija el algoritmo para la campaña.

## Trabajo de cada integrante

Integrante 1  Medir localidad y accesos del núcleo C secuencial (3 h). Aplicar como máximo una mejora justificada y documentar su efecto (3 h). Entregable: Comparativa de una optimización C. Ubicación: c_secuencial/src/matrix.c.

Integrante 2  Medir reparto OpenMP y configuraciones iniciales de P y T (3 h). Ajustar granularidad o copias y verificar que no se fuerce un único núcleo (3 h). Entregable: Comparativa del híbrido C. Ubicación: c_paralelo/src/matrix.c.

Integrante 3  Medir asignaciones y acceso a slices del Go secuencial (3 h). Reducir asignaciones evitables y comprobar equivalencia numérica (3 h). Entregable: Comparativa de una optimización Go. Ubicación: go_secuencial/matrix.go.

Integrante 4  Medir tamaño de bloque y coste del canal de Go paralelo (3 h). Ajustar bloques y cantidad de workers sin crear tareas por celda (3 h). Entregable: Comparativa de granularidad Go. Ubicación: go_paralelo/workers.go.

Integrante 5  Estimar memoria del proceso raíz y del resto de procesos (3 h). Medir el pico en tamaños piloto y fijar límites seguros para la campaña (3 h). Entregable: Tabla de memoria y capacidad. Ubicación: docs/memoria.md.

Integrante 6  Ejecutar pruebas de regresión después de cada cambio aceptado (3 h). Revisar diferencias de orden de bucles y oportunidades de optimización desigual (3 h). Entregable: Informe de equidad algorítmica. Ubicación: docs/equidad_algoritmica.md.

Integrante 7  Recopilar mediciones del piloto con metadatos completos (3 h). Descartar cambios sin mejora consistente o mantenerlos como experimento separado (3 h). Entregable: Registro de decisiones de rendimiento. Ubicación: docs/optimizaciones.md.

Integrante 8  Actualizar decisiones de diseño y su relación con la literatura (3 h). Definir qué cambios se conservan y los criterios para congelar el algoritmo (3 h). Entregable: Diseño validado y decisiones de optimización. Ubicación: docs/arquitectura.md.

Cada integrante añade 1 h de revisión cruzada y 1 h de coordinación: 8 h en total. La evidencia y observaciones se registran en docs/sprints/sprint-06.md.

## Registro de cierre

- Ejecución actual: trabajo individual asistido por Codex. No se declaran 64 h personales; las horas activas no fueron cronometradas. El tiempo de máquina medido se detalla abajo.
- Rama: `feature/s06-optimizacion-evidencia`. No se abrieron issues/PR nuevos ni se publicó la rama durante esta ejecución.
- Pruebas y evidencias: ver integración técnica Linux y sus archivos originales. La batería Windows final sigue pendiente.
- Alcance acordado: Windows está en otra partición; el usuario indicó continuar solo con lo que no requiere Windows. Se conservan los núcleos de producción hasta contar con la evidencia contractual.
- Revisión actual: inspección propia de código, fuentes archivadas, datos, equidad y documentos. Revisión externa y aceptación Windows pendientes.

### Antecedente de diseño recibido en PR #43

El registro siguiente conserva la entrega original. Su declaración de congelación
queda condicionada por los criterios de aceptación corregidos en
[arquitectura](../arquitectura.md); no acredita los experimentos pendientes.

#### Integrante 8

- Participantes y horas reales: Roberto (8 h: 3 h actualización de decisiones de diseño y fundamentación con la literatura científica, 3 h formulación de criterios de congelamiento algorítmico y evaluación de optimizaciones descartadas, 1 h coordinación general, 1 h revisión cruzada asignada a I1 Yessly).
- Issues y pull requests: Rama de trabajo `feature/s06-i08-diseno-optimizaciones`.
- Pruebas y evidencias: Entregable `docs/arquitectura.md` completado y actualizado con las Secciones 9 a 12. Se fundamenta la jerarquía de memoria (L1/L2/L3), líneas de caché de 64 bytes y la superioridad de stride-1 en el orden canónico $i \to k \to j$ frente a $i \to j \to k$ (Dongarra et al., Hennessy & Patterson). Se analiza el particionado jerárquico comparado con H-SUMMA (Quintin & Wagner 2013) y la ausencia de sobrecostes de empaquetado 2D en el reparto 1D continuo por filas. Se fundamenta el modelo CSP de Go (Hoare, Golani et al. 2021). Se formulan las decisiones de diseño para descartar tiling manual y SIMD asimétrico en favor de la auto-vectorización del compilador y la equidad algorítmica. Se formaliza el Marco Normativo de Congelamiento Algorítmico en 5 criterios inviolables para las campañas de los Sprints 7 y 8.
- Bloqueos y decisiones: Se declara oficialmente congelado el algoritmo canónico $i \to k \to j$ en sus cuatro versiones (`c_secuencial`, `c_paralelo`, `go_secuencial`, `go_paralelo`), prohibiendo alteraciones de bucles que distorsionen la comparabilidad de rendimiento.
- Revision y criterio de aceptacion: Entregable de I8 finalizado y conforme; listo para revisión formal por Integrante 7 (Andrés). Revisión a I1 Yessly pendiente a la publicación de su PR de Sprint 6.


## Integración técnica del alcance Linux

| Trabajo | Resultado entregado | Aceptación que permanece pendiente |
| --- | --- | --- |
| C secuencial | Base frente a candidata con alias de C restringida; referencia por celda y compilación controlada en unidades separadas. | Antes/después MSVC y regresión Windows. |
| C híbrido | Kernel OpenMP local frente a static,1 con T=1,2,4; particionado y casos vacíos probados. | Procesos MPI reales, P/T, afinidad e hilos por rank en Windows. |
| Go secuencial | Slices por fila, diagnóstico de asignaciones y producto con semillas/casos impares. | Comparativa Go windows/amd64 y oportunidad equivalente en paralelo. |
| Go paralelo | Base frente a bloques de 16 y canal sin buffer, W=1,2,4; pruebas de estabilidad y carreras. | Confirmación de los resultados en Windows. |
| Memoria | [Modelo por raíz/rank/conjunto y picos RSS Linux](../memoria.md). | Picos Windows por proceso y agregado simultáneo MPI. |
| Equidad | [Auditoría de las cuatro versiones y regresión portable](../equidad_algoritmica.md). | Batería común MSVC/MS-MPI Debug/Release final. |
| Decisiones | [Antes/después, dispersión, exclusiones y decisiones](../optimizaciones.md). | Aceptación de una candidata en la plataforma de campaña. |
| Diseño | [Arquitectura revisada](../arquitectura.md): fuentes verificadas, cronometraje y congelación condicionada. | Cierre formal y congelación experimental de S7. |

### Evidencias y resultados

- [Intento A](../../resultados/diagnostico/s06/20261112T033150Z_fedora/entorno.json): 342 corridas, 57 grupos; 57 calentamientos
  y 285 medidas. Se usan sus grupos Go. Los C se conservan como exploración.
- [Intento B controlado C](../../resultados/diagnostico/s06/20261112T035217Z_fedora/entorno.json): 144 corridas, 24 grupos;
  24 calentamientos y 120 medidas. Corrige la ventaja potencial de compilar
  candidata junto al harness y base por separado. Las comparativas C usan B.
- Total bruto: **486 corridas numéricamente válidas**. Cada grupo tiene un
  calentamiento y cinco medidas únicas; se alternaron rondas directas/inversas.
  Se conservan resultados desfavorables, fuentes exactas, hashes y diagnósticos.
- Los grupos base/candidata se comparan dentro de su mismo intento. No se
  fusionan medidas de A/B ni se escoge el lote por ser más rápido.
- Tiempo de pared sumado de las corridas: **1264.5 s**; incluye referencia,
  arranque y validación. No equivale a horas activas de desarrollo.
- [Verificación](../../resultados/diagnostico/s06/verificacion_20261112T032934Z/verificacion.json): **85 comprobaciones PASS**;
  cuatro construcciones ASan no pudieron enlazar por falta de libasan. Sus
  errores se conservaron y los mismos contratos se ejecutaron en -O0/-g y -O2.
- Go: pruebas completas, vet y race en ambos módulos. Compilación cruzada de
  pruebas windows/amd64 correcta; no se ejecutaron esos binarios en Windows.
- C: contratos secuenciales y locales OpenMP, fixtures, fallos simulados,
  4480 pares de partición y candidatas controladas en dimensiones 1,3,7,17,65.
- Comparador: suite existente pasada en PowerShell Linux, con alias temporal
  de powershell.exe a pwsh. No acredita PowerShell Windows/MS-MPI.
- Runner: seis pruebas de resumen/captura/fallos/timeout y lotes de prueba
  pequeños; `go_paralelo` ahora permite compilar pruebas en Linux mediante
  un stub de metadatos que sigue rechazando la CLI de campaña fuera de Windows.

### Decisiones de integración

1. Mantener los cuatro núcleos de campaña. Las candidatas quedan en pruebas,
   con los datos disponibles para aceptarlas o descartarlas después de Windows.
2. Mantener bloques ceil(N/W), canal W y límite MaxWorkers=1024. La variación
   de canal/bloques no dio una mejora consistente entre tamaños/presupuestos.
3. No atribuir a caché una causa no medida ni garantizar vectorización en todos
   los compiladores. Corregir autores/alcance de la literatura y el falso
   requisito de igualdad por bits o significación garantizada por superar 5%.
4. Conservar reserva de matrices antes de T0 y coordinación Go dentro de total_s.
   No prometer que el GC solo se ejecuta después del cronómetro.
5. Sincronizar la plantilla de entorno con el protocolo 1.3, sin habilitar el
   benchmark pendiente de S7 ni producir datos oficiales de S8.

### Criterio de aceptación actual

- [x] Alcance Linux autorizado ejecutado y documentado, con evidencia reproducible.
- [x] Candidatas aisladas y validación por celda, sin ventaja algorítmica aplicada
  de forma desigual a los programas de campaña.
- [x] Memoria estimada y pico RSS observado del laboratorio, con límites claros.
- [x] Informes de optimización, equidad y arquitectura coherentes con los datos.
- [ ] Batería Windows final Debug/Release de las cuatro versiones.
- [ ] Comparativas MSVC/MS-MPI y memoria por rank/conjunto en Windows.
- [ ] Revisión externa, cierre formal y fijación experimental para S7.

El [procedimiento de reproducción y pendientes](../sprint06_reproduccion.md)
permite continuar desde esta entrega. No se marca completado el cierre técnico
integral de S6 hasta aportar las comprobaciones Windows que faltan.
