# Reporte de calidad de datos — Sprint 8, Integrante 5

**Responsable:** Integrante 5  
**Estado:** Preparación iniciada; auditoría de los lotes oficiales pendiente de recepción.  
**Rama de trabajo:** `feature/s08-i05-calidad-datos`  
**Referencias:** [asignación S8](sprints/sprint-08.md), [protocolo de medición](protocolo_medicion.md)

## 1. Alcance y estado actual

La tarea asignada es auditar completitud y validez numérica de los cuatro lotes
oficiales, clasificar fallos sin borrar datos y mantener un inventario de
observaciones.

En la revisión inicial del repositorio, `resultados/raw/` contiene únicamente
`.gitkeep`; todavía no están disponibles los CSV oficiales. Por ese motivo este
documento registra los criterios y el estado de recepción, pero **no certifica
resultados ni afirma que se hayan auditado mediciones**. Se actualizará al recibir
los datos originales y sus metadatos.

| Lote esperado según la asignación S8 | Ruta esperada | Estado |
| --- | --- | --- |
| C secuencial | `resultados/raw/c_secuencial.csv` | Pendiente de recepción |
| C paralelo | `resultados/raw/c_paralelo.csv` | Pendiente de recepción |
| Go secuencial | `resultados/raw/go_secuencial.csv` | Pendiente de recepción |
| Go paralelo | `resultados/raw/go_paralelo.csv` | Pendiente de recepción |

El protocolo también describe campañas con directorios propios bajo
`resultados/raw/<campaign_id>/`, que incluyen `entorno.json`, `plan.csv`,
`mediciones.csv`, `bitacora.txt` y demás evidencia. Si los lotes se entregan con
esa estructura, se conservará y documentará la ruta recibida; no se renombrarán
ni sobrescribirán los originales.

## 2. Criterios de auditoría

Se aplicarán los criterios de `docs/protocolo_medicion.md` y de aceptación de
`docs/sprints/sprint-08.md`:

1. **Integridad CSV:** cabecera canónica exacta de 20 columnas, campos parseables
   y sin desplazamientos. El archivo original se preserva sin editar.
2. **Identidad y parámetros:** versión correspondiente al lote, metadatos
   coherentes con la campaña, semilla canónica `42` y dimensiones oficiales
   `N ∈ {512, 1024, 2048}`. Una extensión `N=4096` solo se revisará si fue
   habilitada y justificada conforme al protocolo.
3. **Repeticiones:** un warmup (`repetition=0`, `is_warmup=true`) y cinco
   mediciones (`repetition=1..5`, `is_warmup=false`) por configuración prevista.
   El warmup no cuenta entre las cinco observaciones válidas.
4. **Validez numérica:** una observación válida requiere `validation_status=OK`,
   tiempos numéricos finitos y no negativos, y `kernel_s ≤ total_s`. Una fila con
   estado fallido debe tener tiempos vacíos y conservar su diagnóstico.
5. **Configuración:** `configuration`, versión y parámetros de concurrencia deben
   coincidir; `observed_threads` debe concordar con `threads` en C paralelo.
   También se revisarán consistencia de `commit`, host y metadatos de entorno
   dentro de cada campaña.
6. **Completitud:** cada configuración prevista tendrá cinco observaciones
   válidas o una exclusión justificada. Los grupos incompletos y las anomalías se
   informarán; no se reemplazará una observación lenta seleccionando otra corrida.
7. **Preservación:** no se borrarán ni modificarán filas fallidas, lentas o
   discrepantes. Se anotarán el archivo/fila/configuración, el problema y la
   evidencia disponible.

## 3. Inventario de observaciones y fallos

Pendiente de completar cuando estén disponibles los lotes. Se registrarán todas
las incidencias, incluidas las que no invaliden por sí solas una campaña.

| Lote / archivo | Fila o configuración | Tipo de observación/fallo | Evidencia y clasificación | Acción/seguimiento |
| --- | --- | --- | --- | --- |
| Pendiente | Pendiente | Pendiente | Sin datos oficiales recibidos | Solicitar lote al responsable correspondiente |

## 4. Resultado por lote

| Lote | Filas recibidas | Configuraciones completas | Observaciones válidas | Fallos / exclusiones | Dictamen |
| --- | ---: | ---: | ---: | ---: | --- |
| C secuencial | — | — | — | — | Pendiente de recepción |
| C paralelo | — | — | — | — | Pendiente de recepción |
| Go secuencial | — | — | — | — | Pendiente de recepción |
| Go paralelo | — | — | — | — | Pendiente de recepción |

## 5. Herramientas y evidencia

El repositorio ya incluye `scripts/summarize_results.ps1` para validar el esquema,
campos y estados, y resumir grupos; `scripts/verify_campaign.ps1` verifica además
la estructura y trazabilidad completa de una campaña con plan, entorno y logs.
Se usarán cuando lleguen los datos en el formato correspondiente. No se han
instalado herramientas ni dependencias para esta preparación.

| Verificación | Estado | Evidencia |
| --- | --- | --- |
| Existencia de CSV oficiales en `resultados/raw/` | No disponibles en la revisión inicial | Solo se encontró `.gitkeep` |
| Validación de los cuatro lotes | Pendiente | Requiere archivos de los integrantes 1–4 |
| Revisión de completitud y validez numérica | Pendiente | Requiere los lotes oficiales y metadatos |
| Suite `tests/summarize_results_test.ps1` | Aprobada: 43 pruebas, 0 fallidas | Prueba automatizada del resumidor con datos de prueba; no valida la campaña oficial |
| Suite `tests/summarize_integrity_test.ps1` | Aprobada: 11 comprobaciones | Prueba automatizada de integridad con datos de prueba; no valida la campaña oficial |

## 6. Pendientes para cerrar la tarea

- [ ] Recibir los cuatro CSV originales y la evidencia/metadatos de campaña.
- [ ] Validar estructura y campos de cada lote.
- [ ] Inventariar las observaciones y clasificar anomalías sin alterar los datos.
- [ ] Comprobar cinco mediciones válidas o exclusión justificada por configuración.
- [ ] Completar las tablas de resultados y emitir un dictamen por lote.
- [ ] Registrar evidencia y revisión cruzada en `docs/sprints/sprint-08.md`.
