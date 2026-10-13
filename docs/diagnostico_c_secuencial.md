# Diagnóstico C secuencial

**Integrante:** 1 · Yessly

**Fechas:** revisión inicial 30/09/2026; actualización 01/10/2026.

**Estado:** contenido técnico conforme para S1/S2. La evaluación en la voz de Roberto (I8) y la distribución estimada de horas están registradas en los cierres de ambos sprints.

## Qué revisé

Leí el programa, sus interfaces y sus pruebas. En la base recibida solo funcionaba la prueba de instalación; la multiplicación, las entradas y el cronómetro estaban pendientes.

## Qué funciona ahora

Completé las validaciones de las matrices y la reserva y liberación de memoria. Rechazo tamaños inválidos, datos faltantes o sobrantes, NaN e infinitos. Acepto ceros y valores negativos.

El generador y el lector de archivos ya estaban implementados. Ajusté su validación de tamaño y documenté quién libera la memoria.

El programa sigue aceptando `--smoke-test`. Si intento calcular, devuelve código 2 porque la multiplicación sigue pendiente.

## Qué falta

| Trabajo | Sprint | Responsable |
| --- | --- | --- |
| Implementar la multiplicación C | 3 | I1 |
| Integrar argumentos y cronómetro | 3 | I2 |
| Comprobar las entradas generadas entre C y Go | 3 | I6 e I7 |
| Comparar todos los resultados de las matrices | 3 | I5 |
| Ampliar las pruebas de errores y memoria | 5 | Equipo |

## Cómo lo comprobé

Ejecuté desde la raíz el 01/10/2026:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version c_secuencial -Configuration Release
```

Ambos comandos terminaron con código 0. Pasaron las validaciones, las pruebas de memoria, las entradas y la instalación. Los tamaños enormes los comprobé sin reservar esa memoria. Estas pruebas todavía no comprueban una multiplicación.

## Acuerdos y revisión

Adapté C a la [propuesta de I3](especificaciones_c_go_secuencial.md). Confirmé las reglas de datos y los códigos de salida: 0 para éxito, 1 para error y 2 para pendiente.

También revisé y acepté el diagnóstico y el diseño de I2. Dejé los resultados en [S1](sprints/sprint-01.md) y [S2](sprints/sprint-02.md).

**Revisión de I8 · 01/10/2026:** La evaluación asistida en la voz de Roberto confirma que el diagnóstico, las interfaces y las pruebas Debug/Release cumplen el alcance de S1/S2. Las revisiones completas y los cierres documentales están en [S1](sprints/sprint-01.md) y [S2](sprints/sprint-02.md).
