#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winreg.h>

#include <errno.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <mpi.h>
#include <omp.h>

#include "build_info.h"
#include "input.h"
#include "matrix.h"
#include "partition.h"

#ifndef PROJECT_COMMIT
#define PROJECT_COMMIT "dev"
#endif
#ifndef PROJECT_CONFIGURATION
#define PROJECT_CONFIGURATION "unknown"
#endif

#ifndef _OPENMP
#error Compile c_paralelo with /openmp.
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

static int requested_threads(int rank, int *threads) {
    const char *text = getenv("OMP_NUM_THREADS");
    const char *dynamic = getenv("OMP_DYNAMIC");
    char *end;
    long value;

    if (text == NULL || *text == '\0' || dynamic == NULL) {
        if (rank == 0) {
            fputs("ERROR: defina OMP_NUM_THREADS y OMP_DYNAMIC=FALSE.\n", stderr);
        }
        return 0;
    }
    if (_stricmp(dynamic, "FALSE") != 0) {
        if (rank == 0) {
            fputs("ERROR: OMP_DYNAMIC debe ser FALSE para fijar el numero de hilos.\n",
                  stderr);
        }
        return 0;
    }
    errno = 0;
    value = strtol(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0' || value < 1 ||
        value > INT_MAX) {
        if (rank == 0) {
            fputs("ERROR: OMP_NUM_THREADS debe ser un entero positivo.\n", stderr);
        }
        return 0;
    }
    *threads = (int)value;
    return 1;
}

static int mpi_check(int status, const char *operation) {
    if (status == MPI_SUCCESS) return 1;
    fprintf(stderr, "ERROR: %s fallo (codigo MPI %d).\n", operation, status);
    MPI_Abort(MPI_COMM_WORLD, 1);
    return 0;
}

static int load_inputs(const Options *options, size_t *n_out,
                       double **a_out, double **b_out) {
    size_t n, count;
    double *a = NULL, *b = NULL;

    *n_out = 0;
    *a_out = NULL;
    *b_out = NULL;

    if (options->input_path != NULL) {
        FILE *stream = NULL;
        double *data_a = NULL, *data_b = NULL;
        size_t file_n = 0;
        int input_status, close_status;

        if (fopen_s(&stream, options->input_path, "rb") != 0 || stream == NULL) {
            fprintf(stderr, "ERROR: no se pudo abrir la entrada: %s\n",
                    options->input_path);
            return 0;
        }
        input_status = input_read(stream, &data_a, &data_b, &file_n);
        close_status = fclose(stream);
        if (input_status != 0 || close_status != 0) {
            if (input_status == INPUT_IO_ERROR || close_status != 0) {
                fputs("ERROR: fallo de lectura de matrices.\n", stderr);
            } else if (input_status == INPUT_NO_MEMORY) {
                fputs("ERROR: memoria insuficiente al leer matrices.\n", stderr);
            } else {
                fputs("ERROR: archivo de matrices invalido.\n", stderr);
            }
            free(data_a);
            free(data_b);
            return 0;
        }
        n = file_n;
        a = data_a;
        b = data_b;
    } else {
        n = (size_t)options->n;
        if (n < 1 || n > PARTITION_MAX_N ||
            matrix_multiply_rows_validate(n, n) != MATRIX_OK) {
            fputs("ERROR: N excede el limite de MPI (N <= 46340).\n", stderr);
            return 0;
        }
        count = n * n;
        a = (double *)malloc(count * sizeof(*a));
        b = (double *)malloc(count * sizeof(*b));
        if (a == NULL || b == NULL) {
            fputs("ERROR: no se pudo reservar memoria para A y B.\n", stderr);
            free(a);
            free(b);
            return 0;
        }
        if (input_generate(a, b, n, options->seed) != 0) {
            fputs("ERROR: no se pudieron generar las matrices.\n", stderr);
            free(a);
            free(b);
            return 0;
        }
    }

    if (n < 1 || n > PARTITION_MAX_N ||
        matrix_multiply_rows_validate(n, n) != MATRIX_OK) {
        fputs("ERROR: N excede el limite de MPI (N <= 46340).\n", stderr);
        free(a);
        free(b);
        return 0;
    }

    *n_out = n;
    *a_out = a;
    *b_out = b;
    return 1;
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

static int write_csv(const Options *options, size_t n, int processes, int threads,
                     int observed_threads, const RunMetadata *metadata,
                     double kernel_s, double total_s) {
    static const char *headers[20] = {
        "timestamp", "version", "commit", "hostname", "cpu_model", "ram_gb",
        "os_version", "configuration", "n", "seed", "processes", "threads",
        "observed_threads", "workers", "gomaxprocs", "repetition", "is_warmup",
        "kernel_s", "total_s", "validation_status"
    };
    char configuration_text[64], n_text[32], seed_text[32];
    char processes_text[16], threads_text[16], observed_text[16];
    char repetition_text[16], kernel_text[64], total_text[64];
    const char *record[20];
    size_t i;

    if (!isfinite(kernel_s) || kernel_s < 0.0 || !isfinite(total_s) ||
        total_s < kernel_s) {
        fputs("ERROR: tiempos de medicion invalidos.\n", stderr);
        return 0;
    }
    if (snprintf(configuration_text, sizeof(configuration_text), "c_paralelo_P%d_T%d",
                 processes, threads) < 0 ||
        snprintf(n_text, sizeof(n_text), "%zu", n) < 0 ||
        snprintf(seed_text, sizeof(seed_text), "%u", (unsigned)options->seed) < 0 ||
        snprintf(processes_text, sizeof(processes_text), "%d", processes) < 0 ||
        snprintf(threads_text, sizeof(threads_text), "%d", threads) < 0 ||
        snprintf(observed_text, sizeof(observed_text), "%d", observed_threads) < 0 ||
        snprintf(repetition_text, sizeof(repetition_text), "%d", options->repetition) < 0 ||
        snprintf(kernel_text, sizeof(kernel_text), "%.9f", kernel_s) < 0 ||
        snprintf(total_text, sizeof(total_text), "%.9f", total_s) < 0) {
        fputs("ERROR: no se pudo formatear la fila CSV.\n", stderr);
        return 0;
    }
    record[0] = metadata->timestamp;
    record[1] = "c_paralelo";
    record[2] = PROJECT_COMMIT;
    record[3] = metadata->hostname;
    record[4] = metadata->cpu_model;
    record[5] = metadata->ram_gb;
    record[6] = metadata->os_version;
    record[7] = configuration_text;
    record[8] = n_text;
    record[9] = seed_text;
    record[10] = processes_text;
    record[11] = threads_text;
    record[12] = observed_text;
    record[13] = "1";
    record[14] = "";
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

static int write_matrix_stream(FILE *stream, size_t n, const double *data) {
    size_t row, column;
    if (fprintf(stream, "%zu\n", n) < 0) return 0;
    for (row = 0; row < n; ++row) {
        for (column = 0; column < n; ++column) {
            if (column != 0 && fputc(' ', stream) == EOF) return 0;
            if (fprintf(stream, "%.17g", data[row * n + column]) < 0) return 0;
        }
        if (fputc('\n', stream) == EOF) return 0;
    }
    return !ferror(stream);
}

static int save_matrix(const char *path, size_t n, const double *data) {
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
    result = write_matrix_stream(stream, n, data);
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

static int validate_result(size_t n, const double *actual,
                           const double *reference) {
    size_t i, count = n * n;
    for (i = 0; i < count; ++i) {
        double expected = reference[i];
        double difference = fabs(actual[i] - expected);
        double tolerance = 1e-9 + 1e-9 * fabs(expected);
        if (!isfinite(actual[i]) || !isfinite(expected) || difference > tolerance) {
            fprintf(stderr, "ERROR: resultado incorrecto en C[%zu,%zu].\n",
                    i / n, i % n);
            return 0;
        }
    }
    return 1;
}

static int run_smoke(int rank, int size, int provided) {
    int threads = 0, failed, any_failed = 0;

#pragma omp parallel reduction(+:threads)
    {
        threads += 1;
    }
    /* Every MPI call occurs on the initializing thread, outside OpenMP. */
    failed = (size != 2 || threads != 2);
    if (!mpi_check(MPI_Allreduce(&failed, &any_failed, 1, MPI_INT, MPI_MAX,
                                 MPI_COMM_WORLD), "MPI_Allreduce(smoke)")) {
        return EXIT_ERROR;
    }
    printf("Prueba de instalacion: proceso %d/%d, hilos %d, nivel MPI %d "
           "(FUNNELED=%d).\n", rank, size, threads, provided,
           MPI_THREAD_FUNNELED);
    if (any_failed) {
        fputs("La prueba exige exactamente 2 procesos y 2 hilos por proceso.\n",
              stderr);
        return EXIT_ERROR;
    }
    return EXIT_OK;
}

static int prepare_reference(size_t n, const double *a, const double *b,
                             double **reference_out) {
    double *reference;
    size_t i, j, k, count = n * n;

    *reference_out = NULL;
    reference = (double *)malloc(count * sizeof(*reference));
    if (reference == NULL) {
        fputs("ERROR: no se pudo reservar la referencia de validacion.\n", stderr);
        return 0;
    }

    /* Independent i,j,k reference, prepared completely outside both timers. */
    for (i = 0; i < n; ++i) {
        for (j = 0; j < n; ++j) {
            double sum = 0.0;
            for (k = 0; k < n; ++k) {
                sum += a[i * n + k] * b[k * n + j];
            }
            if (!isfinite(sum)) {
                fputs("ERROR: la referencia contiene valores no finitos.\n", stderr);
                free(reference);
                return 0;
            }
            reference[i * n + j] = sum;
        }
    }
    *reference_out = reference;
    return 1;
}

static int finalize_root(const Options *options, int processes, int threads,
                         int observed_threads, size_t n, const double *c,
                         const double *reference, const RunMetadata *metadata,
                         double kernel_s, double total_s) {
    if (!validate_result(n, c, reference)) return 0;

    if (options->output_path != NULL &&
        !save_matrix(options->output_path, n, c)) {
        fprintf(stderr, "ERROR: no se pudo guardar la salida: %s\n",
                options->output_path);
        return 0;
    }
    return write_csv(options, n, processes, threads, observed_threads,
                     metadata, kernel_s, total_s);
}

static int run_hybrid(const Options *options, int rank, int size, int threads) {
    int load_status = 0, n_int = 0;
    int local_ok = 1, global_ok = 1;
    int observed_local = 1, observed_min = 1, observed_max = 1;
    RunMetadata metadata = {0};
    size_t n = 0, count = 0, local_count = 0;
    double *a_full = NULL, *b = NULL, *c_full = NULL, *reference = NULL;
    double *a_local = NULL, *c_local = NULL;
    int *rows = NULL, *first = NULL, *counts = NULL, *displacements = NULL;
    double t0 = 0.0, t1 = 0.0, k0 = 0.0, k1 = 0.0;
    double kernel_local = 0.0, total_local = 0.0;
    double kernel_s = 0.0, total_s = 0.0;
    int exit_code = EXIT_ERROR;

    if (rank == 0) {
        if (!load_inputs(options, &n, &a_full, &b)) load_status = 1;
        if (load_status == 0) n_int = (int)n;
    }
    if (!mpi_check(MPI_Bcast(&load_status, 1, MPI_INT, 0, MPI_COMM_WORLD),
                   "MPI_Bcast(load_status)")) {
        goto done;
    }
    if (load_status != 0) {
        if (rank == 0) {
            fputs("ERROR: no se pudieron preparar las matrices de entrada.\n",
                  stderr);
        }
        goto done;
    }
    if (!mpi_check(MPI_Bcast(&n_int, 1, MPI_INT, 0, MPI_COMM_WORLD),
                   "MPI_Bcast(n)")) {
        goto done;
    }
    n = (size_t)n_int;

    if (n < 1 || n > PARTITION_MAX_N ||
        matrix_multiply_rows_validate(n, n) != MATRIX_OK) {
        local_ok = 0;
    }
    if (local_ok) {
        rows = (int *)malloc((size_t)size * sizeof(*rows));
        first = (int *)malloc((size_t)size * sizeof(*first));
        counts = (int *)malloc((size_t)size * sizeof(*counts));
        displacements = (int *)malloc((size_t)size * sizeof(*displacements));
        if (rows == NULL || first == NULL || counts == NULL ||
            displacements == NULL) {
            local_ok = 0;
        }
    }
    if (local_ok) {
        if (partition_split(n, size, rows, first) != PARTITION_OK ||
            partition_rows(n, size, counts, displacements) != PARTITION_OK) {
            local_ok = 0;
        }
    }
    if (!mpi_check(MPI_Allreduce(&local_ok, &global_ok, 1, MPI_INT, MPI_MIN,
                                 MPI_COMM_WORLD), "MPI_Allreduce(partition)")) {
        goto done;
    }
    if (!global_ok) {
        if (rank == 0) {
            fputs("ERROR: no se pudo calcular el reparto de filas.\n", stderr);
        }
        goto done;
    }

    count = n * n;
    local_count = (size_t)rows[rank] * n;
    local_ok = 1;
    if (rank != 0) {
        b = (double *)malloc(count * sizeof(*b));
        if (b == NULL) local_ok = 0;
    }
    if (local_ok) {
        a_local = (double *)malloc((local_count == 0 ? 1 : local_count) *
                                   sizeof(*a_local));
        c_local = (double *)malloc((local_count == 0 ? 1 : local_count) *
                                   sizeof(*c_local));
        if (a_local == NULL || c_local == NULL) local_ok = 0;
    }
    if (rank == 0 && local_ok) {
        c_full = (double *)malloc(count * sizeof(*c_full));
        if (c_full == NULL) local_ok = 0;
    }
    if (rank == 0 && local_ok) {
        /* Prepare the validation reference before the T0 barrier. */
        if (!prepare_reference(n, a_full, b, &reference)) local_ok = 0;
    }
    if (rank == 0 && local_ok) {
        if (!collect_metadata(&metadata)) {
            local_ok = 0;
        } else if (!format_timestamp(metadata.timestamp,
                                     sizeof(metadata.timestamp))) {
            fputs("ERROR: no se pudo obtener la hora UTC.\n", stderr);
            local_ok = 0;
        }
    }
    if (!mpi_check(MPI_Allreduce(&local_ok, &global_ok, 1, MPI_INT, MPI_MIN,
                                 MPI_COMM_WORLD), "MPI_Allreduce(memory)")) {
        goto done;
    }
    if (!global_ok) {
        if (rank == 0) {
            fputs("ERROR: no se pudieron preparar los recursos del hibrido.\n",
                  stderr);
        }
        goto done;
    }

    /* The barrier is outside total_s. T0 starts before Bcast; total_s covers
     * Bcast of B, Scatterv of A, clearing, the OpenMP region and Gatherv. */
    if (!mpi_check(MPI_Barrier(MPI_COMM_WORLD), "MPI_Barrier(T0)")) {
        goto done;
    }
    t0 = MPI_Wtime();
    if (!mpi_check(MPI_Bcast(b, (int)count, MPI_DOUBLE, 0, MPI_COMM_WORLD),
                   "MPI_Bcast(B)")) {
        goto done;
    }
    if (!mpi_check(MPI_Scatterv(a_full, counts, displacements, MPI_DOUBLE,
                                a_local, (int)local_count, MPI_DOUBLE, 0,
                                MPI_COMM_WORLD), "MPI_Scatterv(A)")) {
        goto done;
    }
    matrix_clear(c_local, local_count);
    if (rows[rank] > 0) {
        k0 = MPI_Wtime();
        matrix_accumulate_rows(a_local, b, c_local, (size_t)rows[rank], n,
                               &observed_local);
        k1 = MPI_Wtime();
        kernel_local = k1 - k0;
    } else {
        /* The protocol fixes kernel_s = 0 for a rank without rows. */
        observed_local = threads;
        kernel_local = 0.0;
    }
    if (!mpi_check(MPI_Gatherv(c_local, (int)local_count, MPI_DOUBLE,
                               c_full, counts, displacements, MPI_DOUBLE, 0,
                               MPI_COMM_WORLD), "MPI_Gatherv(C)")) {
        goto done;
    }
    t1 = MPI_Wtime();

    total_local = t1 - t0;
    local_ok = (isfinite(kernel_local) && kernel_local >= 0.0 &&
                isfinite(total_local) && total_local >= kernel_local) ? 1 : 0;
    if (!mpi_check(MPI_Allreduce(&local_ok, &global_ok, 1, MPI_INT, MPI_MIN,
                                 MPI_COMM_WORLD), "MPI_Allreduce(timers)")) {
        goto done;
    }
    if (!global_ok) {
        if (rank == 0) {
            fputs("ERROR: las duraciones medidas no cumplen el protocolo.\n",
                  stderr);
        }
        goto done;
    }

    if (!mpi_check(MPI_Reduce(&kernel_local, &kernel_s, 1, MPI_DOUBLE, MPI_MAX,
                              0, MPI_COMM_WORLD), "MPI_Reduce(kernel_s)")) {
        goto done;
    }
    if (!mpi_check(MPI_Reduce(&total_local, &total_s, 1, MPI_DOUBLE, MPI_MAX,
                              0, MPI_COMM_WORLD), "MPI_Reduce(total_s)")) {
        goto done;
    }
    if (!mpi_check(MPI_Reduce(&observed_local, &observed_min, 1, MPI_INT,
                              MPI_MIN, 0, MPI_COMM_WORLD),
                   "MPI_Reduce(observed_min)")) {
        goto done;
    }
    if (!mpi_check(MPI_Reduce(&observed_local, &observed_max, 1, MPI_INT,
                              MPI_MAX, 0, MPI_COMM_WORLD),
                   "MPI_Reduce(observed_max)")) {
        goto done;
    }

    if (rank == 0) {
        if (!isfinite(kernel_s) || kernel_s < 0.0 || !isfinite(total_s) ||
            total_s < kernel_s) {
            fputs("ERROR: los tiempos reducidos no son validos.\n", stderr);
            local_ok = 0;
        } else if (observed_min != threads || observed_max != threads) {
            fputs("ERROR: los hilos observados no coinciden con OMP_NUM_THREADS.\n",
                  stderr);
            local_ok = 0;
        } else {
            local_ok = 1;
        }
    }
    if (!mpi_check(MPI_Bcast(&local_ok, 1, MPI_INT, 0, MPI_COMM_WORLD),
                   "MPI_Bcast(timer_status)")) {
        goto done;
    }
    if (!local_ok) goto done;

    if (rank == 0) {
        local_ok = finalize_root(options, size, threads, observed_min, n,
                                 c_full, reference, &metadata, kernel_s,
                                 total_s);
    }
    if (!mpi_check(MPI_Bcast(&local_ok, 1, MPI_INT, 0, MPI_COMM_WORLD),
                   "MPI_Bcast(validation)")) {
        goto done;
    }
    if (!local_ok) goto done;

    exit_code = EXIT_OK;

done:
    free(a_full);
    free(b);
    free(c_full);
    free(reference);
    free(a_local);
    free(c_local);
    free(rows);
    free(first);
    free(counts);
    free(displacements);
    return exit_code;
}

int main(int argc, char **argv) {
    Options options;
    int parsed = parse_options(argc, argv, &options);
    int provided = 0, rank = 0, size = 0, threads = 0;
    int exit_code = EXIT_ERROR;

    if (parsed < 0) return EXIT_ERROR;
    if (MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided) !=
        MPI_SUCCESS) {
        fputs("ERROR: MPI_Init_thread fallo.\n", stderr);
        return EXIT_ERROR;
    }
    if (provided < MPI_THREAD_FUNNELED) {
        fputs("ERROR: MPI no proporciona MPI_THREAD_FUNNELED.\n", stderr);
        MPI_Abort(MPI_COMM_WORLD, 1);
        return EXIT_ERROR;
    }
    if (MPI_Comm_rank(MPI_COMM_WORLD, &rank) != MPI_SUCCESS ||
        MPI_Comm_size(MPI_COMM_WORLD, &size) != MPI_SUCCESS) {
        fputs("ERROR: no se pudo obtener rango o numero de procesos.\n", stderr);
        MPI_Abort(MPI_COMM_WORLD, 1);
        return EXIT_ERROR;
    }

    if (parsed == 2) {
        exit_code = run_smoke(rank, size, provided);
    } else {
        int thread_ok = requested_threads(rank, &threads);
        int all_thread_ok = 0;
        if (MPI_Allreduce(&thread_ok, &all_thread_ok, 1, MPI_INT, MPI_MIN,
                          MPI_COMM_WORLD) != MPI_SUCCESS) {
            fputs("ERROR: MPI_Allreduce de OpenMP fallo.\n", stderr);
            MPI_Abort(MPI_COMM_WORLD, 1);
            return EXIT_ERROR;
        }
        if (!all_thread_ok) {
            if (rank == 0) {
                fputs("ERROR: configuracion OpenMP invalida en algun rango.\n",
                      stderr);
            }
            exit_code = EXIT_ERROR;
        } else {
            exit_code = run_hybrid(&options, rank, size, threads);
        }
    }

    if (MPI_Finalize() != MPI_SUCCESS) return EXIT_ERROR;
    return exit_code;
}
