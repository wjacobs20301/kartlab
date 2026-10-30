adrp x9, #0x3db000
add x9, x9, #0x88
mrs x10, tpidrro_el0
b #0x208044
ldaxr x11, [x9]
mov x12, x10
cbz x11, #0x208060
and x13, x11, #0xfffffffffffffff0
cmp x13, x10
b.ne #0x20806c
add x12, x11, #1
stxr w13, x12, [x9]
cbnz w13, #0x208044
ret
b #0x20bf50
adrp x9, #0x3db000
add x9, x9, #0x88
ldr x10, [x9]
tst x10, #0xf
b.eq #0x20bf48
sub x10, x10, #1
str x10, [x9]
ret
stlr xzr, [x9]
ret
clrex
adrp x11, #0x3d8000
ldr x12, [x11, #0xff0]
add x12, x12, #1
str x12, [x11, #0xff0]
mov x0, #0x1000
svc #0xb
b #0x203de0
