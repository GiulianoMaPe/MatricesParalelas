# Verificación de la entrega inicial (entorno)

Estado: pruebas locales de instalación completadas el 17/09/2026; pendiente la
reproducción en los demás equipos y la revisión cruzada. Este documento describe
el alcance y los pasos de comprobación; no sustituye las actas de los integrantes
en `docs/entorno/`.

## Verificación local ejecutada el 17/09/2026

| Comprobación | Resultado observado |
| --- | --- |
| Windows nativo | 64 bits, build 26200 |
| MSVC / SDK Windows | MSVC 14.51.36231 HostX64/x64; SDK 10.0.26100.0; inicialización automática desde una terminal sin MSVC |
| MS-MPI | Runtime 10.1.12498.52 x64; mpi.h presente y msmpi.lib x64 confirmado con dumpbin |
| Go / Git | Go 1.27.0 windows/amd64; Git 2.45.1.windows.1 x64 |
| build_windows.ps1 -Version all -Configuration Release -Tests | Correcto en las cuatro versiones; objetos de pruebas separados |
| test_windows.ps1 -Version all (Debug) | Correcto en las cuatro versiones, código final 0 |
| C secuencial | Compilación y ejecución correctas, sin MPI/OpenMP |
| C híbrido | Dos procesos; ambos observaron dos hilos y nivel MPI 1, equivalente a FUNNELED |
| Go secuencial/paralelo | go fmt, go vet, go test y ejecución correctos; sincronización de dos goroutines comprobada |
| Operaciones pendientes | Los ejecutables rechazan --n/--seed con código 2; sin productos ni mediciones |
| Ruta con espacios y directorio externo | Compilación Release de las cuatro versiones comprobada en una copia temporal local; pruebas C de rechazo correctas |
| Limpieza | Eliminó build en la copia temporal conservando fuentes |
| Benchmark | Rechazó el esqueleto con código 2, sin generar resultados |
| Configuración y Git | PowerShell/JSON válidos; build, cachés y secretos de ejemplo ignorados; remoto existente preservado |

Se corrigió el paso de argumentos MSVC en PowerShell 5.1: ahora usa un archivo de
respuesta dentro de build y normaliza las rutas MPI con barra final. Se comprobó
el caso real del SDK instalado bajo una ruta con espacios.

El primer lanzamiento MPI dentro del sandbox devolvió acceso denegado al crear
procesos. La prueba híbrida y después la batería completa se repitieron fuera del
sandbox y pasaron. No se cambiaron firewall, servicios, PATH ni políticas del sistema.
En una ejecución anterior Go avisó que no podía escribir telemetría fuera del
workspace; las compilaciones y pruebas terminaron correctamente. La ejecución
final no presentó ese aviso.

Siguen pendientes: comprobar F5 e IntelliSense de manera interactiva en VS Code,
reproducir en las otras PCs, revisión cruzada, corrección matemática y benchmarks.
No se ejecutó go test -race ni se considera validado. Las herramientas `code`,
`gopls` y `dlv` se encontraron, pero su presencia no demuestra una sesión F5 correcta.

## Alcance

Esta entrega prepara el entorno de desarrollo para las cuatro versiones. Los
algoritmos de multiplicación aún no están implementados: `status.json` de cada
versión indica `algorithm: pending` y `validation: pending`.

- `c_secuencial`, `c_paralelo`, `go_secuencial` y `go_paralelo` son esqueletos.
- Solo la prueba de instalación `--smoke-test` está funcional.
- Cualquier solicitud de cálculo (`--n`/`--seed`) termina con código 2; no hay
  matrices ni tiempos ficticios.
- No hay resultados experimentales; `resultados/` conserva solo su estructura.

## Qué verifica cada prueba

| Prueba | Herramienta | Verifica |
| --- | --- | --- |
| Diagnóstico de entorno | `scripts/check_env_windows.ps1` | MSVC x64, SDK MPI (mpi.h, msmpi.lib), Go, Git |
| Compilación C | `scripts/build_windows.ps1` | Compila C secuencial y paralelo (Debug/Release) |
| Híbrido 2 × 2 | `scripts/run_hybrid_windows.ps1` | 2 procesos MPI × 2 hilos OpenMP con `OMP_NUM_THREADS=2` y `OMP_DYNAMIC=FALSE` |
| Smoke test C/Go | `--smoke-test` de cada ejecutable | El binario se construye y responde a la prueba de instalación |
| Go fmt/vet/test | `scripts/test_windows.ps1` | Formato, análisis estático y pruebas unitarias de los módulos Go |

Las pruebas de instalación no demuestran corrección matemática.

## Cómo reproducir

Desde la raíz del clon, en PowerShell heredado de la consola x64:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version all -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1
.\c_secuencial\build\Debug\c_secuencial.exe --smoke-test
.\go_secuencial\build\Debug\go_secuencial.exe --smoke-test
```

Ver `docs/instalacion-windows.md` para requisitos de instalación y solución de
problemas. Los comandos con `--n`/`--seed` deben terminar con código 2 hasta que
se implementen los multiplicadores.

## Resultados por equipo

| Integrante | Diagnóstico | C híbrido 2 × 2 | Smoke test C | Smoke test Go | go test | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| 1 Yessly | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 2 Sebastian | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 3 Giuliano | OK local | OK 2 × 2 | OK | OK | OK | Pendiente revisión cruzada |
| 4 Eva | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 5 Fernando | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 6 Gerardo | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 7 Andres | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 8 Roberto | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |

Adjuntar las salidas relevantes en `docs/entorno/integrante-NN.md` (evidencia sin
credenciales ni variables de entorno completas).

## Criterio de aceptación de la base técnica

- Los ocho integrantes compilan y ejecutan la prueba C híbrida y la prueba Go.
- Una segunda persona puede repetir cada resultado siguiendo solo estas
  instrucciones y las de `docs/instalacion-windows.md`.
- La estructura está en GitHub y los registros de entorno están revisados.

Estas comprobaciones pertenecen a la preparación técnica previa al plan de
desarrollo de la guía vigente. Se conservan las evidencias y los pendientes por PC;
no equivalen a completar el nuevo Sprint 1.

El cierre de S1 se registra en `docs/sprints/sprint-01.md` y exige diagnóstico por
versión, lista priorizada de pendientes y casos de referencia comprobados. Este
documento solo verifica la base técnica recibida.
