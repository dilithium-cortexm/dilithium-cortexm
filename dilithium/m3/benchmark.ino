#include <cstdint>

extern "C"
{
    #include "benchmark.h"
    #include "stack.h"
    #include "sign.h"
    #include "ntt.h"
    #include <sam.h>
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


int32_t poly0[256], poly1[256], poly2[256];

void benchmark_ntt()
{
  ntt_asm_schoolbook(poly0, zetas_asm);
}

void benchmark_invntt()
{
  inv_ntt_asm_schoolbook(poly0, zetas_inv_asm);

}

void benchmark_pointwise()
{
    poly_pointwise_invmontgomery_asm_mul(poly2, poly0, poly1);
}

void benchmark_ntt_leaktime()
{
    ntt_asm_smull(poly0, zetas_asm);
}

void benchmark_invntt_leaktime()
{
    inv_ntt_asm_smull(poly0, zetas_asm);
}

void benchmark_pointwise_leaktime()
{
    poly_pointwise_invmontgomery_asm_smull(poly2, poly0, poly1);
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

void benchmark_keygen() {
    crypto_sign_keypair(pk, sk);
#if SIGN_STACKSTRATEGY == 1
    precompute_strategy_1_sk_parts(&sk_precomp, sk);
#endif
}

void benchmark_sign() {
#if SIGN_STACKSTRATEGY == 1
    crypto_sign(sm, &smlen, sm, MLEN, &sk_precomp);
#else
    crypto_sign(sm, &smlen, sm, MLEN, sk);
#endif
}

void benchmark_verify() {
    verif_result = crypto_sign_open(sm, &smlen, sm, smlen, pk);
}

static void clock_setup() {
    /* Settings to run the clock at 16 MHz from the PLL */
    static const uint32_t SYS_BOARD_PLLAR = (CKGR_PLLAR_ONE | CKGR_PLLAR_MULA(3UL) | CKGR_PLLAR_PLLACOUNT(0x3fUL) | CKGR_PLLAR_DIVA(1UL));
    static const uint32_t SYS_BOARD_MCKR = ( PMC_MCKR_PRES_CLK_3 | PMC_MCKR_CSS_PLLA_CLK);

    /* Initialize PLLA to (15+1)*6=96MHz */
    PMC->CKGR_PLLAR = SYS_BOARD_PLLAR;
    while (!(PMC->PMC_SR & PMC_SR_LOCKA)) {}

    PMC->PMC_MCKR = SYS_BOARD_MCKR;
    while (!(PMC->PMC_SR & PMC_SR_MCKRDY)) {}

    /* Reduce the flash wait states again  */
    EFC0->EEFC_FMR = EEFC_FMR_FWS(0); // 4 waitstate flash access
    EFC1->EEFC_FMR = EEFC_FMR_FWS(0);

    SystemCoreClockUpdate(); // re-synchronize the USB with the new clock speed

    // UART configuration
    // Enable the peripheral uart controller
    PMC->PMC_PCER0 = 1 << ID_UART;

    // Reset and disable receiver & transmitter
    UART->UART_CR = UART_CR_RSTRX | UART_CR_RSTTX | UART_CR_RXDIS | UART_CR_TXDIS;

    // Set the baudrate to (Arduino standard) 9600
    UART->UART_BRGR = SystemCoreClock / (16 * 9600); // 96000000 / (16 * BRGR) = BaudRate
    // No Parity
    UART->UART_MR = UART_MR_PAR_NO;

    // Disable PDC channel requests
    UART->UART_PTCR = UART_PTCR_RXTDIS | UART_PTCR_TXTDIS;

    // Disable / Enable interrupts on end of receive
    UART->UART_IDR = 0xFFFFFFFF;
    NVIC_EnableIRQ((IRQn_Type) ID_UART);
    UART->UART_IER = UART_IER_RXRDY;

    // Enable receiver and transmitter
    UART->UART_CR = UART_CR_RXEN | UART_CR_TXEN;
}

static void bench()
{
    uint32_t measurement;
    size_t stack_usage;

    Serial.println("--------");
    Serial.println(CRYPTO_ALGNAME);
    Serial.flush();

    clock_setup();

    Serial.println("--------");
    Serial.print("Clock frequency: ");
    Serial.println(SystemCoreClock);
    Serial.flush();

    // Stack space measurements
    Serial.println("--------");
    Serial.println("KeyGen stack measurement:");
    stack_profile_begin();
    benchmark_keygen();
    stack_usage = stack_profile_end();
    Serial.println(stack_usage, DEC);

    Serial.println("--------");
    Serial.println("Sign stack measurement:");
    benchmark_sign();
    stack_profile_begin();
    benchmark_sign();
    stack_usage = stack_profile_end();
    Serial.println(stack_usage, DEC);

    Serial.println("--------");
    Serial.println("Open stack measurement:");
    stack_profile_begin();
    benchmark_verify();
    stack_usage = stack_profile_end();
    Serial.println(stack_usage, DEC);

    // Performance measurements

    Serial.println("--------");
    Serial.println("NTT measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_ntt);
    Serial.println(measurement, DEC);

    Serial.println("INVNTT measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_invntt);
    Serial.println(measurement, DEC);
    Serial.println("--------");
    Serial.flush();

    Serial.println("pointwise measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_pointwise);
    Serial.println(measurement, DEC);
    Serial.println("--------");
    Serial.flush();

    // make sure none of the short-cuts trigger
    memset(poly0, 0xff, sizeof(poly0));
    Serial.println("--------");
    Serial.println("NTT_leaktime measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_ntt_leaktime);
    Serial.println(measurement, DEC);

    Serial.println("INVNTT_leaktime measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_invntt_leaktime);
    Serial.println(measurement, DEC);
    Serial.println("--------");
    Serial.flush();

    memset(poly1, 0xff, sizeof(poly1));
    memset(poly2, 0xff, sizeof(poly2));
    Serial.println("pointwise_leaktime measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_pointwise_leaktime);
    Serial.println(measurement, DEC);
    Serial.println("--------");
    Serial.flush();


    Serial.println("KeyGen measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_keygen);
    Serial.println(measurement, DEC);
    Serial.println("Sign measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_sign);
    Serial.println(measurement, DEC);
    Serial.println("Open measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_verify);
    Serial.println(measurement, DEC);
    if(verif_result != 0)
    {
       Serial.println("ERROR");
    } else {
        Serial.println("OK");
    }

    Serial.println("--------");
    Serial.println("#");
    Serial.flush();
}

void loop()
{
    for(int i = 0; i < CRYPTO_ITERATIONS; i++){
        bench();
    }
    halt();
}
