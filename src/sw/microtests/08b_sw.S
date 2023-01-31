// This is a more complex test that tests that your processor handles SW (and
// ADDI, AUIPC, and LW) correctly.
.text
start:
    la x1, e

    // test positive offsets
    li x2, 15
    sw x2, 0(x1) // address of e

    li x2, 10
    sw x2, 4(x1) // address of f

    li x2, 5
    sw x2, 8(x1)  // address of g

    li x2, 0
    sw x2, 12(x1) // address of h

    // test negative offsets
    li x2, 1
    sw x2, -4(x1) // address of d

    li x2, 2
    sw x2, -8(x1) // address of c

    // test large offsets
    li x3, 0x810

    li x2, 100
    sw x2, 0x7f0(x3) // address of a

    li x2, 200
    sw x2, 0x7f4(x3) // address of b

    // check
    lw x2, 0(x1)   // e
    lw x3, 4(x1)   // f
    lw x4, 8(x1)   // g
    lw x5, 12(x1)  // h
    lw x6, -4(x1)  // d
    lw x7, -8(x1)  // c
    lw x8, -12(x1) // b
    lw x9, -16(x1) // a
    unimp

.data
a:      .word 0
b:      .word 1
c:      .word 52
d:      .word -215
e:      .word 17
f:      .word 59
g:      .word 12
h:      .word -16

