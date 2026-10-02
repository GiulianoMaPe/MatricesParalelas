#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "matrix.h"
#include "input.h"

static int check_fixture(const char *path, size_t want_n, const double *want_a, const double *want_b) {
    FILE *stream = fopen(path, "rb");
    double *a = NULL, *b = NULL;
    size_t n = 0, i;
    int result;
    if (stream == NULL) return 1;
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
    FILE *stream = tmpfile();
    double *a = NULL, *b = NULL;
    size_t n = 0;
    int result;
    if (stream == NULL) return 1;
    if (fputs("2\r\n+1 2.\r\n.5 -2e-1\r\n3 4\r\n5 6  \r\n", stream) == EOF ||
        fflush(stream) != 0 || fseek(stream, 0, SEEK_SET) != 0) {
        fclose(stream);
        return 1;
    }
    result = input_read(stream, &a, &b, &n);
    fclose(stream);
    if (result != 0 || n != 2 || fabs(a[0] - 1.0) > 1e-15 || fabs(a[1] - 2.0) > 1e-15 ||
        fabs(a[2] - 0.5) > 1e-15 || fabs(a[3] + 0.2) > 1e-15 || fabs(b[0] - 3.0) > 1e-15 ||
        fabs(b[1] - 4.0) > 1e-15 || fabs(b[2] - 5.0) > 1e-15 || fabs(b[3] - 6.0) > 1e-15) {
        free(a);
        free(b);
        return 1;
    }
    free(a);
    free(b);
    return 0;
}

static int rejects_fixture(const char *text) {
    FILE *stream = tmpfile();
    double *a = NULL, *b = NULL;
    size_t n = 0;
    int result;
    int clean;
    if (stream == NULL) return 1;
    if (fputs(text, stream) == EOF || fflush(stream) != 0 || fseek(stream, 0, SEEK_SET) != 0) {
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
        FILE *stream = tmpfile();
        double *a = NULL, *b = NULL;
        size_t n = 0;
        int status, ok;
        if (stream == NULL) return 1;
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

int main(void) {
    double a[4], b[4];
    const double want_a[4] = {-0.363, 0.036, -0.215, 0.602};
    const double want_b[4] = {0.941, -0.453, -0.554, 0.579};
    const uint32_t want_states[8] = {1083814273u, 378494188u, 2479403867u, 955863294u,
                                     1613448261u, 110225632u, 1921058495u, 508781842u};
    const double fixture_producto_a[] = {1, 2, 3, 4}, fixture_producto_b[] = {5, 6, 7, 8};
    const double fixture_escalar_a[] = {-3}, fixture_escalar_b[] = {4};
    const double fixture_identidad_a[] = {1, 0, 0, 1}, fixture_identidad_b[] = {-1, 2, 3, -4};
    const double fixture_cero_a[] = {0, 0, 0, 0}, fixture_cero_b[] = {1, -2, 3, -4};
    const char *invalid[] = {"", "x 1 2", "0 1 2", "-1 1 2", "1 1", "1 1 2 3", "1 NaN 2",
                             "1 +Inf 2", "1 0x1p2 2", "1 1e 2", "1 1e9999 2", "1 1 2 extra"};
    double c = -123.0;
    uint32_t state = 42;
    size_t i;

    for (i = 0; i < 8; ++i) {
        if (input_next_state(&state) != want_states[i]) return 1;
    }
    if (input_generate(a, b, 2, 42) != 0) return 1;
    for (i = 0; i < 4; ++i) {
        if (a[i] - want_a[i] > 1e-15 || want_a[i] - a[i] > 1e-15) return 1;
        if (b[i] - want_b[i] > 1e-15 || want_b[i] - b[i] > 1e-15) return 1;
    }
    if (check_fixture("tests/fixtures/producto2.input.txt", 2, fixture_producto_a, fixture_producto_b) != 0) return 1;
    if (check_fixture("tests/fixtures/escalar.input.txt", 1, fixture_escalar_a, fixture_escalar_b) != 0) return 1;
    if (check_fixture("tests/fixtures/identidad.input.txt", 2, fixture_identidad_a, fixture_identidad_b) != 0) return 1;
    if (check_fixture("tests/fixtures/cero.input.txt", 2, fixture_cero_a, fixture_cero_b) != 0) return 1;
    if (accepts_crlf_fixture() != 0) return 1;
    if (check_file_format_contract() != 0) return 1;
    for (i = 0; i < sizeof(invalid) / sizeof(invalid[0]); ++i) {
        if (rejects_fixture(invalid[i]) != 0) return 1;
    }
    if (input_generate(a, b, 0, 42) != INPUT_INVALID) return 1;
    if (input_generate(NULL, b, 2, 42) != INPUT_INVALID) return 1;
    if (matrix_multiply(a, b, &c, 1) != MATRIX_PENDING || c != -123.0) return 1;
    puts("OK: estados/valores LCG, fixtures y entradas malformadas.");
    return 0;
}
