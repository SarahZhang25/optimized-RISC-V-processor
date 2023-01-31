// This tests that your processor treats the word 0x80000033, which looks like
// an ADD instruction but has an incorrect funct7, as an unimplemented
// instruction.
.text
start:
    .word 0x80000033 // looks like an add instruction, but really isn't
    unimp
