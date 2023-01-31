// This is an even more complex test that tests that your processor handles
// JALR (and LUI and ADDI) correctly.
.text
start:
    li x1, 0x1111
    li x2, 0x2222
    jalr x3,  0x123(x1) // A. jumps to 0x1234
    li x16, 1
    unimp

. = 0x1234
    jalr x4,   0x247(x1) // B. jumps to 0x1358
    jalr x10,  0x77f(x1) // H. jumps to 0x1890
    jalr x12, -0x672(x2) // J. jumps to 0x1bb0
    unimp

. = 0x1358
    jalr x5,   0x777(x1) // C. jumps to 0x1888
    jalr x9,   0x127(x1) // G. jumps to 0x1238
    jalr x14, -0x66e(x2) // L. jumps to 0x1bb4
    unimp

. = 0x1888
    jalr x6,  -0x676(x2) // D. jumps to 0x1bac
    jalr x8,   0x24b(x1) // F. jumps to 0x135c
    jalr x11,  0x12b(x1) // I. jumps to 0x123c
    unimp

. = 0x1bac
    jalr x7,   0x77b(x1) // E. jumps to 0x188c
    jalr x13,  0x24f(x1) // K. jumps to 0x1360
    jalr x15,    0x0(x3) // M. return to 0xc
    unimp
