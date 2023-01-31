// This is a minimal test that tests that your processor handles SW (and ADDI
// and LW) correctly.
.text
start:
    li x1, 0x1000
    li x2, 0x87654321
    sw x2, 0(x1)
    lw x3, 0(x1)
    unimp
