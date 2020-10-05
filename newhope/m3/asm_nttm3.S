.syntax unified
.thumb
.macro montgomerym3 q, qinv, a, tmp
    mul \tmp, \a, \qinv
    sxth.w \tmp, \tmp
    mla \a, \tmp, \q, \a
    asr.w \a, \a, #16
.endm
.macro butterflym3 a0, a1, twiddle, q, qinv, tmp
    mul \a1, \a1, \twiddle
    mul \tmp, \a1, \qinv
    sxth.w \tmp, \tmp
    mla \tmp, \tmp, \q, \a1
    sub.w \a1, \a0, \tmp, asr#16
    add.w \a0, \a0, \tmp, asr#16
.endm

.macro unsigned_barrettm3 a, q, tmp, barrettconst
  mul \tmp, \a, \barrettconst
  asr.w \tmp, \tmp, #28
  mls \a, \tmp, \q, \a
.endm

.macro signed_barrettm3 a, q, tmp, barrettconst
  mul \tmp, \a, \barrettconst
  add.w \tmp, \tmp, #134217728
  asr.w \tmp, \tmp, #28
  mla \a, \tmp, \q, \a
.endm


.global asm_ntt_m3
.type asm_ntt_m3,%function
.align 2
asm_ntt_m3:
  push.w    {r4-r11, r14}

  poly        .req r0
  twiddle_ptr .req r1
  poly0       .req r2
  poly1       .req r3
  poly2       .req r4
  poly3       .req r5
  poly4       .req r6
  poly5       .req r7
  poly6       .req r8
  poly7       .req r9
  twiddle     .req r10
  montconst   .req r10
  barrettconst .req r10
  qinv        .req r11
  q           .req r14
  tmp         .req r12
  tmp2        .req r14

  movw q, #12289
  movw qinv, #12287

  movw tmp, #128
  1:
    push.w {tmp}
    ldrsh.w twiddle, [twiddle_ptr]
    ldrsh.w poly0, [poly, #0]
    ldrsh.w poly1, [poly, #1*2]
    ldrsh.w poly2, [poly, #2*2]
    ldrsh.w poly3, [poly, #3*2]
    ldrsh.w poly4, [poly, #4*2]
    ldrsh.w poly5, [poly, #5*2]
    ldrsh.w poly6, [poly, #6*2]
    ldrsh.w poly7, [poly, #7*2]

    // STAGE 1
    butterflym3 poly0, poly1, twiddle, q, qinv, tmp
    butterflym3 poly2, poly3, twiddle, q, qinv, tmp
    butterflym3 poly4, poly5, twiddle, q, qinv, tmp
    butterflym3 poly6, poly7, twiddle, q, qinv, tmp

    // STAGE 2
    ldrsh.w twiddle, [twiddle_ptr, #2]
    butterflym3 poly0, poly2, twiddle, q, qinv, tmp
    butterflym3 poly4, poly6, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr, #4]
    butterflym3 poly1, poly3, twiddle, q, qinv, tmp
    butterflym3 poly5, poly7, twiddle, q, qinv, tmp

    movw barrettconst, #43692
    sxth.w barrettconst, barrettconst
    signed_barrettm3 poly0, q, tmp, barrettconst
    signed_barrettm3 poly1, q, tmp, barrettconst
    signed_barrettm3 poly2, q, tmp, barrettconst
    signed_barrettm3 poly3, q, tmp, barrettconst
    //signed_barrettm3 poly4, q, tmp, barrettconst
    //signed_barrettm3 poly5, q, tmp, barrettconst
    //signed_barrettm3 poly6, q, tmp, barrettconst
    //signed_barrettm3 poly7, q, tmp, barrettconst

    // STAGE 3
    ldrsh.w twiddle, [twiddle_ptr, #6]
    butterflym3 poly0, poly4, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr, #8]
    butterflym3 poly1, poly5, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr, #10]
    butterflym3 poly2, poly6, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr, #12]
    butterflym3 poly3, poly7, twiddle, q, qinv, tmp

    strh.w poly1, [poly, #1*2]
    strh.w poly2, [poly, #2*2]
    strh.w poly3, [poly, #3*2]
    strh.w poly4, [poly, #4*2]
    strh.w poly5, [poly, #5*2]
    strh.w poly6, [poly, #6*2]
    strh.w poly7, [poly, #7*2]
    strh.w poly0, [poly], #16
    pop.w {tmp}
    subs tmp, #1
  bne.w 1b


  sub.w poly, #2048
  add.w twiddle_ptr, #14

  mov.w tmp, #16
  1:
    push.w {tmp}
    mov.w tmp, #8
    2:
      push.w {tmp}
      ldrsh.w twiddle, [twiddle_ptr]
      ldrsh.w poly0, [poly, #0]
      ldrsh.w poly1, [poly, #1*16]
      ldrsh.w poly2, [poly, #2*16]
      ldrsh.w poly3, [poly, #3*16]
      ldrsh.w poly4, [poly, #4*16]
      ldrsh.w poly5, [poly, #5*16]
      ldrsh.w poly6, [poly, #6*16]
      ldrsh.w poly7, [poly, #7*16]

      // STAGE 4
      butterflym3 poly0, poly1, twiddle, q, qinv, tmp
      butterflym3 poly2, poly3, twiddle, q, qinv, tmp
      butterflym3 poly4, poly5, twiddle, q, qinv, tmp
      butterflym3 poly6, poly7, twiddle, q, qinv, tmp

      movw barrettconst, #43692
      sxth.w barrettconst, barrettconst
      signed_barrettm3 poly0, q, tmp, barrettconst
      signed_barrettm3 poly1, q, tmp, barrettconst
      //signed_barrettm3 poly2, q, tmp, barrettconst
      //signed_barrettm3 poly3, q, tmp, barrettconst
      signed_barrettm3 poly4, q, tmp, barrettconst
      signed_barrettm3 poly5, q, tmp, barrettconst
      //signed_barrettm3 poly6, q, tmp, barrettconst
      //signed_barrettm3 poly7, q, tmp, barrettconst


      // STAGE 5
      ldrsh.w twiddle, [twiddle_ptr, #2]
      butterflym3 poly0, poly2, twiddle, q, qinv, tmp
      butterflym3 poly4, poly6, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #4]
      butterflym3 poly1, poly3, twiddle, q, qinv, tmp
      butterflym3 poly5, poly7, twiddle, q, qinv, tmp

      // STAGE 6
      ldrsh.w twiddle, [twiddle_ptr, #6]
      butterflym3 poly0, poly4, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #8]
      butterflym3 poly1, poly5, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #10]
      butterflym3 poly2, poly6, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #12]
      butterflym3 poly3, poly7, twiddle, q, qinv, tmp


      movw barrettconst, #43692
      sxth.w barrettconst, barrettconst
      signed_barrettm3 poly0, q, tmp, barrettconst
      signed_barrettm3 poly1, q, tmp, barrettconst
      signed_barrettm3 poly2, q, tmp, barrettconst
      signed_barrettm3 poly3, q, tmp, barrettconst
      signed_barrettm3 poly4, q, tmp, barrettconst
      signed_barrettm3 poly5, q, tmp, barrettconst
      signed_barrettm3 poly6, q, tmp, barrettconst
      signed_barrettm3 poly7, q, tmp, barrettconst

      strh.w poly1, [poly, #1*16]
      strh.w poly2, [poly, #2*16]
      strh.w poly3, [poly, #3*16]
      strh.w poly4, [poly, #4*16]
      strh.w poly5, [poly, #5*16]
      strh.w poly6, [poly, #6*16]
      strh.w poly7, [poly, #7*16]
      strh.w poly0, [poly], #2
      add.w twiddle_ptr, #2+4+8
      pop.w {tmp}
      subs tmp, #1
      bne.w 2b
      add.w poly, #7*16
      sub.w twiddle_ptr, #8*(2+4+8)
    pop.w {tmp}
    subs tmp, #1
    bne.w 1b

  sub.w poly, #2048
  add.w twiddle_ptr, #8*(2+4+8)
  mov.w tmp, #2
  1:
    push.w {tmp}
    mov.w tmp, #64
    2:
      push.w {tmp}
      ldrsh.w twiddle, [twiddle_ptr]
      ldrsh.w poly0, [poly, #0]
      ldrsh.w poly1, [poly, #1*128]
      ldrsh.w poly2, [poly, #2*128]
      ldrsh.w poly3, [poly, #3*128]
      ldrsh.w poly4, [poly, #4*128]
      ldrsh.w poly5, [poly, #5*128]
      ldrsh.w poly6, [poly, #6*128]
      ldrsh.w poly7, [poly, #7*128]
      // STAGE 7
      butterflym3 poly0, poly1, twiddle, q, qinv, tmp
      butterflym3 poly2, poly3, twiddle, q, qinv, tmp
      butterflym3 poly4, poly5, twiddle, q, qinv, tmp
      butterflym3 poly6, poly7, twiddle, q, qinv, tmp

      // STAGE 8
      ldrsh.w twiddle, [twiddle_ptr, #2]
      butterflym3 poly0, poly2, twiddle, q, qinv, tmp
      butterflym3 poly4, poly6, twiddle, q, qinv, tmp

      ldrsh.w twiddle, [twiddle_ptr, #4]
      butterflym3 poly1, poly3, twiddle, q, qinv, tmp
      butterflym3 poly5, poly7, twiddle, q, qinv, tmp

      movw barrettconst, #43692
      sxth.w barrettconst, barrettconst
      signed_barrettm3 poly0, q, tmp, barrettconst
      signed_barrettm3 poly1, q, tmp, barrettconst
      signed_barrettm3 poly2, q, tmp, barrettconst
      signed_barrettm3 poly3, q, tmp, barrettconst
      //signed_barrettm3 poly4, q, tmp, barrettconst
      //signed_barrettm3 poly5, q, tmp, barrettconst
      //signed_barrettm3 poly6, q, tmp, barrettconst
      //signed_barrettm3 poly7, q, tmp, barrettconst

      // STAGE 9
      ldrsh.w twiddle, [twiddle_ptr, #6]
      butterflym3 poly0, poly4, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #8]
      butterflym3 poly1, poly5, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #10]
      butterflym3 poly2, poly6, twiddle, q, qinv, tmp
      ldrsh.w twiddle, [twiddle_ptr, #12]
      butterflym3 poly3, poly7, twiddle, q, qinv, tmp

      strh.w poly1, [poly, #1*128]
      strh.w poly2, [poly, #2*128]
      strh.w poly3, [poly, #3*128]
      strh.w poly4, [poly, #4*128]
      strh.w poly5, [poly, #5*128]
      strh.w poly6, [poly, #6*128]
      strh.w poly7, [poly, #7*128]
      strh.w poly0, [poly], #2
      add.w twiddle_ptr, #2+4+8
      pop.w {tmp}
      subs tmp, #1
      bne.w 2b
      add.w poly, #7*128
      sub.w twiddle_ptr, #64*(2+4+8)
    pop.w {tmp}
    subs tmp, #1
    bne.w 1b
  sub.w poly, #2048
  add.w twiddle_ptr, #64*(2+4+8)

  mov.w tmp, #128
  1:
    push.w {tmp}
    ldrsh.w poly0, [poly, #0]
    ldrsh.w poly1, [poly, #2]
    ldrsh.w poly2, [poly, #4]
    ldrsh.w poly3, [poly, #6]
    ldrsh.w poly4, [poly, #1024]
    ldrsh.w poly5, [poly, #1026]
    ldrsh.w poly6, [poly, #1028]
    ldrsh.w poly7, [poly, #1030]

    // STAGE 10
    ldrsh.w twiddle, [twiddle_ptr], #2
    butterflym3 poly0, poly4, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr], #2
    butterflym3 poly1, poly5, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr], #2
    butterflym3 poly2, poly6, twiddle, q, qinv, tmp
    ldrsh.w twiddle, [twiddle_ptr], #2
    butterflym3 poly3, poly7, twiddle, q, qinv, tmp

    movw barrettconst, #21844
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
    strh.w poly4, [poly, #1024]
    strh.w poly5, [poly, #1026]
    strh.w poly6, [poly, #1028]
    strh.w poly7, [poly, #1030]
    strh.w poly0, [poly], #8
    pop.w {tmp}
    subs tmp, #1
    bne.w 1b
  pop.w {r4-r11, pc}
