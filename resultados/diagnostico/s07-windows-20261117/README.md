# Aceptación parcial S7 en Windows · 17/11/2026

**S7 sigue abierto.** Las pruebas de automatización y tres versiones reales pasan;
Smart App Control bloquea el ejecutable Go paralelo antes del piloto integrado.
Los datos controlados y el dry-run no son observaciones experimentales.

El usuario confirma que esta es la PC oficial, que revisará el piloto, que las
horas declaradas son 8 por integrante y que no hay sensor de temperatura.
La franja de máquina S8 y la aceptación final del piloto siguen pendientes.

## Evidencia

| Archivo/carpeta | Contenido |
| --- | --- |
| `intento-01/` | Build Release y regresión del intento `s07_windows_20261117_piloto_01`, detenido antes de medir |
| `code-integrity.json` | Eventos de Windows: bloqueo de Go paralelo por política `{0283ac0f-fff1-49ae-ada1-8a933130cad6}` |
| `seguridad.json` | Smart App Control activado; consulta administrativa de políticas sin privilegios suficientes |
| `pruebas.json` | Códigos de salida de ocho baterías ejecutadas secuencialmente |
| `csv.txt` | Fila válida y tres rechazos esperados |
| `c-paralelo.txt` | 23/23 comprobaciones |
| `go-secuencial.txt`, `go-secuencial-ejecutable/` | 81/81 comprobaciones, incluidos seis lotes reales pequeños; no son el piloto S7 |
| `go-paralelo-controlado.txt` | 26/26 comprobaciones controladas |
| `go-paralelo-con-ejecutable.txt` | Intento real rechazado por Control de aplicaciones; no aprobado |
| `resumen.txt` | 43/43 comprobaciones |
| `integridad-resumen.txt` | 11/11 comprobaciones |
| `manifiestos.txt` | 10/10 comprobaciones |
| `campana-controlada.txt` | 48/48 comprobaciones con procesos controlados |
| `aceptacion-controlada.txt` | 12/12 comprobaciones del procedimiento corregido |
| `regresion-sin-build-*.txt` | Regresión real de C secuencial, C híbrido y Go secuencial con `-SkipBuild`, código 0 |
| `binarios-regresion-sin-build.json` | SHA-256 idénticos de los cuatro ejecutables antes/después de esa regresión |
| `sintaxis.json` | Parser PowerShell 5.1: 31 archivos, sin errores |
| `planificacion/` | Dry-run nativo: 198 corridas, sin exclusiones, cero observaciones |
| `builds/` | Manifiestos de los binarios del intento; no contienen ejecutables |
| `sources/`, `cambios.patch`, `revision.json` | Fuentes corregidas y revisión del árbol de trabajo, sin afirmar candidata limpia |

PC observada: Ryzen 5 3600 (6 núcleos físicos/12 lógicos), Windows 11 Pro
build 26300, RAM visible 17085501440 bytes, alimentación AC y plan Equilibrado.
Durante el dry-run había 4351414272 bytes de RAM disponible; la huella matricial
máxima estimada era 75497472 bytes, sin incluir runtime/pilas. No se midió
temperatura. Los valores de planificación no certifican las condiciones futuras.

Herramientas: PowerShell 5.1.26100.9711, MSVC 14.44.35207, Windows SDK
10.0.26100.0, MS-MPI Runtime 10.1.12498.52 y Go 1.27.4 windows/amd64.
Los manifiestos identifican también el SDK MPI por hashes.

## Cambios y límites

La reproducción tenía una recompilación involuntaria a través de la regresión.
El aceptador ahora usa `test_windows.ps1 -SkipBuild`, comprueba builds antes y
después de las pruebas y conserva stdout/stderr junto con la etiqueta/código
real de los fallos. Las pruebas nuevas comprueban también que cargar los helpers
no sobrescribe el CampaignId y que una mutación detiene la campaña antes de medir.

HEAD de procedencia: `66900cd4787edd565d82444136e16b9edc6071af`.
Los binarios se compilaron durante el intento inicial; las correcciones posteriores
de scripts están sin congelar. No se consideran los binarios actuales una
congelación limpia para S8. Hay que fijar la nueva candidata y reconstruir antes
de iniciar piloto y reproducción definitivos.

El bloqueo pertenece a Smart App Control (estado On), confirmado por eventos
CodeIntegrity 3077 y la consulta local de Defender. Microsoft indica que
[no admite excepciones por aplicación](https://support.microsoft.com/en-gb/windows/security/threat-malware-protection/smart-app-control-frequently-asked-questions).
No se modificaron sus políticas ni se desactivaron las protecciones del equipo.
La autorización para investigar la ejecución no equivale a una autorización
informada para reducir la protección de todo Windows.

No hay campaña integrada COMPLETE ni reproducción ni estimación basada en un
piloto completo. S8 sigue sin datos oficiales nuevos. Los pasos para continuar
están en [el acta](../../../docs/campana.md).

Actualización posterior del 17/11/2026: el propietario acepta el cambio global
y desactiva Smart App Control manualmente. `seguridad-posterior.json` confirma
Off y Go paralelo N=2/W=2 ejecuta correctamente. Los archivos anteriores son
evidencia histórica del intento bloqueado; la aceptación se reinicia sobre una
nueva candidata limpia. El piloto completo tendrá su propia carpeta.
