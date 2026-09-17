#include <stdio.h>
#include <string.h>
#include <mpi.h>
#include <omp.h>
#include "matrix.h"
#ifndef _OPENMP
#error Compile this installation test with /openmp.
#endif
int main(int argc, char **argv) {
    int rank = 0, size = 0, provided = 0, threads = 0, failed = 0, any_failed = 0;
    if (argc != 2 || strcmp(argv[1], "--smoke-test") != 0) {
        fputs("PENDIENTE: algoritmo hibrido y --n/--seed. Prueba disponible: --smoke-test.\n", stderr);
        return MATRIX_PENDING;
    }
    if (MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided) != MPI_SUCCESS) return 1;
    if (provided < MPI_THREAD_FUNNELED) {
        fputs("MPI no proporciona MPI_THREAD_FUNNELED.\n", stderr);
        MPI_Abort(MPI_COMM_WORLD, 1);
        return 1;
    }
    if (MPI_Comm_rank(MPI_COMM_WORLD, &rank) != MPI_SUCCESS ||
        MPI_Comm_size(MPI_COMM_WORLD, &size) != MPI_SUCCESS) {
        MPI_Abort(MPI_COMM_WORLD, 1);
        return 1;
    }
    #pragma omp parallel reduction(+:threads)
    {
        threads += 1;
    }
    /* Every MPI call occurs on the initializing thread, outside OpenMP. */
    failed = (size != 2 || threads != 2);
    if (MPI_Allreduce(&failed, &any_failed, 1, MPI_INT, MPI_MAX, MPI_COMM_WORLD) != MPI_SUCCESS) {
        MPI_Abort(MPI_COMM_WORLD, 1);
        return 1;
    }
    printf("Prueba de instalacion: proceso %d/%d, hilos %d, nivel MPI %d (FUNNELED=%d). Algoritmo pendiente.\n",
           rank, size, threads, provided, MPI_THREAD_FUNNELED);
    if (any_failed) fputs("La prueba exige exactamente 2 procesos y 2 hilos por proceso.\n", stderr);
    if (MPI_Finalize() != MPI_SUCCESS) return 1;
    return any_failed ? 1 : 0;
}