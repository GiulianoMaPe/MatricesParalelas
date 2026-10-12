#include "timer.h"
#include "matrix.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

int timer_seconds(double *seconds) {
    LARGE_INTEGER counter, frequency;
    if (seconds == NULL) return MATRIX_INVALID_ARGUMENT;
    if (!QueryPerformanceFrequency(&frequency) || frequency.QuadPart == 0)
        return MATRIX_INVALID_ARGUMENT;
    if (!QueryPerformanceCounter(&counter))
        return MATRIX_INVALID_ARGUMENT;
    *seconds = (double)counter.QuadPart / (double)frequency.QuadPart;
    return MATRIX_OK;
}