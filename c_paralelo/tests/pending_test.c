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
    for (i = 0; i < sizeof(invalid) / sizeof(invalid[0]); ++i) {
        if (rejects_fixture(invalid[i]) != 0) return 1;
    }
    if (input_generate(a, b, 0, 42) != INPUT_INVALID) return 1;
    if (input_generate(NULL, b, 2, 42) != INPUT_INVALID) return 1;
    if (matrix_multiply(a, b, &c, 1) != MATRIX_PENDING || c != -123.0) return 1;
    puts("OK: estados/valores LCG, fixtures y entradas malformadas.");
    return 0;
}
