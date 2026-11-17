# Campaña y candidata experimental S7

Estado al 17/11/2026: integración probada en Windows nativo; bloqueo de Smart
App Control resuelto por el propietario y ejecución Go paralelo comprobada.
PC oficial, revisor y 8 h por integrante confirmados. Se prepara la candidata
limpia para completar y aceptar piloto y reproducción antes de cerrar S7.

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

El aceptador compila una sola vez; ejecuta la regresión con
`test_windows.ps1 -SkipBuild` y verifica manifiestos/fuentes/hashes antes y
después de las pruebas. En reproducción, `-SkipBuild` del aceptador conserva
también esa omisión durante la regresión. Faltando ejecutables o pruebas C,
hay que construir y reiniciar ambos intentos, sin recompilar entre ellos.

## Estado nativo de la PC oficial · 17/11/2026

El responsable confirma la PC oficial, su revisión personal, 8 h por integrante
y ausencia de sensor térmico. No se atribuyen revisiones independientes nuevas
a otros integrantes. No hay todavía franja de máquina S8 confirmada. Sin sensor
se documenta la limitación y se revisan carga, memoria, alimentación, pausas e
incidencias; no se afirma estabilidad térmica medida.

Ryzen 5 3600, 6 núcleos físicos/12 lógicos, Windows 11 Pro build 26300,
17085501440 bytes de RAM visible, AC y plan Equilibrado. MSVC 14.44.35207,
Windows SDK 10.0.26100.0, MS-MPI Runtime 10.1.12498.52, Go 1.27.4 windows/amd64
y PowerShell 5.1.26100.9711. Las opciones y hashes observados se conservan en
el [diagnóstico Windows](../resultados/diagnostico/s07-windows-20261117/README.md).

El dry-run nativo planifica 198 corridas sin exclusiones: 33 calentamientos y
165 medidas, N=256/512/1024, semilla 42 y W=1/2/4. Sigue siendo planificación.
El intento `s07_windows_20261117_piloto_01` se detuvo antes de medir al bloquear
Windows el binario Go paralelo (evento CodeIntegrity 3077; política
`{0283ac0f-fff1-49ae-ada1-8a933130cad6}`; SmartAppControlState=On).
No existe piloto integrado COMPLETE, reproducción ni estimación basada en él.

HEAD de procedencia: `66900cd4787edd565d82444136e16b9edc6071af`.
La corrección de recompilación involuntaria y sus pruebas están pendientes de
fijarse como nueva candidata limpia. Resolver primero el bloqueo de ejecución,
conservar todos los intentos y reiniciar la aceptación con nuevos IDs. La
congelación final incluirá esa nueva revisión, hashes de ambos intentos, revisión
de la evidencia y reserva concreta de máquina para S8.

Actualización posterior del 17/11/2026: el propietario acepta expresamente el
cambio global y desactiva Smart App Control manualmente. La consulta posterior
confirma Off y Go paralelo N=2/W=2 devuelve CSV OK. Los registros de bloqueo
anteriores se conservan como historia. Se reinicia la aceptación con una nueva
candidata limpia y los IDs `s07_windows_20261117_piloto_02` y
`s07_windows_20261117_reproduccion_02`. Las carpetas de salida de ambos intentos
y sus planes se excluyen localmente durante las mediciones para que generar
evidencia no modifique el estado de las fuentes; su publicación será explícita.

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
