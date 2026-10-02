#include "matrix.h"
#include <math.h>
#include <stdint.h>
#include <stdlib.h>

int matrix_validate_dimension(size_t n, size_t *elements, size_t *bytes) {
    size_t count;
    if (n == 0) return MATRIX_INVALID_DIMENSION;
    if (n > SIZE_MAX / n) return MATRIX_SIZE_OVERFLOW;
    count = n * n;
    if (count > (size_t)PTRDIFF_MAX / sizeof(double)) return MATRIX_SIZE_OVERFLOW;
    if (elements != NULL) *elements = count;
    if (bytes != NULL) *bytes = count * sizeof(double);
    return MATRIX_OK;
}

int matrix_validate(const Matrix *matrix) {
    size_t count, i;
    int status;
    if (matrix == NULL) return MATRIX_INVALID_ARGUMENT;
    status = matrix_validate_dimension(matrix->n, &count, NULL);
    if (status != MATRIX_OK) return status;
    if (matrix->length != count || matrix->data == NULL) {
        return MATRIX_INVALID_DATA_LENGTH;
    }
    for (i = 0; i < count; ++i) {
        if (!isfinite(matrix->data[i])) return MATRIX_NON_FINITE_VALUE;
    }
    return MATRIX_OK;
}

int matrix_allocate(Matrix *matrix, size_t n) {
    size_t count;
    double *data;
    int status;
    if (matrix == NULL || matrix->data != NULL || matrix->n != 0 || matrix->length != 0) {
        return MATRIX_INVALID_ARGUMENT;
    }
    status = matrix_validate_dimension(n, &count, NULL);
    if (status != MATRIX_OK) return status;
    data = (double *)calloc(count, sizeof(*data));
    if (data == NULL) return MATRIX_NO_MEMORY;
    matrix->n = n;
    matrix->length = count;
    matrix->data = data;
    return MATRIX_OK;
}

void matrix_release(Matrix *matrix) {
    if (matrix == NULL) return;
    free(matrix->data);
    matrix->n = 0;
    matrix->length = 0;
    matrix->data = NULL;
}

/* Ordered address subtraction avoids overflowing an address + byte count. */
static int buffers_overlap(const double *left, const double *right, size_t bytes) {
    uintptr_t a = (uintptr_t)left;
    uintptr_t b = (uintptr_t)right;
    return a <= b ? b - a < bytes : a - b < bytes;
}

int matrix_multiply_checked(const Matrix *a, const Matrix *b,
                            double *c, size_t c_length) {
    size_t bytes;
    int status = matrix_validate(a);
    if (status != MATRIX_OK) return status;
    status = matrix_validate(b);
    if (status != MATRIX_OK) return status;
    if (a->n != b->n) return MATRIX_DIMENSION_MISMATCH;
    if (c == NULL || c_length != a->length) return MATRIX_INVALID_DATA_LENGTH;
    status = matrix_validate_dimension(a->n, NULL, &bytes);
    if (status != MATRIX_OK) return status;
    if (buffers_overlap(c, a->data, bytes) || buffers_overlap(c, b->data, bytes)) {
        return MATRIX_INVALID_ARGUMENT;
    }
    /* Sprint 2 validates contracts; the mathematical kernel enters in S3. */
    return MATRIX_PENDING;
}

int matrix_multiply(const double *a, const double *b, double *c, size_t n) {
    size_t count;
    Matrix matrix_a, matrix_b;
    int status = matrix_validate_dimension(n, &count, NULL);
    if (status != MATRIX_OK) return status;
    matrix_a.n = matrix_b.n = n;
    matrix_a.length = matrix_b.length = count;
    matrix_a.data = (double *)a;
    matrix_b.data = (double *)b;
    return matrix_multiply_checked(&matrix_a, &matrix_b, c, count);
}
