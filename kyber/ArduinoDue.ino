#include <cstdint>

extern "C"
{
#include "benchmark.h"
#include "api.h"
#include "poly.h"
extern void invntt_fast_m3(int16_t*, const int16_t zetas[128]);
extern void ntt_fast_m3(int16_t*, const int16_t zetas[128]);

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

const int16_t zetas_asm[128] = {
// 7 & 6 & 5 layers
2571, 2970, 1812, 1493, 1422, 287, 202,
// 1st loop of 4 & 3 & 2 layers
3158, 573, 2004, 1223, 652, 2777, 1015,
// 2nd loop of 4 & 3 & 2 layers
622, 264, 383, 2036, 1491, 3047, 1785,
// 3rd loop of 4 & 3 & 2 layers
1577, 2500, 1458, 516, 3321, 3009, 2663,
// 4th loop of 4 & 3 & 2 layers
182, 1727, 3199, 1711, 2167, 126, 1469,
// 5th loop of 4 & 3 & 2 layers
962, 2648, 1017, 2476, 3239, 3058, 830,
// 6th loop of 4 & 3 & 2 layers
2127, 732, 608, 107, 1908, 3082, 2378,
// 7th loop of 4 & 3 & 2 layers
1855, 1787, 411, 2931, 961, 1821, 2604,
// 8th loop of 4 & 3 & 2 layers
1468, 3124, 1758, 448, 2264, 677, 2054,
// 1 layer
2226, 430, 555, 843, 2078, 871, 1550, 105, 422, 587, 177, 3094, 3038, 2869, 1574, 1653, 3083, 778, 1159, 3182, 2552, 1483, 2727, 1119, 1739, 644, 2457, 349, 418, 329, 3173, 3254, 817, 1097, 603, 610, 1322, 2044, 1864, 384, 2114, 3193, 1218, 1994, 2455, 220, 2142, 1670, 2144, 1799, 2051, 794, 1819, 2475, 2459, 478, 3221, 3021, 996, 991, 958, 1869, 1522, 1628,
};

poly p, p1, p2;

void benchmark_ntt()
{
    ntt_fast_m3(p.coeffs, zetas_asm);
}

const int16_t zetas_inv_asm[128] = {
// 1 layer
1701, 1807, 1460, 2371, 2338, 2333, 308, 108, 2851, 870, 854, 1510, 2535, 1278, 1530, 1185, 1659, 1187, 3109, 874, 1335, 2111, 136, 1215, 2945, 1465, 1285, 2007, 2719, 2726, 2232, 2512, 75, 156, 3000, 2911, 2980, 872, 2685, 1590, 2210, 602, 1846, 777, 147, 2170, 2551, 246, 1676, 1755, 460, 291, 235, 3152, 2742, 2907, 3224, 1779, 2458, 1251, 2486, 2774, 2899, 1103,
// 1st loop of 2 & 3 & 4 layers
1275, 2652, 1065, 2881, 1571, 205, 1861,
// 2nd loop of 2 & 3 & 4 layers
725, 1508, 2368, 398, 2918, 1542, 1474,
// 3rd loop of 2 & 3 & 4 layers
951, 247, 1421, 3222, 2721, 2597, 1202,
// 4th loop of 2 & 3 & 4 layers
2499, 271, 90, 853, 2312, 681, 2367,
// 5th loop of 2 & 3 & 4 layers
1860, 3203, 1162, 1618, 130, 1602, 3147,
// 6th loop of 2 & 3 & 4 layers
666, 320, 8, 2813, 1871, 829, 1752,
// 7th loop of 2 & 3 & 4 layers
1544, 282, 1838, 1293, 2946, 3065, 2707,
// 8th loop of 2 & 3 & 4 layers
2314, 552, 2677, 2106, 1325, 2756, 171,
// 5 & 6 & 7 layers
3127, 3042, 1907, 1836, 1517, 359, 1932,
// 128^-1 * 2^32
1441
};
void benchmark_invntt()
{
    invntt_fast_m3(p.coeffs, zetas_inv_asm);
}

void benchmark_pointwise()
{
    poly_basemul(&p, &p1, &p2);
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


void test_kyber(){
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
    Serial.println(CRYPTO_ALGNAME);
    Serial.println("Testing:");
    test_kyber();
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
