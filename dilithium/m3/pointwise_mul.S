.syntax unified
.thumb

//Schoolbook multiplication (smlal)
.macro const_mul32_acc acc0, acc1, a0, a1, b0, b1, tmp
    mul     \tmp, \a0, \b0
    adds.w    \acc0, \acc0, \tmp
    mul     \tmp, \a1, \b1
    adc.w     \acc1, \acc1, \tmp
    mul     \tmp, \a1, \b0
    mla     \tmp, \a0, \b1, \tmp
    adds.w    \acc0, \acc0, \tmp, lsl #16
    adc.w     \acc1, \acc1, \tmp, asr #16
.endm

//Schoolbook multiplication (smull) -- slightly reordered to be able to use c0=a0
.macro const_mul32 c0, c1, a0, a1, b0, b1, tmp
    mul     \tmp, \a1, \b0
    mla     \tmp, \a0, \b1, \tmp
    mul     \c0, \a0, \b0
    mul     \c1, \a1, \b1
    adds.w    \c0, \c0, \tmp, lsl #16
    adc.w     \c1, \c1, \tmp, asr #16
.endm

// pah = res is possible
.macro montgomery_multiplication_m3 res, pal, pah, pbl, pbh, tmp0, qinv, ql, qh
    const_mul32  \pal, \res, \pal, \pah, \pbl, \pbh, \tmp0
    mul \pbh, \pal, \qinv
    ubfx \pbl, \pbh, #0, #16
    asr.w \pbh, \pbh, #16
    const_mul32_acc \pal, \res, \pbl, \pbh, \ql, \qh, \tmp0
.endm

.global poly_pointwise_invmontgomery_asm_mul
.type poly_pointwise_invmontgomery_asm_mul, %function
.align 2
poly_pointwise_invmontgomery_asm_mul:
    push.w {r4-r9, r14}
    c_ptr .req r0
    a_ptr .req r1
    b_ptr .req r2
    qinv  .req r3
    ql    .req r4
    qh    .req r5
    pal   .req r6
    pah   .req r7
    pbl   .req r8
    pbh   .req r9
    tmp0  .req r14
    ctr   .req r12

    movw ql, #0xE001
    movw qh, #0x7F
    movw ctr, #256
    ldr.w qinv, poly_pointwise_invmontgomery_asm_mul_qinv

    1:
        ldrsh.w pah, [a_ptr, #2]
        ldrh pal, [a_ptr], #4
        ldrsh.w pbh, [b_ptr, #2]
        ldrh pbl, [b_ptr], #4

        montgomery_multiplication_m3 pah, pal, pah, pbl, pbh, tmp0, qinv, ql, qh

        str pah, [c_ptr], #4

        subs.w ctr, ctr, #1
        bne.w 1b
    pop.w {r4-r9, pc}


.global poly_pointwise_acc_invmontgomery_asm_mul
.type poly_pointwise_acc_invmontgomery_asm_mul, %function
.align 2
poly_pointwise_acc_invmontgomery_asm_mul:
    push.w {r4-r10, r14}
    c_ptr .req r0
    a_ptr .req r1
    b_ptr .req r2
    qinv  .req r3
    ql    .req r4
    qh    .req r5
    pal   .req r6
    pah   .req r7
    pbl   .req r8
    pbh   .req r9
    pcc   .req r10
    tmp0  .req r14
    ctr   .req r12

    movw ql, #0xE001
    movw qh, #0x7F
    movw ctr, #256
    ldr.w qinv, poly_pointwise_invmontgomery_asm_mul_qinv

    1:
        ldrsh.w pah, [a_ptr, #2]
        ldrh pal, [a_ptr], #4
        ldrsh.w pbh, [b_ptr, #2]
        ldrh pbl, [b_ptr], #4
        ldr.w pcc, [c_ptr]

        montgomery_multiplication_m3 pah, pal, pah, pbl, pbh, tmp0, qinv, ql, qh

        add.w pah, pah, pcc
        str pah, [c_ptr], #4

        subs.w ctr, ctr, #1
        bne.w 1b
    pop.w {r4-r10, pc}


.align 2
poly_pointwise_invmontgomery_asm_mul_qinv:
.word 4236238847
