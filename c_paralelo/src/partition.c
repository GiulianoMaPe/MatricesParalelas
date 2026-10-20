#include "partition.h"

#include <limits.h>

/*
 * Both functions implement the S2 design documented in partition.h:
 * q = N / P and r = N % P. The first r ranks receive one extra row. No MPI
 * calls, no threads and no allocations happen here, so the vectors can be
 * checked without initializing MPI.
 */

int partition_split(size_t n, int processes, int *rows, int *first_rows) {
    int quotient, remainder, rank;

    if (n < 1 || n > (size_t)INT_MAX || processes < 1 ||
        rows == NULL || first_rows == NULL) {
        return PARTITION_INVALID;
    }

    quotient = (int)(n / (size_t)processes);
    remainder = (int)(n % (size_t)processes);

    for (rank = 0; rank < processes; ++rank) {
        int local_rows = quotient + (rank < remainder ? 1 : 0);
        size_t first = (size_t)rank * (size_t)quotient;
        if (rank < remainder) {
            first += (size_t)rank;
        } else {
            first += (size_t)remainder;
        }
        rows[rank] = local_rows;
        first_rows[rank] = (int)first;
    }
    return PARTITION_OK;
}

int partition_rows(size_t n, int processes, int *counts, int *displacements) {
    int quotient, remainder, rank, first = 0;

    if (n < 1 || n > PARTITION_MAX_N || processes < 1 ||
        counts == NULL || displacements == NULL) {
        return PARTITION_INVALID;
    }

    quotient = (int)(n / (size_t)processes);
    remainder = (int)(n % (size_t)processes);

    for (rank = 0; rank < processes; ++rank) {
        int local_rows = quotient + (rank < remainder ? 1 : 0);
        /* n <= 46340 makes local_rows*n and first*n fit in a signed int. */
        counts[rank] = local_rows * (int)n;
        displacements[rank] = first * (int)n;
        first += local_rows;
    }
    return PARTITION_OK;
}
