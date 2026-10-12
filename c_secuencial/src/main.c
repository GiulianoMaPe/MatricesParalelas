#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include "matrix.h"
#include "input.h"
#include "timer.h"

/* Exit codes: 0 = success, 1 = error, 2 = pending. */
#define EXIT_OK      0
#define EXIT_ERROR   1
#define EXIT_PENDING 2

/* Dependency: the multiplication kernel of PR #19 (matrix_multiply_validate,
 * matrix_clear, matrix_accumulate) is NOT in this branch, so matrix.h exposes
 * no way to time the product yet. This file therefore parses, validates,
 * allocates, generates and reports PENDING (exit 2); the exact timed flow is
 * documented at the multiplication step below. Nothing is faked here. */

/* --- Argument parsing helpers ------------------------------------------- */

#define PARSE_INVALID 0  /* empty text, trailing garbage or bad sign */
#define PARSE_OK      1
#define PARSE_RANGE   2  /* numeric text outside the representable range */

/* long long is 64-bit on Windows x64 (LLP64), unlike long. Parsing into the
 * widest signed type lets matrix_validate_dimension own the n*n / byte-count
 * overflow checks instead of failing earlier with a misleading message. */
static int parse_i64(const char *str, long long *out) {
    char *end;
    long long value;
    if (str == NULL || *str == '\0') return PARSE_INVALID;
    errno = 0;
    value = strtoll(str, &end, 10);
    if (end == str || *end != '\0') return PARSE_INVALID;
    if (errno == ERANGE) return PARSE_RANGE;
    *out = value;
    return PARSE_OK;
}

static int parse_u32(const char *str, uint32_t *out) {
    char *end;
    unsigned long long value;
    if (str == NULL || *str == '\0') return PARSE_INVALID;
    /* Reject leading minus sign for unsigned parsing. */
    if (*str == '-') return PARSE_INVALID;
    errno = 0;
    value = strtoull(str, &end, 10);
    if (end == str || *end != '\0') return PARSE_INVALID;
    if (errno == ERANGE) return PARSE_RANGE;
    if (value > (unsigned long long)UINT32_MAX) return PARSE_RANGE;
    *out = (uint32_t)value;
    return PARSE_OK;
}

int main(int argc, char **argv) {
    /* Argument state. */
    int have_n = 0, have_seed = 0;
    long long n_signed = 0;
    uint32_t seed = 0;
    size_t n = 0;
    int status;
    int parsed;
    int i;

    /* Matrix descriptors (owned). */
    Matrix mat_a = {0, 0, NULL};
    Matrix mat_b = {0, 0, NULL};
    Matrix mat_c = {0, 0, NULL};

    /* The measurement variables (t0/t1/t2/t3, kernel_s, total_s) are only
     * introduced once matrix_multiply_validate/matrix_clear/matrix_accumulate
     * exist in matrix.h. See the documented flow at the multiplication step. */

    /* --- smoke-test ------------------------------------------------------- */
    if (argc == 2 && strcmp(argv[1], "--smoke-test") == 0) {
        double timer_start = 0.0, timer_end = 0.0;
        volatile double spin = 0.0;
        int timer_status;
        int j;

        /* Self-check of the measurement primitive: timer_seconds must succeed
         * and move forward. This work is NOT part of any benchmark interval. */
        timer_status = timer_seconds(&timer_start);
        if (timer_status != MATRIX_OK) {
            fprintf(stderr, "ERROR: timer_seconds fallo (codigo %d).\n", timer_status);
            return EXIT_ERROR;
        }
        for (j = 0; j < 1000000; ++j) spin += 1.0;
        timer_status = timer_seconds(&timer_end);
        if (timer_status != MATRIX_OK || timer_end < timer_start) {
            fprintf(stderr, "ERROR: timer_seconds sin avance monotono (codigo %d).\n",
                    timer_status);
            return EXIT_ERROR;
        }
        printf("OK: prueba de instalacion C secuencial x64, sin MPI ni OpenMP. "
               "Cronometro operativo (%.9f s observados).\n", timer_end - timer_start);
        (void)spin;
        return EXIT_OK;
    }

    /* --- Parse arguments -------------------------------------------------- */
    for (i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--n") == 0) {
            if (have_n) {
                fputs("ERROR: argumento --n duplicado.\n", stderr);
                return EXIT_ERROR;
            }
            if (i + 1 >= argc) {
                fputs("ERROR: --n requiere un valor.\n", stderr);
                return EXIT_ERROR;
            }
            ++i;
            parsed = parse_i64(argv[i], &n_signed);
            if (parsed != PARSE_OK) {
                if (parsed == PARSE_RANGE) {
                    fprintf(stderr, "ERROR: --n fuera de rango: %s\n", argv[i]);
                } else {
                    fprintf(stderr, "ERROR: --n valor no numerico: %s\n", argv[i]);
                }
                return EXIT_ERROR;
            }
            have_n = 1;
        } else if (strcmp(argv[i], "--seed") == 0) {
            if (have_seed) {
                fputs("ERROR: argumento --seed duplicado.\n", stderr);
                return EXIT_ERROR;
            }
            if (i + 1 >= argc) {
                fputs("ERROR: --seed requiere un valor.\n", stderr);
                return EXIT_ERROR;
            }
            ++i;
            parsed = parse_u32(argv[i], &seed);
            if (parsed != PARSE_OK) {
                if (parsed == PARSE_RANGE) {
                    fprintf(stderr, "ERROR: --seed fuera de rango (0..4294967295): %s\n",
                            argv[i]);
                } else {
                    fprintf(stderr, "ERROR: --seed valor invalido: %s\n", argv[i]);
                }
                return EXIT_ERROR;
            }
            have_seed = 1;
        } else if (strcmp(argv[i], "--smoke-test") == 0) {
            /* --smoke-test with other arguments is invalid. */
            fputs("ERROR: --smoke-test no acepta otros argumentos.\n", stderr);
            return EXIT_ERROR;
        } else {
            fprintf(stderr, "ERROR: argumento desconocido: %s\n", argv[i]);
            return EXIT_ERROR;
        }
    }

    /* Both --n and --seed are required. */
    if (!have_n || !have_seed) {
        fputs("ERROR: se requieren --n <N> y --seed <SEED>.\n", stderr);
        return EXIT_ERROR;
    }

    /* Validate n > 0. Negative text dimensions must be rejected before the
     * conversion to size_t (see matrix.h contract). */
    if (n_signed <= 0) {
        fputs("ERROR: --n debe ser un entero positivo.\n", stderr);
        return EXIT_ERROR;
    }
    n = (size_t)n_signed;

    /* Validate dimension: checks n*n overflow and byte overflow. */
    status = matrix_validate_dimension(n, NULL, NULL);
    if (status == MATRIX_INVALID_DIMENSION) {
        fputs("ERROR: dimension de matriz invalida.\n", stderr);
        return EXIT_ERROR;
    }
    if (status == MATRIX_SIZE_OVERFLOW) {
        fputs("ERROR: desbordamiento de tamano al calcular n*n o bytes.\n", stderr);
        return EXIT_ERROR;
    }
    if (status != MATRIX_OK) {
        fputs("ERROR: validacion de dimension fallida.\n", stderr);
        return EXIT_ERROR;
    }

    /* --- Allocate matrices ------------------------------------------------ */
    status = matrix_allocate(&mat_a, n);
    if (status != MATRIX_OK) {
        fputs("ERROR: no se pudo reservar memoria para la matriz A.\n", stderr);
        return EXIT_ERROR;
    }

    status = matrix_allocate(&mat_b, n);
    if (status != MATRIX_OK) {
        fputs("ERROR: no se pudo reservar memoria para la matriz B.\n", stderr);
        matrix_release(&mat_a);
        return EXIT_ERROR;
    }

    status = matrix_allocate(&mat_c, n);
    if (status != MATRIX_OK) {
        fputs("ERROR: no se pudo reservar memoria para la matriz C.\n", stderr);
        matrix_release(&mat_a);
        matrix_release(&mat_b);
        return EXIT_ERROR;
    }

    /* --- Generate input --------------------------------------------------- */
    status = input_generate(mat_a.data, mat_b.data, n, seed);
    if (status != 0) {
        fputs("ERROR: fallo al generar las matrices de entrada.\n", stderr);
        matrix_release(&mat_a);
        matrix_release(&mat_b);
        matrix_release(&mat_c);
        return EXIT_ERROR;
    }

    /* --- Multiplication flow ---------------------------------------------- */
    /* DEPENDENCIA PENDIENTE (PR #19, rama feature/s03-i01-nucleo-c-secuencial):
     * matrix_multiply_validate(), matrix_clear() and matrix_accumulate() are
     * not declared in this branch's matrix.h, so the timed flow cannot compile
     * yet. It is NOT duplicated or stubbed here; on this branch the checked API
     * below performs validation only and returns MATRIX_PENDING for valid input.
     *
     * Flow to wire up once PR #19 lands (docs/protocolo_medicion.md §3.1-3.3):
     *
     *   // BEFORE any timer: validation writes nothing and never touches C.
     *   status = matrix_multiply_validate(&mat_a, &mat_b, mat_c.data, mat_c.length);
     *   if (status != MATRIX_OK) { ... error, exit 1 ... }
     *
     *   timer_seconds(&t0);                              // T0: total_s starts
     *   matrix_clear(mat_c.data, mat_c.length);          // inside total_s
     *   matrix_accumulate(mat_a.data, mat_b.data, mat_c.data, n);
     *   timer_seconds(&t1);                              // T1: total_s ends
     *   total_s = t1 - t0;
     *
     *   matrix_clear(mat_c.data, mat_c.length);  // auxiliary, OUTSIDE both timers
     *   timer_seconds(&t2);                              // kernel_s starts
     *   matrix_accumulate(mat_a.data, mat_b.data, mat_c.data, n);
     *   timer_seconds(&t3);                              // kernel_s ends
     *   kernel_s = t3 - t2;
     *
     *   status = matrix_validate(&mat_c);   // project API: finite values in C
     *   if (status != MATRIX_OK) { ... error, exit 1 ... }
     *
     *   // Protocol §3.3: report, never fix or hide an anomaly.
     *   if (!isfinite(total_s) || total_s < 0.0 || !isfinite(kernel_s) ||
     *       kernel_s < 0.0 || kernel_s > total_s) { ... ERROR, exit 1 ... }
     *
     *   printf("n=%zu seed=%u kernel_s=%.9f total_s=%.9f\n",
     *          n, (unsigned)seed, kernel_s, total_s);   // after every timer
     *
     * printf/puts, argument parsing, validation, generation, malloc/calloc and
     * free stay outside both intervals (§3.3). matrix_multiply_checked() must
     * NOT be used for the benchmark: it mixes validation, clearing, kernel and
     * the finite check in a single opaque call. */

    /* Use the currently available checked API to validate inputs.
     * This returns MATRIX_PENDING because the kernel is not yet implemented. */
    status = matrix_multiply_checked(&mat_a, &mat_b, mat_c.data, mat_c.length);
    if (status == MATRIX_PENDING) {
        fputs("PENDIENTE: la multiplicacion depende del PR #19 "
              "(matrix_multiply_validate/matrix_clear/matrix_accumulate). "
              "Argumentos, memoria y timer estan listos.\n", stderr);
        matrix_release(&mat_a);
        matrix_release(&mat_b);
        matrix_release(&mat_c);
        return EXIT_PENDING;
    }
    if (status == MATRIX_NON_FINITE_VALUE) {
        fputs("ERROR: el producto contiene valores no finitos (desbordamiento).\n", stderr);
        matrix_release(&mat_a);
        matrix_release(&mat_b);
        matrix_release(&mat_c);
        return EXIT_ERROR;
    }
    if (status != MATRIX_OK) {
        fprintf(stderr, "ERROR: validacion de multiplicacion fallida (codigo %d).\n", status);
        matrix_release(&mat_a);
        matrix_release(&mat_b);
        matrix_release(&mat_c);
        return EXIT_ERROR;
    }

    /* Only reachable once PR #19 makes matrix_multiply_checked compute the
     * product. The timed flow documented above is still not wired up, and this
     * program must never claim success without kernel_s/total_s: report the
     * pending integration explicitly instead of exiting silently. */
    fputs("PENDIENTE: el nucleo del PR #19 ya calcula, pero la integracion de "
          "medicion (matrix_multiply_validate + matrix_clear + matrix_accumulate "
          "con kernel_s y total_s) sigue sin cablearse en main.c.\n", stderr);
    matrix_release(&mat_a);
    matrix_release(&mat_b);
    matrix_release(&mat_c);
    return EXIT_PENDING;
}