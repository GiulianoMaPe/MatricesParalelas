#include "matrix.h"

#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#ifdef _OPENMP
#include <omp.h>
#endif

int matrix_multiply_rows_validate(size_t local_rows, size_t n) {
    size_t count;

    if (n == 0 || local_rows > n) return MATRIX_INVALID_DIMENSION;
    /* MSVC OpenMP and the MPI count arguments use signed int. */
    if (n > (size_t)INT_MAX) return MATRIX_SIZE_OVERFLOW;
    if (n > SIZE_MAX / n) return MATRIX_SIZE_OVERFLOW;
    count = n * n;
    if (count > (size_t)PTRDIFF_MAX / sizeof(double)) {
        return MATRIX_SIZE_OVERFLOW;
    }
    return MATRIX_OK;
}

void matrix_clear(double *values, size_t length) {
    if (values == NULL || length == 0) return;
    /* All-bits-zero is +0.0 for IEEE-754 doubles. */
    memset(values, 0, length * sizeof(*values));
}

void matrix_accumulate_rows(const double *a_rows, const double *b,
                            double *c_rows, size_t local_rows, size_t n,
                            int *observed_threads) {
    int rows, dimension, i, observed = 1;

    if (local_rows == 0) {
        if (observed_threads != NULL) *observed_threads = 1;
        return;
    }
    if (local_rows > (size_t)INT_MAX || n > (size_t)INT_MAX) {
        if (observed_threads != NULL) *observed_threads = 1;
        return;
    }

    rows = (int)local_rows;
    dimension = (int)n;

    /* The region preserves the static schedule and its implicit end barrier.
     * These are part of the local kernel interval. No MPI call is allowed
     * inside this block: MPI is only used by the initial thread outside it. */
#ifdef _OPENMP
#pragma omp parallel
#endif
    {
#ifdef _OPENMP
#pragma omp single
        observed = omp_get_num_threads();
#pragma omp for schedule(static)
#endif
        for (i = 0; i < rows; ++i) {
            const double *a_row = a_rows + (size_t)i * n;
            double *c_row = c_rows + (size_t)i * n;
            int k, j;
            for (k = 0; k < dimension; ++k) {
                const double a_ik = a_row[k];
                const double *b_row = b + (size_t)k * n;
                for (j = 0; j < dimension; ++j) {
                    c_row[j] += a_ik * b_row[j];
                }
            }
        }
    }

    if (observed_threads != NULL) *observed_threads = observed;
}

static int all_finite(const double *values, size_t length) {
    size_t i;
    for (i = 0; i < length; ++i) {
        if (!isfinite(values[i])) return 0;
    }
    return 1;
}

int matrix_multiply_rows_checked(const double *a_rows, const double *b,
                                 double *c_rows, size_t local_rows, size_t n) {
    int status = matrix_multiply_rows_validate(local_rows, n);
    size_t count;

    if (status != MATRIX_OK) return status;
    if (local_rows == 0) return MATRIX_OK;
    if (a_rows == NULL || b == NULL || c_rows == NULL) {
        return MATRIX_INVALID_ARGUMENT;
    }

    count = local_rows * n;
    matrix_clear(c_rows, count);
    matrix_accumulate_rows(a_rows, b, c_rows, local_rows, n, NULL);
    return all_finite(c_rows, count) ? MATRIX_OK : MATRIX_NON_FINITE_VALUE;
}

int matrix_multiply(const double *a, const double *b, double *c, size_t n) {
    int status = matrix_multiply_rows_validate(n, n);
    size_t count;

    if (status != MATRIX_OK) return status;
    if (a == NULL || b == NULL || c == NULL) return MATRIX_INVALID_ARGUMENT;

    count = n * n;
    matrix_clear(c, count);
    matrix_accumulate_rows(a, b, c, n, n, NULL);
    return all_finite(c, count) ? MATRIX_OK : MATRIX_NON_FINITE_VALUE;
}
