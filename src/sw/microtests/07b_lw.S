// This is a more complex test that tests that your processor handles LW (and
// AUIPC and ADDI) correctly.
.text
start:
    la x1, e // pseudoinstruction that puts the address of label e into x1
    lw x2, 0(x1)
    lw x3, 4(x1)
    lw x4, 8(x1)
    lw x5, 12(x1)
    lw x6, -4(x1)
    lw x7, -8(x1)
    lw x8, -12(x1)
    lw x9, -16(x1)
    addi x10, x1, -0x800
    lw x11, 0x7F0(x10) // should match the address of a
    lw x12, 0x7F4(x10)
    lw x13, 0x7F8(x10)
    lw x14, 0x7FC(x10)
    unimp

.data
. = 0x1000
a:      .word 0
b:      .word 1
c:      .word 52
d:      .word -215
e:      .word 17
f:      .word 59
g:      .word 12
h:      .word -16

