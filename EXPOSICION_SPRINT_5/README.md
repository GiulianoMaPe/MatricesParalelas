# Demostraciones del Sprint 5

Descargar o clonar el repositorio y abrir **`00_MENU.bat`** con doble clic en
Windows x64. Los cuatro ejecutables Release están incluidos; no hay que
compilar para realizar las demostraciones.

Orden recomendado del menú: **1 → 3 → 2 → 4**:

1. Comparar el producto de C secuencial y Go paralelo con la referencia.
2. Mostrar el rechazo de 1025 workers.
3. Mostrar el rechazo de N=4097 en C secuencial.
4. Presentar la evidencia histórica del cierre Debug/Release.

Consultar [GUIA_RAPIDA.md](GUIA_RAPIDA.md) para el reparto entre cuatro
expositores y la mención breve de los ocho avances individuales.

Las cuatro carpetas contienen sus `.exe` y `.bat` específicos. Los lanzadores
usan rutas relativas y conservan el resultado visible. C paralelo y la
comparación de las cuatro versiones requieren MS-MPI Runtime. Los runtimes C
necesarios deben estar disponibles en el equipo; para ejecutar los binarios
Go no es necesario instalar el SDK Go.

`datos/` contiene las entradas y referencias. `salidas/` se regenera al abrir
las pruebas y no se versiona. Los dos logs `evidencia_*.log` corresponden al
cierre del 05/11/2026: mostrarlos no vuelve a ejecutar la batería.

`EJECUTABLES.json` identifica el commit compilado y sus huellas SHA-256.
`99_ACTUALIZAR_EJECUTABLES.bat` recompila y copia los binarios desde el proyecto;
requiere las herramientas de compilación y no reemplaza la evidencia histórica.
