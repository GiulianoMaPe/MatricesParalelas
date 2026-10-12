#include <stdio.h>
#include <string.h>
#include <math.h>
#include "matrix.h"

static int failures = 0;
#define CHECK(cond) do { if (!(cond)) { \
    fprintf(stderr, "FALLO linea %d: %s\n", __LINE__, #cond); ++failures; } } while (0)

static int close_enough(double got, double expected) {
    return fabs(got - expected) <= 1e-9 + 1e-9 * fabs(expected);
}
static int equal_all(const double *got, const double *expected, size_t n) {
    size_t i;
    for (i = 0; i < n; ++i) if (!close_enough(got[i], expected[i])) return 0;
    return 1;
}
static Matrix view(double *data, size_t n) {
    Matrix m; m.n = n; m.length = n * n; m.data = data; return m;
}

int main(void) {
    /* producto conocido 2x2 */
    { double a[] = {1,2,3,4}, b[] = {5,6,7,8}, c[4] = {99,99,99,99}, e[] = {19,22,43,50};
      Matrix ma = view(a,2), mb = view(b,2);
      CHECK(matrix_multiply_checked(&ma,&mb,c,4) == MATRIX_OK);
      CHECK(equal_all(c,e,4)); }
    /* escalar N=1 */
    { double a[] = {-3}, b[] = {4}, c[1] = {7}; Matrix ma = view(a,1), mb = view(b,1);
      CHECK(matrix_multiply_checked(&ma,&mb,c,1) == MATRIX_OK);
      CHECK(close_enough(c[0], -12.0)); }
    /* identidad con negativos */
    { double a[] = {1,0,0,1}, b[] = {-1,2,3,-4}, c[4] = {5,5,5,5};
      Matrix ma = view(a,2), mb = view(b,2);
      CHECK(matrix_multiply_checked(&ma,&mb,c,4) == MATRIX_OK);
      CHECK(equal_all(c,b,4)); }
    /* cero */
    { double a[] = {0,0,0,0}, b[] = {1,-2,3,-4}, c[4] = {9,9,9,9}, e[] = {0,0,0,0};
      Matrix ma = view(a,2), mb = view(b,2);
      CHECK(matrix_multiply_checked(&ma,&mb,c,4) == MATRIX_OK);
      CHECK(equal_all(c,e,4)); }
    /* impar 3x3 */
    { double a[] = {1,2,3,4,5,6,7,8,9}, b[] = {9,8,7,6,5,4,3,2,1}, c[9];
      double e[] = {30,24,18,84,69,54,138,114,90};
      Matrix ma = view(a,3), mb = view(b,3);
      memset(c, 0, sizeof c);
      CHECK(matrix_multiply_checked(&ma,&mb,c,9) == MATRIX_OK);
      CHECK(equal_all(c,e,9)); }
    /* llamadas repetidas sobre el mismo C no acumulan; A y B no cambian */
    { double a[] = {1,2,3,4}, b[] = {5,6,7,8}, c[4] = {0,0,0,0}, e[] = {19,22,43,50};
      double a0[4], b0[4]; Matrix ma = view(a,2), mb = view(b,2);
      memcpy(a0,a,sizeof a); memcpy(b0,b,sizeof b);
      CHECK(matrix_multiply_checked(&ma,&mb,c,4) == MATRIX_OK);
      CHECK(matrix_multiply_checked(&ma,&mb,c,4) == MATRIX_OK);
      CHECK(equal_all(c,e,4));
      CHECK(memcmp(a,a0,sizeof a) == 0 && memcmp(b,b0,sizeof b) == 0); }
    /* A y B pueden compartir datos (A*A) */
    { double a[] = {1,2,3,4}, c[4], e[] = {7,10,15,22}; Matrix ma = view(a,2);
      CHECK(matrix_multiply_checked(&ma,&ma,c,4) == MATRIX_OK);
      CHECK(equal_all(c,e,4)); }
    /* camino separado: validar, vaciar, acumular == checked */
    { double a[] = {1,2,3,4}, b[] = {5,6,7,8}, c[4] = {42,42,42,42}, e[] = {19,22,43,50};
      Matrix ma = view(a,2), mb = view(b,2);
      CHECK(matrix_multiply_validate(&ma,&mb,c,4) == MATRIX_OK);
      CHECK(c[0] == 42.0);  /* validate no escribe */
      matrix_clear(c,4);
      CHECK(c[0] == 0.0 && c[3] == 0.0);
      matrix_accumulate(a,b,c,2);
      CHECK(equal_all(c,e,4)); }
    /* adaptador legacy */
    { double a[] = {1,2,3,4}, b[] = {5,6,7,8}, c[4], e[] = {19,22,43,50};
      CHECK(matrix_multiply(a,b,c,2) == MATRIX_OK);
      CHECK(equal_all(c,e,4)); }
    /* errores: no tocan C */
    { double a[] = {1,2,3,4}, b[] = {5,6,7,8}, c[4] = {7,7,7,7}, d[] = {7,7,7,7};
      Matrix ma = view(a,2), mb = view(b,2), m1; double one[1] = {1};
      m1 = view(one,1);
      CHECK(matrix_multiply_checked(&ma,&mb,NULL,4) == MATRIX_INVALID_DATA_LENGTH);
      CHECK(matrix_multiply_checked(&ma,&mb,c,3) == MATRIX_INVALID_DATA_LENGTH);
      CHECK(matrix_multiply_checked(&ma,&m1,c,4) == MATRIX_DIMENSION_MISMATCH);
      CHECK(matrix_multiply_checked(NULL,&mb,c,4) == MATRIX_INVALID_ARGUMENT);
      CHECK(matrix_multiply_checked(&ma,&mb,a,4) == MATRIX_INVALID_ARGUMENT); /* C solapa A */
      CHECK(matrix_multiply(a,b,c,0) == MATRIX_INVALID_DIMENSION);
      CHECK(equal_all(c,d,4)); }
    /* NaN e infinito en la entrada */
    { double a[] = {1,NAN,3,4}, b[] = {5,6,7,8}, c[4] = {7,7,7,7}; Matrix ma = view(a,2), mb = view(b,2);
      CHECK(matrix_multiply_checked(&ma,&mb,c,4) == MATRIX_NON_FINITE_VALUE);
      CHECK(c[0] == 7.0); }
    /* desbordamiento del producto -> resultado no finito */
    { double a[] = {1e200}, b[] = {1e200}, c[1]; Matrix ma = view(a,1), mb = view(b,1);
      CHECK(matrix_multiply_checked(&ma,&mb,c,1) == MATRIX_NON_FINITE_VALUE); }
    /* desbordamiento de tamano */
    CHECK(matrix_validate_dimension((size_t)-1, NULL, NULL) == MATRIX_SIZE_OVERFLOW);

    if (failures) { fprintf(stderr, "%d comprobaciones fallaron\n", failures); return 1; }
    puts("OK: nucleo C secuencial (producto, identidad, cero, escalar, impar, repeticion, errores).");
    return 0;
}
