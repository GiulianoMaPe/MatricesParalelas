# Sprint 8 · Integrante 2 (Sebastian) — Plan, evidencia y handoff

**Estado:** herramienta de extracción/verificación entregada y probada; **campaña
oficial pendiente de ejecución en la PC oficial**.
**Objetivo del sprint:** producir `resultados/raw/c_paralelo.csv` desde una
campaña oficial con participación real de procesos e hilos verificada.
**Asignación oficial:** [`docs/sprints/sprint-08.md`](sprint-08.md), Integrante 2.
**Entregable oficial:** CSV originales de C paralelo · `resultados/raw/c_paralelo.csv`.

---

## 1. Resumen ejecutivo

El trabajo de I2 en S8 tiene dos partes:

1. **Ejecutar y supervisar** las combinaciones del híbrido C y verificar que cada
   fila tenga `processes=P`, `threads=T`, `observed_threads=T`, `OMP_DYNAMIC=FALSE`
   y repeticiones completas; registrar anomalías sin borrar datos.
2. **Entregar** `resultados/raw/c_paralelo.csv` con solo las filas
   `version=c_paralelo` de la campaña oficial, preservando los CSV originales.

En esta rama se implementó y probó la **herramienta de cierre** (extractor y
validador) y se generó una **extracción de diagnóstico** desde el piloto S7.
La campaña oficial no pudo ejecutarse en esta PC por falta de MSVC, Windows SDK
y MS-MPI, cuya instalación requiere permisos de administrador (§3). El CSV
oficial **no se creó ni se simuló**.

---

## 2. Alcance y no alcance

### Dentro del alcance de I2

- Supervisar el lote `c_paralelo` de la campaña integrada oficial.
- Verificar procesos, hilos, `OMP_NUM_THREADS`, `OMP_DYNAMIC=FALSE`, argumentos
  `mpiexec -n P`, filas por rank, igualdad `stdout`/CSV y estado de bitácora.
- Extraer la vista `resultados/raw/c_paralelo.csv` sin recalcular tiempos.
- Registrar anomalías y grupos incompletos sin inventar filas.

### Fuera del alcance de I2

- Ejecutar los lotes `c_secuencial`, `go_secuencial` y `go_paralelo` (I1/I3/I4).
- Aceptación global y calidad de los cuatro lotes (I5).
- Resumen estadístico y speedups (I7).
- Congelación de la candidata y acta de campaña (I8).

---

## 3. Preflight de esta PC y bloqueo

| Requisito | Resultado en esta PC |
| --- | --- |
| `cl.exe` / MSVC C++ | **Ausente** |
| Windows SDK | **Ausente** |
| `mpiexec.exe` / MS-MPI | **Ausente** |
| Go | Presente, pero no habilita el híbrido C |
| Permisos de administrador | **No** (`IsInRole(Administrator)=False`) |

Los paquetes de Visual Studio Build Tools y MS-MPI existen en `winget`, pero su
instalación exige elevación. Por eso **esta PC no puede producir la campaña
oficial** y no se ejecutó ningún binario C.

Consecuencia: el entregable `resultados/raw/c_paralelo.csv` queda **pendiente**
hasta ejecutar en la PC oficial (`PCG1UL14N0`, Ryzen 5 3600, 6 núcleos físicos,
MSVC 14.44, Windows SDK 10.0.26100, MS-MPI 10.1.12498.52, según
[`docs/campana.md`](../campana.md)).

---

## 4. Entregado en esta rama

| ID | Entregable | Ruta | Estado |
| --- | --- | --- | --- |
| D1 | Extractor/validador de `c_paralelo` | `scripts/extract_s08_c_paralelo.ps1` | Implementado |
| D2 | Pruebas del extractor (13 casos) | `tests/extract_s08_c_paralelo_test.ps1` | 13/13 |
| D3 | Evidencia de diagnóstico (piloto S7) | `resultados/diagnostico/s08_i02_piloto_s07/` | Generada |
| D4 | Plan y handoff oficial | `docs/sprints/sprint-08-i02-plan.md` | Este documento |
| D5 | Registro en el acta del sprint | `docs/sprints/sprint-08.md` | Añadido |
| D6 | `resultados/raw/c_paralelo.csv` | `resultados/raw/c_paralelo.csv` | **Pendiente en PC oficial** |

---

## 5. Extractor: uso y controles

### 5.1 Interfaz

```text
scripts/extract_s08_c_paralelo.ps1
    -CampaignDirectory <carpeta integrada>   (obligatorio)
    -Phase oficial | piloto | diagnostico    (por defecto: oficial)
    -OutputPath <ruta>                        (oficial: resultados/raw/c_paralelo.csv)
    -ManifestPath <ruta>                      (por defecto: junto a OutputPath)
    -ExpectedSizes 512,1024,2048              (opcional)
    -ExpectedCommit <sha completo>            (opcional)
    -AllowIncomplete                          (escribe vista marcada INCOMPLETE)
    -PassThru                                 (devuelve el manifiesto)
```

El extractor **no ejecuta matrices** ni reconstruye tiempos. Lee
`entorno.json`, `plan.csv`, `mediciones.csv`, `bitacora.txt`, `estado.json` y
`logs/`, valida y copia solo las líneas `version=c_paralelo` **byte a byte**.

### 5.2 Controles aplicados

| Control | Regla |
| --- | --- |
| Esquema | Cabecera canónica de 20 campos, sin BOM |
| Plan | Orden, N, configuración, semilla, repetición y calentamiento |
| Rondas | 1 calentamiento + repeticiones 1..5 únicas por grupo |
| Procesos | `processes=P` observado por el programa |
| Hilos | `threads=T`, `observed_threads=T` y `OMP_NUM_THREADS=T` |
| Entorno OMP | `OMP_DYNAMIC=FALSE` |
| MPI | `mpiexec -n P` y filas por rank |
| Igualdad | La vista coincide con `mediciones.csv` |
| Bitácora | Estado `OK` por corrida |
| Metadatos | Commit, hostname y tamaños coherentes |
| Fase oficial | Árbol limpio, fase `oficial`, N=512/1024/2048 y lote completo |

Las anomalías se clasifican en `critical`, `warning` e `info`. En fase oficial
cualquier anomalía crítica impide acreditar el lote; con `-AllowIncomplete` se
conserva la vista marcada `INCOMPLETE` y el proceso termina con error.

### 5.3 Ejecución oficial (handoff)

En la PC oficial, desde la raíz del repositorio, con la candidata congelada,
árbol limpio y binarios Release ya compilados y probados:

```powershell
# 1. Campaña integrada oficial (I5/I6 o el responsable de la franja)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 `
    -Version all -Fase oficial -OutputRoot resultados\raw `
    -CampaignId s08_i02_c_paralelo_01 -TimeoutSeconds 300

# 2. Extracción y verificación del lote C paralelo
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\raw\s08_i02_c_paralelo_01 `
    -Phase oficial `
    -ExpectedCommit 97ccc981e9068d8ec0753cd8a4b7572a6bece34d
```

Resultado esperado: `resultados/raw/c_paralelo.csv` y
`resultados/raw/c_paralelo_revision.json` con estado `VERIFIED`.

Si la campaña se ejecuta con otro `CampaignId`, ajustar la ruta del paso 2. Si
la candidata oficial cambia, actualizar `-ExpectedCommit` o omitirlo para tomar
el commit de `entorno.json`, y registrar el cambio en el acta.

Con 6 núcleos físicos se esperan **6 configuraciones** (`P1_T1`, `P1_T2`,
`P2_T1`, `P1_T4`, `P2_T2`, `P4_T1`) × 3 tamaños × 6 filas = **108 filas**. Si la
PC oficial habilita W=8, serán 10 configuraciones y 180 filas.

---

## 6. Evidencia de diagnóstico (no oficial)

Para comprobar el extractor sobre datos reales se usó el piloto integrado de S7
`resultados/piloto/s07_windows_20261117_reproduccion_06`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\piloto\s07_windows_20261117_reproduccion_06 `
    -Phase piloto -ExpectedSizes 256,512,1024 `
    -OutputPath .\resultados\diagnostico\s08_i02_piloto_s07\c_paralelo_piloto.csv `
    -ManifestPath .\resultados\diagnostico\s08_i02_piloto_s07\revision_i02.json
```

Resultado: `VERIFIED_PILOT`, **108 filas**, **18 grupos**, **0 anomalías
críticas**; una advertencia `os_heredado` (etiqueta Windows 10 vs Windows 11 en
`entorno.json`) que se conserva sin reescribir. La procedencia completa está en
[`resultados/diagnostico/s08_i02_piloto_s07/README.md`](../../resultados/diagnostico/s08_i02_piloto_s07/README.md).

Este resultado es **diagnóstico**, no acredita S8 y no se copia a `resultados/raw/`.

---

## 7. Pruebas

```powershell
# Extractor (13 casos: extracción, bytes, hilos, ranks, fallos, BOM, plan, fase oficial)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\extract_s08_c_paralelo_test.ps1

# Regresión del caso C paralelo de S7 (23 casos)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\bench_c_paralelo_test.ps1
```

Estado actual: **13/13** y **23/23**. Las pruebas no requieren MSVC ni MS-MPI:
usan campañas sintéticas y fixtures CSV.

---

## 8. Criterios de aceptación

- [ ] Campaña oficial ejecutada en la PC oficial con árbol limpio y N=512/1024/2048.
- [ ] `resultados/raw/c_paralelo.csv` contiene 1 calentamiento + 5 medidas `OK`
      por configuración y tamaño, o una exclusión justificada.
- [ ] `processes=P`, `threads=T` y `observed_threads=T` en todas las filas `OK`.
- [ ] `OMP_DYNAMIC=FALSE`, `OMP_NUM_THREADS=T` y `mpiexec -n P` registrados.
- [ ] Manifiesto `VERIFIED` con hashes del CSV fuente y de la vista.
- [ ] Anomalías registradas sin borrar ni sustituir observaciones.
- [ ] Revisión cruzada de I1/I5 y horas reales en `docs/sprints/sprint-08.md`.

Los dos primeros puntos **no están cumplidos** en esta PC; dependen de la
ejecución oficial.

---

## 9. Horas

| Bloque | Horas | Estado |
| --- | ---: | --- |
| Extractor/validador y controles de P/T | 3 h | Completado |
| Pruebas y extracción de diagnóstico | 3 h | Completado |
| Ejecución y supervisión oficial | 3 h | **Pendiente en PC oficial** |
| Verificación de participación y anomalías | 3 h | **Pendiente con la campaña** |
| Revisión cruzada y coordinación | 2 h | Parcial (handoff documentado) |

Las 8 h de I2 se completan cuando la campaña oficial esté ejecutada y revisada.

---

## 10. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Instalar MSVC/MS-MPI requiere admin | No medir en esta PC | Ejecutar en la PC oficial; no simular datos |
| PC oficial ocupada o sin franja | Retraso del entregable | Coordinar con I6/I8; conservar el plan listo |
| `observed_threads != T` | Fila inválida | `OMP_DYNAMIC=FALSE`; extraer y marcar crítico |
| Timeout deja procesos vivos | Contamina corridas | `taskkill /T /F` del orquestador; revisar logs |
| Campaña con árbol sucio | No acredita oficial | Fase oficial exige `dirty=false`; repetir en carpeta nueva |
| Commit distinto al congelado | Pérdida de trazabilidad | `-ExpectedCommit`; registrar en el acta |
| Vista derivada confundida con CSV oficial | Entregable inválido | Fase `piloto`/`diagnostico` exige `-OutputPath` explícito |

---

## 11. Checklist de cierre

- [x] Extractor implementado con cabecera canónica y sin BOM.
- [x] Verificación de procesos, hilos, OMP, MPI, ranks y bitácora.
- [x] Extracción byte a byte y manifiesto con hashes y anomalías.
- [x] 13 pruebas del extractor y 23 de regresión en verde.
- [x] Diagnóstico real sobre el piloto S7, etiquetado como no oficial.
- [x] Handoff con comandos exactos para la PC oficial.
- [ ] Ejecutar la campaña oficial y generar `resultados/raw/c_paralelo.csv`.
- [ ] Registrar horas reales, revisión cruzada y aceptación en el acta.
