#include <cstdint>

extern "C"
{
    #include "../dilithium/sign.h"
}

static void halt()
{
    while (true)
        ;
}

void setup()
{
    // Initialize serial and wait for port to open.
    Serial.begin(9600);
    while (!Serial)
        ;
}

#define MLEN 59

unsigned char pk[CRYPTO_PUBLICKEYBYTES];
unsigned char sk[CRYPTO_SECRETKEYBYTES];
unsigned char sm[MLEN+CRYPTO_BYTES];
size_t smlen;
int verif_result = 0;

#if SIGN_STACKSTRATEGY == 1
struct strategy_1_sk_precomp sk_precomp;
#endif

void test_dilithium(){
    //Alice generates a public key
    crypto_sign_keypair(pk, sk);
    Serial.println("DONE keypair!");
    Serial.flush();

    //Bob derives a secret key and creates a response
#if SIGN_STACKSTRATEGY == 1
    precompute_strategy_1_sk_parts(&sk_precomp, sk);
    crypto_sign(sm, &smlen, sm, MLEN, &sk_precomp);
#else
    crypto_sign(sm, &smlen, sm, MLEN, sk);
#endif
    Serial.println("DONE signing!");
    Serial.flush();

    //Alice uses Bobs response to get her secret key
    verif_result = crypto_sign_open(sm, &smlen, sm, smlen, pk);
    Serial.println("DONE verification!");
    Serial.flush();

    if(verif_result!=0)
    {
        Serial.println("ERROR");
    } else {
        Serial.println("OK");
    }
    Serial.flush();
}

static void bench()
{
    uint32_t measurement;
    size_t stack_usage;

    Serial.println("--------");
    Serial.println(CRYPTO_ALGNAME);
    Serial.println("Testing:");
    test_dilithium();
    Serial.println("--------");
    Serial.println("#");
    Serial.flush();
}

void loop()
{
    for(int i=0;i<CRYPTO_ITERATIONS;i++){
        bench();
    }
    halt();
}
