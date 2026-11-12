# Decisiones de optimización — cierre S6

Revisión del 12/11/2026. Se priorizaron e integraron las entregas I4 e I7;
I8 ya estaba integrado. Se conservan sus aportes y autorías. El
[original de I7](optimizaciones_i7_original_s06.md) y el
[diagnóstico Linux](optimizaciones_portable_s06.md) permanecen como antecedentes,
separados de la [aceptación Windows](cierre_s06_windows.md).

## Decisiones que recibe S7

| Hipótesis | Decisión | Fundamento y frontera |
| --- | --- | --- |
| C-01 `restrict_c` | Experimental; conservar base | No se exige promover cambios: el contrato y la equidad final priorizan una base común. Los datos MSVC inferiores muestran el efecto local, sin convertir aliasing aislado en una optimización aceptada en el híbrido. |
| C-02 `static1` | Conservar `schedule(static)` | Kernel local separado; no sustituye las observaciones MPI completas ni prueba una mejora general de P/T. |
| GO-01 `row_slices` | Experimental; conservar índices actuales | El kernel ya tiene cero reservas. Promover solo el secuencial requeriría contrastar también `multiplyBlock`; se conserva simetría y se entrega la oportunidad como experimento futuro, sin reclamar que la candidata sea más lenta. |
| GO-02 `block16` | Conservar `ceil(N/W)` | Se prioriza la conclusión de I4: los beneficios dependen de N/W y el reparto dinámico debe estudiarse simétricamente. |
| GO-03 `unbuffered` | Conservar canal W | No se acepta una política universal por un subconjunto favorable. El pool, canal, despacho/cierre/espera siguen dentro de total_s. |
| OPT-01 de I7: i,k,j | Conservar | Accesos contiguos verificados por inspección; no se acredita la cifra 8–12x sin la comparación bruta correspondiente. |
| OPT-02/03/04: tiling, transposición y SIMD manual | Excluidos del alcance canónico | Decisión de diseño/equidad; no se inventan medidas para técnicas que este cierre no ejecutó. Transponer a otro buffer no viola por sí mismo la inmutabilidad, pero cambia representación/trabajo y requiere evaluación simétrica. |
| OPT-05: reservas | Conservar | Matrices y slots antes de T0; canal/pool dentro de total_s. No se garantiza ausencia del GC durante cálculo. |
| OPT-06: filas contiguas | Conservar | Un propietario por fila. Hay como máximo W tareas, no necesariamente exactamente W, y no se afirma ausencia total de false sharing sin medirlo. |

Se fija el algoritmo existente, sin introducir cambios artificiales. La decisión
no necesita que todas las candidatas regresen: las mejoras aisladas pueden
permanecer experimentales al no aceptarse su integración simétrica en este sprint.

## Antes/después en MSVC y Go Windows

Semilla 42, un calentamiento y cinco medidas, mismas condiciones. Valores en ms:
mediana [IQR]. Reducción = 100*(base-candidata)/base; negativa es regresión.
Cada fila pertenece a su mismo grupo N/W e intento, sin fusionar hosts ni Linux.
Los grupos Go con alguna medida total/kernel menor de 100 ms son diagnóstico
de tiempos cortos por la resolución local cercana a 0,5 ms. No justifican por sí
solos una aceptación; `clock-policy.json` los clasifica sin eliminar datos.

| Laboratorio | N | W/T | Candidata | Total base | Total candidata | Reducción | Kernel base → candidata |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| go_paralelo | 1024 | 4 | unbuffered | 480.411 [20.819] | 453.078 [25.555] | +5.69% | 479.406 → 451.570 |
| go_paralelo | 1024 | 4 | block16 | 480.411 [20.819] | 481.741 [26.896] | -0.28% | 479.406 → 479.695 |
| go_paralelo | 1024 | 2 | unbuffered | 777.927 [101.967] | 796.433 [41.436] | -2.38% | 776.916 → 794.850 |
| go_paralelo | 1024 | 2 | block16 | 777.927 [101.967] | 789.992 [174.092] | -1.55% | 776.916 → 788.985 |
| go_paralelo | 1024 | 1 | unbuffered | 1282.107 [84.976] | 1283.700 [77.086] | -0.12% | 1280.084 → 1283.196 |
| go_paralelo | 1024 | 1 | block16 | 1282.107 [84.976] | 1221.669 [24.211] | +4.71% | 1280.084 → 1220.153 |
| go_secuencial | 1024 | 1 | row_slices | 869.825 [86.325] | 457.561 [47.683] | +47.40% | 868.819 → 455.385 |
| c_openmp_local | 1024 | 4 | static1 | 254.454 [12.152] | 230.282 [28.513] | +9.50% | 253.249 → 229.132 |
| c_openmp_local | 1024 | 2 | static1 | 464.315 [61.975] | 393.440 [13.355] | +15.26% | 463.264 → 392.264 |
| c_openmp_local | 1024 | 1 | static1 | 742.068 [33.915] | 549.308 [76.996] | +25.98% | 740.933 → 547.604 |
| c_secuencial | 1024 | 1 | restrict_c | 234.119 [29.443] | 230.721 [35.525] | +1.45% | 232.936 → 229.592 |
| go_paralelo | 512 | 4 | unbuffered | 46.905 [2.015] | 45.356 [5.404] | +3.30% | 45.956 → 44.853 |
| go_paralelo | 512 | 4 | block16 | 46.905 [2.015] | 42.462 [0.429] | +9.47% | 45.956 → 41.960 |
| go_paralelo | 512 | 2 | unbuffered | 76.151 [10.866] | 75.127 [8.695] | +1.34% | 75.645 → 74.623 |
| go_paralelo | 512 | 2 | block16 | 76.151 [10.866] | 79.448 [8.531] | -4.33% | 75.645 → 79.433 |
| go_paralelo | 512 | 1 | unbuffered | 141.404 [5.519] | 144.168 [8.660] | -1.95% | 141.404 → 143.164 |
| go_paralelo | 512 | 1 | block16 | 141.404 [5.519] | 140.395 [2.348] | +0.71% | 141.404 → 139.887 |
| go_secuencial | 512 | 1 | row_slices | 95.909 [1.970] | 51.398 [1.084] | +46.41% | 95.909 → 50.887 |
| c_openmp_local | 512 | 4 | static1 | 27.778 [5.255] | 24.218 [1.749] | +12.82% | 27.410 → 23.943 |
| c_openmp_local | 512 | 2 | static1 | 42.535 [3.709] | 35.248 [3.552] | +17.13% | 42.244 → 34.956 |
| c_openmp_local | 512 | 1 | static1 | 74.667 [1.158] | 61.267 [2.130] | +17.95% | 74.388 → 60.894 |
| c_secuencial | 512 | 1 | restrict_c | 23.842 [0.659] | 24.752 [1.897] | -3.82% | 23.557 → 24.407 |
| go_paralelo | 256 | 4 | unbuffered | 7.817 [0.923] | 6.158 [0.424] | +21.22% | 6.812 → 6.158 |
| go_paralelo | 256 | 4 | block16 | 7.817 [0.923] | 6.182 [0.906] | +20.92% | 6.812 → 6.154 |
| go_paralelo | 256 | 2 | unbuffered | 10.093 [1.992] | 10.971 [2.060] | -8.70% | 10.093 → 10.824 |
| go_paralelo | 256 | 2 | block16 | 10.093 [1.992] | 11.150 [2.920] | -10.47% | 10.093 → 11.150 |
| go_paralelo | 256 | 1 | unbuffered | 17.466 [0.427] | 17.514 [1.259] | -0.27% | 17.466 → 17.514 |
| go_paralelo | 256 | 1 | block16 | 17.466 [0.427] | 18.501 [1.547] | -5.93% | 17.466 → 18.501 |
| go_secuencial | 256 | 1 | row_slices | 12.234 [0.612] | 6.547 [0.099] | +46.48% | 12.234 → 6.500 |
| c_openmp_local | 256 | 4 | static1 | 3.468 [0.474] | 3.369 [0.660] | +2.84% | 3.369 → 3.293 |
| c_openmp_local | 256 | 2 | static1 | 6.096 [0.532] | 5.023 [0.052] | +17.60% | 6.018 → 4.944 |
| c_openmp_local | 256 | 1 | static1 | 9.540 [0.940] | 7.779 [0.167] | +18.46% | 9.456 → 7.625 |
| c_secuencial | 256 | 1 | restrict_c | 3.073 [0.094] | 3.260 [0.433] | -6.09% | 2.992 → 3.181 |

Los mínimos/máximos, IQR kernel, tiempo de pared y todas las observaciones están
en el [resumen](../resultados/piloto/s06_windows_20261112/summary.csv) y los [originales](../resultados/piloto/s06_windows_20261112/observations.jsonl).
Los picos del programa completo se conservan aparte en [memoria](memoria.md):
no se atribuyen a variantes aisladas sin perfiles por variante.
Los JSON incluyen las asignaciones N=17 del kernel/API/pool; no se presentan como
asignaciones del N principal ni se usan sus tiempos para escalabilidad.

## Revisión de la evidencia recibida

I4 aporta 720 corridas en Ryzen 7 3700X/Go 1.27.1, más benchmarks del canal.
El CSV tiene 189 filas con kernel mayor que total al mezclar
QPC y el reloj de los workers. Se preserva intacto y se limita su uso al estudio
exploratorio de total QPC; no se acepta como CSV contractual ni para calcular
overhead válido. El [auditor](../resultados/piloto/s06_windows_20261112/verification/granularity-historical-audit.json)
registra hash y conteos. Se corrigió el arnés: total/kernel usan el reloj
monotónico de producción, QPC es auxiliar y los tiempos inválidos abortan.
Pasaron 72 corridas pequeñas con todos los bloques y dos presupuestos.

La tabla preliminar de I7 no incluye corridas brutas con las que reconstruir
sus porcentajes. Se conserva como entrega histórica atribuida, sin inventar
metadatos ni aceptarla como prueba nueva. El 5% no demuestra significación;
se consideran dispersión, extremos, consistencia y condiciones.

No se midieron contadores de caché, pausas GC ni instrucciones SIMD emitidas en
Windows. No se sostienen garantías sobre ellos. La tolerancia es
`abs(obtenido-esperado) <= 1e-9 + 1e-9*abs(esperado)`, no igualdad por bits obligatoria.
