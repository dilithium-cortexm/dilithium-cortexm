.syntax unified
.thumb

.macro barrettm3 a, tmp, q, barrettconst
    mul.w \tmp, \a, \barrettconst
    asr.w \tmp, \tmp, #26
    mul.w \tmp, \tmp, \q
    sub.w \a, \a, \tmp
.endm

.macro montgomerym3 q, qinv, a, tmp
  mul.w \tmp, \a, \qinv
  sxth.w \tmp, \tmp
  mla.w \a, \tmp, \q, \a
  asr.w \a, \a, #16
.endm

.align 2
.global pointwise_sub_m3
.type pointwise_sub_m3, %function
pointwise_sub_m3:
  push.w {r4-r11, lr}

  movw r14, #51
  1:
    ldrsh.w r4, [r1, #2]
    ldrsh.w r5, [r1, #4]
    ldrsh.w r6, [r1, #6]
    ldrsh.w r7, [r1, #8]
    ldrsh.w r3, [r1], #10
    ldrsh.w r9, [r2, #2]
    ldrsh.w r10, [r2, #4]
    ldrsh.w r11, [r2, #6]
    ldrsh.w r12, [r2, #8]
    ldrsh.w r8, [r2], #10

    sub.w r3, r3, r8
    sub.w r4, r4, r9
    sub.w r5, r5, r10
    sub.w r6, r6, r11
    sub.w r7, r7, r12

    strh.w r4, [r0, #2]
    strh.w r5, [r0, #4]
    strh.w r6, [r0, #6]
    strh.w r7, [r0, #8]
    strh.w r3, [r0], #10
    subs.w r14, #1
  bne.w 1b

  ldrsh.w r3, [r1]
  ldrsh.w r4, [r2]
  sub.w r3, r3, r4
  strh.w r3, [r0]

  pop.w {r4-r11, pc}


.align 2
.global pointwise_add_m3
.type pointwise_add_m3, %function
pointwise_add_m3:
  push.w {r4-r11, lr}
  movw.w r14, #51
  1:
    ldrsh.w r4, [r1, #2]
    ldrsh.w r5, [r1, #4]
    ldrsh.w r6, [r1, #6]
    ldrsh.w r7, [r1, #8]
    ldrsh.w r3, [r1], #10
    ldrsh.w r9, [r2, #2]
    ldrsh.w r10, [r2, #4]
    ldrsh.w r11, [r2, #6]
    ldrsh.w r12, [r2, #8]
    ldrsh.w r8, [r2], #10

    add.w r3, r3, r8
    add.w r4, r4, r9
    add.w r5, r5, r10
    add.w r6, r6, r11
    add.w r7, r7, r12

    strh.w r4, [r0, #2]
    strh.w r5, [r0, #4]
    strh.w r6, [r0, #6]
    strh.w r7, [r0, #8]
    strh.w r3, [r0], #10
    subs.w r14, #1
  bne.w 1b

  ldrsh.w r3, [r1]
  ldrsh.w r4, [r2]
  add.w r3, r3, r4
  strh.w r3, [r0]
  pop.w {r4-r11, pc}

  .global asm_barrett_reduce_m3
.type asm_barrett_reduce_m3,%function
.align 2
asm_barrett_reduce_m3:
  push.w    {r4-r11, r14}

  poly        .req r0
  poly0       .req r1
  poly1       .req r2
  poly2       .req r3
  poly3       .req r4
  poly4       .req r5
  poly5       .req r6
  poly6       .req r7
  poly7       .req r8
  poly8       .req r14
  loop        .req r9
  barrettconst .req r10
  q           .req r11
  tmp         .req r12

  movw barrettconst, #20159
  movw q, #3329

  movw loop, #28
  1:
    ldrsh.w poly0, [poly, #0]
    ldrsh.w poly1, [poly, #2]
    ldrsh.w poly2, [poly, #4]
    ldrsh.w poly3, [poly, #6]
    ldrsh.w poly4, [poly, #8]
    ldrsh.w poly5, [poly, #10]
    ldrsh.w poly6, [poly, #12]
    ldrsh.w poly7, [poly, #14]
    ldrsh.w poly8, [poly, #16]

    barrettm3 poly0, tmp, q, barrettconst
    barrettm3 poly1, tmp, q, barrettconst
    barrettm3 poly2, tmp, q, barrettconst
    barrettm3 poly3, tmp, q, barrettconst
    barrettm3 poly4, tmp, q, barrettconst
    barrettm3 poly5, tmp, q, barrettconst
    barrettm3 poly6, tmp, q, barrettconst
    barrettm3 poly7, tmp, q, barrettconst
    barrettm3 poly8, tmp, q, barrettconst

    strh.w poly1, [poly, #2]
    strh.w poly2, [poly, #4]
    strh.w poly3, [poly, #6]
    strh.w poly4, [poly, #8]
    strh.w poly5, [poly, #10]
    strh.w poly6, [poly, #12]
    strh.w poly7, [poly, #14]
    strh.w poly8, [poly, #16]
    strh.w poly0, [poly], #18
    subs.w loop, #1
  bne.w 1b

  ldrsh.w poly0, [poly, #0]
  ldrsh.w poly1, [poly, #2]
  ldrsh.w poly2, [poly, #4]
  ldrsh.w poly3, [poly, #6]
  barrettm3 poly0, tmp, q, barrettconst
  barrettm3 poly1, tmp, q, barrettconst
  barrettm3 poly2, tmp, q, barrettconst
  barrettm3 poly3, tmp, q, barrettconst
  strh.w poly0, [poly, #0]
  strh.w poly1, [poly, #2]
  strh.w poly2, [poly, #4]
  strh.w poly3, [poly, #6]
  pop.w     {r4-r11, pc}



.global asm_frommont_m3
.type asm_frommont_m3,%function
.align 2
asm_frommont_m3:
  push.w    {r4-r11, r14}

  poly        .req r0
  poly0       .req r1
  poly1       .req r2
  poly2       .req r3
  poly3       .req r4
  poly4       .req r5
  poly5       .req r6
  poly6       .req r7
  poly7       .req r8
  loop        .req r9
  constant    .req r10
  qinv        .req r14
  q           .req r11
  tmp         .req r12

  movw q, #3329
  movw qinv, #3327

  movw constant, #1353

movw loop, #32
  1:
    ldrsh.w poly0, [poly, #0]
    ldrsh.w poly1, [poly, #2]
    ldrsh.w poly2, [poly, #4]
    ldrsh.w poly3, [poly, #6]
    ldrsh.w poly4, [poly, #8]
    ldrsh.w poly5, [poly, #10]
    ldrsh.w poly6, [poly, #12]
    ldrsh.w poly7, [poly, #14]

    mul.w poly0, poly0, constant
    mul.w poly1, poly1, constant
    mul.w poly2, poly2, constant
    mul.w poly3, poly3, constant
    mul.w poly4, poly4, constant
    mul.w poly5, poly5, constant
    mul.w poly6, poly6, constant
    mul.w poly7, poly7, constant
    montgomerym3 q, qinv, poly0, tmp
    montgomerym3 q, qinv, poly1, tmp
    montgomerym3 q, qinv, poly2, tmp
    montgomerym3 q, qinv, poly3, tmp
    montgomerym3 q, qinv, poly4, tmp
    montgomerym3 q, qinv, poly5, tmp
    montgomerym3 q, qinv, poly6, tmp
    montgomerym3 q, qinv, poly7, tmp

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



  .unreq poly
  .unreq poly0
  .unreq poly1
  .unreq poly2
  .unreq poly3
  .unreq poly4
  .unreq poly5
  .unreq poly6
  .unreq poly7
  .unreq q
  .unreq qinv
  .unreq tmp
  .unreq loop


.global doublebasemul_asm_m3
.type doublebasemul_asm_m3, %function
.align 2
doublebasemul_asm_m3:
  push.w {r4-r11, lr}

  rptr  .req r0
  aptr  .req r1
  bptr  .req r2
  zeta  .req r3
  poly0 .req r4
  poly1 .req r6
  poly2 .req r5
  poly3 .req r7
  q     .req r8
  qinv  .req r14
  tmp   .req r9
  tmp2  .req r10

  movw.w  q, #3329
  movw.w qinv, #3327

  ldrsh.w poly0, [aptr, #0]
  ldrsh.w poly1, [aptr, #2]
  ldrsh.w poly2, [bptr, #0]
  ldrsh.w poly3, [bptr, #2]

  mul.w tmp, poly1, poly3
  montgomerym3 q, qinv, tmp, tmp2
  mul.w tmp, tmp, zeta
  mla.w tmp, poly0, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  strh.w tmp, [rptr, #0]

  mul.w tmp, poly0, poly3
  mla.w tmp, poly1, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  strh.w tmp, [rptr, #2]


  neg.w zeta, zeta

  ldrsh.w poly0, [aptr, #4]
  ldrsh.w poly1, [aptr, #6]
  ldrsh.w poly2, [bptr, #4]
  ldrsh.w poly3, [bptr, #6]

  mul.w tmp, poly1, poly3
  montgomerym3 q, qinv, tmp, tmp2
  mul.w tmp, tmp, zeta
  mla.w tmp, poly0, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  strh.w tmp, [rptr, #4]

  mul.w tmp, poly0, poly3
  mla.w tmp, poly1, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  strh.w tmp, [rptr, #6]

  pop.w {r4-r11, pc}

.unreq qinv

.global doublebasemul_asm_acc_m3
.type doublebasemul_asm_acc_m3, %function
.align 2
doublebasemul_asm_acc_m3:
  push.w {r4-r11, lr}

  rptr  .req r0
  aptr  .req r1
  bptr  .req r2
  zeta  .req r3
  poly0 .req r4
  poly1 .req r6
  poly2 .req r5
  poly3 .req r7
  q     .req r8
  qinv  .req r11
  tmp   .req r9
  tmp2  .req r10
  res0  .req r12
  res1  .req r14

  movw  q, #3329
  movw qinv, #3327

  ldrsh.w poly0, [aptr, #0]
  ldrsh.w poly1, [aptr, #2]
  ldrsh.w poly2, [bptr, #0]
  ldrsh.w poly3, [bptr, #2]
  ldrsh.w res0, [rptr, #0]
  ldrsh.w res1, [rptr, #2]

  mul.w tmp, poly1, poly3
  montgomerym3 q, qinv, tmp, tmp2
  mul.w tmp, tmp, zeta
  mla.w tmp, poly0, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  add.w res0, res0, tmp
  strh.w res0, [rptr, #0]

  mul.w tmp, poly0, poly3
  mla.w tmp, poly1, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  add.w res1, res1, tmp
  strh.w res1, [rptr, #2]

  neg.w zeta, zeta

  ldrsh.w poly0, [aptr, #4]
  ldrsh.w poly1, [aptr, #6]
  ldrsh.w poly2, [bptr, #4]
  ldrsh.w poly3, [bptr, #6]
  ldrsh.w res0, [rptr, #4]
  ldrsh.w res1, [rptr, #6]

  mul.w tmp, poly1, poly3
  montgomerym3 q, qinv, tmp, tmp2
  mul.w tmp, tmp, zeta
  mla.w tmp, poly0, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  add.w res0, res0, tmp
  strh.w res0, [rptr, #4]

  mul.w tmp, poly0, poly3
  mla.w tmp, poly1, poly2, tmp
  montgomerym3 q, qinv, tmp, tmp2
  add.w res1, res1, tmp
  strh.w res1, [rptr, #6]

  pop.w {r4-r11, pc}

.unreq qinv
.global basemul_asm_m3
.type basemul_asm_m3, %function
.align 2
basemul_asm_m3:
    push.w {r4-r11, lr}

    .unreq zeta
    rptr    .req r0
    aptr    .req r1
    bptr    .req r2
    zetaptr .req r3
    poly0   .req r4
    poly1   .req r6
    poly2   .req r5
    poly3   .req r7
    q       .req r8
    qinv    .req r11
    tmp     .req r9
    tmp2    .req r10
    zeta    .req r12
    loop    .req r14

    movw q, #3329
    movw qinv, #3327

    movw loop, #64
    1:
      ldrsh.w zeta, [zetaptr], #2

      ldrsh.w poly1, [aptr,  #2]
      ldrsh.w poly0, [aptr], #4
      ldrsh.w poly3, [bptr, #2]
      ldrsh.w poly2, [bptr], #4

      mul.w tmp, poly1, poly3
      montgomerym3 q, qinv, tmp, tmp2
      mul.w tmp, tmp, zeta
      mla.w tmp, poly0, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      strh.w tmp, [rptr], #2

      mul.w tmp, poly0, poly3
      mla.w tmp, poly1, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      strh.w tmp, [rptr], #2

      neg.w zeta, zeta

      ldrsh.w poly1, [aptr,  #2]
      ldrsh.w poly0, [aptr], #4
      ldrsh.w poly3, [bptr, #2]
      ldrsh.w poly2, [bptr], #4

      mul.w tmp, poly1, poly3
      montgomerym3 q, qinv, tmp, tmp2
      mul.w tmp, tmp, zeta
      mla.w tmp, poly0, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      strh.w tmp, [rptr], #2

      mul.w tmp, poly0, poly3
      mla.w tmp, poly1, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      strh.w tmp, [rptr], #2

      subs.w loop, #1
    bne.w 1b

    pop.w {r4-r11, pc}

.unreq qinv

.global basemul_asm_acc_m3
.type basemul_asm_acc_m3, %function
.align 2
basemul_asm_acc_m3:
    push.w {r4-r11, lr}

    rptr    .req r0
    aptr    .req r1
    bptr    .req r2
    zetaptr .req r3
    poly0   .req r4
    poly1   .req r6
    poly2   .req r5
    poly3   .req r7
    q       .req r8
    qinv    .req r11
    tmp     .req r9
    tmp2    .req r10
    zeta    .req r12
    loop    .req r14

    movw q, #3329
    movw qinv, #3327

    movw loop, #64
    1:
      ldrsh.w zeta, [zetaptr], #2

      ldrsh.w poly1, [aptr,  #2]
      ldrsh.w poly0, [aptr], #4
      ldrsh.w poly3, [bptr, #2]
      ldrsh.w poly2, [bptr], #4

      mul.w tmp, poly1, poly3
      montgomerym3 q, qinv, tmp, tmp2
      mul.w tmp, tmp, zeta
      mla.w tmp, poly0, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      ldrsh.w tmp2, [rptr]
      add.w tmp, tmp, tmp2
      strh.w tmp, [rptr], #2

      mul.w tmp, poly0, poly3
      mla.w tmp, poly1, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      ldrsh.w tmp2, [rptr]
      add.w tmp, tmp, tmp2
      strh.w tmp, [rptr], #2

      neg.w zeta, zeta

      ldrsh.w poly1, [aptr,  #2]
      ldrsh.w poly0, [aptr], #4
      ldrsh.w poly3, [bptr, #2]
      ldrsh.w poly2, [bptr], #4

      mul.w tmp, poly1, poly3
      montgomerym3 q, qinv, tmp, tmp2
      mul.w tmp, tmp, zeta
      mla.w tmp, poly0, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      ldrsh.w tmp2,[rptr]
      add.w tmp, tmp, tmp2
      strh.w tmp, [rptr], #2

      mul.w tmp, poly0, poly3
      mla.w tmp, poly1, poly2, tmp
      montgomerym3 q, qinv, tmp, tmp2
      ldrsh.w tmp2,[rptr]
      add.w tmp, tmp, tmp2
      strh.w tmp, [rptr], #2

      subs.w loop, #1
    bne.w 1b

    pop.w {r4-r11, pc}
