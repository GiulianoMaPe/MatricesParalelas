#include <stdio.h>
#include <string.h>
#include "matrix.h"
int main(int argc, char **argv) {
    if (argc == 2 && strcmp(argv[1], "--smoke-test") == 0) {
        puts("OK: prueba de instalacion C secuencial x64, sin MPI ni OpenMP. Algoritmo pendiente.");
        return 0;
    }
    fputs("PENDIENTE: multiplicacion y argumentos --n/--seed. Use --smoke-test para probar la instalacion.\n", stderr);
    return MATRIX_PENDING;
}