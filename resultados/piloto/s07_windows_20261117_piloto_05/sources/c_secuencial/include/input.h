#ifndef INPUT_H
#define INPUT_H
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
/* Internal input statuses, distinct from executable exit codes and MATRIX_*.
 * main must map these to exit 1, not forward INPUT_IO_ERROR as pending. */
#define INPUT_INVALID 1
#define INPUT_IO_ERROR 2
#define INPUT_NO_MEMORY 3
/* Caller owns two disjoint buffers, each with at least n*n accessible doubles.
 * Validate size with matrix_validate_dimension before allocating those buffers.
 * Fills A, then B, continuing one uint32 LCG state; includes seeds 0/UINT32_MAX.
 * 0 = success; INPUT_INVALID = NULL pointer or invalid/unrepresentable size.
 * Checks arguments before writing. Does not allocate or free caller data. */
int input_generate(double *a, double *b, size_t n, uint32_t seed);
/* Advances state modulo 2^32; NULL returns 0 without writing. The returned
 * integer is a PRNG state, not a status. */
uint32_t input_next_state(uint32_t *state);
/* stream remains owned/open by caller. a and b are distinct output variables;
 * they must not own existing buffers, since this function replaces their values.
 * Success returns 0, n and two separate malloc buffers of n*n doubles.
 * Caller frees both (or adopts each in a Matrix with length=n*n and releases it).
 * With valid output pointers, failure sets *a=*b=NULL and *n=0, frees temporary
 * allocations, and reports INPUT_INVALID/INPUT_IO_ERROR/INPUT_NO_MEMORY.
 * NULL arguments or a==b return INPUT_INVALID before writing any output.
 * Requires N on its own line, then N rows of A and N rows of B, each with
 * exactly N decimal values. Accepts LF/CRLF and trailing whitespace, no BOM.
 * See docs/formato_datos.md. */
int input_read(FILE *stream, double **a, double **b, size_t *n);
#endif
