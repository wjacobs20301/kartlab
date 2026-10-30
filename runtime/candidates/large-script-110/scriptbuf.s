// Exact pinned-module derivative of angular-velocity-110 (subsdk9 b0dc2c3b...).
// pushExecLocalFileModule (text 0x4b7c0) reads scripts into a stack char[0x2000]
// at sp+0x70. These stubs read into a 64 KiB buffer from the AngelScript engine
// heap instead (asAllocImpl -> engineHeap->tryAlloc), pass it to
// buildOnceOrGetModule as a non-owning std::string (only c_str() is used and
// AddScriptSection copies), then free it. If the allocation fails, the original
// stack buffer and 0x2000 limit are used, so the worst case is the old behaviour.
// x23 is saved at 0x4b83c and restored on every exit (0x4b974, 0x4bb2c) but is
// otherwise unused by the function; it carries the buffer pointer.
// Every `.word 0` placeholder is a call/branch the builder fills in.
.equ BUFSIZE, 0x10000
.text
.p2align 2

// Replaces `bl readTextFile` at 0x4b9e8. In: x0 = caller sp+0x70, x2 = path.
.global read_stub
read_stub:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x0, x2, [sp, #16]
    mov x0, #BUFSIZE
.global call_alloc
call_alloc:
    .word 0                     // bl asAllocImpl
    mov x23, x0
    mov x1, #BUFSIZE
    cbnz x0, 1f
    ldr x23, [sp, #16]          // allocation failed: original stack buffer
    mov x1, #0x2000
1:  mov x0, x23
    ldr x2, [sp, #24]
.global call_read
call_read:
    .word 0                     // bl readTextFile
    ldp x29, x30, [sp], #32
    ret

// Replaces `mov x0, #0x34` at 0x4ba30 (read-error path, after the message print).
.global error_stub
error_stub:
    stp x29, x30, [sp, #-16]!
    add x1, sp, #0x80           // caller sp+0x70
    cmp x23, x1
    b.eq 2f
    mov x0, x23
.global call_free_error
call_free_error:
    .word 0                     // bl asFreeImpl
2:  ldp x29, x30, [sp], #16
    mov x0, #0x34
    ret

// Branched to from 0x4bab8 (read succeeded). x21 = filename, x24 = sp+0x50.
.global success_stub
success_stub:
    mov x0, x23
.global call_strlen
call_strlen:
    .word 0                     // bl strlen
    stp x23, x0, [sp, #0x50]    // std::string{ptr=buf, size=len}
    str x0, [sp, #0x60]         // capacity=len (never freed by the caller)
    mov x2, x24
    mov x1, x21
    mov x0, x21
.global call_build
call_build:
    .word 0                     // bl buildOnceOrGetModule
    mov x24, x0
    add x1, sp, #0x70
    cmp x23, x1
    b.eq 3f
    mov x0, x23
.global call_free_ok
call_free_ok:
    .word 0                     // bl asFreeImpl
3:  mov x4, x24
.global success_return
success_return:
    .word 0                     // b 0x4bb28 (cbz x4 -> build-failed path)
