// Stack usage profiling
//
//
// This file implements functions for stack usage counting for our dilithium-m3
// project.  **This file is not portable!**  However, choose to adapt it for
// your purposes.
//
// To measure the stack space that is used by some piece of code, we first
// fill the memory with 'canary' values.  Later, we will count how many of
// these canary values are left and determine how many were overwritten.
// This number is the amount of stack that was used by the measured code.

#include <stddef.h>
#include <stdint.h>

// The canary_region_size sets the size of the region which is filled with
// 0xAA, counting the stack usage of the crypto algorithms.
//
// I *guess* that the .bss section will not be larger than 16 KiB.  So set
// the canary_region_size to 80 KiB (= 96 KiB - 16 KiB).
#if SIGN_STACKSTRATEGY == 1
// The precomputation struct is stored in the .bss section, so we will need
// to reserve about 64 KiB for that.
const static size_t canary_region_size = (96 - 64) * 1024;
#else
const static size_t canary_region_size = 80 * 1024;
#endif

// Fill up the memory with this value
const static uint8_t undef_value = 0xAA;

volatile static uint8_t *canary_region = NULL;

// Start stack profiling and return a pointer to the canary region
volatile uint8_t *stack_profile_begin()
{
    volatile uint8_t local_canary_region[canary_region_size];
    canary_region = local_canary_region;
    for (size_t i = 0; i < canary_region_size; i++)
    {
        canary_region[i] = undef_value;
    }
    return canary_region;
}

// End stack profiling and return the size of the canary region that was *not*
// left intact.
size_t stack_profile_end()
{
    size_t canary_region_remain = 0;
    for (size_t i = 0; i < canary_region_size; i++)
    {
        if (canary_region[i] == undef_value)
        {
            canary_region_remain++;
        }
        else
        {
            break;
        }
    }
    return canary_region_size - canary_region_remain;
}
