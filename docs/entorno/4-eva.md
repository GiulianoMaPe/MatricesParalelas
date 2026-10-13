# Entorno del integrante 4 · Eva

Estado: completado (01/10/2026). Hardware y dependencias base identificadas.
Pendiente: instalar MS-MPI Runtime y SDK para compilar C paralelo; Go requiere reiniciar terminal tras instalación.

| Dato | Valor |
| --- | --- |
| Integrante y fecha | Eva · 01 de octubre de 2026 |
| Windows 11, edición y compilación | Windows 11 Pro, 64 bits, build 26200 (10.0.26200) |
| CPU, núcleos físicos y lógicos | AMD Ryzen 7 3700X 8-Core Processor · 8 físicos / 16 lógicos |
| RAM y configuración de energía | 16 GB · plan AMD Ryzen Balanced |
| MSVC, destino x64 y SDK Windows | VS 2022 Community 17.10; cl.exe 19.43.34809 (versión 14.43.34808); destino x64; Windows SDK 10.0.22621.0 (cabeceras y kernel32.lib x64 presentes) |
| MS-MPI Runtime y SDK x64 | **FALTANTE**: Runtime (mpiexec.exe) y SDK (mpi.h, msmpi.lib). Instalar msmpisetup.exe y msmpisdk.msi. |
| Go (go version; GOOS/GOARCH) | go1.27.1 windows/amd64 |
| Git y VS Code | Git 2.51.2.windows.1 · VS Code 1.140.0 (x64) |
| Extensiones C/C++ y Go; gopls/dlv | ms-vscode.cpptools (C/C++); golang.go (Go) instaladas |
| Diagnóstico, pruebas y fecha | 01/10/2026: `check_env_windows.ps1` detectó Windows 11, Git, MSVC y Windows SDK. Reportó faltante: MS-MPI Runtime, MS-MPI SDK, Go en PATH. |
| PC candidata a medición y disponibilidad | Buena candidata por CPU (8 núcleos físicos / 16 hilos) y 16 GB RAM; considerar límite de memoria al fijar N máximo para campaña. |

Adjuntar salidas relevantes sin credenciales ni variables de entorno completas.
Registrar incidencias y persona que reprodujo las pruebas.
