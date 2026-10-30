0021bd80 600240f9 ldr x0, [x19]
0021bd84 88040010 adr x8, #0x21be14
0021bd88 82060050 adr x2, #0x21be5a
0021bd8c 21060010 adr x1, #0x21be50
0021bd90 07008052 mov w7, #0
0021bd94 06008052 mov w6, #0
0021bd98 050080d2 mov x5, #0
0021bd9c 64008052 mov w4, #3
0021bda0 e3630191 add x3, sp, #0x58
0021bda4 095840f9 ldr x9, [x0, #0xb0]
0021bda8 e00313aa mov x0, x19
0021bdac e8ff05a9 stp x8, xzr, [sp, #0x58]
0021bdb0 ffff06a9 stp xzr, xzr, [sp, #0x68]
0021bdb4 6a008052 mov w10, #3
0021bdb8 eae30139 strb w10, [sp, #0x78]
0021bdbc 20013fd6 blr x9
0021bdc0 8002f837 tbnz w0, #0x1f, #0x21be10
0021bdc4 600240f9 ldr x0, [x19]
0021bdc8 48030010 adr x8, #0x21be30
0021bdcc a2050030 adr x2, #0x21be81
0021bdd0 01040010 adr x1, #0x21be50
0021bdd4 07008052 mov w7, #0
0021bdd8 06008052 mov w6, #0
0021bddc 050080d2 mov x5, #0
0021bde0 64008052 mov w4, #3
0021bde4 e3630191 add x3, sp, #0x58
0021bde8 095840f9 ldr x9, [x0, #0xb0]
0021bdec e00313aa mov x0, x19
0021bdf0 e8ff05a9 stp x8, xzr, [sp, #0x58]
0021bdf4 ffff06a9 stp xzr, xzr, [sp, #0x68]
0021bdf8 6a008052 mov w10, #3
0021bdfc eae30139 strb w10, [sp, #0x78]
0021be00 20013fd6 blr x9
0021be04 6000f837 tbnz w0, #0x1f, #0x21be10
0021be08 f92340f9 ldr x25, [sp, #0x40]
0021be0c d58cf817 b #0x3f160
0021be10 e18cf817 b #0x3f194
0021be14 280500f0 adrp x8, #0x2c2000
0021be18 08b540f9 ldr x8, [x8, #0x168]
0021be1c 082540f9 ldr x8, [x8, #0x48]
0021be20 899f8952 mov w9, #0x4cfc
0021be24 490fa072 movk w9, #0x7a, lsl #16
0021be28 1001098b add x16, x8, x9
0021be2c 00021fd6 br x16
0021be30 fd7bbea9 stp x29, x30, [sp, #-0x20]!
0021be34 fd030091 mov x29, sp
0021be38 e007022d stp s0, s1, [sp, #0x10]
0021be3c e21b00bd str s2, [sp, #0x18]
0021be40 e1430091 add x1, sp, #0x10
0021be44 f4ffff97 bl #0x21be14
0021be48 fd7bc2a8 ldp x29, x30, [sp], #0x20
0021be4c c0035fd6 ret 
