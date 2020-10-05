// Cycle-accurate benchmarking for the Cortex M3 (header)

#ifndef DILITHIUM_M3_BENCHMARK_H_
#define DILITHIUM_M3_BENCHMARK_H_

#include <stdint.h>

// Return the current value of the CYCCNT register.
//
// This function will lazily initialize the CYCCNT register the first time it
// is called.
uint32_t cyccnt();

// Benchmark the supplied function `fn`.
//
// This function tares results and can safely be used for measuring accurate
// cycle counts.
//
// Warning: Measurements that take longer than 2^32 cycles will overflow
// the CYCCNT register.  Do not rely on results for measurements that take
// longer than 10 seconds!
int32_t benchmark(void fn(void));

#endif /* DILITHIUM_M3_BENCHMARK_H_ */
