# Entorno del integrante 3 · Giuliano

Estado: completado (17/09/2026). Todas las dependencias instaladas y verificadas en
esta maquina. Pendiente solo: confirmar con el inventario del equipo la PC
candidata a medicion y que una segunda persona repita las pruebas.

| Dato | Valor |
| --- | --- |
| Integrante y fecha | Giuliano · 17 de septiembre de 2026 |
| Windows 11, edición y compilación | Windows 11 Pro, 64 bits, build 26200 |
| CPU, núcleos físicos y lógicos | AMD Ryzen 5 3600 · 6 físicos / 12 lógicos |
| RAM y configuración de energía | 16 GB (15,9 GB visibles) · plan Equilibrado |
| MSVC, destino x64 y SDK Windows | Build Tools 2026 (18.10) · cl 14.51.36231 (Hostx64/x64) · Windows SDK 10.0.26100.0 |
| MS-MPI Runtime y SDK x64 | v10.1.3 · Runtime 10.1.12498.52 y SDK instalados (mpi.h, msmpi.lib x64; MSMPI_INC/LIB64/BIN) |
| Go (go version; GOOS/GOARCH) | go1.27.0 windows/amd64 · GOROOT C:\Program Files\Go |
| Git y VS Code | Git 2.45.1.windows.1 · VS Code 1.138.0 x64 |
| Extensiones C/C++ y Go; gopls/dlv | ms-vscode.cpptools (+ extension pack, cpp-devtools, cmake-tools); golang.go; gopls instalado · dlv 1.27.2 |
| Diagnóstico, pruebas y fecha | 17/09/2026: check_env_windows.ps1 OK (MSVC x64, SDK, msmpi.lib x64, Go, Git); build all Debug OK; test_windows.ps1 all OK; run_hybrid_windows.ps1 OK 2×2 (procesos 0/1, 2 hilos, nivel MPI FUNNELED); smoke-test OK en c_secuencial, go_secuencial, go_paralelo (c_paralelo exige lanzamiento por mpiexec) |
| PC candidata a medición y disponibilidad | Candidata (6 núcleos / 12 hilos, 16 GB); confirmar con el inventario del equipo |

Adjuntar salidas relevantes sin credenciales ni variables de entorno completas.
Registrar incidencias y persona que reprodujo las pruebas.

Nota: durante la preparacion se corrigio `scripts/common_windows.ps1` (inicializacion
de MSVC con rutas con espacios en VS 2026); verificar en el repositorio.