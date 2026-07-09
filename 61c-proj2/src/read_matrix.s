.globl read_matrix

.text
# ==============================================================================
# FUNCTION: Allocates memory and reads in a binary file as a matrix of integers
#
# FILE FORMAT:
#   The first 8 bytes are two 4 byte ints representing the # of rows and columns
#   in the matrix. Every 4 bytes afterwards is an element of the matrix in
#   row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is a pointer to an integer, we will set it to the number of rows
#   a2 (int*)  is a pointer to an integer, we will set it to the number of columns
# Returns:
#   a0 (int*)  is the pointer to the matrix in memory
# Exceptions:
#   - If malloc returns an error,
#     this function terminates the program with error code 26
#   - If you receive an fopen error or eof,
#     this function terminates the program with error code 27
#   - If you receive an fclose error or eof,
#     this function terminates the program with error code 28
#   - If you receive an fread error or eof,
#     this function terminates the program with error code 29
# ==============================================================================
read_matrix:

    # Prologue
    #ra s0 s1 s2 s3 s4
    addi sp,sp,-32
    sw ra,0(sp)
    sw s0,4(sp)
    sw s1,8(sp)
    sw s2,12(sp)
    sw s3,16(sp)
    sw s4,20(sp)
    
    mv s0,a0 #s0=filename
    mv s1,a1 #s1=row1_ptr
    mv s2,a2 #s2=cols_ptr
    
    #fopen
    mv a0,s0
    li a1,0 #only read
    jal fopen
    li t0 -1
    beq a0,t0,error_27
    mv s0,a0

    #fread
    mv a0,s0
    mv a1,s1 #rows
    li a2,4
    jal fread
    li t0 4
    bne a0 t0 error_29
    
    mv a0,s0 
    mv a1,s2 #columns
    li a2,4
    jal fread
    li t0 4
    bne a0 t0 error_29

    #malloc
    lw t0,0(s1)
    lw t1 0(s2)
    mul t2,t0,t1
    slli t2,t2,2
    mv s4,t2

    mv a0,s4
    jal malloc
    beq a0,x0,error_26
    mv s3,a0

    #read_matrix
    mv a0,s0
    mv a1,s3
    mv a2,s4
    jal fread
    bne a0,s4,error_29

    #close the file
    mv a0,s0
    jal fclose
    li t0,-1
    beq a0,t0,error_28

    # Epilogue
    mv a0,s3
    lw ra,0(sp)
    lw s0,4(sp)
    lw s1,8(sp)
    lw s2,12(sp)
    lw s3,16(sp)
    lw s4,20(sp)
    addi sp,sp,32
    ret


error_26:
    li a0,26
    j exit

error_27:
    li a0,27
    j exit
error_28:
    li a0,28
    j exit
error_29:
    li a0,29
    j exit

    jr ra
