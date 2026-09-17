#include <stdio.h>
#include "matrix.h"
#include "input.h"
int main(void) {
    double a = 3.0, b = 4.0, c = -123.0;
    if (matrix_multiply(&a, &b, &c, 1) != MATRIX_PENDING || c != -123.0) return 1;
    if (input_generate(&a, &b, 1, 42) != MATRIX_PENDING || a != 3.0 || b != 4.0) return 1;
    puts("OK: operaciones pendientes no producen matrices falsas.");
    return 0;
}