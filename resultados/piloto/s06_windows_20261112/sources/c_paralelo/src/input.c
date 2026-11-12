#include "input.h"
#include "matrix.h"
#include <math.h>
#include <stdlib.h>
#include <stdint.h>

uint32_t input_next_state(uint32_t *state) {
    if (state == NULL) {
        return 0;
    }
    *state = (uint32_t)((uint64_t)1664525u * *state + 1013904223u);
    return *state;
}

/* 1 = line read, 0 = EOF, -1 = I/O, -2 = allocation, -3 = format.
 * Only LF/CRLF terminate a line. NUL and non-ASCII bytes cannot be part of the
 * decimal fixture grammar, so reject them before using C string functions. */
static int read_line(FILE *stream, char **line, size_t *capacity) {
    size_t length = 0;
    int ch;
    for (;;) {
        char *resized;
        ch = fgetc(stream);
        if (ch == EOF) {
            if (ferror(stream)) return -1;
            if (length == 0) return 0;
            break;
        }
        if (ch == '\n') break;
        if (ch == '\r') {
            ch = fgetc(stream);
            if (ch == EOF && ferror(stream)) return -1;
            if (ch != '\n') return -3;
            break;
        }
        if (ch == 0 || ch > 127) return -3;
        if (length + 1 >= *capacity) {
            size_t next_capacity;
            if (*capacity > SIZE_MAX / 2) return -2;
            next_capacity = *capacity == 0 ? 32 : *capacity * 2;
            resized = (char *)realloc(*line, next_capacity);
            if (resized == NULL) return -2;
            *line = resized;
            *capacity = next_capacity;
        }
        (*line)[length++] = (char)ch;
    }
    /* Empty lines also need a terminating NUL. */
    if (*capacity == 0) {
        *line = (char *)malloc(1);
        if (*line == NULL) return -2;
        *capacity = 1;
    }
    (*line)[length] = '\0';
    return 1;
}

static char *next_row_token(char **cursor) {
    char *token;
    while (**cursor == ' ' || **cursor == '\t') ++*cursor;
    if (**cursor == '\0') return NULL;
    token = *cursor;
    while (**cursor != '\0' && **cursor != ' ' && **cursor != '\t') ++*cursor;
    if (**cursor != '\0') *(*cursor)++ = '\0';
    return token;
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
    parsed = strtod(token, &end);
    if (*end != '\0' || !isfinite(parsed)) {
        return 0;
    }
    *value = parsed;
    return 1;
}

static int line_status(int status) {
    if (status == -2) {
        return INPUT_NO_MEMORY;
    }
    if (status == -1) {
        return INPUT_IO_ERROR;
    }
    return INPUT_INVALID;
}

int input_read(FILE *stream, double **a, double **b, size_t *n) {
    char *line = NULL, *cursor, *token;
    size_t line_capacity = 0;
    size_t dimension, count, row, column;
    double *matrix_a = NULL, *matrix_b = NULL;
    int status, result = INPUT_INVALID;

    if (stream == NULL || a == NULL || b == NULL || n == NULL || a == b) {
        return INPUT_INVALID;
    }
    *a = NULL;
    *b = NULL;
    *n = 0;

    status = read_line(stream, &line, &line_capacity);
    if (status != 1) {
        result = line_status(status);
        goto done;
    }
    cursor = line;
    token = next_row_token(&cursor);
    if (token == NULL || !parse_dimension(token, &dimension) ||
        next_row_token(&cursor) != NULL) goto done;
    if (dimension > SIZE_MAX / dimension || dimension > SIZE_MAX / 2) goto done;
    count = dimension * dimension;
    if (count > (size_t)PTRDIFF_MAX / sizeof(double)) goto done;
    matrix_a = (double *)malloc(count * sizeof(double));
    matrix_b = (double *)malloc(count * sizeof(double));
    if (matrix_a == NULL || matrix_b == NULL) {
        result = INPUT_NO_MEMORY;
        goto done;
    }

    for (row = 0; row < 2 * dimension; ++row) {
        double *matrix = row < dimension ? matrix_a : matrix_b;
        size_t local_row = row < dimension ? row : row - dimension;
        status = read_line(stream, &line, &line_capacity);
        if (status != 1) {
            result = line_status(status);
            goto done;
        }
        cursor = line;
        for (column = 0; column < dimension; ++column) {
            token = next_row_token(&cursor);
            if (token == NULL || !parse_value(token, &matrix[local_row * dimension + column])) {
                goto done;
            }
        }
        if (next_row_token(&cursor) != NULL) goto done;
    }
    while ((status = read_line(stream, &line, &line_capacity)) == 1) {
        cursor = line;
        if (next_row_token(&cursor) != NULL) goto done;
    }
    if (status != 0) {
        result = line_status(status);
        goto done;
    }
    *a = matrix_a;
    *b = matrix_b;
    *n = dimension;
    matrix_a = NULL;
    matrix_b = NULL;
    result = 0;

done:
    free(line);
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
    if (count > (size_t)PTRDIFF_MAX / sizeof(*a)) {
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

