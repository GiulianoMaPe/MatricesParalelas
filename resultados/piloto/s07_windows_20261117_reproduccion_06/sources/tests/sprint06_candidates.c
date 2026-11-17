/* Experimental alternatives in a separate translation unit, just like the
 * production kernel. Build without LTO for the controlled comparison. */
#include <limits.h>
#include <stddef.h>
#ifdef S06_OPENMP
#include <omp.h>

/* Identical preconditions, branches and loop body to matrix_accumulate_rows;
 * the only scheduling change is schedule(static,1). */
void sprint06_candidate(const double *a_rows, const double *b,
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
#pragma omp parallel
    {
#pragma omp single
        observed = omp_get_num_threads();
#pragma omp for schedule(static, 1)
        for (i = 0; i < rows; ++i) {
            const double *a_row = a_rows + (size_t)i * n;
            double *c_row = c_rows + (size_t)i * n;
            int k, j;
            for (k = 0; k < dimension; ++k) {
                const double a_ik = a_row[k];
                const double *b_row = b + (size_t)k * n;
                for (j = 0; j < dimension; ++j) c_row[j] += a_ik * b_row[j];
            }
        }
    }
    if (observed_threads != NULL) *observed_threads = observed;
}
#else
#ifdef _MSC_VER
#define S06_RESTRICT __restrict
#else
#define S06_RESTRICT restrict
#endif

/* Same loops as matrix_accumulate; only the C alias contract differs. */
void sprint06_candidate(const double *a, const double *b,
                        double *S06_RESTRICT c, size_t n) {
    size_t i, k, j;
    for (i = 0; i < n; ++i) {
        const double *a_row = a + i * n;
        double *c_row = c + i * n;
        for (k = 0; k < n; ++k) {
            const double a_ik = a_row[k];
            const double *b_row = b + k * n;
            for (j = 0; j < n; ++j) c_row[j] += a_ik * b_row[j];
        }
    }
}
#endif
