0021abd0 adrp x2, #0x3d1000
0021abd4 nop
0021abd8 mov x5, sp
0021abdc add x1, x0, x1
0021abe0 nop
0021abe4 nop
0021abe8 nop
0021abec cmp x1, x2
0021abf0 b.hi #0x21abfc
0021abf4 str x1, [x4, #0x328]
0021abf8 ret
0021abfc mov w0, #0xc
0021ac00 str w0, [x3]
0021ac04 mov x0, #-1
0021ac08 ret
0021ac0c adrp x0, #0x2d9000
0021ac10 nop
0021ac14 nop
0021ac18 nop
0021ac1c str x0, [x4, #0x328]
0021ac20 b #0x21abd0
