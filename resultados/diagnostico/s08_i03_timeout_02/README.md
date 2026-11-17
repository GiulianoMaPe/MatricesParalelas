# Subcampaña I3 · intento 02 · timeout del control MPI

| Campo | Resultado |
| --- | --- |
| Campaña | s08_i03_go_secuencial_02 |
| Estado | INCOMPLETE |
| Plan | 72 corridas |
| Observaciones aceptadas | 11, todas warmups |
| Fallo | Orden 12: C paralelo P4/T1, N=2048, warmup |
| Límite | 300 s |
| Pared del proceso fallido | 300.135338 s |
| Pared de campaña | 624.0443951 s |
| CSV | 11 filas OK y 1 TIMEOUT, tiempos vacíos en la fila fallida |
| CPU térmica | Sin lectura por decisión del responsable |
| GPU | Muestras separadas en gpu_muestras.csv; captura parcial cada 30 s |

Se conservaron y compararon por SHA-256 los 51 archivos originales antes de
retirar la copia duplicada de la candidata. `gpu_muestras.csv` y este README
son complementos; los archivos originales no se alteraron. Se conservan stdout,
stderr, PID, parámetros, diagnóstico por rank disponible y estado incompleto.

El proceso raíz MPI seguía usando CPU antes del límite; los otros tres ranks
esperaban. Eso no acredita un bloqueo ni permite atribuir el tiempo a una causa
única. Las corridas C secuencial y Go secuencial N=2048 terminaron en 147.981 s
y 66.825 s de pared, respectivamente. La referencia de validación se prepara
fuera de los cronómetros internos.

La repetición completa usa ID nuevo `s08_i03_go_secuencial_03` y timeout de
900 s, conforme a la regla de ajustar el límite conservando el intento anterior.
Mantiene N=512/1024/2048, semilla 42, P4/T1, W1 y los mismos cuatro binarios.
No se trasladan filas de este intento a la extracción final de I3.
