/* Test-only adapters for MSVC stdio conveniences; no production source changes. */
#include <stdio.h>
#include <errno.h>
static inline int fopen_s(FILE **f, const char *path, const char *mode) {
    *f = fopen(path, mode); return *f ? 0 : errno;
}
static inline int tmpfile_s(FILE **f) { *f = tmpfile(); return *f ? 0 : errno; }
