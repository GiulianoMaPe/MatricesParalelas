#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include "partition.h"

struct PartitionCase {
    size_t n;
    int processes;
    const int *rows;
    const int *first_rows;
    const int *counts;
    const int *displacements;
};

static int check_case(const struct PartitionCase *test) {
    int rows[8], first_rows[8], counts[8], displacements[8];
    int i;

    if (test->processes > (int)(sizeof(rows) / sizeof(rows[0]))) return 1;
    if (partition_split(test->n, test->processes, rows, first_rows) != PARTITION_OK) {
        fprintf(stderr, "partition_split rechazo N=%zu P=%d\n", test->n, test->processes);
        return 1;
    }
    if (partition_rows(test->n, test->processes, counts, displacements) != PARTITION_OK) {
        fprintf(stderr, "partition_rows rechazo N=%zu P=%d\n", test->n, test->processes);
        return 1;
    }

    for (i = 0; i < test->processes; ++i) {
        if (rows[i] != test->rows[i] || first_rows[i] != test->first_rows[i] ||
            counts[i] != test->counts[i] || displacements[i] != test->displacements[i]) {
            fprintf(stderr,
                    "reparto incorrecto N=%zu P=%d rank=%d: rows=%d first=%d count=%d displ=%d\n",
                    test->n, test->processes, i, rows[i], first_rows[i], counts[i], displacements[i]);
            return 1;
        }
        if (counts[i] != rows[i] * (int)test->n ||
            displacements[i] != first_rows[i] * (int)test->n) {
            fprintf(stderr, "unidades incorrectas N=%zu P=%d rank=%d\n", test->n, test->processes, i);
            return 1;
        }
        if (i > 0 && first_rows[i] != first_rows[i - 1] + rows[i - 1]) {
            fprintf(stderr, "bloques no contiguos N=%zu P=%d rank=%d\n", test->n, test->processes, i);
            return 1;
        }
    }

    if (first_rows[0] != 0 || first_rows[test->processes - 1] + rows[test->processes - 1] != (int)test->n ||
        displacements[test->processes - 1] + counts[test->processes - 1] != (int)(test->n * test->n)) {
        fprintf(stderr, "el reparto no cubre toda la matriz N=%zu P=%d\n", test->n, test->processes);
        return 1;
    }
    return 0;
}

static int check_invalid_inputs(void) {
    int rows[2] = {71, 72}, first_rows[2] = {81, 82};
    int counts[2] = {91, 92}, displacements[2] = {101, 102};

    if (partition_split(0, 1, rows, first_rows) != PARTITION_INVALID ||
        rows[0] != 71 || rows[1] != 72 || first_rows[0] != 81 || first_rows[1] != 82) {
        fputs("partition_split no rechazo N=0 sin modificar buffers\n", stderr);
        return 1;
    }
    if (partition_split(1, 0, rows, first_rows) != PARTITION_INVALID ||
        rows[0] != 71 || first_rows[0] != 81) {
        fputs("partition_split no rechazo P=0 sin modificar buffers\n", stderr);
        return 1;
    }
    if (partition_split(1, 1, NULL, first_rows) != PARTITION_INVALID ||
        partition_split(1, 1, rows, NULL) != PARTITION_INVALID) {
        fputs("partition_split no rechazo punteros nulos\n", stderr);
        return 1;
    }
    if (partition_rows(0, 1, counts, displacements) != PARTITION_INVALID ||
        counts[0] != 91 || counts[1] != 92 || displacements[0] != 101 || displacements[1] != 102) {
        fputs("partition_rows no rechazo N=0 sin modificar buffers\n", stderr);
        return 1;
    }
    if (partition_rows(1, 0, counts, displacements) != PARTITION_INVALID ||
        counts[0] != 91 || displacements[0] != 101) {
        fputs("partition_rows no rechazo P=0 sin modificar buffers\n", stderr);
        return 1;
    }
    if (partition_rows(1, 1, NULL, displacements) != PARTITION_INVALID ||
        partition_rows(1, 1, counts, NULL) != PARTITION_INVALID) {
        fputs("partition_rows no rechazo punteros nulos\n", stderr);
        return 1;
    }
    if (partition_rows((size_t)46341, 1, counts, displacements) != PARTITION_INVALID ||
        counts[0] != 91 || displacements[0] != 101) {
        fputs("partition_rows no rechazo N=46341 o modifico buffers\n", stderr);
        return 1;
    }
    return 0;
}

int main(void) {
    static const int rows_10_4[] = {3, 3, 2, 2};
    static const int first_10_4[] = {0, 3, 6, 8};
    static const int counts_10_4[] = {30, 30, 20, 20};
    static const int displs_10_4[] = {0, 30, 60, 80};
    static const int rows_7_3[] = {3, 2, 2};
    static const int first_7_3[] = {0, 3, 5};
    static const int counts_7_3[] = {21, 14, 14};
    static const int displs_7_3[] = {0, 21, 35};
    static const int rows_3_5[] = {1, 1, 1, 0, 0};
    static const int first_3_5[] = {0, 1, 2, 3, 3};
    static const int counts_3_5[] = {3, 3, 3, 0, 0};
    static const int displs_3_5[] = {0, 3, 6, 9, 9};
    static const int rows_4_8[] = {1, 1, 1, 1, 0, 0, 0, 0};
    static const int first_4_8[] = {0, 1, 2, 3, 4, 4, 4, 4};
    static const int counts_4_8[] = {4, 4, 4, 4, 0, 0, 0, 0};
    static const int displs_4_8[] = {0, 4, 8, 12, 16, 16, 16, 16};
    static const int rows_46340[] = {46340};
    static const int first_46340[] = {0};
    static const int counts_46340[] = {2147395600};
    static const int displs_46340[] = {0};
    static const struct PartitionCase cases[] = {
        {10, 4, rows_10_4, first_10_4, counts_10_4, displs_10_4},
        {7, 3, rows_7_3, first_7_3, counts_7_3, displs_7_3},
        {3, 5, rows_3_5, first_3_5, counts_3_5, displs_3_5},
        {4, 8, rows_4_8, first_4_8, counts_4_8, displs_4_8},
        {46340, 1, rows_46340, first_46340, counts_46340, displs_46340}
    };
    size_t i;

    for (i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        if (check_case(&cases[i]) != 0) return 1;
    }
    if (check_invalid_inputs() != 0) return 1;
    puts("OK: particionado MPI, bloques vacios, limites y argumentos invalidos.");
    return 0;
}
