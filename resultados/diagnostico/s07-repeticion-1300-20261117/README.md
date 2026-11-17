# Preparación de repetición S7 en reposo · 17/11/2026

S7 continúa abierto. El responsable difiere la aceptación de los lotes `_02`
por dudas de uso concurrente y confirma la PC dedicada hoy **13:00–14:00,
America/Lima**. Los datos anteriores y sus diferencias se conservan íntegros.

## Programación real

Tarea de Windows: `Codex-S7-Repeticion-20261117-1300`, habilitada, estado Ready,
próxima ejecución 17/11/2026 a las 13:00 (UTC−5), con token interactivo y
privilegios limitados. `programacion.json` y `tarea-programada.xml` conservan
acción, configuración y hashes de scripts. El estado de ejecución se escribirá
en `.cache/s07_1300/estado.json`; este directorio es una instantánea de preparación.

La tarea solicita vigilia mientras se ejecuta (`WakeToRun`), sin cambiar el plan
de energía. Requiere dejar Windows con sesión iniciada. No se ejecuta más tarde
si se pierde la hora; se limita a una hora, con límite propio de mediciones a las
13:55 para archivar antes de las 14:00. Véase la
[semántica oficial de WakeToRun](https://learn.microsoft.com/en-us/windows/win32/api/taskschd/nf-taskschd-itasksettings-put_waketorun).

Candidata medida: `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, copia limpia
`.cache/s08-candidata-97ccc98`, cuatro binarios originales, sin recompilar.
IDs: `s07_windows_20261117_piloto_03` y `s07_windows_20261117_reproduccion_03`.
Cada intento repite aceptación completa, tabla de 198 corridas y verificación;
se dejan dos minutos de reposo entre ambos. Los datos se copian a
`resultados/piloto/` y se comparan en `s07_windows_20261117_cierre_03/`.
El resultado automático seguirá requiriendo revisión humana.

El control inicial exige ausencia de Zoom/navegadores, misma candidata/fuentes/
binarios y media de cinco muestras CPU ≤10%. Ese 10% es una heurística operativa
de reposo y no un umbral retroactivo del protocolo. Durante la ejecución se
comprueban aplicaciones cada cinco segundos. Si reaparecen, se interrumpen los
procesos propios de las pruebas, se conservan parciales y no se cierra la
aplicación del usuario. Ante un lote incompleto se necesitan IDs nuevos.

## Sensores y elección del responsable

La GTX 1070 permite leer temperatura/carga mediante el `nvidia-smi` instalado:
consulta inicial 57 °C; la prueba finita corregida conserva tres muestras de
52 °C a intervalos de cinco segundos. Son lecturas diagnósticas actuales, no
temperaturas retrospectivas de los lotes `_02`.
[Consulta oficial NVIDIA](https://docs.nvidia.com/deploy/nvidia-smi/index.html).

ACPI/WMI no entrega temperatura CPU en esta placa. LibreHardwareMonitor 0.9.6
se descargó del [repositorio oficial](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/tag/v0.9.6)
y su ZIP coincide con SHA-256 publicado
`086d9f1b5a99e643edc2cfaaac16051685b551e4c5ac0b32a57c58c0e529c001`.
Se inspeccionó el instalador PawnIO embebido: versión 2.1.0.0, firma válida de
namazso, SHA-256 `A3A46226C5E2824F4CDD42BE0EECBABFC672C86F7889710F5AB1E6AD385B47A0`.
El responsable eligió **solo GPU y CPU sin lectura**: no se ejecutó el programa
ni se instaló PawnIO/otro controlador. La GPU no sustituye la temperatura CPU
ni demuestra estabilidad térmica del Ryzen.

El muestreador realiza una consulta finita cada cinco segundos y añade/flushea
cada fila, conservando CSV crudo y CSV con UTC. La prueba inicial con el bucle
nativo/archivo no conservó muestras suficientes; fue reemplazada y no se usará.
Los CSV externos incluyen pruebas de aceptación y medición; el generador de
informe selecciona solo muestras entre el inicio/fin reales de cada campaña.
El observador añade una pequeña carga: se emplea igual en ambos intentos y no
se modifican las fronteras de los cronómetros C/Go.

## Verificación de la preparación

- Parser PowerShell: dos scripts sin errores.
- Sintaxis Python: dos scripts compilados sin errores.
- Prueba previa real: bloquea el inicio porque Zoom está activo y la carga media
  observada es 34.2%; no inicia mediciones.
- Muestreador GPU real: tres filas conservadas a cinco segundos.
- Supervisor: tres escenarios con procesos PowerShell controlados, sin matrices:
  aplicación bloqueada interrumpe solo el hijo, límite horario interrumpe el hijo
  y terminación normal conserva salida/telemetría. Los tres pasan.
- La copia congelada sigue limpia y sus cuatro hashes coinciden con el piloto.

Los scripts de este directorio están archivados para revisión. La acción real
usa `.cache/s07_1300/repetir_s07.ps1`; no ejecutar la copia archivada como si su
ubicación fuera la carpeta operativa. No borrar `.cache`/builds antes de la tarea.
