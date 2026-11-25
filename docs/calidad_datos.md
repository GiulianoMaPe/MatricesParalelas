# Reporte parcial de calidad de datos — Sprint 8

Estado: auditoría parcial realizada el 24/11/2026. El dictamen final debe esperar los cuatro lotes oficiales.

## Inventario de entregables

| Entregable | Estado | Observaciones |
|---|---|---|
| `resultados/raw/c_secuencial.csv` | Ausente | Sin lote recibido |
| `resultados/raw/c_paralelo.csv` | Ausente | Sin lote recibido |
| `resultados/raw/go_secuencial.csv` | Ausente | Sin lote recibido |
| `resultados/raw/go_paralelo.csv` | Completo para I4 | 54 filas: 9 calentamientos y 45 mediciones |

## Auditoría de Go paralelo

- Origen: `PCG1UL14N0`.
- Commit registrado: `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.
- Semilla: 42.
- Tamanos: 512, 1024 y 2048.
- Workers: 1, 2 y 4.
- Cada combinacion tiene cinco mediciones y un calentamiento.
- Las 45 mediciones tienen `validation_status=OK`.
- Las 9 configuraciones están completas.
- No se encontraron exclusiones ni filas inválidas en el CSV entregado.
- El resumen estadístico existe en `resultados/resumen/go_paralelo_resumen.csv`.
- El manifiesto conserva el SHA-256 del CSV y la procedencia de la extracción.

Avisos retenidos sin borrar datos:

- `N=1024/W=2`: dispersión IQR/mediana superior al 10 %.
- `N=1024/W=4`: dispersión IQR/mediana superior al 10 %.
- Configuraciones `N=512/W=2` y `N=512/W=4`: tiempos inferiores al umbral corto documentado de 100 ms.

Estos avisos no justifican descartar observaciones. Cada advertencia debe conservarse en el dictamen final.

## Pruebas realizadas

- `go test` pasó en `go_secuencial`.
- `go test` pasó en `go_paralelo`.
- El resumidor generó nueve grupos completos y sin errores para Go paralelo.
- La ejecución Windows completa no pudo acreditarse en esta sesión por ausencia de `.git`, cl.exe y MS-MPI.

## Pendientes para dictamen final

1. Recibir los tres CSV oficiales restantes.
2. Verificar la fase `oficial`, la PC, la semilla, el commit completo y el estado de la campaña.
3. Comprobar cinco muestreos por configuración, la entrada de cada repetición y el estado numérico.
4. Inventariar fallos y exclusiones sin eliminar originales.
5. Emitir el dictamen final de los cuatro lotes.
