#ifndef RANDOMBYTES_H
#define RANDOMBYTES_H

#include <stddef.h>

#ifndef randombytes

// Use djb's deterministic RNG
//#define randombytes randombytes_notrandombytes

// Use the hardware RNG in the Arduino Due
#define randombytes randombytes_trng

#endif

int randombytes(unsigned char *x, size_t xlen);

#endif
