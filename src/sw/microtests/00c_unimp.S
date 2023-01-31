// This tests that your processor treats the word 0xAAAAAAAA as an
// unimplemented instruction.
.text
start:
    .word 0xAAAAAAAA
    unimp
