#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winreg.h>

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "matrix.h"
#include "timer.h"
#include "build_info.h"

#ifndef PROJECT_COMMIT
#define PROJECT_COMMIT "dev"
#endif
#ifndef PROJECT_CONFIGURATION
#define PROJECT_CONFIGURATION "unknown"
#endif

#define EXIT_OK 0
#define EXIT_ERROR 1
#define EXIT_PENDING 2
#define PARSE_INVALID 0
#define PARSE_OK 1
#define PARSE_RANGE 2
#define CSV_FIELD_CAPACITY 512

typedef struct {
    const char *input_path;
    const char *output_path;
    int have_n;
    int have_seed;
    int repetition;
    long long n;
    uint32_t seed;
} Options;

typedef struct {
    char hostname[CSV_FIELD_CAPACITY];
    char cpu_model[CSV_FIELD_CAPACITY];
    char os_version[CSV_FIELD_CAPACITY];
    char ram_gb[32];
    char timestamp[32];
} RunMetadata;

static int parse_signed_dimension(const char *text, long long *value) {
    char *end;
    long long parsed;
    const unsigned char *cursor = (const unsigned char *)text;
    if (text == NULL || *text == '\0') return PARSE_INVALID;
    while (*cursor != '\0') {
        if (*cursor < '0' || *cursor > '9') return PARSE_INVALID;
        ++cursor;
    }
    errno = 0;
    parsed = strtoll(text, &end, 10);
    if (end == text || *end != '\0') return PARSE_INVALID;
    if (errno == ERANGE) return PARSE_RANGE;
    *value = parsed;
    return PARSE_OK;
}

static int parse_unsigned(const char *text, uint64_t maximum, uint64_t *value) {
    const unsigned char *cursor = (const unsigned char *)text;
    char *end;
    unsigned long long parsed;
    if (text == NULL || *text == '\0') return PARSE_INVALID;
    while (*cursor != '\0') {
        if (*cursor < '0' || *cursor > '9') return PARSE_INVALID;
        ++cursor;
    }
    errno = 0;
    parsed = strtoull(text, &end, 10);
    if (end == text || *end != '\0') return PARSE_INVALID;
    if (errno == ERANGE || parsed > maximum) return PARSE_RANGE;
    *value = (uint64_t)parsed;
    return PARSE_OK;
}

static int parse_options(int argc, char **argv, Options *options) {
    int seen_n = 0, seen_seed = 0, seen_input = 0, seen_output = 0;
    int seen_repetition = 0;
    int i;
    memset(options, 0, sizeof(*options));
    options->repetition = 1;

    if (argc == 2 && strcmp(argv[1], "--smoke-test") == 0) return 2;
    for (i = 1; i < argc; ++i) {
        const char *option = argv[i];
        const char *value;
        if (strcmp(option, "--smoke-test") == 0) {
            fputs("ERROR: --smoke-test no acepta otros argumentos.\n", stderr);
            return -1;
        }
        if (i + 1 >= argc || argv[i + 1][0] == '\0' ||
            strncmp(argv[i + 1], "--", 2) == 0) {
            fprintf(stderr, "ERROR: %s requiere un valor.\n", option);
            return -1;
        }
        value = argv[++i];
        if (strcmp(option, "--n") == 0) {
            int parsed;
            if (seen_n) {
                fputs("ERROR: argumento --n duplicado.\n", stderr);
                return -1;
            }
            parsed = parse_signed_dimension(value, &options->n);
            if (parsed != PARSE_OK) {
                fprintf(stderr, "ERROR: valor invalido para --n: %s\n", value);
                return -1;
            }
            if (options->n <= 0) {
                fputs("ERROR: --n debe ser un entero positivo.\n", stderr);
                return -1;
            }
            seen_n = options->have_n = 1;
        } else if (strcmp(option, "--seed") == 0) {
            uint64_t parsed_value;
            int parsed;
            if (seen_seed) {
                fputs("ERROR: argumento --seed duplicado.\n", stderr);
                return -1;
            }
            parsed = parse_unsigned(value, UINT32_MAX, &parsed_value);
            if (parsed != PARSE_OK) {
                fprintf(stderr, "ERROR: valor invalido para --seed: %s\n", value);
                return -1;
            }
            options->seed = (uint32_t)parsed_value;
            seen_seed = options->have_seed = 1;
        } else if (strcmp(option, "--input") == 0) {
            if (seen_input) {
                fputs("ERROR: argumento --input duplicado.\n", stderr);
                return -1;
            }
            options->input_path = value;
            seen_input = 1;
        } else if (strcmp(option, "--output") == 0) {
            if (seen_output) {
                fputs("ERROR: argumento --output duplicado.\n", stderr);
                return -1;
            }
            options->output_path = value;
            seen_output = 1;
        } else if (strcmp(option, "--repetition") == 0) {
            uint64_t parsed_value;
            int parsed;
            if (seen_repetition) {
                fputs("ERROR: argumento --repetition duplicado.\n", stderr);
                return -1;
            }
            parsed = parse_unsigned(value, 5, &parsed_value);
            if (parsed != PARSE_OK) {
                fputs("ERROR: --repetition debe estar entre 0 y 5.\n", stderr);
                return -1;
            }
            options->repetition = (int)parsed_value;
            seen_repetition = 1;
        } else {
            fprintf(stderr, "ERROR: argumento desconocido: %s\n", option);
            return -1;
        }
    }

    if (seen_input) {
        if (seen_n || seen_seed) {
            fputs("ERROR: --input no se combina con --n ni --seed.\n", stderr);
            return -1;
        }
    } else if (!seen_n || !seen_seed) {
        fputs("ERROR: use --n N --seed SEED o --input archivo.\n", stderr);
        return -1;
    }
    return 0;
}

static int registry_string(HKEY root, const char *path, const char *name,
                           char *buffer, DWORD capacity) {
    DWORD bytes = capacity;
    LONG status = RegGetValueA(root, path, name, RRF_RT_REG_SZ, NULL, buffer, &bytes);
    if (status != ERROR_SUCCESS || bytes == 0) return 0;
    buffer[capacity - 1] = '\0';
    return buffer[0] != '\0';
}

static int collect_metadata(RunMetadata *metadata) {
    DWORD hostname_length = (DWORD)sizeof(metadata->hostname);
    MEMORYSTATUSEX memory;
    char product[CSV_FIELD_CAPACITY];
    char build[64];
    DWORD ubr = 0, ubr_bytes = (DWORD)sizeof(ubr);
    LONG ubr_status;
    HKEY root = HKEY_LOCAL_MACHINE;
    const char *cpu_key = "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0";
    const char *windows_key = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";

    memset(metadata, 0, sizeof(*metadata));
    if (!GetComputerNameA(metadata->hostname, &hostname_length) || hostname_length == 0) {
        fputs("ERROR: no se pudo obtener el nombre del equipo.\n", stderr);
        return 0;
    }
    if (!registry_string(root, cpu_key, "ProcessorNameString",
                         metadata->cpu_model, (DWORD)sizeof(metadata->cpu_model))) {
        fputs("ERROR: no se pudo obtener el modelo de CPU.\n", stderr);
        return 0;
    }
    if (!registry_string(root, windows_key, "ProductName", product, (DWORD)sizeof(product)) ||
        !registry_string(root, windows_key, "CurrentBuildNumber", build, (DWORD)sizeof(build))) {
        fputs("ERROR: no se pudo obtener la version de Windows.\n", stderr);
        return 0;
    }
    memory.dwLength = (DWORD)sizeof(memory);
    if (!GlobalMemoryStatusEx(&memory) || memory.ullTotalPhys == 0) {
        fputs("ERROR: no se pudo obtener la memoria RAM total.\n", stderr);
        return 0;
    }
    if (snprintf(metadata->ram_gb, sizeof(metadata->ram_gb), "%.3f",
                 (double)memory.ullTotalPhys / 1073741824.0) < 0) {
        fputs("ERROR: no se pudieron formatear los metadatos de RAM.\n", stderr);
        return 0;
    }
    ubr_status = RegGetValueA(root, windows_key, "UBR", RRF_RT_REG_DWORD,
                              NULL, &ubr, &ubr_bytes);
    if (ubr_status == ERROR_SUCCESS) {
        if (snprintf(metadata->os_version, sizeof(metadata->os_version),
                     "%s build %s.%lu", product, build, (unsigned long)ubr) < 0) {
            fputs("ERROR: no se pudieron formatear los metadatos de Windows.\n", stderr);
            return 0;
        }
    } else if (snprintf(metadata->os_version, sizeof(metadata->os_version),
                        "%s build %s", product, build) < 0) {
        fputs("ERROR: no se pudieron formatear los metadatos de Windows.\n", stderr);
        return 0;
    }
    return 1;
}

static int format_timestamp(char *buffer, size_t capacity) {
    SYSTEMTIME utc;
    GetSystemTime(&utc);
    return snprintf(buffer, capacity, "%04u-%02u-%02uT%02u:%02u:%02uZ",
                    (unsigned)utc.wYear, (unsigned)utc.wMonth, (unsigned)utc.wDay,
                    (unsigned)utc.wHour, (unsigned)utc.wMinute,
                    (unsigned)utc.wSecond) > 0;
}

static int csv_field(FILE *stream, const char *text) {
    const unsigned char *cursor = (const unsigned char *)text;
    int quote = strpbrk(text, ",\"\r\n") != NULL;
    if (quote && fputc('"', stream) == EOF) return 0;
    while (*cursor != '\0') {
        if (*cursor == '"' && fputc('"', stream) == EOF) return 0;
        if (fputc(*cursor++, stream) == EOF) return 0;
    }
    if (quote && fputc('"', stream) == EOF) return 0;
    return 1;
}

static int write_csv(const Options *options, size_t n, const RunMetadata *metadata,
                     double kernel_s, double total_s) {
    static const char *headers[20] = {
        "timestamp", "version", "commit", "hostname", "cpu_model", "ram_gb",
        "os_version", "configuration", "n", "seed", "processes", "threads",
        "observed_threads", "workers", "gomaxprocs", "repetition", "is_warmup",
        "kernel_s", "total_s", "validation_status"
    };
    char n_text[32], seed_text[32], repetition_text[16];
    char kernel_text[64], total_text[64];
    const char *record[20];
    size_t i;

    if (!isfinite(kernel_s) || kernel_s < 0.0 || !isfinite(total_s) ||
        total_s < kernel_s) {
        fputs("ERROR: tiempos de medicion invalidos.\n", stderr);
        return 0;
    }
    if (snprintf(n_text, sizeof(n_text), "%zu", n) < 0 ||
        snprintf(seed_text, sizeof(seed_text), "%u", (unsigned)options->seed) < 0 ||
        snprintf(repetition_text, sizeof(repetition_text), "%d", options->repetition) < 0 ||
        snprintf(kernel_text, sizeof(kernel_text), "%.9f", kernel_s) < 0 ||
        snprintf(total_text, sizeof(total_text), "%.9f", total_s) < 0) {
        fputs("ERROR: no se pudo formatear la fila CSV.\n", stderr);
        return 0;
    }
    record[0] = metadata->timestamp;
    record[1] = "c_secuencial";
    record[2] = PROJECT_COMMIT;
    record[3] = metadata->hostname;
    record[4] = metadata->cpu_model;
    record[5] = metadata->ram_gb;
    record[6] = metadata->os_version;
    record[7] = PROJECT_CONFIGURATION;
    record[8] = n_text;
    record[9] = seed_text;
    record[10] = "1";
    record[11] = "1";
    record[12] = "1";
    record[13] = "1";
    record[14] = "1";
    record[15] = repetition_text;
    record[16] = options->repetition == 0 ? "true" : "false";
    record[17] = kernel_text;
    record[18] = total_text;
    record[19] = "OK";

    for (i = 0; i < 20; ++i) {
        if (i != 0 && fputc(',', stdout) == EOF) return 0;
        if (!csv_field(stdout, headers[i])) return 0;
    }
    if (fputc('\n', stdout) == EOF) return 0;
    for (i = 0; i < 20; ++i) {
        if (i != 0 && fputc(',', stdout) == EOF) return 0;
        if (!csv_field(stdout, record[i])) return 0;
    }
    if (fputc('\n', stdout) == EOF || fflush(stdout) != 0) {
        fputs("ERROR: no se pudo escribir el CSV.\n", stderr);
        return 0;
    }
    return 1;
}

static int write_matrix_stream(FILE *stream, const Matrix *matrix) {
    size_t row, column;
    if (fprintf(stream, "%zu\n", matrix->n) < 0) return 0;
    for (row = 0; row < matrix->n; ++row) {
        for (column = 0; column < matrix->n; ++column) {
            if (column != 0 && fputc(' ', stream) == EOF) return 0;
            if (fprintf(stream, "%.17g", matrix->data[row * matrix->n + column]) < 0)
                return 0;
        }
        if (fputc('\n', stream) == EOF) return 0;
    }
    return !ferror(stream);
}

static int save_matrix(const char *path, const Matrix *matrix) {
    size_t path_length = strlen(path);
    size_t temp_capacity;
    char *temp_path;
    FILE *stream;
    int result;
    if (path_length > SIZE_MAX - 48) return 0;
    temp_capacity = path_length + 48;
    temp_path = (char *)malloc(temp_capacity);
    if (temp_path == NULL) return 0;
    if (snprintf(temp_path, temp_capacity, "%s.tmp.%lu", path,
                 (unsigned long)GetCurrentProcessId()) < 0) {
        free(temp_path);
        return 0;
    }
    if (fopen_s(&stream, temp_path, "wb") != 0 || stream == NULL) {
        free(temp_path);
        return 0;
    }
    result = write_matrix_stream(stream, matrix);
    if (fclose(stream) != 0) result = 0;
    if (result && MoveFileExA(temp_path, path,
                              MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        free(temp_path);
        return 1;
    }
    DeleteFileA(temp_path);
    free(temp_path);
    return 0;
}

static int load_inputs(const Options *options, Matrix *a, Matrix *b) {
    if (options->input_path != NULL) {
        FILE *stream = NULL;
        double *data_a = NULL, *data_b = NULL;
        size_t n = 0, count;
        int input_status, close_status;
        if (fopen_s(&stream, options->input_path, "rb") != 0 || stream == NULL) {
            fprintf(stderr, "ERROR: no se pudo abrir la entrada: %s\n", options->input_path);
            return 0;
        }
        input_status = input_read(stream, &data_a, &data_b, &n);
        close_status = fclose(stream);
        if (input_status != 0 || close_status != 0) {
            if (input_status == INPUT_IO_ERROR || close_status != 0)
                fputs("ERROR: fallo de lectura de matrices.\n", stderr);
            else if (input_status == INPUT_NO_MEMORY)
                fputs("ERROR: memoria insuficiente al leer matrices.\n", stderr);
            else
                fputs("ERROR: archivo de matrices invalido.\n", stderr);
            free(data_a);
            free(data_b);
            return 0;
        }
        if (matrix_validate_dimension(n, &count, NULL) != MATRIX_OK) {
            fputs("ERROR: dimension de entrada fuera de rango.\n", stderr);
            free(data_a);
            free(data_b);
            return 0;
        }
        a->n = b->n = n;
        a->length = b->length = count;
        a->data = data_a;
        b->data = data_b;
        return 1;
    }

    if (matrix_allocate(a, (size_t)options->n) != MATRIX_OK ||
        matrix_allocate(b, (size_t)options->n) != MATRIX_OK) {
        fputs("ERROR: no se pudo reservar memoria para A y B.\n", stderr);
        matrix_release(a);
        matrix_release(b);
        return 0;
    }
    if (input_generate(a->data, b->data, a->n, options->seed) != 0) {
        fputs("ERROR: no se pudieron generar las matrices.\n", stderr);
        matrix_release(a);
        matrix_release(b);
        return 0;
    }
    return 1;
}

static int validate_against_reference(const Matrix *actual, const double *reference) {
    size_t i;
    int status = matrix_validate(actual);
    if (status != MATRIX_OK) {
        fprintf(stderr, "ERROR: resultado matricial invalido (codigo %d).\n", status);
        return 0;
    }
    for (i = 0; i < actual->length; ++i) {
        double expected = reference[i];
        double difference = fabs(actual->data[i] - expected);
        double tolerance = 1e-9 + 1e-9 * fabs(expected);
        if (!isfinite(expected) || difference > tolerance) {
            fprintf(stderr, "ERROR: resultado incorrecto en C[%zu,%zu].\n",
                    i / actual->n, i % actual->n);
            return 0;
        }
    }
    return 1;
}

static int run_product(const Options *options) {
    Matrix a = {0, 0, NULL}, b = {0, 0, NULL}, c = {0, 0, NULL};
    RunMetadata metadata;
    double *reference = NULL;
    size_t i, j, k;
    double total_start, kernel_start, kernel_end, total_end;
    double kernel_s, total_s;
    int status, exit_code = EXIT_ERROR;

    if (!load_inputs(options, &a, &b)) goto done;
    status = matrix_allocate(&c, a.n);
    if (status != MATRIX_OK) {
        fprintf(stderr, "ERROR: no se pudo reservar memoria para C (codigo %d).\n", status);
        goto done;
    }
    status = matrix_multiply_validate(&a, &b, c.data, c.length);
    if (status == MATRIX_PENDING) {
        fputs("PENDIENTE: multiplicacion no implementada.\n", stderr);
        exit_code = EXIT_PENDING;
        goto done;
    }
    if (status != MATRIX_OK) {
        fprintf(stderr, "ERROR: entradas de multiplicacion invalidas (codigo %d).\n", status);
        goto done;
    }
    if (c.length > SIZE_MAX / sizeof(double)) {
        fputs("ERROR: desbordamiento al reservar la referencia.\n", stderr);
        goto done;
    }
    reference = (double *)malloc(c.length * sizeof(double));
    if (reference == NULL) {
        fputs("ERROR: no se pudo reservar la matriz de referencia.\n", stderr);
        goto done;
    }
    /* Independent i,j,k reference, prepared completely outside both timers. */
    for (i = 0; i < a.n; ++i) {
        for (j = 0; j < a.n; ++j) {
            double sum = 0.0;
            for (k = 0; k < a.n; ++k)
                sum += a.data[i * a.n + k] * b.data[k * a.n + j];
            if (!isfinite(sum)) {
                fputs("ERROR: la referencia contiene valores no finitos.\n", stderr);
                goto done;
            }
            reference[i * a.n + j] = sum;
        }
    }
    if (!collect_metadata(&metadata)) goto done;
    if (!format_timestamp(metadata.timestamp, sizeof(metadata.timestamp))) {
        fputs("ERROR: no se pudo obtener la hora UTC.\n", stderr);
        goto done;
    }

    if (timer_seconds(&total_start) != MATRIX_OK) {
        fputs("ERROR: no se pudo iniciar el cronometro total.\n", stderr);
        goto done;
    }
    matrix_clear(c.data, c.length);
    if (timer_seconds(&kernel_start) != MATRIX_OK) {
        fputs("ERROR: no se pudo iniciar el cronometro del kernel.\n", stderr);
        goto done;
    }
    matrix_accumulate(a.data, b.data, c.data, a.n);
    if (timer_seconds(&kernel_end) != MATRIX_OK || timer_seconds(&total_end) != MATRIX_OK) {
        fputs("ERROR: no se pudo detener el cronometro.\n", stderr);
        goto done;
    }
    kernel_s = kernel_end - kernel_start;
    total_s = total_end - total_start;
    if (!isfinite(kernel_s) || kernel_s < 0.0 || !isfinite(total_s) ||
        total_s < kernel_s) {
        fputs("ERROR: las duraciones medidas no cumplen el protocolo.\n", stderr);
        goto done;
    }
    if (!validate_against_reference(&c, reference)) goto done;
    if (options->output_path != NULL && !save_matrix(options->output_path, &c)) {
        fprintf(stderr, "ERROR: no se pudo guardar la salida: %s\n", options->output_path);
        goto done;
    }
    if (!write_csv(options, a.n, &metadata, kernel_s, total_s)) goto done;
    exit_code = EXIT_OK;

done:
    free(reference);
    matrix_release(&a);
    matrix_release(&b);
    matrix_release(&c);
    return exit_code;
}

static int smoke_test(void) {
    double start, end;
    volatile double spin = 0.0;
    int i;
    if (timer_seconds(&start) != MATRIX_OK) {
        fputs("ERROR: timer_seconds fallo.\n", stderr);
        return EXIT_ERROR;
    }
    for (i = 0; i < 1000000; ++i) spin += 1.0;
    if (timer_seconds(&end) != MATRIX_OK || end < start) {
        fputs("ERROR: timer_seconds no avanzo de forma monotona.\n", stderr);
        return EXIT_ERROR;
    }
    printf("OK: prueba de instalacion C secuencial x64, sin MPI ni OpenMP. "
           "Cronometro operativo (%.9f s observados).\n", end - start);
    (void)spin;
    return EXIT_OK;
}

int main(int argc, char **argv) {
    Options options;
    int parsed = parse_options(argc, argv, &options);
    if (parsed == 2) return smoke_test();
    if (parsed != 0) return EXIT_ERROR;
    return run_product(&options);
}
