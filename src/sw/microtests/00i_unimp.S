// This tests that your processor treats the word 0x40109093, which looks like
// an SRLI/SRAI instruction but has an incorrect funct7, as an unimplemented
// instruction.
.text
start:
    // 1000000 00001 00001 101 00001 0010011
    .word 0x8010d093 // SRLI/SRAI with invalid funct7
    unimp
