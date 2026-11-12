#ifndef MATRIX_H
#define MATRIX_H
#include <stddef.h>

/* Internal statuses, not process exit codes. main maps every calculation
 * error to 1; MATRIX_PENDING is reserved for the old skeleton contract. */
enum {
    MATRIX_OK = 0,
    MATRIX_INVALID_ARGUMENT = 1,
    MATRIX_PENDING = 2,
    MATRIX_INVALID_DIMENSION = 3,
    MATRIX_SIZE_OVERFLOW = 4,
    MATRIX_INVALID_DATA_LENGTH = 5,
    MATRIX_NON_FINITE_VALUE = 6,
    MATRIX_DIMENSION_MISMATCH = 7,
    MATRIX_NO_MEMORY = 8
};

/* Hybrid local-row kernel.
 *
 * The MPI rank owns a contiguous block of local_rows rows of A and writes the
 * same block of C. B is the complete N x N matrix on every rank:
 *
 *     a_rows[i*N + k]   local rows of A          (local_rows x N)
 *     b[k*N + j]        complete B               (N x N)
 *     c_rows[i*N + j]   local rows of C          (local_rows x N)
 *
 * Rows are distributed by partition.h; therefore every row of C has exactly
 * one owner. matrix_accumulate_rows() runs an OpenMP region over those rows
 * and never calls MPI. The openmp loop index is a signed int because MSVC
 * OpenMP requires a signed integral loop variable. k, j and the row pointers
 * are declared inside the loop body and are private to each thread.
 */

/* Validates local_rows <= n and n*n in elements/bytes. Also rejects n values
 * that do not fit the signed int used by OpenMP and MPI counts. It does not
 * inspect pointers or allocate memory. */
int matrix_multiply_rows_validate(size_t local_rows, size_t n);

/* Explicit zeroing of a local C block. The caller already validated the
 * dimensions. It is part of total_s but not of kernel_s. */
void matrix_clear(double *values, size_t length);

/* Accumulates C += A*B for the local rows with loop order i,k,j. A, B and C
 * must be validated and C must be zeroed. observed_threads receives the number
 * of threads that entered the OpenMP region (1 when local_rows is zero or
 * OpenMP is disabled). No MPI call occurs inside the region. */
void matrix_accumulate_rows(const double *a_rows, const double *b,
                            double *c_rows, size_t local_rows, size_t n,
                            int *observed_threads);

/* Validates, zeroes the local C block, accumulates and checks that the result
 * is finite. Intended for unit tests; the timed path uses the three functions
 * above so that clearing stays inside total_s and outside kernel_s. */
int matrix_multiply_rows_checked(const double *a_rows, const double *b,
                                 double *c_rows, size_t local_rows, size_t n);

/* Full-matrix adapter used by tests and by P=1 debugging. It is equivalent to
 * matrix_multiply_rows_checked(a, b, c, n, n). */
int matrix_multiply(const double *a, const double *b, double *c, size_t n);

#endif
