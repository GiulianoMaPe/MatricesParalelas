#ifndef MATRIX_H
#define MATRIX_H
#include <stddef.h>

/* Function statuses, not process exit codes. In S3 main will map errors to exit 1,
 * pending operations to exit 2, and success to exit 0. */
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

/* Square row-major matrix: data[i*n+j], n > 0, length == n*n.
 * A descriptor may borrow a caller buffer. Only release a descriptor that owns
 * a malloc/calloc buffer (from matrix_allocate or adopted from input_read).
 * Copying a descriptor does not copy data or transfer ownership. */
typedef struct {
    size_t n;
    size_t length;
    double *data;
} Matrix;

/* Checks n*n and its bytes before multiplication/allocation. The byte count
 * must fit PTRDIFF_MAX (signed pointer-sized integer), matching Go's int limit
 * on Windows x64. Optional counts are written only on success. No allocation.
 * Negative text dimensions must be rejected before conversion to size_t. */
int matrix_validate_dimension(size_t n, size_t *elements, size_t *bytes);

/* Validate dimension, exact length/non-NULL data, then finite values, in order.
 * Zeros and negative values are legal. Never modifies the descriptor or data.
 * Caller must supply an actual buffer of at least length accessible elements. */
int matrix_validate(const Matrix *matrix);

/* Requires an empty, initialized descriptor: Matrix m = {0, 0, NULL}.
 * On success owns a zero-filled heap buffer. On error leaves m unchanged.
 * Refuses to overwrite an existing descriptor, preventing lost allocations.
 * Arithmetic validity does not guarantee available RAM; reports allocation
 * failure as MATRIX_NO_MEMORY. */
int matrix_allocate(Matrix *matrix, size_t n);

/* Free an owned buffer and reset n/length/data. NULL and an already released
 * descriptor are safe. Never call on borrowed stack/static data or a copied
 * alias of an owner. Free each allocation exactly once. */
void matrix_release(Matrix *matrix);

/* Validate A, B, matching dimensions, then C's exact capacity and non-overlap.
 * A/B may share data; C must be disjoint from both. Writes NOTHING: it is meant
 * to run BEFORE the timers start. Returns MATRIX_OK when the product can be
 * computed. C need not be initialized or finite. */
int matrix_multiply_validate(const Matrix *a, const Matrix *b,
                             const double *c, size_t c_length);

/* Explicit zeroing of C. Counts in total_s but NOT in kernel_s.
 * Precondition (checked beforehand with matrix_multiply_validate): c points to
 * length writable doubles. */
void matrix_clear(double *c, size_t length);

/* Pure accumulation c += a*b with loop order i,k,j. No validation and no
 * zeroing: this is the interval measured by kernel_s. Preconditions: validated
 * with matrix_multiply_validate and C already cleared with matrix_clear. */
void matrix_accumulate(const double *a, const double *b, double *c, size_t n);

/* Validate, clear C, accumulate and check the result is finite. Returns
 * MATRIX_OK on success. On validation errors all buffers remain untouched. On
 * MATRIX_NON_FINITE_VALUE (the product overflowed) the contents of C are
 * unspecified and must not be used. C need not be initialized: it is zeroed
 * inside the call, so repeated calls never accumulate earlier results. */
int matrix_multiply_checked(const Matrix *a, const Matrix *b,
                            double *c, size_t c_length);

/* Legacy adapter: caller guarantees n*n accessible elements in A, B and C.
 * Raw pointers cannot reveal capacity; new callers should use the checked API.
 * Performs the same work as matrix_multiply_checked. */
int matrix_multiply(const double *a, const double *b, double *c, size_t n);
#endif
