#include "randombytes.h"
#include "sign.h"
#include "hal.h"

#include <string.h>
#define NTESTS 15
#define MLEN 59

__attribute__((optimize("-O0"))) void before_keypair() {
       asm("nop");
}

__attribute__((optimize("-O0"))) void after_keypair() {
       asm("nop");
       asm("nop");
}

__attribute__((optimize("-O0"))) void after_sign() {
       asm("nop");
       asm("nop");
       asm("nop");
}

__attribute__((optimize("-O0"))) void after_open() {
       asm("nop");
       asm("nop");
       asm("nop");
       asm("nop");
}

static int test_sign(void)
{
    unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    unsigned char sk[CRYPTO_SECRETKEYBYTES];
    unsigned char sm[MLEN + CRYPTO_BYTES];
    unsigned char m[MLEN] = {0};
    unsigned char m2[MLEN];

    size_t mlen;
    size_t smlen;
    #if SIGN_STACKSTRATEGY == 1
    struct strategy_1_sk_precomp sk_precomp;
    #endif

    int i;
    before_keypair();
    for (i = 0; i < CRYPTO_ITERATIONS; i++)
    {
        crypto_sign_keypair(pk, sk);
        #if SIGN_STACKSTRATEGY == 1
        precompute_strategy_1_sk_parts(&sk_precomp, sk);
        #endif
    }

    after_keypair();

    for (i = 0; i < CRYPTO_ITERATIONS; i++)
    {
        #if SIGN_STACKSTRATEGY == 1
        crypto_sign(sm, &smlen, m, MLEN, &sk_precomp);
        #else
        crypto_sign(sm, &smlen, m, MLEN, sk);
        #endif
    }

    after_sign();

    for (i = 0; i < CRYPTO_ITERATIONS; i++)
    {
        crypto_sign_open(m2, &mlen, sm, smlen, pk);
    }

    after_open();
    return 0;
}


int main(void)
{
    hal_setup(CLOCK_BENCHMARK);
    test_sign();
    while(1);
    return 0;
}

