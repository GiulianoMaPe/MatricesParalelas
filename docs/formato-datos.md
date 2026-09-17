# Fixtures compartidos

Texto UTF-8 sin BOM, separador decimal punto, espacios entre valores; sin comentarios
ni encabezados. Primera línea: entero positivo N. A continuación N filas de A y N
filas de B, exactamente N números por fila. Salida esperada: N seguido de N filas de C.
Aceptar LF y CRLF, espacios finales y salto de línea final; rechazar valores extra,
faltantes, dimensiones inválidas, NaN e infinitos. El lector aún no está implementado.

`tests/fixtures/producto2.input.txt`:

```text
2
1 2
3 4
5 6
7 8
```

`producto2.expected.txt` contiene `2`, `19 22`, `43 50` en tres líneas.
También hay casos escalar negativo (N=1), identidad y cero. Son resultados conocidos
preparados a mano, **no resultados producidos por los esqueletos**.
Faltan el lector, el comparador, N impar, pruebas de error y particiones no divisibles.
