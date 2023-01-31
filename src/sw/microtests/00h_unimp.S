// This tests that your processor treats the word 0x40109093, which looks like
// an SLLI instruction but has an incorrect funct7, as an unimplemented
// instruction.
.text
start:
    // 0100000 00001 00001 001 00001 0010011
    .word 0x40109093 // SLLI with invalid funct7
    unimp
