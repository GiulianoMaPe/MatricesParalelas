#include "input.h"
#include "matrix.h"
#include <errno.h>
#include <math.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

uint32_t input_next_state(uint32_t *state) {
    if (state == NULL) {
        return 0;
    }
    *state = (uint32_t)((uint64_t)1664525u * *state + 1013904223u);
    return *state;
}

static int is_ascii_space(int ch) {
    return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';
}

static int read_token(FILE *stream, char **token, size_t *capacity) {
    int ch;
    size_t length = 0;
    do {
        ch = fgetc(stream);
        if (ch == EOF) {
            return ferror(stream) ? -1 : 0;
        }
    } while (is_ascii_space(ch));

    do {
        char *resized;
        if (length + 1 >= *capacity) {
            size_t next_capacity = *capacity == 0 ? 32 : *capacity * 2;
            if (next_capacity <= *capacity) {
                return -2;
            }
            resized = (char *)realloc(*token, next_capacity);
            if (resized == NULL) {
                return -2;
            }
            *token = resized;
            *capacity = next_capacity;
        }
        (*token)[length++] = (char)ch;
        ch = fgetc(stream);
    } while (ch != EOF && !is_ascii_space(ch));

    if (ch == EOF && ferror(stream)) {
        return -1;
    }
    (*token)[length] = '\0';
    return 1;
}

static int parse_dimension(const char *token, size_t *dimension) {
    size_t value = 0;
    const unsigned char *cursor = (const unsigned char *)token;
    if (*cursor == '\0') {
        return 0;
    }
    while (*cursor != '\0') {
        size_t digit;
        if (*cursor < '0' || *cursor > '9') {
            return 0;
        }
        digit = (size_t)(*cursor - '0');
        if (value > (SIZE_MAX - digit) / 10) {
            return 0;
        }
        value = value * 10 + digit;
        ++cursor;
    }
    if (value == 0) {
        return 0;
    }
    *dimension = value;
    return 1;
}

static int is_decimal_float(const char *token) {
    const unsigned char *cursor = (const unsigned char *)token;
    size_t digits = 0;
    if (*cursor == '+' || *cursor == '-') {
        ++cursor;
    }
    while (*cursor >= '0' && *cursor <= '9') {
        ++cursor;
        ++digits;
    }
    if (*cursor == '.') {
        ++cursor;
        while (*cursor >= '0' && *cursor <= '9') {
            ++cursor;
            ++digits;
        }
    }
    if (digits == 0) {
        return 0;
    }
    if (*cursor == 'e' || *cursor == 'E') {
        size_t exponent_digits = 0;
        ++cursor;
        if (*cursor == '+' || *cursor == '-') {
            ++cursor;
        }
        while (*cursor >= '0' && *cursor <= '9') {
            ++cursor;
            ++exponent_digits;
        }
        if (exponent_digits == 0) {
            return 0;
        }
    }
    return *cursor == '\0';
}

static int parse_value(const char *token, double *value) {
    char *end;
    double parsed;
    if (!is_decimal_float(token)) {
        return 0;
    }
    errno = 0;
    parsed = strtod(token, &end);
    if (errno == ERANGE || *end != '\0' || !isfinite(parsed)) {
        return 0;
    }
    *value = parsed;
    return 1;
}

static int token_status(int status) {
    if (status == -2) {
        return INPUT_NO_MEMORY;
    }
    if (status < 0) {
        return INPUT_IO_ERROR;
    }
    return INPUT_INVALID;
}

int input_read(FILE *stream, double **a, double **b, size_t *n) {
    char *token = NULL;
    size_t token_capacity = 0;
    size_t dimension, count, i;
    double *matrix_a = NULL;
    double *matrix_b = NULL;
    int status, result = INPUT_INVALID;

    if (stream == NULL || a == NULL || b == NULL || n == NULL) {
        return INPUT_INVALID;
    }
    *a = NULL;
    *b = NULL;
    *n = 0;

    status = read_token(stream, &token, &token_capacity);
    if (status != 1) {
        result = token_status(status);
        goto done;
    }
    if (!parse_dimension(token, &dimension) || dimension > SIZE_MAX / dimension) {
        goto done;
    }
    count = dimension * dimension;
    if (count > SIZE_MAX / sizeof(double) || count > SIZE_MAX / 2) {
        goto done;
    }
    matrix_a = (double *)malloc(count * sizeof(double));
    matrix_b = (double *)malloc(count * sizeof(double));
    if (matrix_a == NULL || matrix_b == NULL) {
        result = INPUT_NO_MEMORY;
        goto done;
    }

    for (i = 0; i < 2 * count; ++i) {
        double value;
        status = read_token(stream, &token, &token_capacity);
        if (status != 1) {
            result = token_status(status);
            goto done;
        }
        if (!parse_value(token, &value)) {
            goto done;
        }
        if (i < count) {
            matrix_a[i] = value;
        } else {
            matrix_b[i - count] = value;
        }
    }
    status = read_token(stream, &token, &token_capacity);
    if (status != 0) {
        result = status < 0 ? token_status(status) : INPUT_INVALID;
        goto done;
    }

    *a = matrix_a;
    *b = matrix_b;
    *n = dimension;
    matrix_a = NULL;
    matrix_b = NULL;
    result = 0;

done:
    free(token);
    free(matrix_a);
    free(matrix_b);
    return result;
}

int input_generate(double *a, double *b, size_t n, uint32_t seed) {
    size_t count, i;
    uint32_t state = seed;

    if (a == NULL || b == NULL || n == 0 || n > SIZE_MAX / n) {
        return INPUT_INVALID;
    }
    count = n * n;
    if (count > SIZE_MAX / sizeof(*a)) {
        return INPUT_INVALID;
    }

    for (i = 0; i < count; ++i) {
        input_next_state(&state);
        a[i] = ((double)(int64_t)(state % 2001u) - 1000.0) / 1000.0;
    }
    for (i = 0; i < count; ++i) {
        input_next_state(&state);
        b[i] = ((double)(int64_t)(state % 2001u) - 1000.0) / 1000.0;
    }
    return 0;
}

