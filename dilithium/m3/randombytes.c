#include "randombytes.h"
#include <sam.h>
#include <stdint.h>
#include <stdbool.h>

static bool trng_enabled = false;

static void pmc_enable_peripheral(const uint32_t pid)
{
    PMC->PMC_PCR = PMC_PCR_PID(pid);
    const uint32_t pcr = PMC->PMC_PCR;
    PMC->PMC_PCR = pcr | PMC_PCR_CMD | PMC_PCR_EN;
}

int randombytes(uint8_t *buf, size_t xlen)
{
    if (!trng_enabled)
    {
        // Power up the TRNG peripheral clock
        pmc_enable_peripheral(ID_TRNG);

        // Enable the RNG
        TRNG->TRNG_CR = TRNG_CR_ENABLE | TRNG_CR_KEY(0x524e47);
        trng_enabled = true;
    }

    uint32_t data;
    for (size_t i = 0; i < xlen; i++)
    {
        if (i % 4 == 0)
        {
            while (!(TRNG->TRNG_ISR & TRNG_ISR_DATRDY))
            {
                // busy-wait
            }
            data = (TRNG->TRNG_ODATA >> TRNG_ODATA_ODATA_Pos) & TRNG_ODATA_ODATA_Msk;
        }
        buf[i] = (uint8_t)data;
        data >>= 8;
    }
    return 0;
}