.globl relu

.text
# ==============================================================================
# FUNCTION: Performs an inplace element-wise ReLU on an array of ints
# Arguments:
#   a0 (int*) is the pointer to the array
#   a1 (int)  is the # of elements in the array
# Returns:
#   None
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# ==============================================================================
relu:
    # Prologue
    li t0 1
    bge a1,t0,start_logic
    li a0 36
    j exit

start_logic:
    li t0,0
loop_start:
    beq t0,a1,loop_end
    lw t2,0(a0)
    bge t2,x0,skip_zero
    li t2,0
skip_zero:
    sw t2,0(a0)
    addi a0,a0,4
    addi t0,t0,1
    j loop_start
loop_continue:



loop_end:


    # Epilogue


    jr ra
