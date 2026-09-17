# Verificación de la entrega inicial (entorno)

Estado: pendiente de ejecución en cada equipo. Este documento describe el alcance y
los pasos para comprobar esta entrega; no sustituye las actas de los integrantes en
`docs/entorno/`.

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
| 3 Giuliano | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 4 Eva | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 5 Fernando | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 6 Gerardo | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 7 Andres | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |
| 8 Roberto | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |

Adjuntar las salidas relevantes en `docs/entorno/integrante-NN.md` (evidencia sin
credenciales ni variables de entorno completas).

## Criterio de aceptación

- Los ocho integrantes compilan y ejecutan la prueba C híbrida y la prueba Go.
- Una segunda persona puede repetir cada resultado siguiendo solo estas
  instrucciones y las de `docs/instalacion-windows.md`.
- La estructura está en GitHub y los registros de entorno están revisados.

El cierre formal del Sprint 1 queda en `docs/sprints/sprint-01.md`; este documento
solo define cómo verificar la entrega inicial.