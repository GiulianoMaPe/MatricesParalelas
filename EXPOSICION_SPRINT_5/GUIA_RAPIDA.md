# Exposición S5: abrir y mostrar

**Inicio:** doble clic en `00_MENU.bat`. Exponen cuatro personas.
Orden recomendado del menú: **1 → 3 → 2 → 4**.

## Expositor 1: introducción y C

Decir: «Tenemos cuatro versiones del mismo producto matricial: C y Go,
secuenciales y paralelas. S5 refuerza errores, límites y validación».

Mencionar rápidamente los ocho frentes, sin dar la palabra a todos:

> Yessly: robustez C secuencial; Sebastian: errores colectivos C paralelo;
> Giuliano: entrada/salida Go; Eva: workers y estabilidad; Fernando:
> validación numérica; Gerardo: batería integral; Andrés: auditoría temporal;
> Roberto: reproducción independiente.

Es un resumen de asignaciones. El acta precisa la procedencia de las entregas
y la integración asistida de la batería durante el cierre.

**Abrir:** `01_COMPARAR_C_Y_GO.bat` u opción **1**.
**Señalar:** C=[19 22; 43 50], código 0, validación OK, max_abs=max_rel=0.
**Explicar:** coincide con la referencia en ambas versiones. El ejemplo pequeño
demuestra corrección; sus tiempos no prueban aceleración.

## Expositor 2: Go

Decir: «La lectura Go secuencial comprueba capacidad desde la cabecera y
propaga fallos de lectura/escritura. Go paralelo verifica buffers y aplica el
mismo límite de workers en CLI y API; se probó estabilidad y ausencia de carreras».

**Abrir:** `go_paralelo/02_LIMITE_WORKERS.bat` u opción **3**.
**Señalar:** 1025 se rechaza, máximo 1024, código del programa 1.
**Explicar:** rechazar ese dato es el resultado esperado; 1024 no es una
recomendación de configuración para esta PC.

## Expositor 3: validación

Decir: «Comparamos cada celda con tolerancia absoluta y relativa. La batería
integra las cuatro versiones y controla errores con timeout y diagnóstico».

**Abrir:** `c_secuencial/03_LIMITE_4096.bat` u opción **2**.
**Señalar:** N=4097 se rechaza antes del cálculo, código 1.

**Después abrir:** `03_RESULTADOS_SPRINT_5.bat` u opción **4**.
**Señalar:** Debug y Release aprobados; 48 productos, 98 errores controlados y
296 invocaciones de compatibilidad entre ambas configuraciones.
**Aclarar:** esta pantalla muestra evidencia histórica del cierre, no vuelve a
ejecutar la batería completa.

## Expositor 4: medición y cierre

Decir: «kernel_s mide el cálculo; total_s añade reparto y coordinación. Lectura,
referencia, validación y escritura quedan fuera. El cierre técnico de S5 está
completado y se registraron 64 horas. S6 optimizará con evidencia».

**Mostrar en VS Code:** `docs/protocolo_medicion.md`, sección 9, y
`docs/sprints/sprint-05.md`, tabla de resultados.
**Estado administrativo:** siguen pendientes las conformidades Giuliano→Eva,
Fernando→Gerardo, Gerardo→Andrés y Roberto→Yessly.

## Pruebas de reserva

| Archivo | Qué muestra |
| --- | --- |
| `c_secuencial/01_PRODUCTO_CORRECTO.bat` | Producto C secuencial frente a referencia |
| `c_secuencial/02_DIMENSION_CERO.bat` | Rechazo de N=0 |
| `go_secuencial/01_PRODUCTO_CORRECTO.bat` | Producto Go secuencial |
| `go_secuencial/02_ENTRADA_TRUNCADA.bat` | Error de lectura y salida anterior conservada |
| `go_paralelo/01_PRODUCTO_CORRECTO.bat` | Producto con dos workers |
| `c_paralelo/01_PRODUCTO_MPI.bat` | Producto con P=2/T=2 |
| `c_paralelo/02_PROCESOS_SIN_FILAS.bat` | N=3/P=5/T=1; dos procesos sin filas |
| `c_paralelo/03_ENTRADA_TRUNCADA.bat` | Fallo de lectura y finalización colectiva |
| `02_COMPARAR_LAS_4.bat` | Las cuatro versiones sobre el mismo fixture |

Las pruebas C paralelo y la comparación de las cuatro necesitan MS-MPI Runtime.
Las tres demostraciones recomendadas funcionan sin lanzar MPI.

## Archivos y uso

- Abrir los **.bat**, que pasan los argumentos y mantienen el resultado visible.
  Los **.exe** dentro de cada carpeta son los programas compilados reales.
- Las entradas están en `datos/`; matrices, CSV y diagnósticos quedan en `salidas/`.
- `EJECUTABLES.json` identifica commit y SHA-256 de los cuatro binarios.
- `evidencia_debug.log` y `evidencia_release.log` son copias de los logs del cierre.
- `99_ACTUALIZAR_EJECUTABLES.bat` recompila y copia los binarios. Usarlo antes
  de exponer y con la carpeta dentro del proyecto. Requiere las herramientas
  de compilación; no vuelve a ejecutar las pruebas ni reemplaza la evidencia histórica.
- Para trasladar las demos, copiar **la carpeta completa**. Los lanzadores usan
  rutas relativas; Windows x64 y los runtimes C/MPI necesarios deben estar
  disponibles en el equipo de destino. Para ejecutar los Go compilados no se
  necesita instalar el SDK Go.

Esta guía forma parte del paquete publicado. El guion detallado y la explicación
general de la raíz se conservan como documentos personales locales.
Las salidas generadas por las demostraciones están excluidas mediante el
`.gitignore` de esta carpeta.
