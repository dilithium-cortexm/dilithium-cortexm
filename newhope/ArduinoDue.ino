#include <cstdint>

extern "C"
{
#include "benchmark.h"
#include "api.h"
#include "poly.h"
#define NEWHOPE_N 1024
extern void asm_invntt_m3(int16_t p[NEWHOPE_N], const int16_t gammas[NEWHOPE_N]);
extern void asm_ntt_m3(int16_t p[NEWHOPE_N], const int16_t gammas[NEWHOPE_N]);
extern int16_t gammas_bitrev_montgomery_m3[NEWHOPE_N];
extern int16_t gammas_inv_montgomery_m3[NEWHOPE_N];
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

poly p;

void benchmark_ntt()
{
    asm_ntt_m3(p.coeffs, gammas_bitrev_montgomery_m3);
}


void benchmark_invntt()
{
    asm_invntt_m3(p.coeffs, gammas_inv_montgomery_m3);
}

poly p1;
void benchmark_pointwise()
{
    poly_mul_pointwise(&p, &p1);
}

unsigned char pk[CRYPTO_PUBLICKEYBYTES];
unsigned char sk[CRYPTO_SECRETKEYBYTES];
unsigned char ct[CRYPTO_CIPHERTEXTBYTES];
unsigned char key_b[CRYPTO_BYTES];
unsigned char key_a[CRYPTO_BYTES];
void benchmark_keygen(){
    crypto_kem_keypair(pk, sk);
}
void benchmark_enc(){
    crypto_kem_enc(ct, key_b, pk);
}

void benchmark_dec(){
    crypto_kem_dec(key_a, ct, sk);
}


void test_newhope(){
    //Alice generates a public key
    crypto_kem_keypair(pk, sk);
    Serial.println("DONE key pair generation!");

    //Bob derives a secret key and creates a response
    crypto_kem_enc(ct, key_b, pk);
    Serial.println("DONE encapsulation!");

    //Alice uses Bobs response to get her secret key
    crypto_kem_dec(key_a, ct, sk);
    Serial.println("DONE decapsulation!");

    if(memcmp(key_a, key_b, CRYPTO_BYTES))
    {
        Serial.println("ERROR KEYS");
    } else {
        Serial.println("OK KEYS");
    }

}

static void bench()
{
    uint32_t measurement;
    Serial.println("--------");
    Serial.println("Testing:");
    Serial.println(CRYPTO_ALGNAME);
    test_newhope();


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

    Serial.println("KeyGen measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_keygen);
    Serial.println(measurement, DEC);
    Serial.println("Encaps measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_enc);
    Serial.println(measurement, DEC);
    Serial.println("Decaps measurement:");
    Serial.flush();
    measurement = benchmark(benchmark_dec);
    Serial.println(measurement, DEC);
    if(memcmp(key_a, key_b, CRYPTO_BYTES))
    {
        Serial.println("ERROR KEYS");
    } else {
        Serial.println("OK KEYS");
    }

    Serial.println("--------");
    Serial.println("#");
    Serial.flush();
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


void loop()
{
    clock_setup();
    for(int i=0;i<CRYPTO_ITERATIONS;i++){
        bench();
    }
    halt();
}
