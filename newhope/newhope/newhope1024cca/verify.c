#include "verify.h"
#include <stddef.h>
#include <stdint.h>

/*************************************************
* Name:        cmov
*
* Description: Copy len bytes from x to r if b is 1;
*              don't modify x if b is 0. Requires b to be in {0,1};
*              assumes two's complement representation of negative integers.
*              Runs in constant time.
*
* Arguments:   unsigned char *r:       pointer to output byte array
*              const unsigned char *x: pointer to input byte array
*              size_t len:             Amount of bytes to be copied
*              unsigned char b:        Condition bit; has to be in {0,1}
**************************************************/
void cmov(unsigned char *r, const unsigned char *x, size_t len, unsigned char b) {
  size_t i;

  b = -b;
  for (i = 0; i < len; i++) {
    r[i] ^= b & (x[i] ^ r[i]);
  }
}
