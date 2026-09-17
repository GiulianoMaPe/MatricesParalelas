# Trabajo del equipo

Crear una issue por tarea, una rama `feature/sNN-iNN-descripcion` y un pull request
hacia main. Indicar cambio, prueba ejecutada, resultado y limitaciones; usar las plantillas.
Asignar revisión cruzada según docs/sprints/README.md. No integrar con pruebas fallidas
ni afirmar que un algoritmo está completo cuando solo pasa una prueba de instalación.

El propietario debe invitar a los otros siete integrantes y configurar en GitHub la
revisión requerida de main cuando publique. Estas acciones remotas aún no se realizaron.
No hay CI remoto configurado: el autor y la persona revisora ejecutan las pruebas
Windows pertinentes y adjuntan su evidencia. Acordar nombres y versiones en S1.

Actualizar main con `git pull --ff-only` antes de crear una rama. Resolver conflictos
en la rama de trabajo y repetir pruebas. Coordinar archivos compartidos antes de editarlos.
Versionar código, fixtures pequeños y documentación; nunca build, cachés, secretos ni
matrices grandes. Revisar `git diff --cached` antes de cada commit.
