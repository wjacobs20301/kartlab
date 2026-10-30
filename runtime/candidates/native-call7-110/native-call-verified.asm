00041ecc b #0x40c60  ->  b #0x21bf4c
# stub
0021bf4c fd7bbba9 stp x29, x30, [sp, #-0x50]!
0021bf50 fd030091 mov x29, sp
0021bf54 f35301a9 stp x19, x20, [sp, #0x10]
0021bf58 f30300aa mov x19, x0
0021bf5c 4193f897 bl #0x40c60
0021bf60 d4030010 adr x20, #0x21bfd8
0021bf64 f41300f9 str x20, [sp, #0x20]
0021bf68 ffff02a9 stp xzr, xzr, [sp, #0x28]
0021bf6c ffff03a9 stp xzr, xzr, [sp, #0x38]
0021bf70 49008052 mov w9, #2
0021bf74 e9030139 strb w9, [sp, #0x40]
0021bf78 e00313aa mov x0, x19
0021bf7c 616d4810 adr x1, #0x2acd28
0021bf80 e2830091 add x2, sp, #0x20
0021bf84 03008052 mov w3, #0
0021bf88 040080d2 mov x4, #0
0021bf8c 690240f9 ldr x9, [x19]
0021bf90 292d40f9 ldr x9, [x9, #0x58]
0021bf94 20013fd6 blr x9
0021bf98 f41300f9 str x20, [sp, #0x20]
0021bf9c ffff02a9 stp xzr, xzr, [sp, #0x28]
0021bfa0 ffff03a9 stp xzr, xzr, [sp, #0x38]
0021bfa4 49008052 mov w9, #2
0021bfa8 e9030139 strb w9, [sp, #0x40]
0021bfac e00313aa mov x0, x19
0021bfb0 416e4870 adr x1, #0x2acd7b
0021bfb4 e2830091 add x2, sp, #0x20
0021bfb8 03008052 mov w3, #0
0021bfbc 040080d2 mov x4, #0
0021bfc0 690240f9 ldr x9, [x19]
0021bfc4 292d40f9 ldr x9, [x9, #0x58]
0021bfc8 20013fd6 blr x9
0021bfcc f35341a9 ldp x19, x20, [sp, #0x10]
0021bfd0 fd7bc5a8 ldp x29, x30, [sp], #0x50
0021bfd4 c0035fd6 ret 
0021bfd8 f00300aa mov x16, x0
0021bfdc e00301aa mov x0, x1
0021bfe0 e10302aa mov x1, x2
0021bfe4 e20303aa mov x2, x3
0021bfe8 e30304aa mov x3, x4
0021bfec e40305aa mov x4, x5
0021bff0 e50306aa mov x5, x6
0021bff4 e60307aa mov x6, x7
0021bff8 00021fd6 br x16
# RO 0x2acd28: u64 ptr_call(ptr_t, u64, u64, u64, u64, u64, u64, u64, float, float, float, float)
# RO 0x2acd7b: float ptr_callf(ptr_t, u64, u64, u64, u64, u64, u64, u64, float, float, float, float)
