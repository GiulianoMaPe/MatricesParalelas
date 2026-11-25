# Entorno del integrante 6 · Gerardo

Estado: inventario local completado el 24/11/2026. Control oficial independiente pendiente.

| Dato | Valor |
| --- | --- |
| Integrante y fecha | Gerardo · 24 de noviembre de 2026 |
| Windows 11, edición y compilación | Windows 10 Pro for Workstations 64 bits, build 26300 |
| CPU, núcleos físicos y lógicos | 12th Gen Intel Core i3-12100F · 4 físicos / 8 lógicos · 3.30 GHz |
| RAM y configuración de energía | 16 GB físicos · plan activo Economizador |
| MSVC, destino x64 y SDK Windows | No detectado cl.exe; SDK 10.0.26100.0 disponible en el sistema |
| MS-MPI Runtime y SDK x64 | No detectados mpiexec.exe ni cl.exe en esta sesión |
| Go (go version; GOOS/GOARCH) | go1.27.1 windows/amd64 |
| Git y VS Code | Git 2.51.2.windows.1 · VS Code 1.147.0 |
| Extensiones C/C++ y Go; gopls/dlv | No inventariadas automáticamente; VS Code y Go están disponibles |
| Diagnóstico, pruebas y fecha | 24/11/2026: `go test` pasó en go_secuencial y go_paralelo. MSVC/MS-MPI no están disponibles en esta sesión |
| PC candidata a medición y disponibilidad | PC local disponible como control; no es la PC oficial PCG1UL14N0 y no debe mezclarse con la campaña oficial |

Incidencias:

- La raíz descargada no contiene directorio `.git`, por lo que no pudo verificarse un HEAD local ni generar una trazabilidad desde Git.
- La sesión no tiene herramientas C/MS-MPI activas. No se ejecutó una campaña C completa.
- El plan de energía Economizador no debe usarse para la campaña oficial sin cambiarlo y registrar la modificación.
- La ejecución independiente debe usar otra etiqueta de campaña y conservar sus CSV, plan, metadatos y hashes originales.
