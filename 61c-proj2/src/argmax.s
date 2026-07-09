.globl argmax

.text
# =================================================================
# FUNCTION: Given a int array, return the index of the largest
#   element. If there are multiple, return the one
#   with the smallest index.
# Arguments:
#   a0 (int*) is the pointer to the start of the array
#   a1 (int)  is the # of elements in the array
# Returns:
#   a0 (int)  is the first index of the largest element
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# =================================================================
argmax:
    # Prologue
    li t0,1
    bge a1,t0,start_logic
    addi a0,x0,36
    j exit

start_logic:
    
    li t0 0
    lw t1 0(a0)
    li t2 0
    li t3 0
loop_start:
    
    beq t0,a1,loop_end
    lw t3,0(a0)
    bge t1 t3 jump
    mv t1 t3
    mv t2 t0
    
jump:
    addi a0 a0 4
    addi t0 t0 1
    j loop_start
loop_continue:


loop_end:
    # Epilogue
    mv a0,t2
    jr ra
