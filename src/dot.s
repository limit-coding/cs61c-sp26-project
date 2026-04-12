.globl dot

.text
# =======================================================
# FUNCTION: Dot product of 2 int arrays
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the number of elements to use
#   a3 (int)  is the stride of arr0
#   a4 (int)  is the stride of arr1
# Returns:
#   a0 (int)  is the dot product of arr0 and arr1
# Exceptions:
#   - If the number of elements to use is less than 1,
#     this function terminates the program with error code 36
#   - If the stride of either array is less than 1,
#     this function terminates the program with error code 37
# =======================================================
dot:

    # Prologue
    li t0,1
    blt a2,t0,error_36
    blt a3,t0,error_37
    blt a4,t0,error_37
    
    li t0,0
    li t1,0
    slli t2,a3,2
    slli t3,a4,2
loop_start:
    bge t1,a2,loop_end
    lw t4,0(a0)
    lw t5,0(a1)
    mul t6 t4 t5
    add t0 t0 t6
    add a0 a0 t2
    add a1,a1,t3
    addi t1,t1,1
    j loop_start

loop_end:
    mv a0,t0

    # Epilogue


    jr ra
    

error_36:
    li a0,36
    j exit

error_37:
    li a0,37
    j exit
