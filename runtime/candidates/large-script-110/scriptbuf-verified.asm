# patched sites
0004b9e8 bl #0x72da0  ->  bl #0x21beac
0004ba1c add x0, sp, #0x70  ->  mov x0, x23
0004ba28 add x0, sp, #0x70  ->  mov x0, x23
0004ba30 mov x0, #0x34  ->  bl #0x21bee8
0004bab8 add x1, x24, #0x10  ->  b #0x21bf0c
# stub
0021beac fd7bbea9 stp x29, x30, [sp, #-0x20]!
0021beb0 fd030091 mov x29, sp
0021beb4 e00b01a9 stp x0, x2, [sp, #0x10]
0021beb8 2000a0d2 mov x0, #0x10000
0021bebc a151f897 bl #0x30540
0021bec0 f70300aa mov x23, x0
0021bec4 2100a0d2 mov x1, #0x10000
0021bec8 600000b5 cbnz x0, #0x21bed4
0021becc f70b40f9 ldr x23, [sp, #0x10]
0021bed0 010084d2 mov x1, #0x2000
0021bed4 e00317aa mov x0, x23
0021bed8 e20f40f9 ldr x2, [sp, #0x18]
0021bedc b15bf997 bl #0x72da0
0021bee0 fd7bc2a8 ldp x29, x30, [sp], #0x20
0021bee4 c0035fd6 ret 
0021bee8 fd7bbfa9 stp x29, x30, [sp, #-0x10]!
0021beec e1030291 add x1, sp, #0x80
0021bef0 ff0201eb cmp x23, x1
0021bef4 60000054 b.eq #0x21bf00
0021bef8 e00317aa mov x0, x23
0021befc 9951f897 bl #0x30560
0021bf00 fd7bc1a8 ldp x29, x30, [sp], #0x10
0021bf04 800680d2 mov x0, #0x34
0021bf08 c0035fd6 ret 
0021bf0c e00317aa mov x0, x23
0021bf10 fc84ff97 bl #0x1fd300
0021bf14 f70305a9 stp x23, x0, [sp, #0x50]
0021bf18 e03300f9 str x0, [sp, #0x60]
0021bf1c e20318aa mov x2, x24
0021bf20 e10315aa mov x1, x21
0021bf24 e00315aa mov x0, x21
0021bf28 fabaf897 bl #0x4ab10
0021bf2c f80300aa mov x24, x0
0021bf30 e1c30191 add x1, sp, #0x70
0021bf34 ff0201eb cmp x23, x1
0021bf38 60000054 b.eq #0x21bf44
0021bf3c e00317aa mov x0, x23
0021bf40 8851f897 bl #0x30560
0021bf44 e40318aa mov x4, x24
0021bf48 f8bef817 b #0x4bb28
