# Entorno del integrante 7 · Andres

Estado: en preparación (29/09/2026). Hardware y dependencias base identificadas.
Pendiente: instalar MSVC (C++ Build Tools) y MS-MPI SDK para compilar C.

| Dato | Valor |
| --- | --- |
| Integrante y fecha | Andrés · 29 de septiembre de 2026 |
| Windows 11, edición y compilación | Windows 11 Home Single Language, 64 bits, build 26200 |
| CPU, núcleos físicos y lógicos | AMD Ryzen 7 8845HS w/ Radeon 780M Graphics · 8 físicos / 16 lógicos |
| RAM y configuración de energía | 8 GB visibles · plan Equilibrado |
| MSVC, destino x64 y SDK Windows | Pendiente (Instalar carga "Desarrollo para el escritorio con C++" en Visual Studio Installer) |
| MS-MPI Runtime y SDK x64 | Runtime v10.1.12498.18 instalado (`mpiexec.exe`); SDK pendiente (`msmpisdk.msi` para `mpi.h` y `msmpi.lib`) |
| Go (go version; GOOS/GOARCH) | go1.27.1 windows/amd64 · GOROOT C:\Program Files\Go |
| Git y VS Code | Git 2.45.1.windows.1 · VS Code con extensiones recomendadas |
| Extensiones C/C++ y Go; gopls/dlv | ms-vscode.cpptools; golang.go instaladas |
| Diagnóstico, pruebas y fecha | 29/09/2026: `check_env_windows.ps1` detectó Windows 11, Git, Go y MS-MPI Runtime. Diagnóstico reportó faltante de MSVC y MS-MPI SDK. |
| PC candidata a medición y disponibilidad | Muy buena candidata por CPU (8 núcleos físicos / 16 hilos); considerar 8 GB de RAM al fijar $N$ máximo. |

Adjuntar salidas relevantes sin credenciales ni variables de entorno completas.
Registrar incidencias y persona que reprodujo las pruebas.