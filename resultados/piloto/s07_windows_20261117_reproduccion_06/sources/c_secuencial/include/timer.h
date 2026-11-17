#ifndef TIMER_H
#define TIMER_H
/* Borrowed writable seconds pointer. Does not allocate or transfer ownership.
 * Uses QueryPerformanceCounter/Frequency and returns MATRIX_OK on success;
 * NULL arguments or Windows clock failures return a non-pending error.
 * Caller takes differences; zeroing C belongs to total_s, pure i,k,j to kernel_s,
 * and input preparation/validation/I/O stay outside both intervals. */
int timer_seconds(double *seconds);
#endif
