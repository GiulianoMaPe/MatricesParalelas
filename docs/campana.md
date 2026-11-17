# Campaña y candidata experimental S7

Estado al 17/11/2026: piloto integrado y reproducción completos y verificados en
Windows nativo, 198 observaciones OK y 33 grupos por intento. Candidata limpia
`97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, mismos binarios y fuentes.
El responsable no acepta todavía estos lotes por dudas de uso concurrente
(Zoom/navegador) y solicita repetir con la PC dedicada el 17/11, 13:00–14:00
America/Lima. Se medirá GPU; CPU quedará sin lectura térmica por elección del
responsable. Reserva S8 provisional: 18/11, 09:00–12:00, sujeta a esta repetición.

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

## Resultado integrado Windows · 17/11/2026

Este resultado sustituye los pendientes técnicos de los registros anteriores.
El [informe de cierre](../resultados/piloto/s07_windows_20261117_cierre/README.md)
conserva comprobaciones cruzadas, hashes, condiciones, diferencias y reserva.

| Intento | Estado | Observaciones / grupos | Duración |
| --- | --- | --- | --- |
| `s07_windows_20261117_piloto_02` | COMPLETE / VERIFIED | 198 OK / 33 COMPLETE | 715.7244307 s |
| `s07_windows_20261117_reproduccion_02` | COMPLETE / VERIFIED | 198 OK / 33 COMPLETE | 715.8565236 s |

Commit experimental: **`97ccc981e9068d8ec0753cd8a4b7572a6bece34d`**.
Los dos intentos tienen fuentes/builds limpios, mismo plan byte a byte, hashes
de fuentes y cuatro binarios idénticos, mismas herramientas y parámetros.
N=256/512/1024, semilla 42, W=1/2/4, 33 warmups y 165 medidas por intento;
ninguna exclusión. La reproducción pasa toda la aceptación con `-SkipBuild`.
Los CSV, stdout/stderr, procesos, ranks y grupos pasan el verificador.

Herramientas observadas: compilador MSVC 19.44.35230.0 (toolset 14.44.35207),
Windows SDK 10.0.26100.0, MS-MPI Runtime 10.1.12498.52, Go 1.27.4 windows/amd64
y PowerShell 5.1.26100.9711. El SDK MPI se identifica por hashes en los manifiestos.

Se conservaron todos los datos y los dos resúmenes independientes. La mediana
del cambio absoluto relativo de medianas `total_s` entre 33 grupos es 3.6004%;
el máximo es 28.2531% en C paralelo N=512/P2/T2. No se afirma equivalencia
temporal exacta ni se eliminan outliers/speedups lentos. No hay sensor térmico;
se registraron cargas de 1–80% y 1–57% y RAM libre mínima 2015820/3180024 KiB.
Las muestras pueden incluir carga anterior y no acreditan aislamiento perfecto.
La revisión del responsable debe aceptar expresamente estas limitaciones; no se
atribuyen diferencias a caché, temperatura o tareas de fondo sin medición causal.

### Reserva y ejecución posterior de S8

El propietario autorizó elegir las horas necesarias y adaptar su uso de la PC.
Se reserva **18/11/2026 de 09:00 a 12:00, America/Lima (UTC−5)**. El mayor piloto
proyecta 95.4475 min de campaña, 143.1713 min con margen del 50%, más 30 min de
preparación/revisión y redondeo a tres horas. Es una estimación inicial.
N=2048 requiere hasta 288 MiB matriciales estimados más runtime/pilas; volver a
comprobar memoria/carga/AC/plan y anotar ausencia de sensor antes de medir.
Timeout inicial 300 s por corrida; máximo observado en piloto 8.5629233 s
(proyección cúbica simple 68.5034 s, sin garantía de tiempos futuros).

La copia local `.cache/s08-candidata-97ccc98` contiene el commit medido,
fuentes byte a byte y los cuatro binarios originales. Sus manifiestos se
validaron con el requisito `Official`, y su árbol está limpio. La documentación
y evidencia de cierre se versionan después, sin cambiar esa candidata.
Para S8 en esta PC, usar esa copia y comprobar HEAD/limpieza antes de medir:

Desde la raíz de este repositorio:

```powershell
Set-Location .\.cache\s08-candidata-97ccc98
git rev-parse HEAD
git status --short
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bench_windows.ps1 -Version all -Fase oficial -CampaignId s08_oficial_01 -TimeoutSeconds 300
```

El comando oficial es preparación para S8: no se ha ejecutado como parte de S7.
Si faltan la copia/binarios en otro clon, reconstruir y repetir aceptación;
no asumir los hashes originales. El registro humano de aceptación final está
en `resultados/piloto/s07_windows_20261117_cierre/aceptacion_responsable.json`.

## Revisión diferida y repetición en reposo · 17/11/2026

El responsable informa que está utilizando Zoom y Google/navegador y prefiere
repetir antes de aceptar el cierre. Se conservan íntegros ambos lotes `_02` y
sus verificaciones técnicas; no se declaran aceptados para cerrar S7 ni se
atribuye causalmente la dispersión a una aplicación concreta.

Confirma disponibilidad dedicada hoy de **13:00 a 14:00 (Lima)**. Se prepara
la tarea local `Codex-S7-Repeticion-20261117-1300`, con la misma candidata y
binarios de `.cache/s08-candidata-97ccc98`, y nuevos IDs
`s07_windows_20261117_piloto_03` / `s07_windows_20261117_reproduccion_03`.
La supervisión comprueba ausencia de Zoom/navegadores y carga media inicial
de CPU no superior al 10% (heurística operativa, no umbral retroactivo del
protocolo), deja dos minutos de reposo entre lotes y conserva parciales ante fallo.
Si reaparece una aplicación bloqueada, interrumpe sus propios procesos de prueba;
no cierra aplicaciones del usuario. Se reserva el tramo desde 13:55 para archivo.

La GTX 1070 permite leer temperatura/carga mediante `nvidia-smi`, ya instalado;
se probó un registrador finito cada cinco segundos con tres muestras reales.
La interfaz ACPI consultada no entrega temperatura CPU. LibreHardwareMonitor
0.9.6 fue descargado de su repositorio oficial y verificado por SHA-256, pero
el responsable eligió **solo GPU**, sin instalar el controlador PawnIO.
No se instaló ningún controlador. GPU no sustituye la temperatura del Ryzen
ni acredita estabilidad térmica de CPU. Los registros GPU se correlacionarán
por UTC con las mediciones y se conservarán en `monitor_externo/`.

Estado operativo y motivos de bloqueo: `.cache/s07_1300/estado.json`.
Los nuevos datos se copiarán a `resultados/piloto/`; el informe técnico se
generará en `s07_windows_20261117_cierre_03/`, sin conceder aceptación humana
automáticamente. La reserva S8 se revisará con esas duraciones y el cierre
seguirá pendiente de la revisión del responsable.

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
