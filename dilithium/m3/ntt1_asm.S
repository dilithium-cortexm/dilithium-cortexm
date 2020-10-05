.syntax unified

//Schoolbook multiplication (smlal)
.macro const_mul32_acc acc0, acc1, a0, a1, b0, b1, tmp
  mul     \tmp, \a0, \b0
  adds    \acc0, \acc0, \tmp
  mul     \tmp, \a1, \b1
  adc     \acc1, \acc1, \tmp
  mul     \tmp, \a1, \b0
  mla     \tmp, \a0, \b1, \tmp
  adds    \acc0, \acc0, \tmp, lsl #16
  adc     \acc1, \acc1, \tmp, asr #16
.endm

//Schoolbook multiplication (smull)
.macro const_mul32 c0, c1, a0, a1, b0, b1, tmp
  mul     \c0, \a0, \b0
  mul     \c1, \a1, \b1
  mul     \tmp, \a1, \b0
  mla     \tmp, \a0, \b1, \tmp
  adds    \c0, \c0, \tmp, lsl #16
  adc     \c1, \c1, \tmp, asr #16
.endm

//Constant-time butterfly with Montgomery (schoolbook multiplication)
.macro ct_butterfly_montg_const pol0, pol1_l,pol1_h, zeta_l, zeta_h, ql, qh, qinv, th, tl, tmp
  const_mul32  \tl, \th, \pol1_l, \pol1_h, \zeta_l, \zeta_h, \tmp
  mul \pol1_h, \tl, \qinv
  ubfx \pol1_l, \pol1_h, #0, #16   //take lower 16b
  asr \pol1_h, \pol1_h, #16
  const_mul32_acc \tl, \th, \pol1_l, \pol1_h, \ql, \qh, \tmp
  sub \pol1_l, \pol0, \th
  add.w \pol0, \pol0, \th
.endm

.macro wrap_butterfly const, incr
  ldr.w pol0, [ptr_p]
  ldrh.w pol1_l, [ptr_p, #\const]
  ldrsh.w pol1_h, [ptr_p, #\const+2]
  ct_butterfly_montg_const pol0, pol1_l, pol1_h, zeta_l, zeta_h, ql, qh, qinv, temp_h, temp_l, temp
  str.w pol0, [ptr_p],#4+\incr     // p++
  //pol1 is now in pol1_l
  str.w pol1_l, [ptr_p, #\const-\incr-4]
.endm

.macro load_zeta     //2 time 16
  ldrh.w zeta_l,[ptr_zeta],#2
  ldrh.w zeta_h,[ptr_zeta],#2
.endm

//void ntt_asm_schoolbook(int32_t p[N], const uint32_t zetas_asm[N]);
.global ntt_asm_schoolbook
.type ntt_asm_schoolbook,%function
.align 2
ntt_asm_schoolbook:
  //bind aliases
  ptr_p     .req R0
  ptr_zeta  .req R1
  qinv    .req R2
  qh      .req R3
  cntr    .req R4
  pol0    .req R5
  pol1_h    .req R6
  pol1_l    .req R7
  ql      .req R8
  temp_h    .req R9
  temp_l    .req R10
  zeta_h      .req R11
  zeta_l      .req R12
  temp        .req R14

  //preserve registers
  push {r4-r11, r14}
  //load constants, ptr

  movw qinv, #:lower16:0xfc7fdfff
  movt qinv, #:upper16:0xfc7fdfff
  movw ql, #0xE001
  movw qh, #0x7F

  add ptr_zeta, #4  //&zeta[1]

/************************************
 *  Level 7-4 iterate inside blocks *
 ************************************/
//level 7
  movw cntr, #128
  load_zeta //zeta 1
  level_7:
    wrap_butterfly 512, 0
    subs.n cntr, #1
    bne.n level_7
  sub ptr_p, #512     //back to &p[0] -4*128

  //level 6
  movw cntr, #64
  load_zeta  //zeta 2
  level_6_1:
    wrap_butterfly 256, 0
    subs.n cntr, #1
    bne.n level_6_1
  add ptr_p,#256                //&p[128] (+64*4)

  movw cntr, #64
  load_zeta //zeta 3
  level_6_2:
    wrap_butterfly 256, 0
    subs.n cntr, #1
    bne.n level_6_2
  sub ptr_p, #768          //back to &p[0]  -4*192

  //level 5
  movw cntr, #32
  load_zeta //zeta 4
  level_5_1:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_1
  add ptr_p,#128               //&p[64] +32*4

  movw cntr, #32
  load_zeta //zeta 5
  level_5_2:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_2
  add ptr_p,#128               //&p[128] + 32*4

  movw cntr, #32
  load_zeta //zeta 6
  level_5_3:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_3
  add ptr_p,#128               //&p[192] + 32*4

  movw cntr, #32
  load_zeta //zeta 7
  level_5_4:
    wrap_butterfly 128, 0
    subs.n cntr, #1
    bne.n level_5_4
  sub ptr_p, #896     //back to &p[0]  -4*224

  //level 4
  movw cntr, #16
  load_zeta //zeta 8
  level_4_1:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_1
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 9
  level_4_2:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_2
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 10
  level_4_3:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_3
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 11
  level_4_4:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_4
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 12
  level_4_5:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_5
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 13
  level_4_6:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_6
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 14
  level_4_7:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_7
  add ptr_p,#64               //&p[64] +16*4

  movw cntr, #16
  load_zeta //zeta 15
  level_4_8:
    wrap_butterfly 64, 0
    subs.n cntr, #1
    bne.n level_4_8
  sub ptr_p,#960              //back to &p[0]  -240*4

/************************************
 *  Level 3-0 iterate over blocks   *
 ************************************/

  //level 3
  movw cntr, #16
  level_3:
    load_zeta    //zeta 16-31
    .rept 7
      wrap_butterfly 32, 0
    .endr
    wrap_butterfly 32, 32
    subs.w cntr, #1
    bne.w level_3
  sub ptr_p, #1024      //256*4

  //level 2
  movw cntr, #32
  level_2:
    load_zeta    //zeta 32-63
    .rept 3
      wrap_butterfly 16, 0
    .endr
    wrap_butterfly 16, 16
    subs.w cntr, #1
    bne.w level_2
  sub ptr_p, #1024      //256*4

  //level 1
  movw cntr, #64
  level_1:
    load_zeta    //zeta 64-127
    wrap_butterfly 8, 0
    wrap_butterfly 8, 8
    subs.n cntr, #1
    bne.n level_1
  sub ptr_p, #1024      //256*4

  //level 0
  movw cntr, #128
  level_0:
    load_zeta    //zeta 128-255
    wrap_butterfly 4, 4
    subs.n cntr, #1
    bne.n level_0

  //restore registers
  pop {r4-r11, pc}

  //unbind aliases
  .unreq ptr_p
  .unreq ptr_zeta
  .unreq qinv
  .unreq qh
  .unreq cntr
  .unreq pol0
  .unreq pol1_h
  .unreq pol1_l
  .unreq ql
  .unreq temp_h
  .unreq temp_l
  .unreq zeta_h
  .unreq zeta_l
  .unreq temp

