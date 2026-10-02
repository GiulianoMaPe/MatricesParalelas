#ifndef INPUT_H
#define INPUT_H
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
/* Internal statuses, not process exit codes: every input error maps to exit 1,
 * including INPUT_IO_ERROR (2). Exit 2 is reserved for pending operations. */
#define INPUT_INVALID 1
#define INPUT_IO_ERROR 2
#define INPUT_NO_MEMORY 3
/* Fills caller-owned disjoint n*n buffers, A then B with one uint32 LCG state.
 * Checks positive N and byte size <= PTRDIFF_MAX before writing. No allocation. */
int input_generate(double *a, double *b, size_t n, uint32_t seed);
uint32_t input_next_state(uint32_t *state);
/* Requires N on its own line, then N rows of A and N rows of B, each with
 * exactly N finite decimal values. Accepts LF/CRLF and trailing whitespace.
 * stream is borrowed; a/b are distinct empty output variables. Success returns
 * two malloc buffers owned by caller (free both). Failure clears outputs for
 * valid output pointers and frees temporary buffers. NULL/a==b is invalid.
 * Size in bytes must fit PTRDIFF_MAX; no BOM, comments, NaN or infinity. */
int input_read(FILE *stream, double **a, double **b, size_t *n);
#endif
