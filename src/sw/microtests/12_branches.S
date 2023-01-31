// This is a test that tests that your processor handles all the BRANCH
// instructions correctly.
.text
start:
    li x1, 1
    li x2, 2
    li x3, -1
    bne x1, x1, wrong
    li x4, 1
    beq x1, x2, wrong
    li x5, 1
    blt x1, x1, wrong
    li x6, 1
    blt x2, x1, wrong
    li x7, 1
    blt x1, x3, wrong
    li x8, 1
    bge x1, x2, wrong
    li x9, 1
    bge x3, x1, wrong
    li x10, 1
    bltu x1, x1, wrong
    li x11, 1
    bltu x2, x1, wrong
    li x12, 1
    bltu x3, x2, wrong
    li x13, 1
    bgeu x1, x2, wrong
    li x14, 1
    bgeu x2, x3, wrong
    li x15, 1

    beq x1, x1, a
    unimp
a:  li x16, 1
    bne x1, x2, b
    unimp
b:  li x17, 1
    blt x1, x2, c
    unimp
c:  li x18, 1
    blt x3, x1, d
    unimp
d:  li x19, 1
    bge x2, x1, e
    unimp
e:  li x20, 1
    bge x1, x1, f
    unimp
f:  li x21, 1
    bge x1, x3, g
    unimp
g:  li x22, 1
    bltu x1, x2, h
    unimp
h:  li x23, 1
    bltu x2, x3, i
    unimp
i:  li x24, 1
    bgeu x1, x1, j
    unimp
j:  li x25, 1
    bgeu x2, x1, k
    unimp
k:  li x26, 1
    bgeu x3, x2, done
    unimp

done:
    li x27, 1
    unimp

wrong:
    unimp
