.text
.Lcheck:
    str xzr, [sp, #0xd8]
    str xzr, [sp, #0xe0]
    mov w1, #7
    b .Lcheck
