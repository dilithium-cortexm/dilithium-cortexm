#include "sign.h"
#include "randombytes.h"
#include "hal.h"

#include <string.h>

#define NTESTS 15
#define MLEN 32

const uint8_t canary[8] = {
  0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF
};

/* allocate a bit more for all keys and messages and
 * make sure it is not touched by the implementations.
 */
static void write_canary(uint8_t *d) {
  for (size_t i = 0; i < 8; i++) {
    d[i] = canary[i];
  }
}

static int check_canary(const uint8_t *d) {
  for (size_t i = 0; i < 8; i++) {
    if (d[i] != canary[i]) {
      return -1;
    }
  }
  return 0;
}

static int test_sign(void)
{
    unsigned char pk[CRYPTO_PUBLICKEYBYTES+16];
    unsigned char sk[CRYPTO_SECRETKEYBYTES+16];
    unsigned char sm[MLEN + CRYPTO_BYTES+16];
    unsigned char m[MLEN+16];

    size_t mlen;
    size_t smlen;

    int i;
    write_canary(pk); write_canary(pk+sizeof(pk)-8);
    write_canary(sk); write_canary(sk+sizeof(sk)-8);
    write_canary(sm); write_canary(sm+sizeof(sm)-8);
    write_canary(m); write_canary(m+sizeof(m)-8);

    for (i = 0; i < NTESTS; i++) {
        crypto_sign_keypair(pk+8, sk+8);
        hal_send_str("crypto_sign_keypair DONE.\n");

        randombytes(m+8, MLEN);
        #if SIGN_STACKSTRATEGY == 1
        struct strategy_1_sk_precomp sk_precomp;
        precompute_strategy_1_sk_parts(&sk_precomp, sk+8);
        crypto_sign(sm+8, &smlen, m+8, MLEN, &sk_precomp);
        #else
        crypto_sign(sm+8, &smlen, m+8, MLEN, sk+8);
        #endif

        hal_send_str("crypto_sign DONE.\n");

        // By relying on m == sm we prevent having to allocate CRYPTO_BYTES twice
        if (crypto_sign_open(sm+8, &mlen, sm+8, smlen, pk+8))
        {
            hal_send_str("ERROR Signature did not verify correctly!\n");
        }
        else if(check_canary(pk) || check_canary(pk+sizeof(pk)-8) ||
            check_canary(sk) || check_canary(sk+sizeof(sk)-8) ||
            check_canary(sm) || check_canary(sm+sizeof(sm)-8) ||
            check_canary(m) || check_canary(m+sizeof(m)-8))
        {
            hal_send_str("ERROR canary overwritten\n");
        }
        else
        {
            hal_send_str("OK Signature did verify correctly!\n");
        }
        hal_send_str("crypto_sign_open DONE.\n");
    }

    return 0;
}

static int test_wrong_pk(void)
{
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    unsigned char pk2[CRYPTO_PUBLICKEYBYTES];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char sm[MLEN + CRYPTO_BYTES];
    unsigned char m[MLEN];

    size_t mlen;
    size_t smlen;

    int i;

    for (i = 0; i < NTESTS; i++) {
        crypto_sign_keypair(pk2, sk);
        hal_send_str("crypto_sign_keypair DONE.\n");

        crypto_sign_keypair(pk, sk);
        hal_send_str("crypto_sign_keypair DONE.\n");


        randombytes(m, MLEN);
        #if SIGN_STACKSTRATEGY == 1
        struct strategy_1_sk_precomp sk_precomp;
        precompute_strategy_1_sk_parts(&sk_precomp, sk);
        crypto_sign(sm, &smlen, m, MLEN, &sk_precomp);
        #else
        crypto_sign(sm, &smlen, m, MLEN, sk);
        #endif
        hal_send_str("crypto_sign DONE.\n");

        // By relying on m == sm we prevent having to allocate CRYPTO_BYTES twice
        if (crypto_sign_open(sm, &mlen, sm, smlen, pk2))
        {
            hal_send_str("OK Signature did not verify correctly under wrong public key!\n");
        }
        else
        {
            hal_send_str("ERROR Signature did verify correctly under wrong public key!\n");
        }
        hal_send_str("crypto_sign_open DONE.\n");
    }

    return 0;
}

int main(void)
{
    hal_setup(CLOCK_FAST);

    // marker for automated testing
    hal_send_str("==========================");
    test_sign();
    test_wrong_pk();
    hal_send_str("#");
    while(1);
    return 0;
}