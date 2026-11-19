# Intento I3 interrumpido · s08_i03_go_secuencial_01

Estado observado al recuperar el entorno: **interrumpido, sin estado final**.
Se conservan los 40 archivos originales byte a byte; `lock_huerfano.json`
es una copia adicional del bloqueo residual.

| Evidencia | Resultado |
| --- | --- |
| Campaña | s08_i03_go_secuencial_01 |
| Inicio UTC | 2026-11-17T20:20:05Z |
| Plan | 72 corridas |
| CSV recuperado | 9 filas, todas OK y todas warmups |
| Última fila completa | C secuencial, N=2048, repetición 0 |
| Último registro de inicio | Orden 10, Go secuencial, N=2048 |
| Estado final | No existe estado.json; no se atribuye una salida normal |
| Procesos al recuperar | Ningún ejecutable de medición ni runner activo |
| Lock | PID 6636 ausente; retirado después de archivar |
| Entregable I3 | No válido: no contiene las cinco repeticiones por N |

Durante la sesión el ejecutor local dejó de iniciar comandos con
`helper_unknown_error: setup refresh had errors`. No se puede determinar con
estos archivos la causa exacta de la terminación de la campaña. No se mezclan
sus filas con el intento nuevo `s08_i03_go_secuencial_02`.
