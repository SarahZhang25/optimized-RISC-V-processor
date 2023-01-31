// This is test 1 of 2 that tests that your processor handles all the OP
// instructions correctly.
.text
start:
    li x1, 17
    li x2, 3
    add  x3 , x1, x2
    sub  x4 , x1, x2
    slt  x5 , x1, x2
    sltu x6 , x1, x2
    slt  x7 , x2, x1
    sltu x8 , x2, x1
    sll  x9 , x1, x2
    srl  x10, x1, x2
    sra  x11, x1, x2
    and  x12, x1, x2
    or   x13, x1, x2
    xor  x14, x1, x2

    li x16, -17
    li x17, -29
    add  x18, x16, x17
    sub  x19, x16, x17
    slt  x20, x16, x17
    sltu x21, x16, x17
    slt  x22, x17, x16
    sltu x23, x17, x16
    sll  x24, x16, x17
    srl  x25, x16, x17
    sra  x26, x16, x17
    and  x27, x16, x17
    or   x28, x16, x17
    xor  x29, x16, x17
    unimp
