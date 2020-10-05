// Stack usage profiling

#include <stdint.h>
#include <stddef.h>

// Begin stack profiling.
//
// Call this function to start measuring the stack space used by some piece
// of code.  After running the code, call `stack_profile_end` to get the size
// of the stack that was used.
//
// Returns a pointer to the region that was marked with canary values.  You
// should probably never need this.
//
// Warning: `stack_profile_begin` and `stack_profile_end` must be called from
// the same stack frame for measurements to be accurate.
volatile uint8_t *stack_profile_begin();

// End stack profiling and return the size of the stack space that was used.
//
// Warning: `stack_profile_begin` and `stack_profile_end` must be called from
// the same stack frame for measurements to be accurate.
//
// Warning: Calling this function without having called `stack_profile_begin`
// earlier is undefined behavior!
size_t stack_profile_end();
