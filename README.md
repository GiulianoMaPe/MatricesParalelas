# Multiplicación de matrices en Windows 11

Repositorio para un equipo de ocho integrantes y diez sprints. Esta entrega prepara
el entorno: **los cuatro algoritmos están pendientes**. Solo `--smoke-test` ejecuta
una prueba de instalación; cualquier solicitud de cálculo termina con código 2,
sin matrices ni tiempos ficticios.

| Versión | Tecnología | Estado |
| --- | --- | --- |
| `c_secuencial` | MSVC x64, independiente de MPI/OpenMP | Esqueleto y prueba de instalación |
| `c_paralelo` | MSVC x64, MS-MPI y `/openmp` | Esqueleto y prueba de 2 procesos × 2 hilos |
| `go_secuencial` | Go windows/amd64 | Esqueleto y prueba de instalación |
| `go_paralelo` | Go, goroutines y canales | Esqueleto y prueba de sincronización |

## Empezar desde VS Code

1. Instalar las herramientas siguiendo [instalación Windows](docs/instalacion-windows.md).
2. Abrir esta carpeta con **Archivo → Abrir carpeta**, sin crear otra raíz.
3. Aceptar las recomendaciones `ms-vscode.cpptools` y `golang.go`. Las extensiones
   no instalan MSVC, MS-MPI ni Go. La extensión Go puede solicitar instalar `gopls`
   y `dlv`; son herramientas adicionales del editor, necesarias para análisis y depuración.
4. Usar **Terminal → Ejecutar tarea → Diagnostico**.
5. Ejecutar `Build go_secuencial Debug`, `Test go_secuencial` y las tareas equivalentes.
   Cuando estén instaladas todas las dependencias, usar `Build all Debug` y `Test all`.
6. F5 ofrece C secuencial y los dos módulos Go. Las tres configuraciones ejecutan
   `--smoke-test`. Para MPI, usar la tarea `MPI 2 procesos x 2 hilos`; no se ofrece
   una falsa depuración automática de todos los procesos MPI.

Las tareas inicializan MSVC mediante `vswhere` y `VsDevCmd.bat`. Para IntelliSense
de C/MPI, abrir **una instancia nueva** de VS Code desde x64 Native Tools Command
Prompt; consultar el procedimiento exacto en la guía de instalación. El entorno
de una tarea no se propaga al proceso del editor.

## Comandos (PowerShell desde la raíz)

`-ExecutionPolicy Bypass` afecta únicamente al proceso lanzado. Ningún script cambia
la política, el PATH ni variables del sistema de forma permanente.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_env_windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version all -Configuration Debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version all
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 -Version all -Configuration Release
```

Se puede sustituir `all` por cualquiera de las cuatro carpetas. Si una versión
falla, `all` intenta las demás y devuelve error global; no oculta faltantes.
`test_windows.ps1` compila primero, ejecuta las pruebas C disponibles y, para Go,
`go fmt`, `go vet`, `go test` y el ejecutable. Las cachés están en `.cache/`.
Debug/Release tienen salidas separadas; los objetos de pruebas C van en `tests/`
dentro del build de la configuración.

```powershell
.\c_secuencial\build\Debug\c_secuencial.exe --smoke-test
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_hybrid_windows.ps1
.\go_secuencial\build\Debug\go_secuencial.exe --smoke-test
.\go_paralelo\build\Debug\go_paralelo.exe --smoke-test
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\clean_windows.ps1
# Opcional: limpiar también las cachés regenerables
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\clean_windows.ps1 -Cache
```

El contrato futuro será `--n N --seed SEED`, con `--workers W` en Go paralelo.
**Esos argumentos aún no están implementados.** El script `bench_windows.ps1`
documenta su futura interfaz y rechaza las mediciones con código 2 mientras no
exista implementación y validación; tampoco se habilita solo editando `status.json`.
No hay resultados experimentales en esta entrega.

## Organización

```text
MatricesParalelas/                 raíz actual del proyecto
  c_secuencial/                   src, include, tests, build, README, status.json
  c_paralelo/                      src, include, tests, build, README, status.json
  go_secuencial/                   módulo Go independiente, pruebas, build
  go_paralelo/                     módulo Go independiente, workers, pruebas, build
  tests/fixtures/                 entradas y productos conocidos comunes
  scripts/                        automatización PowerShell nativa
  resultados/{raw,resumen,graficos}/
  docs/entorno/                   plantilla y diagnóstico local
  docs/sprints/                   planificación y cierre de los 10 sprints
  .vscode/                        tareas, depuración e IntelliSense
  .github/                        plantillas de issues y pull requests
```

El [árbol completo](docs/arbol-proyecto.txt) enumera los archivos preparados.
`build/` y `.cache/` son locales, ignorados y recreados por los scripts.
La [guía original extraída](docs/guia-extraida.txt) conserva el contenido del
Word, sin archivo de Word; sus ejemplos son antecedentes: prevalecen los scripts
y el alcance actual de esqueletos descritos aquí.

## Desarrollo y validación pendientes

Consultar [contrato](docs/contrato.md), [fixtures](docs/formato-datos.md),
[pruebas](tests/README.md), [protocolo de medición](docs/mediciones.md),
[plan del equipo](docs/sprints/README.md) y [verificación de esta entrega](docs/verificacion-inicial.md).
Las pruebas de instalación no demuestran corrección matemática. Faltan los
multiplicadores, argumentos y validación de tamaños, generador común, lectores,
particionado, cronómetros, comparador completo y campañas de medición.

## Primer commit y publicación

El repositorio local usa `main`, sin commit ni remoto. Crear manualmente en GitHub
un repositorio **vacío** llamado `matrices-paralelas` (sin README ni .gitignore).
Reemplazar `TU NOMBRE`, `TU CORREO` y `PROPIETARIO` antes de ejecutar:

```powershell
git config user.name "TU NOMBRE"
git config user.email "TU CORREO"
git status --short
git add .
git diff --cached --stat
git diff --cached
git commit -m "Preparar entorno Windows y estructura de matrices"
git remote -v
git remote add origin https://github.com/PROPIETARIO/matrices-paralelas.git
git push -u origin main
```

Si para entonces ya existe `origin`, conservarlo y verificar su URL antes del push;
no ejecutar de nuevo `remote add`. Usar el inicio de sesión de Git Credential Manager,
sin insertar tokens en comandos o archivos. Añadir los otros siete integrantes como
colaboradores en GitHub. Las reglas de revisión del equipo están en [CONTRIBUTING.md](CONTRIBUTING.md).

```powershell
git clone https://github.com/PROPIETARIO/matrices-paralelas.git
Set-Location matrices-paralelas
git switch -c feature/s01-i01-entorno
code .
# Hacer cambios y ejecutar las pruebas relevantes.
git add docs/entorno
git commit -m "Registrar entorno de desarrollo"
git push -u origin feature/s01-i01-entorno
```

Abrir un pull request hacia `main`, obtener revisión y luego actualizar la rama base
con `git switch main` y `git pull --ff-only` antes de crear la siguiente rama.
