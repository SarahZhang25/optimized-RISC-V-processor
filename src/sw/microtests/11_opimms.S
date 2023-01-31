// This is a test that tests that your processor handles all the OPIMM
// instructions correctly.
.text
start:
    li x1, 0x123
    addi x2, x1, -0x321
    andi x3, x2, -0xab
    ori  x4, x3, 0xf0
    xori x5, x4, 0xcd
    slli x6, x5, 3
    srai x7, x6, 4
    srli x8, x7, 5

    slti  x9 , x7, 0
    sltiu x10, x7, 0
    slti  x11, x7, -1
    sltiu x12, x7, -1
    slti  x13, x7, -0x800
    sltiu x14, x7, -0x800
    slti  x15, x7, 0x7ff
    sltiu x16, x7, 0x7ff

    slti  x17, x10, 0
    sltiu x18, x10, 0
    slti  x19, x10, -1
    sltiu x20, x10, -1
    slti  x21, x10, -0x800
    sltiu x22, x10, -0x800
    slti  x23, x10, 0x7ff
    sltiu x24, x10, 0x7ff
