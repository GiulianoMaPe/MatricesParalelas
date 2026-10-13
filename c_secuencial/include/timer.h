#ifndef TIMER_H
#define TIMER_H
/* Borrowed writable seconds pointer. Does not allocate or transfer ownership.
 * Current S2 implementation returns MATRIX_PENDING and leaves *seconds intact.
 * S3 will use QueryPerformanceCounter/Frequency, return MATRIX_OK on success
 * and a non-pending error on NULL arguments or Windows clock failure.
 * Caller takes differences; zeroing C belongs to total_s, pure i,k,j to kernel_s,
 * and input preparation/validation/I/O stay outside both intervals. */
int timer_seconds(double *seconds);
#endif
