# Campaña y candidata experimental S7

Estado al 17/11/2026: integración implementada; aceptación del piloto completo y
reproducción pendientes en Windows nativo. No se habilita todavía el cierre S7
ni se afirma una congelación final para S8.

## Procedencia de las entregas

Se conserva la entrega de I8, integrada por el [PR #56](https://github.com/GiulianoMaPe/MatricesParalelas/pull/56),
en el [acta original](campana_i8_original_s07.md). Sus dos lotes Go N=256 en
PC-PETEL son evidencia individual declarada por Roberto. No incluyen los cuatro
casos, la tabla completa ni los metadatos/logs de una campaña integrada.
El candidato anterior `aba9579` tenía `all` deshabilitado: sus lotes no acreditan
la integración actual. Las 72 observaciones de I4 se preservan en
[resultados/piloto/s07_i04_go_paralelo/](../resultados/piloto/s07_i04_go_paralelo/).
No se reúnen lotes de distintas PCs o intentos para simular un piloto completo.

La presente acta sustituye las reglas del acta original que contradicen el
[protocolo v1.3](protocolo_medicion.md): presupuestos W=1/2/4/8 limitados por núcleos
físicos; cero temporal válido; speedup de medianas de `total_s`; N=4096 condicional.
No se atribuyen variaciones a caché ni throttling sin mediciones de esos fenómenos.
No se garantiza una pausa térmica automática: el sensor no está disponible en
este arnés y su revisión se registra manualmente en la bitácora.

## Código y parámetros candidatos

- Conservar los núcleos C/Go y fronteras temporales aceptados en S6; esta entrega
  modifica automatización, validación y documentación.
- Identificar la candidata con `git rev-parse HEAD`. Registrar el commit completo,
  estado del árbol, hashes de fuentes y de los cuatro binarios. `build.json`
  registra las opciones y herramientas efectivas, sin fijar versiones de otra PC.
- Compilar en Release, x64, con MSVC/Windows SDK y MS-MPI nativos. Go usa
  `-buildvcs=true`, optimizaciones predeterminadas y sin instrumentación.
- Piloto: N=256,512,1024; oficial S8: N=512,1024,2048; semilla 42.
- Un calentamiento por combinación y cinco rondas: orden directo en rondas
  impares e inverso en pares, según la tabla del protocolo.
- Hasta 4 núcleos físicos: W=1/2/4 según capacidad. W=8 solo con al menos 8
  núcleos físicos. En 6 núcleos: 11 configuraciones por N, 198 corridas; con
  W=8 habilitado: 16 por N, 288 corridas.
- Memoria matricial estimada: `4*8*N*N` en secuenciales/Go; `(P+5)*8*N*N` en
  C híbrido. Excluir N en las cuatro versiones si alguna combinación excede
  50% de RAM disponible, conservando ambos baselines. No incluye runtime/pilas.
- Timeout inicial 300 s por corrida en el comando de aceptación; ajustar con
  el piloto documentando cualquier nuevo intento, nunca sustituyendo filas.

## Ejecución y reproducción en Windows PowerShell 5.1

```powershell
# Construye, prueba, planifica, mide y verifica; falla al primer error.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\accept_sprint07_windows.ps1 -CampaignId s07_piloto_01

# Nueva carpeta, mismos binarios, misma candidata y parámetros; repetir en reposo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\accept_sprint07_windows.ps1 -CampaignId s07_reproduccion_01 -SkipBuild
```

No ejecutar ambos comandos a la vez. Antes de cada uno, confirmar PC oficial,
alimentación, plan de energía constante y ausencia de otras mediciones. Registrar
carga de fondo, sensores/temperatura, incidencias y disponibilidad de máquina.
Si no hay sensor, declarar esa limitación; no inventar temperaturas.

La carpeta `resultados/piloto/<campaign_id>/` conserva `entorno.json`, `plan.csv`,
`mediciones.csv`, `bitacora.txt`, `estado.json`, `source-hashes.json`, resumen,
logs de procesos y aceptación, verificación y estimación inicial de duración.
Cada proceso registra argumentos, entorno hijo, PID, salida real, stdout/stderr,
timeout y tiempo de pared. Los ranks MPI conservan filas/hilos observados en
archivos individuales y bitácora. El SDK MPI queda identificado por hashes de
su cabecera y biblioteca cuando no ofrece versión de archivo. Un fallo conserva parciales, tiempos vacíos y estado
INCOMPLETE; se repite el lote completo en una carpeta nueva.

Los pilotos con cambios locales archivan también diff, estado y fuentes, incluidas
las no rastreadas. `oficial` exige árbol y builds limpios; los binarios se comprueban
contra HEAD, hash, fuentes de compilación, arquitectura y metadatos VCS Go.
Los modos individuales de I1–I4 siguen disponibles para diagnóstico.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version all -Fase piloto -DryRun
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_campaign.ps1 -CampaignDirectory .\resultados\piloto\s07_piloto_01
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\summarize_results.ps1 -InputPath .\resultados\piloto\s07_piloto_01\mediciones.csv -OutputPath .\resultados\piloto\s07_piloto_01\resumen_estadistico.csv
```

El verificador comprueba tabla/orden, grupos 0..5 completos, coherencia del CSV,
metadatos y logs. No sustituye la ejecución nativa ni la revisión del entorno.
`estimacion.json` proyecta inicialmente 8 veces la duración del piloto por duplicar
N con coste cúbico y sugiere 50% de margen. Es una estimación, no una medición S8
ni una reserva efectiva en el calendario.

## Análisis y condición de cierre

Se integró el análisis de I7 ([PR #54](https://github.com/GiulianoMaPe/MatricesParalelas/pull/54)):
mediana, Q1=x2, Q3=x4, IQR, mínimo/máximo, speedup contra secuencial del mismo
lenguaje, eficiencia y GFLOPS estimados. El resumen añade `campaign_id` a sus
32 columnas; el CSV crudo conserva veinte. Cada archivo de entrada identifica
un intento independiente; no se calcula speedup cruzando archivos. Para pipeline
usar `-CampaignId` y suministrar una sola campaña. COMPLETE requiere exactamente
un warmup OK y repeticiones 1..5 únicas OK. Fallos o duplicados dejan el grupo
incompleto; NaN/Inf, esquema y parámetros incoherentes se rechazan. Ceros válidos
no producen divisiones por cero. Los grupos fallidos quedan visibles.

Para cerrar S7 faltan: piloto integrado completo en la PC oficial, reproducción
de la misma candidata/binarios, revisión de entorno y duración/reserva, y
aceptación del responsable. Mantener las horas/revisiones declaradas por cada
integrante; la integración por Codex no acredita conformidades personales nuevas.
