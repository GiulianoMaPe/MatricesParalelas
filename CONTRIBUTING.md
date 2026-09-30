# Trabajo del equipo

Crear una issue por tarea, una rama `feature/sNN-iNN-descripcion` y un pull request
hacia main. Indicar cambio, prueba ejecutada, resultado y limitaciones; usar las plantillas.
Asignar revisión cruzada según docs/sprints/README.md. No integrar con pruebas fallidas
ni afirmar que un algoritmo está completo cuando solo pasa una prueba de instalación.

El propietario debe invitar a los otros siete integrantes y configurar en GitHub la
revisión requerida de main cuando publique. Estas acciones remotas aún no se realizaron.
No hay CI remoto configurado: el autor y la persona revisora ejecutan las pruebas
Windows pertinentes y adjuntan su evidencia. Los nombres se conservan en
docs/entorno/; cada PC debe verificar sus herramientas antes de desarrollar.

Seguir la guía Word de la raíz y las asignaciones actualizadas de docs/sprints/.
S1 revisa la base y acuerda requisitos; la preparación técnica previa queda fuera
de las 640 horas. Si una tarea ya está resuelta, dedicarla a revisión funcional,
casos límite o documentación del mismo módulo. Registrar desarrollo, revisión y
coordinación reales sin declarar completado un sprint por una prueba de instalación.

I2 e I6 en C e I4 e I7 en Go acuerdan las interfaces de argumentos, lectura y
generación antes de editar los mismos archivos. En S7, I1–I4 implementan funciones
separadas del script de medición e I5 integra después de la revisión.

Actualizar main con `git pull --ff-only` antes de crear una rama. Resolver conflictos
en la rama de trabajo y repetir pruebas. Coordinar archivos compartidos antes de editarlos.
Versionar código, fixtures pequeños y documentación; nunca build, cachés, secretos ni
matrices grandes. Revisar `git diff --cached` antes de cada commit.
