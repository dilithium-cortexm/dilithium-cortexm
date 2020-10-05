#include "sign.h"
#include "hal.h"
#include "sendfn.h"
#include "ntt.h"

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define MLEN 59

#define printcycles(S, U) send_unsignedll((S), (U))

int main(void)
{
  unsigned char sk[CRYPTO_SECRETKEYBYTES];
  unsigned char pk[CRYPTO_PUBLICKEYBYTES];
  unsigned char sm[MLEN+CRYPTO_BYTES];
  int32_t poly0[256], poly1[256], poly2[256];
  size_t smlen;
  unsigned long long t0, t1;

  hal_setup(CLOCK_BENCHMARK);

  hal_send_str("==========================");

  for(int i=0;i<CRYPTO_ITERATIONS;i++){
    // Key-pair generation
    t0 = hal_get_time();
    crypto_sign_keypair(pk, sk);
#if SIGN_STACKSTRATEGY == 1
    struct strategy_1_sk_precomp sk_precomp;
    precompute_strategy_1_sk_parts(&sk_precomp, sk);
#endif
    t1 = hal_get_time();
    printcycles("keypair cycles:", t1-t0);

    // Signing
    t0 = hal_get_time();
#if SIGN_STACKSTRATEGY == 1
    crypto_sign(sm, &smlen, sm, MLEN, &sk_precomp);
#else
    crypto_sign(sm, &smlen, sm, MLEN, sk);
#endif
    t1 = hal_get_time();
    printcycles("sign cycles:", t1-t0);

    // Verification
    t0 = hal_get_time();
    crypto_sign_open(sm, &smlen, sm, smlen, pk);
    t1 = hal_get_time();
    printcycles("verify cycles:", t1-t0);


    // NTT
    t0 = hal_get_time();
    ntt_asm_smull(poly0, zetas_interleaved_asm);
    t1 = hal_get_time();
    printcycles("ntt cycles:", t1-t0);

    // INVNTT
    t0 = hal_get_time();
    inv_ntt_asm_smull(poly0, zetas_interleaved_inv_asm);
    t1 = hal_get_time();
    printcycles("invntt cycles:", t1-t0);

    // pointwise
    t0 = hal_get_time();
    poly_pointwise_invmontgomery_asm_smull(poly0, poly1, poly2);
    t1 = hal_get_time();
    printcycles("pointwise cycles:", t1-t0);
    hal_send_str("#");
  }
  while(1);
  return 0;
}
