# Revisión de cierre S7 · Windows nativo · 17/11/2026

Estado: **lotes técnicamente verificados, sin aceptación para cierre; repetición solicitada**.
Los registros humanos quedan en `aceptacion_responsable.json`; la reserva
autorizada de máquina, en `reserva_maquina.json`.

## Candidata y evidencia

Commit de código medido: `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.
La documentación de cierre posterior no sustituye esa revisión experimental.

| Intento | Estado | Observaciones OK | Grupos completos | Duración de campaña |
| --- | --- | ---: | ---: | ---: |
| [Piloto](../s07_windows_20261117_piloto_02/verificacion.json) | COMPLETE / VERIFIED | 198 | 33 | 715.7244307 s |
| [Reproducción](../s07_windows_20261117_reproduccion_02/verificacion.json) | COMPLETE / VERIFIED | 198 | 33 | 715.8565236 s |

Cada intento contiene 33 calentamientos y 165 medidas, N=256/512/1024,
semilla 42, cuatro versiones y W=1/2/4 según seis núcleos físicos. No hubo
exclusiones por memoria. Plan, CSV, stdout/stderr, procesos y ranks MPI pasan
el verificador; se conservan registros y resultados originales por separado.

Las doce comprobaciones de `verificacion_cruzada.json` pasan: misma candidata,
fuentes y builds limpios, mismos binarios y fuentes, plan idéntico byte a byte,
mismos parámetros, hardware/alimentación, tablas completas y grupos válidos.
La reproducción utilizó `-SkipBuild`; no recompiló los cuatro ejecutables.

SHA-256 de los binarios, iguales en ambos intentos:

| Versión | SHA-256 |
| --- | --- |
| C secuencial | `1FB82C33D0A17B266DABB281B4CB37794227AB524DB685E285B48607DAF96187` |
| C paralelo | `DCBA45091FDB781C8B853A7CAD51FD02C849F3D997DCF16E34C273065F6C776E` |
| Go secuencial | `3C4071ACB70DD028DC808F25EB43600014D36E336D652D2D0544473F8F0C5E11` |
| Go paralelo | `101754DD3CB898F84C08799803CC27B8E14D096E348EC0371FFF8418D8E5907A` |

Herramientas efectivas: MSVC compilador 19.44.35230.0 (toolset 14.44.35207),
Windows SDK 10.0.26100.0, MS-MPI Runtime 10.1.12498.52, Go 1.27.4 windows/amd64
y Windows PowerShell 5.1.26100.9711. El SDK MPI queda identificado por hashes
de `mpi.h` y `msmpi.lib` en los manifiestos de cada intento.

## Condiciones y límites de la comparación

PC oficial confirmada: PCG1UL14N0, Ryzen 5 3600, 6 núcleos físicos/12 lógicos,
Windows 11 Pro build 26300, RAM visible 17085501440 bytes, AC y plan Equilibrado.
Entre el fin del piloto y el inicio de las mediciones de reproducción hubo
5 min 20 s, incluidos reposo y repetición de pruebas. La copia congelada se
preparó antes de comenzar las mediciones del segundo lote.

Se registraron 198 muestras de carga/RAM por intento. Carga observada: 1–80%
en piloto y 1–57% en reproducción. RAM libre mínima: 2015820 y 3180024 KiB,
respectivamente. Estas muestras preceden las corridas y pueden incluir carga
de la corrida anterior; no identifican por sí solas tareas de fondo.

**Estos lotes no capturaron temperatura CPU/GPU**. No se afirma
estabilidad térmica medida, ausencia de throttling ni aislamiento perfecto.
No se atribuyen variaciones a temperatura, caché o carga sin mediciones causales.

La mediana de cambios absolutos relativos entre medianas de `total_s` de los
33 grupos es 3.6004%; el máximo es 28.2531%, C paralelo N=512/P2/T2:
0.0185615 s frente a 0.0238057 s. Se conserva la diferencia y todos los datos;
no se impone retrospectivamente un umbral de equivalencia temporal. La
reproducción acredita el procedimiento y la corrección, con esos límites.
`comparacion_reproduccion.csv` mantiene cada grupo y ambos intentos separados.

## Reserva y preparación de S8

El responsable autoriza elegir la franja necesaria y se adapta a ella.
Reserva de PC: **18/11/2026, 09:00–12:00, America/Lima (UTC−5)**.
La proyección conservadora usa el mayor tiempo observado: 95.4475 min de
campaña S8 y 143.1713 min con 50% de margen; se añaden 30 min de preparación/
revisión y se redondea a tres horas. Es una proyección, no una medición S8.

N=2048 tiene huella matricial máxima estimada de 301989888 bytes (288 MiB),
sin runtime/pilas; revalidar RAM disponible antes de medir. Timeout inicial:
300 s por corrida. El máximo de pared observado en piloto fue 8.5629233 s;
su proyección cúbica simple es 68.5034 s, sin garantía sobre tiempos futuros.
Ante fallo, conservar el intento y repetir el lote completo con ID nuevo.

La copia `.cache/s08-candidata-97ccc98` conserva fuentes byte a byte y binarios
originales; `verificacion_candidata_s8.json` acredita cuatro builds oficiales
coherentes y fuentes limpias. Ejecutar S8 desde esa copia, cuyo HEAD es el
commit medido, siguiendo el [acta](../../../docs/campana.md). Una nueva clonación
no incluye binarios ni esta copia local: reconstruir requiere repetir su
aceptación, sin presumir los hashes originales.

Las 8 h por integrante (64 h de equipo) son declaración del responsable.
La revisión integrada de Codex no se atribuye como revisión cruzada humana
de otros integrantes. La conformidad final corresponde al responsable.

## Decisión posterior del responsable

El responsable comunica uso actual de Zoom y Google/navegador y solicita repetir
en reposo, sin conceder aceptación de cierre. Confirma el 17/11, 13:00–14:00
(Lima). No se eliminan ni sustituyen los archivos de este informe.
Posteriormente se comprobó que la GPU sí tiene sensor accesible mediante
`nvidia-smi`. El responsable elige registrar GPU y mantener CPU sin lectura,
sin instalar PawnIO. Se preparan lotes `_03` y un informe separado; la reserva
S8 de este documento queda provisional hasta revisar esos resultados.
