#ifndef INPUT_H
#define INPUT_H
#include <stddef.h>
#include <stdint.h>
/* TODO: generator and fixture parser defined in docs/contrato.md. */
int input_generate(double *a, double *b, size_t n, uint32_t seed);
#endif