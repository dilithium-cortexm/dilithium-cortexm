.syntax unified

//Schoolbook multiplication (smull)
.macro const_mul32_acc acc0, acc1, a0, a1, b0, b1, tmp
  mul.w     \tmp, \a0, \b0
  adds.w    \acc0, \acc0, \tmp
  mul.w     \tmp, \a1, \b1
  adc.w     \acc1, \acc1, \tmp
  mul.w     \tmp, \a1, \b0
  mla.w     \tmp, \a0, \b1, \tmp
  adds.w    \acc0, \acc0, \tmp, lsl #16
  adc.w     \acc1, \acc1, \tmp, asr #16
.endm

//Schoolbook multiplication (smlal)
.macro const_mul32 c0, c1, a0, a1, b0, b1, tmp
  mul     \c0, \a0, \b0
  mul     \c1, \a1, \b1
  mul     \tmp, \a1, \b0
  mla     \tmp, \a0, \b1, \tmp
  adds    \c0, \c0, \tmp, lsl #16
  adc     \c1, \c1, \tmp, asr #16
.endm

//Schoolbook multiplication 32x16 (smlal)
.macro const_mul32x16 c0, c1, a0, a1, b0, tmp
  mul \c0, \a0, \b0
  mul \tmp, \a1, \b0
  movw \c1, #0
  adds \c0, \c0, \tmp, lsl #16
  adc  \c1, \c1, \tmp, asr #16
.endm

.macro gs_butterfly_montg pol0, pol1, zeta_l, zeta_h, ql, qh, qinv, tmp1, tmp2, tmp3, tmp_q
  sub \tmp1, \pol0 ,\pol1
  add.w \pol0, \pol0, \pol1
  ubfx \tmp3, \tmp1, #0, #16   //low16(tmp1)
  asr \tmp1, \tmp1, #16        //high16(tmp1)
  const_mul32 \tmp2, \pol1, \tmp3, \tmp1, \zeta_l, \zeta_h, \tmp_q
  mul \tmp1, \tmp2, \qinv
  ubfx \tmp3, \tmp1, #0, #16   //low16(tmp1)
  asr \tmp1, \tmp1, #16       //high16(tmp1)
  const_mul32_acc  \tmp2, \pol1, \tmp3, \tmp1, \ql, \qh, \tmp_q
.endm

// Montgomery reduction
.macro montg_red f, pol, ql, qh, qinv, t0, t1, pol_l, pol_h
  ubfx \pol_l, \pol, #0, #16
  asr \pol_h, \pol, #16
  const_mul32x16 \t1, \pol, \pol_l, \pol_h, \f, \t0
  mul \t0,\t1,\qinv
  ubfx \pol_l, \t0, #0, #16
  asr \pol_h, \t0, #16
  const_mul32_acc \t1, \pol, \pol_l, \pol_h, \ql, \qh, \t0
.endm

//handle butterfly
.macro wrap_butterfly const, incr
  ldr.w pol0, [ptr_p]
  ldr.w pol1, [ptr_p, #\const]
  gs_butterfly_montg pol0, pol1, zeta_l, zeta_h, ql, qh, qinv, temp_1, temp_2, temp_3, temp_q
  str.w pol0, [ptr_p],#4+\incr     // p++
  str.w pol1, [ptr_p, #\const-4-\incr]
.endm

.macro load_zeta     //2 time 16
  ldrh zeta_l,[ptr_zeta],#2
  ldrsh zeta_h,[ptr_zeta],#2
.endm

//void inv_ntt_asm_schoolbook(int32_t p[N], const uint32_t zetas_inv_asm[N]);
.global inv_ntt_asm_schoolbook
.type inv_ntt_asm_schoolbook,%function
.align 2
inv_ntt_asm_schoolbook:
  //bind aliases
  ptr_p     .req R0
  ptr_zeta  .req R1
  qinv      .req R2
  ql        .req R3
  cntr      .req R4
  pol0      .req R5
  pol1      .req R6
  qh        .req R7
  temp_1    .req R8
  temp_2    .req R9
  temp_3    .req R10
  zeta_l    .req R11
  zeta_h    .req R12
  temp_q    .req R14

  //preserve registers
  push {R4-R11, R14}
  //load constants, ptr
  ldr qinv, inv_ntt_asm_neg_qinv_signed  //-qinv_signed
  movw ql ,#0xE001  //q = 8380417
  movw qh ,#0x7F

  /************************************
  *  Level 0-3 iterate over blocks *
  ************************************/

  //level 0
  movw cntr, #128
  level_0:
    load_zeta    //zeta 0-127
    wrap_butterfly 4, 4
    subs.n cntr, #1
    bne.n level_0
  sub ptr_p, #1024      //256*4


  //level 1
  movw cntr, #64
  level_1:
    load_zeta     //zeta 128-191
    wrap_butterfly 8, 0
    wrap_butterfly 8, 8
    subs.n cntr, #1
    bne.n level_1
  sub ptr_p, #1024      //256*4

  //level 2
  movw cntr, #32
  level_2:
    load_zeta     //zeta 192-223
    .rept 3
      wrap_butterfly 16, 0
    .endr
    wrap_butterfly 16, 16
    subs.w cntr, #1
    bne.w level_2
  sub ptr_p, #1024      //256*4


  //level 3
  movw cntr, #16
  level_3:
    load_zeta     //zeta 224-239
    .rept 7
      wrap_butterfly 32, 0
    .endr
    wrap_butterfly 32, 32
    subs.w cntr, #1
    bne.w level_3
  sub ptr_p, #1024      //256*4

  /************************************
  *  Level 4-7 iterate inside blocks *
  ************************************/
  //level 4
  load_zeta  //zeta 240
  movw cntr, #16
  level_4_1:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_1
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 241
  movw cntr, #16
  level_4_2:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_2
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 242
  movw cntr, #16
  level_4_3:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_3
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 243
  movw cntr, #16
  level_4_4:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_4
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 244
  movw cntr, #16
  level_4_5:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_5
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 245
  movw cntr, #16
  level_4_6:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_6
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 246
  movw cntr, #16
  level_4_7:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_7
  add.w ptr_p, ptr_p, #64

  load_zeta  //zeta 247
  movw cntr, #16
  level_4_8:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_8
  sub.w ptr_p, ptr_p, #960

   //level 5
  load_zeta  //zeta 248
  movw cntr, #32
  level_5_1:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_1
  add ptr_p, ptr_p, #128

  load_zeta  //zeta 249
  movw cntr, #32
  level_5_2:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_2
  add ptr_p, ptr_p, #128

  load_zeta  //zeta 250
  movw cntr, #32
  level_5_3:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_3
  add ptr_p, ptr_p, #128

  load_zeta  //zeta 251
  movw cntr, #32
  level_5_4:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_4
  sub ptr_p, ptr_p, #896

  //level 6
  load_zeta  //zeta 252
  movw cntr, #64
  level_6_1:
    wrap_butterfly 256, 0
    subs.n cntr, #1
    bne.n level_6_1
  add ptr_p, ptr_p, #256

  load_zeta  //zeta 253
  movw cntr, #64
  level_6_2:
    wrap_butterfly 256, 0
    subs.n cntr, #1
    bne.n level_6_2
  sub ptr_p, ptr_p, #768

   //level 7
  load_zeta  //zeta 254
  .unreq ptr_zeta
  f .req R1
  movw cntr, #128

  movw f, #41978 //=0xA3FA  used for final montgomery reduction
  level_7:
    ldr.w pol0, [ptr_p]
    ldr.w pol1, [ptr_p, #512]   //p + 128*4
    gs_butterfly_montg pol0, pol1, zeta_l, zeta_h, ql, qh, qinv, temp_1, temp_2, temp_3, temp_q
    add temp_3,ql,qh, lsl #16
    montg_red f, pol0, ql, qh, qinv, temp_1, temp_2, temp_3, temp_q

    // We can save the multiplication by f here by instead pre-computing it and putting it into the
    // twiddle factor of the previous butterfly
    // zeta is 3975713 instead of 8354570 (3975713 = (8354570 * 16382) % Q)

    //montg_red f, pol1, ql, qh, qinv, temp_1, temp_2, temp_3, temp_q
    str.w pol0, [ptr_p], #4
    str.w pol1, [ptr_p, #508]
    subs.n cntr, #1
    bne.n level_7

  //restore registers
  pop {R4-R11, PC}

  //unbind aliases
  .unreq ptr_p
  .unreq f
  .unreq qinv
  .unreq ql
  .unreq cntr
  .unreq pol0
  .unreq pol1
  .unreq qh
  .unreq temp_1
  .unreq temp_2
  .unreq temp_3
  .unreq zeta_l
  .unreq zeta_h
  .unreq temp_q

.align 2
inv_ntt_asm_neg_qinv_signed:
.word 0xfc7fdfff
