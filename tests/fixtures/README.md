# Validacion manual de los fixtures

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

## Resultado de la revision

Los cuatro pares de archivos tienen dimensiones, cantidad de filas y valores
coherentes con `docs/formato_datos.md`. No se encontraron resultados esperados
incorrectos. Esta validacion es manual e independiente de los ejecutables: el
lector de fixtures y los algoritmos de multiplicacion siguen pendientes.
