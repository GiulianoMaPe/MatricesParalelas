#ifndef MATRIX_H
#define MATRIX_H
#include <stddef.h>
#define MATRIX_PENDING 2
/* TODO: allocation, overflow checks and independent multiplication. */
int matrix_multiply(const double *a, const double *b, double *c, size_t n);
#endif