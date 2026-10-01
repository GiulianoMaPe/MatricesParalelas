# Diagnóstico funcional: Go secuencial

**Proyecto:** Multiplicación de matrices en C y Go  
**Sprint:** 1 · **Integrante:** 3 (Giuliano)  
**Estado:** diagnóstico terminado.  
**Cómo lo revisé:** leí el código y sus pruebas, y ejecuté la verificación del módulo el 2026-09-30.

## 1. Resumen

El programa Go secuencial todavía no multiplica matrices. Solo permite comprobar que el programa se ejecuta con `--smoke-test`. La multiplicación, la generación de matrices y los argumentos de cálculo siguen pendientes. Las pruebas actuales confirman que esas funciones están pendientes; no comprueban resultados matemáticos.

## 2. Qué hace el programa ahora

1. Si se ejecuta con `--smoke-test`, muestra un mensaje de prueba y termina correctamente.
2. Con cualquier otro argumento, informa que el cálculo está pendiente y termina con código 2.
3. `Multiply` y `Generate` devuelven `ErrPending`; por ahora no calculan ni generan matrices.

## 3. Archivos revisados

| Archivo | Estado | Explicación sencilla |
| --- | --- | --- |
| `main.go` | Parcial | Solo acepta `--smoke-test`; todavía no procesa `--n` ni `--seed`. |
| `matrix.go` | Pendiente | Define cómo guardar una matriz, pero `Multiply` aún no hace el cálculo. |
| `input.go` | Pendiente | `Generate` todavía no crea matrices. |
| `smoke.go` | Parcial | Comprueba que el programa arranque; no prueba la multiplicación. |
| `matrix_test.go` | Parcial | Comprueba que `Multiply` avise que está pendiente. |
| `input_test.go` | Parcial | Comprueba que `Generate` avise que está pendiente. |
| `status.json` | Pendiente | Indica que el algoritmo y su validación no están terminados. |

## 4. Qué falta

| Prioridad | Pendiente | Por qué hace falta | Sprint |
| --- | --- | --- | --- |
| Alta | Acordar con C cómo se reciben argumentos y se informan errores | Las dos versiones deben comportarse de forma parecida. | 2 |
| Alta | Revisar que las dimensiones y los datos sean válidos | Evita errores al usar matrices mal formadas o demasiado grandes. | 2 y 3 |
| Alta | Implementar `Multiply` y probarlo con resultados conocidos | Es la operación principal del programa. | 3 |
| Media | Implementar `Generate` según la regla común del proyecto | Así C y Go pueden usar datos iguales. | 3; coordinar con quien implementa el generador Go |

## 5. Reglas del proyecto que aún no cumple

El contrato pide matrices cuadradas con `N > 0`, valores `float64`, argumentos `--n` y `--seed`, y errores claros cuando la entrada no sirve. También pide rechazar valores no válidos y comparar los resultados celda por celda. Nada de eso está implementado todavía porque el cálculo aún está pendiente.

## 6. Qué habrá que probar cuando se implemente

- Matrices de tamaño 1 y 2, una matriz identidad, una matriz de ceros y valores negativos.
- Dimensiones inválidas o datos incompletos.
- Que los resultados coincidan con los valores esperados y no contengan NaN ni infinitos.
- Que argumentos incorrectos produzcan un error y no un resultado de cálculo.

## 7. Verificación realizada

Ejecuté:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test_windows.ps1 -Version go_secuencial
```

El comando terminó con código 0: compiló el programa, revisó el formato, ejecutó `go vet` y las pruebas, comprobó `--smoke-test` y verificó que un cálculo todavía pendiente termine con código 2. Go mostró avisos al intentar acceder a un archivo de telemetría; aun así, la verificación terminó correctamente. Esto confirma que el esqueleto funciona, no que la multiplicación esté lista.

## 8. Siguientes pasos

- **Sprint 2:** acordar con I1 los argumentos y errores que compartirá con C.
- **Sprint 3:** implementar y probar la multiplicación Go.
- Coordinar con el responsable del generador Go para que ambos usen la misma interfaz.

## Revisión

- Autor: Integrante 3 (Giuliano).
- Revisión cruzada de este diagnóstico: pendiente.
