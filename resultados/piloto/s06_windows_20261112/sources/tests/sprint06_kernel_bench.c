/* Isolated S6 laboratory. Link with ONE implementation's matrix.c/input.c.
 * S06_OPENMP measures the local kernel only: it is NOT an MPI measurement.
 * Experimental kernels never replace production functions. */
#ifndef _WIN32
#define _POSIX_C_SOURCE 200809L
#endif
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "matrix.h"
#include "input.h"
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <time.h>
#endif
#ifdef S06_OPENMP
#include <omp.h>
#endif

static double seconds(void) {
#ifdef _WIN32
    LARGE_INTEGER counter, frequency;
    if (!QueryPerformanceFrequency(&frequency) || !QueryPerformanceCounter(&counter)) exit(1);
    return (double)counter.QuadPart / (double)frequency.QuadPart;
#else
    struct timespec value;
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) exit(1);
    return (double)value.tv_sec + (double)value.tv_nsec / 1e9;
#endif
}

/* A separate translation unit gives production and candidate the same
 * compilation visibility: no implicit advantage from inlining into main. */
#ifdef S06_OPENMP
void sprint06_candidate(const double *a, const double *b, double *c,
                        size_t local_rows, size_t n, int *observed_threads);
#else
void sprint06_candidate(const double *a, const double *b, double *c, size_t n);
#endif

int main(int argc, char **argv) {
    char *end = NULL;
    unsigned long dimension;
    size_t n, count;
    double *a, *b, *c, *reference;
    double t0, k0, kernel_s, total_s;
    int observed = 1, experimental;
    const char *version;
    if (argc != 3) {
        fputs("Usage: laboratory N baseline|restrict_c|static1\n", stderr);
        return 1;
    }
    if (argv[1][0] < '0' || argv[1][0] > '9') return 1;
    dimension = strtoul(argv[1], &end, 10);
    if (*end != '\0' || dimension < 1 || dimension > 4096) return 1;
    n = (size_t)dimension;
    count = n * n;
    experimental = strcmp(argv[2], "baseline") != 0;
#ifdef S06_OPENMP
    version = "c_openmp_local";
    if (experimental && strcmp(argv[2], "static1") != 0) return 1;
    omp_set_dynamic(0);
#else
    version = "c_secuencial";
    if (experimental && strcmp(argv[2], "restrict_c") != 0) return 1;
#endif
    a = (double *)malloc(count * sizeof(*a));
    b = (double *)malloc(count * sizeof(*b));
    c = (double *)malloc(count * sizeof(*c));
    reference = (double *)malloc(count * sizeof(*reference));
    if (!a || !b || !c || !reference) {
        free(a); free(b); free(c); free(reference);
        return 1;
    }
    if (input_generate(a, b, n, 42) != 0) return 1;
    /* Independent i,j,k reference, completely outside the measured interval. */
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            double sum = 0;
            for (size_t k = 0; k < n; ++k) sum += a[i*n+k] * b[k*n+j];
            reference[i*n+j] = sum;
        }
    }
    t0 = seconds();
    matrix_clear(c, count);
    k0 = seconds();
#ifdef S06_OPENMP
    if (experimental) sprint06_candidate(a, b, c, n, n, &observed);
    else matrix_accumulate_rows(a, b, c, n, n, &observed);
#else
    if (experimental) sprint06_candidate(a, b, c, n);
    else matrix_accumulate(a, b, c, n);
#endif
    kernel_s = seconds() - k0;
    total_s = seconds() - t0;
    if (!isfinite(kernel_s) || !isfinite(total_s) || kernel_s < 0 || total_s < kernel_s) return 1;
    for (size_t i = 0; i < count; ++i) {
        if (!isfinite(c[i]) || fabs(c[i]-reference[i]) > 1e-9 + 1e-9*fabs(reference[i])) {
            fprintf(stderr, "MISMATCH at %zu\n", i);
            free(a); free(b); free(c); free(reference);
            return 1;
        }
    }
    printf("{\"schema\":\"s06-laboratory-v1\",\"version\":\"%s\","
           "\"variant\":\"%s\",\"n\":%zu,\"seed\":42,\"workers\":%d,"
           "\"observed_threads\":%d,\"kernel_s\":%.9f,\"total_s\":%.9f,"
           "\"validation_status\":\"OK\"}\n",
           version, argv[2], n, observed, observed, kernel_s, total_s);
    free(a); free(b); free(c); free(reference);
    return 0;
}
