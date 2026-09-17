# Instalación nativa en Windows 11 x64

No se usa WSL, Docker ni Linux. Instalar manualmente los componentes siguientes;
los scripts del repositorio no descargan ni instalan programas.

1. Desde [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/),
   obtener Build Tools. En Visual Studio Installer seleccionar **Desarrollo para el
   escritorio con C++**, herramientas MSVC x64/x86 y un SDK de Windows compatible.
   Si Visual Studio ya está instalado, modificar esa instalación. [Uso oficial de MSVC](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line).
2. Desde [Microsoft MPI](https://github.com/microsoft/Microsoft-MPI), instalar
   **Runtime** (`msmpisetup.exe`) y **SDK** (`msmpisdk.msi`). Ambos son necesarios
   para compilar y ejecutar. [Descarga oficial](https://www.microsoft.com/en-us/download/details.aspx?id=105289).
3. Instalar el MSI de [Go para Windows amd64](https://go.dev/doc/install).
   `go.mod` declara un mínimo de lenguaje Go 1.22.0; el equipo debe acordar una
   versión exacta de herramientas y registrarla. Los scripts usan la versión local,
   sin descarga automática de otra toolchain y sin dependencias externas.
4. Instalar [Git for Windows](https://git-scm.com/install/windows) y
   [Visual Studio Code](https://code.visualstudio.com/), con las extensiones recomendadas.
5. Cerrar y abrir las terminales tras instalar. Ejecutar `check_env_windows.ps1`.

OpenMP se habilita con `/openmp` de MSVC; usar construcciones compatibles con su
soporte clásico. No requiere un compilador distinto. Si un ejecutable necesita
DLL del runtime en otra PC, instalar el redistribuible Visual C++ x64 oficial;
no copiar DLL al repositorio.

## Detección y editor

`Initialize-MSVC` busca `vswhere` en PATH y en la ubicación del instalador,
consulta instalaciones con herramientas C++, e importa el entorno producido por
`VsDevCmd.bat -arch=x64 -host_arch=x64` únicamente al proceso actual.
También acepta una consola x64 ya inicializada y verifica cabeceras y biblioteca
del SDK. [Mecanismo oficial de búsqueda](https://github.com/microsoft/vswhere/wiki/Find-VC).

Para que **IntelliSense** herede `cl`, INCLUDE, LIB y las variables del SDK MPI:

1. Cerrar todas las ventanas de VS Code.
2. En Inicio abrir **x64 Native Tools Command Prompt** de la instalación elegida.
3. En esa consola CMD escribir `powershell -NoProfile`.
4. En PowerShell ejecutar lo siguiente, sustituyendo solamente la ruta del clon:

```powershell
Set-Location 'RUTA DEL CLON'
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1
Get-Command cl
$env:VSCMD_ARG_TGT_ARCH
$env:MSMPI_INC
$env:MSMPI_LIB64
code .
```

La arquitectura debe ser `x64`. Si el SDK MPI está instalado y no aparecen las
variables, abrir una terminal nueva. Para una instalación personalizada, fijar
`MSMPI_INC`, `MSMPI_LIB64` y `MSMPI_BIN` en esa sesión a las rutas reales verificadas
antes de abrir VS Code. No guardar rutas personales en los JSON compartidos.
El diagnóstico muestra las rutas encontradas. Las ubicaciones convencionales solo
se aceptan si existen sus archivos; `dumpbin` verifica la biblioteca MPI x64.

La inicialización automática de una tarea permite compilar, pero no cambia el
entorno del editor ya abierto. Go tiene dos módulos: abrir la raíz con la extensión
Go; si el editor pide elegir un módulo para una operación, elegir su carpeta.
Las configuraciones F5 especifican el módulo y requieren `dlv` instalado mediante
la extensión. No se ha validado depuración hasta disponer de estas herramientas.

## Resolución de problemas

| Mensaje | Acción |
| --- | --- |
| MSVC no inicializado, sin vswhere | Instalar la carga C++ o abrir la consola x64 de una instalación existente |
| SDK Windows incompleto | Modificar Visual Studio Installer e instalar el SDK |
| Falta mpi.h/msmpi.lib | Instalar el SDK MPI; verificar MSMPI_INC y MSMPI_LIB64 |
| Falta mpiexec | Instalar Runtime MPI y reabrir terminal |
| Biblioteca de otra arquitectura | Usar Lib/x64 y limpiar build antes de recompilar |
| La prueba híbrida no observa 2 × 2 | Ejecutar run_hybrid_windows.ps1, que fija OMP_NUM_THREADS=2 y OMP_DYNAMIC=FALSE |
| Go distinto de windows/amd64 | Usar MSI amd64 y revisar GOOS/GOARCH de la sesión |
| Política bloquea scripts | Lanzar PowerShell con los argumentos del README; no cambiar políticas permanentes. Las políticas corporativas pueden requerir al administrador |

No se propone `go test -race` en el entorno básico: exige dependencias de cgo
compatibles que MSVC por sí solo no satisface. Esa validación queda fuera del
alcance actual. Las pruebas normales usan únicamente la biblioteca estándar.

Cada integrante copia `docs/entorno/plantilla.md` a `integrante-NN.md` y completa
sus versiones y evidencias reales. No copiar el diagnóstico de otro equipo.
