# Validacion manual de los fixtures

## Autor y alcance

Este documento registra el trabajo de Fernando, Integrante 5.

- Sprint 1: validacion manual de los cuatro fixtures recibidos.
- Sprint 2: ampliacion de los casos con una matriz 3x3 de dimension impar y
  definicion del criterio de comparacion, tolerancias y politica para `NaN` e
  infinitos.

Revision realizada el 2026-10-01. Cada archivo de entrada contiene primero
`N`, luego las `N` filas de `A` y finalmente las `N` filas de `B`. El archivo
esperado contiene `N` y las `N` filas de `C = A * B`.

## Producto conocido 2 por 2

Para `producto2.input.txt`:

```text
A = [1 2]    B = [5 6]
    [3 4]        [7 8]
```

Calculo celda por celda:

```text
C[0,0] = 1*5 + 2*7 = 19
C[0,1] = 1*6 + 2*8 = 22
C[1,0] = 3*5 + 4*7 = 43
C[1,1] = 3*6 + 4*8 = 50
```

El resultado coincide con `producto2.expected.txt`.

## Identidad

Para `identidad.input.txt`, `A` es la identidad de orden 2. Por tanto,
`A * B = B`:

```text
C = [-1  2]
    [ 3 -4]
```

El resultado coincide con `identidad.expected.txt`.

## Escalar negativo

Para `escalar.input.txt`, las matrices tienen orden 1:

```text
C[0,0] = -3*4 = -12
```

El resultado coincide con `escalar.expected.txt`.

## Matriz cero

Para `cero.input.txt`, todos los elementos de `A` son cero. Cada producto
acumulado es cero, por lo que:

```text
C = [0 0]
    [0 0]
```

El resultado coincide con `cero.expected.txt`.

## Dimension impar con ceros y negativos

`impar3.input.txt` amplia la cobertura con matrices de orden 3:

```text
A = [ 1 -2  0]    B = [2  0 -1]
    [ 0  3  1]        [1 -1  2]
    [-1  0  2]        [0  3  1]
```

Calculo celda por celda:

```text
C[0,0] =  1*2 + (-2)*1 + 0*0     =  0
C[0,1] =  1*0 + (-2)*(-1) + 0*3  =  2
C[0,2] =  1*(-1) + (-2)*2 + 0*1  = -5
C[1,0] =  0*2 + 3*1 + 1*0        =  3
C[1,1] =  0*0 + 3*(-1) + 1*3     =  0
C[1,2] =  0*(-1) + 3*2 + 1*1     =  7
C[2,0] = (-1)*2 + 0*1 + 2*0      = -2
C[2,1] = (-1)*0 + 0*(-1) + 2*3   =  6
C[2,2] = (-1)*(-1) + 0*2 + 2*1   =  3
```

El resultado coincide con `impar3.expected.txt`.

## Criterio de comparacion

Antes de comparar valores, ambas matrices deben tener la misma dimension y todos
sus elementos deben ser finitos. La presencia de `NaN`, infinito positivo o
infinito negativo hace fallar la validacion, incluso si aparece en ambas matrices.

Cada celda se acepta cuando cumple:

```text
abs(obtenido - esperado) <= 1e-9 + 1e-9*abs(esperado)
```

Esto corresponde a una tolerancia absoluta `atol = 1e-9` y una tolerancia
relativa `rtol = 1e-9`. Deben compararse todas las celdas; un checksum no
sustituye esta comprobacion.

## Resultado de la revision

Los cinco pares de archivos tienen dimensiones, cantidad de filas y valores
coherentes con `docs/formato_datos.md`. Los casos cubren producto conocido,
identidad, matriz cero, valor escalar negativo y dimension impar con valores
positivos, negativos y cero. No se encontraron resultados esperados incorrectos.
Esta validacion matematica es manual e independiente de los ejecutables. Los
lectores de fixtures ya existen como funciones y aplican el contrato por lineas;
su integracion en la CLI, el comparador y los algoritmos de multiplicacion siguen
pendientes. Ver [formato comun](../../docs/formato_datos.md).
