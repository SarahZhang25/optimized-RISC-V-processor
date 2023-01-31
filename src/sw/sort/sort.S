#include "src/defines.h"
.section ".text.init"
    .globl sort
    .globl kth_smallest
    .globl violation

/*

QUICKSORT & PARTITION

C implementation (for reference)

int partition(int* p, int start, int end) {
    int x = p[end]; // select pivot
    int j, tmp, i = start - 1;
    for (j = start; j < end; j++) {
        if (p[j] <= x) {
            i++;
            tmp = p[i];
            p[i] = p[j];
            p[j] = tmp;
        }
    }
    tmp = p[i + 1];
    p[i + 1] = p[end];
    p[end] = tmp;
    return i + 1;
}

void quicksort(int* p, int start, int end) {
    if (start < end) {
        int q = partition(p, start, end);
        quicksort(p, start, q - 1);
        quicksort(p, q + 1, end);
    }
}

Python implementation (for reference)

def partition(p, start, end):
    x = p[end]
    i = (start - 1)
    for j in range(start, end):
        if p[j] <= x:
            i = i + 1
            tmp = p[i]
            p[i] = p[j]
            p[j] = tmp

    tmp = p[i + 1]
    p[i + 1] = p[end]
    p[end] = tmp
    return i + 1

def quicksort(p, start, end):
    if start < end:
        q = partition(p, start, end)
        quicksort(p, start, q - 1)
        quicksort(p, q + 1, end)

*/

//  QUICKSORT (should call "partition")
//
//  Inputs:
//  a0 = p (address of array)
//  a1 = start
//  a2 = end

sort:
  slli a1, a1, 2
  slli a2, a2, 2
  add a1, a1, a0
  add a2, a2, a0
  li t1, 48

sortwrapper:
  bge a1, a2, endsort // pass if start >= end

  sub a5, a2, a1 // len of arr
  bge a5, t1, above_threshold_for_isort

// insertion sort
  addi a3, a1, 4 // a3 == addr( 1st ele of array )
isort_outer:
  bgt a3, a2, endsort

  lw a6, 0(a3) // A[i]
  addi a4, a3, -4 // j = i-1

isort_inner:
  lw a7, 0(a4) // A[j]
  blt a4, a1, end_isort_inner // if j < 0
  ble a7, a6, end_isort_inner

  sw a7, 4(a4) // A[j+1] <= A[j]
  addi a4, a4, -4 // j = j-1

  j isort_inner // loop

end_isort_inner:

  sw a6, 4(a4) // A[j+1] <= A[i]
  addi a3, a3, 4 //

  j isort_outer



above_threshold_for_isort:


  // CC: save ra, a0-a2
  addi sp, sp, -12
  sw a2, 4(sp)
  sw ra, 0(sp)

  // partition(p, start, end)
  //call hpartition
hpartition:
  add t0, a1, a2
  srli t0, t0, 3
  slli t0, t0, 2
  lw t0, 0(t0) // pivot val

  // left/right index
  addi a3, a1, -4 //  lo - 1
  addi a4, a2, 4 // hi + 1
  
  // loop forever
hloop:
  //while loops
inc_i:
  addi a3, a3, 4 // i = i + 1
  lw a6, 0(a3) // arr[i]
  blt a6, t0, inc_i // arr[i] < pivot

dec_j:
  addi a4, a4, -4 // j = j - 1 
  lw a7, 0(a4)
  bgt a7, t0, dec_j // arr{j] > pivot

//if indices cross, return j
  bge a3, a4, end_hloop

// swap A{i] and A[j]
  sw a6, 0(a4)
  sw a7, 0(a3)

  j hloop

end_hloop:
  // CC: save a4
  sw a4, 8(sp) 

  // CC: restore saved values
  lw ra, 0(sp)

  // quicksort(p, start, q-1)
  addi a2, a4, 0 // set a2 = q-1
  call sortwrapper

  // CC: restore saved values 
  lw a4, 8(sp)
  lw ra, 0(sp)
  lw a2, 4(sp)
  addi sp, sp, 12

  // tail call elim
  addi a1, a4, 4 // set start = partition result + 1

  j sortwrapper

endsort:
  ret

/*
// HOARSE PARTITION
hpartition:
  add t0, a1, a2
  srli t0, t0, 3
  slli t0, t0, 2
  lw a5, 0(t0) // pivot val

  // left/right index
  addi a3, a1, -4 //  lo - 1
  addi a4, a2, 4 // hi + 1
  
  // loop forever
hloop:
  //while left ind < pivot
inc_i:
  addi a3, a3, 4 // i = i + 1
//inc_i_while:
  lw a6, 0(a3) // arr[i]
  blt a6, a5, inc_i // arr[i] < pivot

dec_j:
  addi a4, a4, -4 // j = j - 1 
//dec_j_while:
  lw a7, 0(a4)
  bgt a7, a5, dec_j // arr{j] > pivot

//if indices cross, return j
  bge a3, a4, end_hloop

// swap A{i] and A[j]
  sw a6, 0(a4)
  sw a7, 0(a3)

  j hloop

end_hloop:
  mv a0, a4 // move j to a0 to return
  ret
*/


/*
// PARTITION
//
// Inputs:
// a0 = starting address of the array = p
// a1 = index of the starting element = start
// a2 = index of the ending element = end
partition:
  // get mem address of p[end]
  slli a2, a2, 2 // a2 = end * 4 =  offset from a0
  add a2, a2, a0 // addr(p[end])
  lw a5, 0(a2) // a5 = x = pivot

  addi a3, a1, -1 // set i = start-1
  //mv a1, a3 	 // save i in a3
  slli a3, a3, 2 // get mem  offset 
  add a3, a3, a0 // addr(p[i])

  addi a4, a3, 4 // j  = address(p[start-1])+4

ploop:
  beq a4, a2, end_ploop // end when addr(p[j]) == addr(p[end]) <=> j == end

  lw a7, 0(a4) // a7 = p[j]
  
  // swap condition
  bgt a7, a5, postswap// skip if p[j] > x 
  addi a3, a3, 4 // increment addr(p[i]) 
  //addi a1, a1, 1 // increment i

  // swap p[i], p[j]
  lw a6, 0(a3) // a6 = p[i]
  sw a6, 0(a4) // p[i] = p[j]
  sw a7, 0(a3) // p[j] = p[i]

postswap:
  addi a4, a4, 4 // j++ <=> addr(p[j]) + 4
  j ploop

end_ploop:
  // swap p[i+1], p[end]
  addi a3, a3, 4 // a3 = addr(p[i+1])
  //addi a1, a1, 1 // i++
  
  lw a6, 0(a3)  
  sw a5, 0(a3) 
  sw a6, 0(a4)

  sub a0, a3, a0 
  srli a0, a0, 2
  // put i+1 in a0
  //mv a0, a1
  ret

*/

/*

Kth SMALLEST

Python implementation (for reference)

# array is the sorted array from sort
# gets index k from the user and prints array[k]
# returns nothing

def kth_smallest(array):
    x = input("enter the index to print\n")
    print array[x]
    return

*/

//  Input:  a0 = address of sorted array
kth_smallest:
  li a1, 0x40004000 // setup for intake from Console
  lw a2, 0(a1) // gets word typed into Console

  slli a2, a2, 2 // offset = a2 * 4
  add a2, a0, a2 // addr(p[k])
  lw a2, 0(a2) // a2 = p[k]

  li a1, 0x40000004 // setup for printing to Console
  sw a2, 0(a1) // print p[k] to console

  ret
