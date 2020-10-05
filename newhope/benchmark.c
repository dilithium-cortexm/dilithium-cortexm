// Cycle-accurate benchmarking for the Cortex M3

#include "benchmark.h"
#include <interrupt_sam_nvic.h>
#include <stdbool.h>

static volatile uint32_t *DWT_CONTROL = (uint32_t *)0xE0001000;
static volatile uint32_t *DWT_CYCCNT = (uint32_t *)0xE0001004;
static volatile uint32_t *DEMCR = (uint32_t *)0xE000EDFC;
static volatile uint32_t *LAR = (uint32_t *)0xE0001FB0;

static bool cyccnt_initialized = false;

// Setup the CYCCNT register.
static void cyccnt_setup()
{
    // Based on <https://stackoverflow.com/a/41188674/5207081>.
    *DEMCR = *DEMCR | 0x01000000;    // enable trace
    *LAR = 0xC5ACCE55;               // unlock access to DWT (ITM, etc.)registers
    *DWT_CYCCNT = 0;                 // clear DWT cycle counter
    *DWT_CONTROL = *DWT_CONTROL | 1; // enable DWT cycle counter
    cyccnt_initialized = true;
}

// Return the current value of the CYCCNT register.
uint32_t cyccnt()
{
    if (!cyccnt_initialized)
    {
        cyccnt_setup();
    }
    return *DWT_CYCCNT;
}

// Measure the execution latency of fn.
//
// Produces measurements with systematic error.  Use `benchmark` instead.
static int32_t __attribute__((noinline)) measure_fn_latency(void fn(void))
{
    __disable_irq();
    const uint32_t tick = cyccnt();
    fn();
    const uint32_t tock = cyccnt();
    __enable_irq();
    return tock - tick;
}

// Empty function.
static void __attribute__((noinline)) empty_function() {}

// Benchmark the supplied function `benchmark_fn`.
int32_t benchmark(void benchmark_fn(void))
{
    const int32_t sample = measure_fn_latency(benchmark_fn);
    const int32_t baseline = measure_fn_latency(empty_function);
    return sample - baseline;
}
