#ifndef PARTITION_H
#define PARTITION_H
#include <stddef.h>
/* TODO: quotient/remainder rows, checked MPI counts and displacements. */
int partition_rows(size_t n, int processes, int *counts, int *displacements);
#endif