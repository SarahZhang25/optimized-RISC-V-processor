// This tests that your processor treats the all-0 word as an unimplemented
// instruction.
.text
start:
    .word 0
    unimp
