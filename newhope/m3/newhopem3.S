.syntax unified
.thumb

.macro montgomerym3 q, qinv, a, tmp
    mul.w \tmp, \a, \qinv
    sxth.w \tmp, \tmp
    mla.w \a, \tmp, \q, \a
    asr.w \a, \a, #16
.endm

.macro unsigned_barrettm3 a, q, tmp, barrettconst
  mul.w \tmp, \a, \barrettconst
  asr.w \tmp, \tmp, #28
  mls.w \a, \tmp, \q, \a
.endm

.global asm_mul_coeff_m3
.type asm_mul_coeff_m3,%function
.align 2
asm_mul_coeff_m3:
  push.w    {r4-r11, lr}
  poly      .req r0
  factors   .req r1
  polya0      .req r2
  polya1      .req r3
  polya2      .req r4
  polya3      .req r5
  polyb0      .req r6
  polyb1      .req r7
  polyb2      .req r8
  polyb3      .req r9
  tmp       .req r10
  rcons     .req r12
  q         .req r11
  qinv      .req r14

  movw q, #12289
  movw qinv, #12287
  movw rcons, #10952

  movw tmp, #256
  1:
    push.w {tmp}
    ldrsh.w polya0, [poly, #0]
    ldrsh.w polya1, [poly, #2]
    ldrsh.w polya2, [poly, #4]
    ldrsh.w polya3, [poly, #6]
    ldrsh.w polyb1, [factors, #2]
    ldrsh.w polyb2, [factors, #4]
    ldrsh.w polyb3, [factors, #6]
    ldrsh.w polyb0, [factors], #8
    mul.w polya0, polya0, polyb0
    montgomerym3 q, qinv, polya0, tmp
    mul.w polya0, polya0, rcons
    montgomerym3 q, qinv, polya0, tmp

    mul.w polya1, polya1, polyb1
    montgomerym3 q, qinv, polya1, tmp
    mul.w polya1, polya1, rcons
    montgomerym3 q, qinv, polya1, tmp

    mul.w polya2, polya2, polyb2
    montgomerym3 q, qinv, polya2, tmp
    mul.w polya2, polya2, rcons
    montgomerym3 q, qinv, polya2, tmp

    mul.w polya3, polya3, polyb3
    montgomerym3 q, qinv, polya3, tmp
    mul.w polya3, polya3, rcons
    montgomerym3 q, qinv, polya3, tmp

    strh.w polya1, [poly, #2]
    strh.w polya2, [poly, #4]
    strh.w polya3, [poly, #6]
    strh.w polya0, [poly], #8
    pop.w {tmp}
    subs.w tmp, #1
    bne.w 1b
  pop.w     {r4-r11, pc}

.unreq q
.unreq qinv
.unreq rcons
.unreq tmp
.unreq polya0
.unreq polya1
.unreq polya2
.unreq polya3
.unreq polyb0
.unreq polyb1
.unreq polyb2
.unreq polyb3

.global asm_eight_mul_m3
.type asm_eight_mul_m3,%function
.align 2
asm_eight_mul_m3:
  push.w    {r4-r11, lr}
  a_ptr     .req r0
  b_ptr     .req r1
  polya0      .req r2
  polya1      .req r3
  polya2      .req r4
  polya3      .req r5
  polyb0      .req r6
  polyb1      .req r7
  polyb2      .req r8
  polyb3      .req r9
  tmp       .req r10
  rcons     .req r12
  q         .req r11
  qinv      .req r14

  movw q, #12289
  movw qinv, #12287
  movw rcons, #10952

  .rept 2
  ldrsh.w polya0, [a_ptr, #0]
  ldrsh.w polya1, [a_ptr, #2]
  ldrsh.w polya2, [a_ptr, #4]
  ldrsh.w polya3, [a_ptr, #6]
  ldrsh.w polyb1, [b_ptr, #2]
  ldrsh.w polyb2, [b_ptr, #4]
  ldrsh.w polyb3, [b_ptr, #6]
  ldrsh.w polyb0, [b_ptr], #8

  mul.w polya0, polya0, polyb0
  montgomerym3 q, qinv, polya0, tmp
  mul.w polya0, polya0, rcons
  montgomerym3 q, qinv, polya0, tmp

  mul.w polya1, polya1, polyb1
  montgomerym3 q, qinv, polya1, tmp
  mul.w polya1, polya1, rcons
  montgomerym3 q, qinv, polya1, tmp

  mul.w polya2, polya2, polyb2
  montgomerym3 q, qinv, polya2, tmp
  mul.w polya2, polya2, rcons
  montgomerym3 q, qinv, polya2, tmp

  mul.w polya3, polya3, polyb3
  montgomerym3 q, qinv, polya3, tmp
  mul.w polya3, polya3, rcons
  montgomerym3 q, qinv, polya3, tmp

  strh.w polya1, [a_ptr, #2]
  strh.w polya2, [a_ptr, #4]
  strh.w polya3, [a_ptr, #6]
  strh.w polya0, [a_ptr], #8
  .endr
  pop.w     {r4-r11, pc}


.unreq q
.unreq qinv
.unreq tmp

.global asm_add_m3
.type asm_add_m3,%function
.align 2
asm_add_m3:
  push.w    {r4-r11, lr}
  a_ptr .req r0
  b_ptr .req r1
  polya0      .req r2
  polya1      .req r3
  polya2      .req r4
  polya3      .req r5
  polyb0      .req r6
  polyb1      .req r7
  polyb2      .req r8
  polyb3      .req r9
  ctr .req r10
  barrettconst .req r11
  tmp .req r12
  q .req r14

  movw q, #12289
  movw ctr, #256
  movw barrettconst, #21844
  1:
    ldrsh.w polya0, [a_ptr, #0]
    ldrsh.w polya1, [a_ptr, #2]
    ldrsh.w polya2, [a_ptr, #4]
    ldrsh.w polya3, [a_ptr, #6]
    ldrsh.w polyb1, [b_ptr, #2]
    ldrsh.w polyb2, [b_ptr, #4]
    ldrsh.w polyb3, [b_ptr, #6]
    ldrsh.w polyb0, [b_ptr], #8

    add.w polya0, polya0, polyb0
    unsigned_barrettm3 polya0, q, tmp, barrettconst
    add.w polya1, polya1, polyb1
    unsigned_barrettm3 polya1, q, tmp, barrettconst
    add.w polya2, polya2, polyb2
    unsigned_barrettm3 polya2, q, tmp, barrettconst
    add.w polya3, polya3, polyb3
    unsigned_barrettm3 polya3, q, tmp, barrettconst

    strh.w polya1, [a_ptr, #2]
    strh.w polya2, [a_ptr, #4]
    strh.w polya3, [a_ptr, #6]
    strh.w polya0, [a_ptr], #8
    subs.w ctr, #1
    bne.w 1b
  pop.w {r4-r11, pc}

.unreq q
.unreq tmp
.unreq barrettconst

.global asm_barrett_reduce_m3
.type asm_barrett_reduce_m3,%function
.align 2
asm_barrett_reduce_m3:
  push.w    {r4-r11, r14}

  poly         .req r0
  poly0        .req r1
  poly1        .req r2
  poly2        .req r3
  poly3        .req r4
  poly4        .req r5
  poly5        .req r6
  poly6        .req r7
  poly7        .req r8
  tmp          .req r10
  loop         .req r11
  q            .req r12
  barrettconst .req r14

  movw q, #12289
  movw barrettconst, #21844

  movw loop, #128
  1:
    ldrsh.w poly0, [poly]
    ldrsh.w poly1, [poly, #2]
    ldrsh.w poly2, [poly, #4]
    ldrsh.w poly3, [poly, #6]
    ldrsh.w poly4, [poly, #8]
    ldrsh.w poly5, [poly, #10]
    ldrsh.w poly6, [poly, #12]
    ldrsh.w poly7, [poly, #14]

    unsigned_barrettm3 poly0, q, tmp, barrettconst
    unsigned_barrettm3 poly1, q, tmp, barrettconst
    unsigned_barrettm3 poly2, q, tmp, barrettconst
    unsigned_barrettm3 poly3, q, tmp, barrettconst
    unsigned_barrettm3 poly4, q, tmp, barrettconst
    unsigned_barrettm3 poly5, q, tmp, barrettconst
    unsigned_barrettm3 poly6, q, tmp, barrettconst
    unsigned_barrettm3 poly7, q, tmp, barrettconst

    strh.w poly1, [poly, #2]
    strh.w poly2, [poly, #4]
    strh.w poly3, [poly, #6]
    strh.w poly4, [poly, #8]
    strh.w poly5, [poly, #10]
    strh.w poly6, [poly, #12]
    strh.w poly7, [poly, #14]
    strh.w poly0, [poly], #16
    subs.w loop, #1
    bne.w 1b
  pop.w     {r4-r11, pc}

.unreq poly0
.unreq poly1
.unreq poly2
.unreq poly3

.global bitrev_m3
.type bitrev_m3,%function
.align 2
bitrev_m3:
  push.w    {r4-r11, r14}
  poly        .req r0
  ind         .req r1
  indrev      .req r2
  next        .req r3
  poly0       .req r4
  poly1       .req r5
  poly2       .req r6
  poly3       .req r7
  tmp0        .req r8
  tmp1        .req r9
  polyhalf    .req r10
  add.w polyhalf, poly, #1024
  movw ind, #0
  mov.w indrev, ind
  loop:
    ldr.w poly0, [poly, ind]
    ldr.w poly1, [polyhalf, ind]
    ldr.w poly2, [poly, indrev]
    ldr.w poly3, [polyhalf, indrev]

    strh.w poly0, [poly, indrev]
    lsr.w poly0, poly0, #16
    strh.w poly0, [polyhalf, indrev]
    strh.w poly2, [poly, ind]
    lsr.w poly2, poly2, #16
    strh.w poly2, [polyhalf, ind]


    add.w indrev, indrev, #2
    add.w ind, ind, #2

    strh.w poly1, [poly, indrev]
    lsr.w poly1, poly1, #16
    strh.w poly1, [polyhalf, indrev]
    strh.w poly3, [poly, ind]
    lsr.w poly3, poly3, #16
    strh.w poly3, [polyhalf, ind]
    sub.w ind, ind, #2
  skip:
    add.w ind, ind, #4
    lsl.w indrev, ind, #20
    rbit.w indrev, indrev
    cmp.w indrev, ind
    bgt.w skip
    cmp.w ind, #1024
    bne.w loop
  pop.w {r4-r11,pc}