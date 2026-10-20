#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "matrix.h"
#include "partition.h"

static int close_enough(double actual, double expected, double tolerance) {
    return fabs(actual - expected) <= tolerance;
}

static int check_fixture(const char *path, size_t want_n,
                         const double *want_a, const double *want_b) {
    FILE *stream = NULL;
    double *a = NULL, *b = NULL;
    size_t n = 0, i;
    int result;
    if (fopen_s(&stream, path, "rb") != 0 || stream == NULL) return 1;
    result = input_read(stream, &a, &b, &n);
    fclose(stream);
    if (result != 0 || n != want_n || a == NULL || b == NULL) {
        free(a);
        free(b);
        return 1;
    }
    for (i = 0; i < n * n; ++i) {
        if (fabs(a[i] - want_a[i]) > 1e-15 || fabs(b[i] - want_b[i]) > 1e-15) {
            free(a);
            free(b);
            return 1;
        }
    }
    free(a);
    free(b);
    return 0;
}

static int accepts_crlf_fixture(void) {
    FILE *stream = NULL;
    double *a = NULL, *b = NULL;
    size_t n = 0;
    int result;
    if (tmpfile_s(&stream) != 0 || stream == NULL) return 1;
    if (fputs("2\r\n+1 2.\r\n.5 -2e-1\r\n3 4\r\n5 6  \r\n", stream) == EOF ||
        fflush(stream) != 0 || fseek(stream, 0, SEEK_SET) != 0) {
        fclose(stream);
        return 1;
    }
    result = input_read(stream, &a, &b, &n);
    fclose(stream);
    if (result != 0 || n != 2 || fabs(a[0] - 1.0) > 1e-15 ||
        fabs(a[1] - 2.0) > 1e-15 || fabs(a[2] - 0.5) > 1e-15 ||
        fabs(a[3] + 0.2) > 1e-15 || fabs(b[0] - 3.0) > 1e-15 ||
        fabs(b[1] - 4.0) > 1e-15 || fabs(b[2] - 5.0) > 1e-15 ||
        fabs(b[3] - 6.0) > 1e-15) {
        free(a);
        free(b);
        return 1;
    }
    free(a);
    free(b);
    return 0;
}

static int rejects_fixture(const char *text) {
    FILE *stream = NULL;
    double *a = NULL, *b = NULL;
    size_t n = 0;
    int result;
    int clean;
    if (tmpfile_s(&stream) != 0 || stream == NULL) return 1;
    if (fputs(text, stream) == EOF || fflush(stream) != 0 ||
        fseek(stream, 0, SEEK_SET) != 0) {
        fclose(stream);
        return 1;
    }
    result = input_read(stream, &a, &b, &n);
    fclose(stream);
    clean = result == INPUT_INVALID && a == NULL && b == NULL && n == 0;
    free(a);
    free(b);
    return clean ? 0 : 1;
}

static int check_file_format_contract(void) {
    struct FormatCase {
        const char *data;
        size_t length;
        int valid;
        double a, b;
    };
#define FORMAT_CASE(text, valid, a, b) {text, sizeof(text) - 1, valid, a, b}
    const struct FormatCase cases[] = {
        FORMAT_CASE("1\n1\n2", 1, 1, 2),
        FORMAT_CASE("1\r\n1\r\n2\r\n", 1, 1, 2),
        FORMAT_CASE(" \t1 \n \t1\t \n2  \n\t \n", 1, 1, 2),
        FORMAT_CASE("1\r\n1\n2\r\n", 1, 1, 2),
        FORMAT_CASE("1\n4.9406564584124654e-324\n1e-9999", 1, nextafter(0.0, 1.0), 0),
        FORMAT_CASE("1 1\n2", 0, 0, 0),
        FORMAT_CASE("2\n1 2 3 4\n5 6\n7 8", 0, 0, 0),
        FORMAT_CASE("2\n1\n2 3 4\n5 6\n7 8", 0, 0, 0),
        FORMAT_CASE("1\n\n1\n2", 0, 0, 0),
        FORMAT_CASE("1\n1\n2\n3", 0, 0, 0),
        FORMAT_CASE("1\n1", 0, 0, 0),
        FORMAT_CASE("1\r1\r2", 0, 0, 0),
        FORMAT_CASE("\xef\xbb\xbf" "1\n1\n2", 0, 0, 0),
        FORMAT_CASE("1\n1\0x\n2", 0, 0, 0),
        FORMAT_CASE("1\n1\xc2\xa0\n2", 0, 0, 0),
        FORMAT_CASE("1\n1\xff\n2", 0, 0, 0),
        FORMAT_CASE("1\nNaN\n2", 0, 0, 0),
        FORMAT_CASE("1\n+Inf\n2", 0, 0, 0),
        FORMAT_CASE("1\n1e9999\n2", 0, 0, 0),
        FORMAT_CASE("1\n0x1p2\n2", 0, 0, 0),
        FORMAT_CASE("1\n1e\n2", 0, 0, 0),
        FORMAT_CASE("18446744073709551615\n1\n2", 0, 0, 0)
    };
#undef FORMAT_CASE
    size_t i;
    for (i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        const struct FormatCase *test = &cases[i];
        FILE *stream = NULL;
        double *a = NULL, *b = NULL;
        size_t n = 0;
        int status, ok;
        if (tmpfile_s(&stream) != 0 || stream == NULL) return 1;
        if (fwrite(test->data, 1, test->length, stream) != test->length ||
            fflush(stream) != 0 || fseek(stream, 0, SEEK_SET) != 0) {
            fclose(stream);
            return 1;
        }
        status = input_read(stream, &a, &b, &n);
        fclose(stream);
        if (test->valid) {
            ok = status == 0 && n == 1 && a != NULL && b != NULL &&
                 a[0] == test->a && b[0] == test->b;
        } else {
            ok = status == INPUT_INVALID && n == 0 && a == NULL && b == NULL;
        }
        free(a);
        free(b);
        if (!ok) {
            fprintf(stderr, "FALLO formato de archivo, caso %zu\n", i);
            return 1;
        }
    }
    return 0;
}

static int check_input_core(void) {
    const double want_a[4] = {-0.363, 0.036, -0.215, 0.602};
    const double want_b[4] = {0.941, -0.453, -0.554, 0.579};
    const uint32_t want_states[8] = {
        1083814273u, 378494188u, 2479403867u, 955863294u,
        1613448261u, 110225632u, 1921058495u, 508781842u
    };
    const double fixture_producto_a[] = {1, 2, 3, 4};
    const double fixture_producto_b[] = {5, 6, 7, 8};
    const double fixture_escalar_a[] = {-3};
    const double fixture_escalar_b[] = {4};
    const double fixture_identidad_a[] = {1, 0, 0, 1};
    const double fixture_identidad_b[] = {-1, 2, 3, -4};
    const double fixture_cero_a[] = {0, 0, 0, 0};
    const double fixture_cero_b[] = {1, -2, 3, -4};
    const char *invalid[] = {
        "", "x 1 2", "0 1 2", "-1 1 2", "1 1", "1 1 2 3", "1 NaN 2",
        "1 +Inf 2", "1 0x1p2 2", "1 1e 2", "1 1e9999 2", "1 1 2 extra"
    };
    double a[4], b[4];
    uint32_t state = 42;
    size_t i;

    for (i = 0; i < 8; ++i) {
        if (input_next_state(&state) != want_states[i]) return 1;
    }
    if (input_generate(a, b, 2, 42) != 0) return 1;
    for (i = 0; i < 4; ++i) {
        if (fabs(a[i] - want_a[i]) > 1e-15 ||
            fabs(b[i] - want_b[i]) > 1e-15) {
            return 1;
        }
    }
    if (check_fixture("tests/fixtures/producto2.input.txt", 2,
                      fixture_producto_a, fixture_producto_b) != 0) return 1;
    if (check_fixture("tests/fixtures/escalar.input.txt", 1,
                      fixture_escalar_a, fixture_escalar_b) != 0) return 1;
    if (check_fixture("tests/fixtures/identidad.input.txt", 2,
                      fixture_identidad_a, fixture_identidad_b) != 0) return 1;
    if (check_fixture("tests/fixtures/cero.input.txt", 2,
                      fixture_cero_a, fixture_cero_b) != 0) return 1;
    if (accepts_crlf_fixture() != 0) return 1;
    if (check_file_format_contract() != 0) return 1;
    for (i = 0; i < sizeof(invalid) / sizeof(invalid[0]); ++i) {
        if (rejects_fixture(invalid[i]) != 0) return 1;
    }
    if (input_generate(a, b, 0, 42) != INPUT_INVALID) return 1;
    if (input_generate(NULL, b, 2, 42) != INPUT_INVALID) return 1;
    return 0;
}

static int check_partition_case(int n, int processes,
                                const int *want_rows, const int *want_first,
                                const int *want_counts,
                                const int *want_displacements) {
    int rows[16], first[16], counts[16], displacements[16];
    int rank;
    if (processes < 1 || processes > 16) return 1;
    if (partition_split((size_t)n, processes, rows, first) != PARTITION_OK) {
        return 1;
    }
    if (partition_rows((size_t)n, processes, counts, displacements) !=
        PARTITION_OK) {
        return 1;
    }
    for (rank = 0; rank < processes; ++rank) {
        if (rows[rank] != want_rows[rank] ||
            first[rank] != want_first[rank] ||
            counts[rank] != want_counts[rank] ||
            displacements[rank] != want_displacements[rank]) {
            fprintf(stderr,
                    "FALLO particion N=%d P=%d rank=%d: "
                    "rows=%d first=%d counts=%d displs=%d\n",
                    n, processes, rank, rows[rank], first[rank],
                    counts[rank], displacements[rank]);
            return 1;
        }
    }
    return 0;
}

static int check_partition_examples(void) {
    const int rows_10_4[4] = {3, 3, 2, 2};
    const int first_10_4[4] = {0, 3, 6, 8};
    const int counts_10_4[4] = {30, 30, 20, 20};
    const int displs_10_4[4] = {0, 30, 60, 80};
    const int rows_7_3[3] = {3, 2, 2};
    const int first_7_3[3] = {0, 3, 5};
    const int counts_7_3[3] = {21, 14, 14};
    const int displs_7_3[3] = {0, 21, 35};
    const int rows_5_2[2] = {3, 2};
    const int first_5_2[2] = {0, 3};
    const int counts_5_2[2] = {15, 10};
    const int displs_5_2[2] = {0, 15};
    const int rows_8_4[4] = {2, 2, 2, 2};
    const int first_8_4[4] = {0, 2, 4, 6};
    const int counts_8_4[4] = {16, 16, 16, 16};
    const int displs_8_4[4] = {0, 16, 32, 48};
    const int rows_2_2[2] = {1, 1};
    const int first_2_2[2] = {0, 1};
    const int counts_2_2[2] = {2, 2};
    const int displs_2_2[2] = {0, 2};
    const int rows_1_1[1] = {1};
    const int first_1_1[1] = {0};
    const int counts_1_1[1] = {1};
    const int displs_1_1[1] = {0};
    const int rows_3_5[5] = {1, 1, 1, 0, 0};
    const int first_3_5[5] = {0, 1, 2, 3, 3};
    const int counts_3_5[5] = {3, 3, 3, 0, 0};
    const int displs_3_5[5] = {0, 3, 6, 9, 9};
    const int rows_4_8[8] = {1, 1, 1, 1, 0, 0, 0, 0};
    const int first_4_8[8] = {0, 1, 2, 3, 4, 4, 4, 4};
    const int counts_4_8[8] = {4, 4, 4, 4, 0, 0, 0, 0};
    const int displs_4_8[8] = {0, 4, 8, 12, 16, 16, 16, 16};

    if (check_partition_case(10, 4, rows_10_4, first_10_4, counts_10_4,
                             displs_10_4) != 0) return 1;
    if (check_partition_case(7, 3, rows_7_3, first_7_3, counts_7_3,
                             displs_7_3) != 0) return 1;
    if (check_partition_case(5, 2, rows_5_2, first_5_2, counts_5_2,
                             displs_5_2) != 0) return 1;
    if (check_partition_case(8, 4, rows_8_4, first_8_4, counts_8_4,
                             displs_8_4) != 0) return 1;
    if (check_partition_case(2, 2, rows_2_2, first_2_2, counts_2_2,
                             displs_2_2) != 0) return 1;
    if (check_partition_case(1, 1, rows_1_1, first_1_1, counts_1_1,
                             displs_1_1) != 0) return 1;
    if (check_partition_case(3, 5, rows_3_5, first_3_5, counts_3_5,
                             displs_3_5) != 0) return 1;
    if (check_partition_case(4, 8, rows_4_8, first_4_8, counts_4_8,
                             displs_4_8) != 0) return 1;
    return 0;
}

static int check_partition_grid(void) {
    int rows[80], first[80], counts[80], displacements[80];
    int n, processes, rank;
    for (n = 1; n <= 64; ++n) {
        for (processes = 1; processes <= 70; ++processes) {
            long long row_sum = 0, count_sum = 0;
            if (partition_split((size_t)n, processes, rows, first) !=
                PARTITION_OK) return 1;
            if (partition_rows((size_t)n, processes, counts, displacements) !=
                PARTITION_OK) return 1;
            if (first[0] != 0) return 1;
            for (rank = 0; rank < processes; ++rank) {
                row_sum += rows[rank];
                count_sum += counts[rank];
                if (rows[rank] < 0 || first[rank] < 0 ||
                    first[rank] + rows[rank] > n) return 1;
                if (counts[rank] != rows[rank] * n ||
                    displacements[rank] != first[rank] * n) return 1;
                if (rank + 1 < processes) {
                    if (first[rank + 1] != first[rank] + rows[rank]) return 1;
                    if (displacements[rank] + counts[rank] !=
                        displacements[rank + 1]) return 1;
                }
            }
            if (row_sum != n || count_sum != (long long)n * n) return 1;
            if (displacements[processes - 1] + counts[processes - 1] !=
                n * n) return 1;
        }
    }
    return 0;
}

static int check_partition_errors(void) {
    int rows[4] = {7, 7, 7, 7};
    int first[4] = {7, 7, 7, 7};
    int counts[4] = {7, 7, 7, 7};
    int displacements[4] = {7, 7, 7, 7};
    int i;

    if (partition_split(0, 1, rows, first) != PARTITION_INVALID) return 1;
    if (partition_split(1, 0, rows, first) != PARTITION_INVALID) return 1;
    if (partition_split(1, 1, NULL, first) != PARTITION_INVALID) return 1;
    if (partition_split(1, 1, rows, NULL) != PARTITION_INVALID) return 1;
    if (partition_split((size_t)INT_MAX + 1, 1, rows, first) !=
        PARTITION_INVALID) return 1;
    if (partition_rows(0, 1, counts, displacements) != PARTITION_INVALID) {
        return 1;
    }
    if (partition_rows(1, 0, counts, displacements) != PARTITION_INVALID) {
        return 1;
    }
    if (partition_rows(1, 1, NULL, displacements) != PARTITION_INVALID) {
        return 1;
    }
    if (partition_rows(1, 1, counts, NULL) != PARTITION_INVALID) return 1;
    if (partition_rows(46341, 1, counts, displacements) != PARTITION_INVALID) {
        return 1;
    }
    for (i = 0; i < 4; ++i) {
        if (rows[i] != 7 || first[i] != 7 || counts[i] != 7 ||
            displacements[i] != 7) return 1;
    }
    if (partition_split(46340, 1, rows, first) != PARTITION_OK) return 1;
    if (rows[0] != 46340 || first[0] != 0) return 1;
    if (partition_rows(46340, 2, counts, displacements) != PARTITION_OK) {
        return 1;
    }
    if (counts[0] != 23170 * 46340 || displacements[1] != 23170 * 46340) {
        return 1;
    }
    return 0;
}

static int check_matrix_core(void) {
    const double a2[4] = {1, 2, 3, 4};
    const double b2[4] = {5, 6, 7, 8};
    const double expected2[4] = {19, 22, 43, 50};
    double a1[1] = {2.0}, b1[1] = {3.0}, c1[1] = {-1.0};
    double c2[4] = {0, 0, 0, 0};
    double inf_a[1] = {HUGE_VAL}, inf_b[1] = {1.0}, inf_c[1] = {0.0};
    double zero_c[1] = {123.0};
    size_t i;

    if (matrix_multiply(a1, b1, c1, 1) != MATRIX_OK ||
        !close_enough(c1[0], 6.0, 1e-15)) return 1;
    if (matrix_multiply(a2, b2, c2, 2) != MATRIX_OK) return 1;
    for (i = 0; i < 4; ++i) {
        if (!close_enough(c2[i], expected2[i], 1e-15)) return 1;
    }
    /* A repeated call must clear the previous result first. */
    if (matrix_multiply(a2, b2, c2, 2) != MATRIX_OK) return 1;
    for (i = 0; i < 4; ++i) {
        if (!close_enough(c2[i], expected2[i], 1e-15)) return 1;
    }
    if (matrix_multiply(inf_a, inf_b, inf_c, 1) !=
        MATRIX_NON_FINITE_VALUE) return 1;
    if (matrix_multiply(NULL, b1, c1, 1) != MATRIX_INVALID_ARGUMENT) return 1;
    if (matrix_multiply(a1, b1, NULL, 1) != MATRIX_INVALID_ARGUMENT) return 1;
    if (matrix_multiply(a1, b1, c1, 0) != MATRIX_INVALID_DIMENSION) return 1;
    if (matrix_multiply_rows_validate(2, 1) != MATRIX_INVALID_DIMENSION) {
        return 1;
    }
    if (matrix_multiply_rows_checked(NULL, b1, zero_c, 0, 1) != MATRIX_OK) {
        return 1;
    }
    if (!close_enough(zero_c[0], 123.0, 0.0)) return 1;
    if (matrix_multiply_rows_checked(NULL, b1, zero_c, 1, 1) !=
        MATRIX_INVALID_ARGUMENT) return 1;
    return 0;
}

static int check_local_rows(void) {
    const double a[9] = {1, -2, 0, 0, 3, 1, -1, 0, 2};
    const double b[9] = {2, 0, -1, 1, -1, 2, 0, 3, 1};
    const double expected[9] = {0, 2, -5, 3, 0, 7, -2, 6, 3};
    double c[9] = {0};
    double c_first_two[6] = {0};
    double c_row_one[3] = {0};
    double untouched[1] = {123.0};
    size_t i;

    if (matrix_multiply_rows_checked(a, b, c, 3, 3) != MATRIX_OK) return 1;
    for (i = 0; i < 9; ++i) {
        if (!close_enough(c[i], expected[i], 1e-15)) return 1;
    }
    if (matrix_multiply_rows_checked(a, b, c_first_two, 2, 3) != MATRIX_OK) {
        return 1;
    }
    for (i = 0; i < 6; ++i) {
        if (!close_enough(c_first_two[i], expected[i], 1e-15)) return 1;
    }
    if (matrix_multiply_rows_checked(a + 3, b, c_row_one, 1, 3) != MATRIX_OK) {
        return 1;
    }
    for (i = 0; i < 3; ++i) {
        if (!close_enough(c_row_one[i], expected[3 + i], 1e-15)) return 1;
    }
    if (matrix_multiply_rows_checked(NULL, b, untouched, 0, 3) != MATRIX_OK) {
        return 1;
    }
    if (!close_enough(untouched[0], 123.0, 0.0)) return 1;
    if (matrix_multiply_rows_checked(a, b, c, 4, 3) !=
        MATRIX_INVALID_DIMENSION) return 1;
    return 0;
}

int main(void) {
    if (check_input_core() != 0) {
        fputs("FALLO: generador, fixtures o formato de entrada.\n", stderr);
        return 1;
    }
    if (check_partition_examples() != 0) {
        fputs("FALLO: ejemplos de particion.\n", stderr);
        return 1;
    }
    if (check_partition_grid() != 0) {
        fputs("FALLO: invariantes de particion.\n", stderr);
        return 1;
    }
    if (check_partition_errors() != 0) {
        fputs("FALLO: validacion de particion.\n", stderr);
        return 1;
    }
    if (check_matrix_core() != 0) {
        fputs("FALLO: nucleo matricial completo.\n", stderr);
        return 1;
    }
    if (check_local_rows() != 0) {
        fputs("FALLO: nucleo de filas locales.\n", stderr);
        return 1;
    }
    puts("OK: entradas, particion (8 ejemplos + 4480 casos) y nucleo local.");
    return 0;
}
