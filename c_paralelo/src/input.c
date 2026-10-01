#ifndef INPUT_H
#define INPUT_H
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
/* Deterministically fills two row-major n-by-n matrices. */
#define INPUT_INVALID 1
#define INPUT_IO_ERROR 2
#define INPUT_NO_MEMORY 3
int input_generate(double *a, double *b, size_t n, uint32_t seed);
uint32_t input_next_state(uint32_t *state);
int input_read(FILE *stream, double **a, double **b, size_t *n);
#endif
