// This tests that your processor treats the word 0x00000083, which looks like
// an LW instruction but has an incorrect funct3, as an unimplemented
// instruction.
.text
start:
    // 0000 0000 0000 00000 000 00001 0000011
    .word 0x00000083 // LW with invalid funct3
    unimp
