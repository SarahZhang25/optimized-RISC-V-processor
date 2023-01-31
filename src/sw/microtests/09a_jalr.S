// This is a minimal test that tests that your processor handles JALR (and
// ADDI) correctly.
.text
start:
    li x1, 0xc     // 0x00
    jalr x2, 0(x1) // 0x04
    unimp          // 0x08
    li x3, 1       // 0x0c
    unimp          // 0x10
