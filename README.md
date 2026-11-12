# Multiplicación de matrices en Windows 11

Repositorio para un equipo de ocho integrantes y diez sprints de desarrollo sobre
una base técnica preparada. Las cuatro versiones ejecutan y validan el producto
real. El [cierre del Sprint 5](docs/sprints/sprint-05.md) reúne la validación
integral, los errores controlados y 64 horas confirmadas. El cierre técnico está
completado; quedan cuatro conformidades personales para el cierre administrativo.
S6 conserva el algoritmo de producción y completa la aceptación Windows:
entregas I4/I7/I8 integradas, comparativas, memoria MPI por rank y revisión.
Consultar [acta S6](docs/sprints/sprint-06.md) y
[evidencia Windows](docs/cierre_s06_windows.md). S7 recibe esta base para su piloto.

| Versión | Tecnología | Estado |
| --- | --- | --- |
| `c_secuencial` | MSVC x64, independiente de MPI/OpenMP | Núcleo, CLI, validación y métricas integrados |
| `c_paralelo` | MSVC x64, MS-MPI y `/openmp` | MPI/OpenMP, particionado y errores colectivos validados en S5 |
| `go_secuencial` | Go windows/amd64 | Producto, CLI, medición y fixtures integrados |
| `go_paralelo` | Go, goroutines y canales | Workers, buffers, estabilidad y errores validados en S5 |

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
`go fmt`, `go vet`, `go test` y el ejecutable. Comprueba los errores controlados
de cada versión; con `-Version all` integra también las 148 invocaciones de
compatibilidad C/Go por configuración. Las cachés están en `.cache/`.
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

Para comparar una salida matricial con una referencia del mismo formato:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\compare_results.ps1 -Expected .\tests\fixtures\producto2.expected.txt -Actual .\ruta\producto2.output.txt
```

El comparador revisa dimensiones y todas las celdas con `atol = rtol = 1e-9`,
rechaza valores no finitos y devuelve código 1 si el formato o algún resultado
no cumple el contrato. Se ejecuta una vez por cada salida que se desea comprobar.

El contrato secuencial es `--n N --seed SEED` o `--input archivo`, con `--output`
opcional y `--repetition 0..5`. C y Go secuenciales implementan estas opciones;
Go paralelo añade `--workers W`. C paralelo recibe P y T mediante
`scripts/run_hybrid_windows.ps1 -Processes P -Threads T`.
El script `bench_windows.ps1 -Version go_secuencial` implementa la medición
individual de S7/I3 con el ejecutable Release, calentamiento y cinco medidas.
Las otras versiones y `all` siguen pendientes y devuelven 2 sin medir.
Consultar [uso, pruebas y aceptación Windows pendiente](docs/validacion_s07_i03.md).

## Organización

```text
MatricesParalelas/                 raíz actual del proyecto
  c_secuencial/                   src, include, tests, build, README, status.json
  c_paralelo/                      src, include, tests, build, README, status.json
  go_secuencial/                   módulo Go independiente, pruebas, build
  go_paralelo/                     módulo Go independiente, workers, pruebas, build
  tests/fixtures/                 entradas y productos conocidos comunes
  scripts/                        automatización PowerShell nativa
  resultados/{piloto,raw,resumen,graficos}/
  docs/entorno/                   plantilla y diagnóstico local
  docs/sprints/                   planificación y cierre de los 10 sprints
  .vscode/                        tareas, depuración e IntelliSense
  .github/                        plantillas de issues y pull requests
```

El [árbol completo](docs/arbol-proyecto.txt) enumera los archivos preparados.
`build/` y `.cache/` son locales, ignorados y recreados por los scripts.
El [plan vigente del equipo](docs/sprints/README.md) define el
plan de desarrollo. Los diez documentos de sprint corresponden a esa versión.
La preparación técnica previa queda fuera de las 640 horas del equipo.

## Comenzar el plan de desarrollo

El [Sprint 1](docs/sprints/sprint-01.md) comienza con la revisión de la base y los
requisitos: diagnósticos funcionales de las cuatro versiones, revisión de fixtures,
diferencias del contrato, preguntas experimentales y requisitos académicos.
Las instrucciones de instalación se conservan como apoyo para preparar cada PC;
no vuelven a asignarse como trabajo de desarrollo ya realizado.

Las rutas acordadas son `docs/formato_datos.md` y `docs/protocolo_medicion.md`.
Los diagnósticos, informes y scripts que aún no existen se crearán en el sprint
asignado. `scripts/compare_results.ps1` implementa la comparación de S3 y
`scripts/summarize_results.ps1` corresponde a S7. `bench_windows.ps1` implementa
el caso individual Go secuencial; falta integrar la campaña completa. El piloto
se guardará en
`resultados/piloto/`, separado de los datos oficiales de S8 en `resultados/raw/`.

## Desarrollo y validación pendientes

Consultar [contrato](docs/contrato.md), [fixtures](docs/formato_datos.md),
[pruebas](tests/README.md), [protocolo de medición](docs/protocolo_medicion.md),
[plan del equipo](docs/sprints/README.md) y [verificación de esta entrega](docs/verificacion-inicial.md).
Las pruebas de instalación no demuestran corrección matemática. Los generadores
y lectores aplican el contrato común. C y Go secuenciales tienen el producto,
la validación de resultados, el flujo de entrada/salida y las métricas integrados.
C paralelo integra el particionado, la comunicación MPI y el núcleo OpenMP;
Go paralelo integra los workers con su ejecutable. Ambos cumplen la aceptación
funcional de S4. S5 completa la batería integral, los errores y la estabilidad.
Las campañas
experimentales oficiales siguen programadas para S7 y S8.
El contrato fija salida 0 para éxito, 1 para
errores y 2 solo para operaciones pendientes; el formato de matrices exige N en
línea propia y N valores por fila. El protocolo distingue cálculo (`kernel_s`)
de vaciado, reparto y coordinación incluidos en `total_s`.

## Primer commit y publicación

Este repositorio ya tiene commits en `main` y un remoto `origin` configurado.
Conservarlos. Para publicar los ajustes locales de esta entrega, revisar y ejecutar:

```powershell
git status --short
git diff
git add README.md docs/arbol-proyecto.txt docs/verificacion-inicial.md scripts/build_windows.ps1 scripts/common_windows.ps1
git diff --cached
git commit -m "Corregir compilacion MSVC con espacios y registrar verificaciones"
git remote -v
git push origin main
```

Estos comandos se entregan para ejecución manual; no se hicieron commit ni push
de estos ajustes. Para futuros cambios de desarrollo usar ramas y pull requests.

**Solo para un repositorio nuevo sin commits ni remoto:** crear manualmente en
GitHub un repositorio vacío llamado `matrices-paralelas` (sin README ni .gitignore).
Reemplazar `TU NOMBRE`, `TU CORREO` y `PROPIETARIO` antes de ejecutar el ejemplo:

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
