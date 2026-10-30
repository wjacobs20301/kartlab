// Exact pinned-module derivative. Code is position independent after the
// builder fixes three external module-relative instructions.
.text
.p2align 2
.global binding_entry
binding_entry:
    ldr x0, [x19]
    adr x8, .Langular_vec
    adr x2, .Ldecl_vec
    adr x1, .Lbody
    mov w7, #0
    mov w6, #0
    mov x5, #0
    mov w4, #3
    add x3, sp, #0x58
    ldr x9, [x0, #0xb0]
    mov x0, x19
    stp x8, xzr, [sp, #0x58]
    stp xzr, xzr, [sp, #0x68]
    mov w10, #3
    strb w10, [sp, #0x78]
    blr x9
    tbnz w0, #31, .Lerror
    ldr x0, [x19]
    adr x8, .Langular_xyz
    adr x2, .Ldecl_xyz
    adr x1, .Lbody
    mov w7, #0
    mov w6, #0
    mov x5, #0
    mov w4, #3
    add x3, sp, #0x58
    ldr x9, [x0, #0xb0]
    mov x0, x19
    stp x8, xzr, [sp, #0x58]
    stp xzr, xzr, [sp, #0x68]
    mov w10, #3
    strb w10, [sp, #0x78]
    blr x9
    tbnz w0, #31, .Lerror
    ldr x25, [sp, #0x40]
.global binding_return
binding_return:
    .inst 0
.Lerror:
.global binding_error
binding_error:
    .inst 0
.Langular_vec:
.global binding_main_page
binding_main_page:
    .inst 0
    ldr x8, [x8, #0x168]
    ldr x8, [x8, #0x48]
    mov w9, #0x4cfc
    movk w9, #0x7a, lsl #16
    add x16, x8, x9
    br x16
.Langular_xyz:
    stp x29, x30, [sp, #-0x20]!
    mov x29, sp
    stp s0, s1, [sp, #0x10]
    str s2, [sp, #0x18]
    add x1, sp, #0x10
    bl .Langular_vec
    ldp x29, x30, [sp], #0x20
    ret
.Lbody: .asciz "RigidBody"
.Ldecl_vec: .asciz "void setAngularVel(const Vector3f &in)"
.Ldecl_xyz: .asciz "void setAngularVel(float, float, float)"
