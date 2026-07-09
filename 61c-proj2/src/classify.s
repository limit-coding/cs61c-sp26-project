.globl classify

.text
# =====================================
# COMMAND LINE ARGUMENTS
# =====================================
# Args:
#   a0 (int)        argc
#   a1 (char**)     argv
#   a1[1] (char*)   pointer to the filepath string of m0
#   a1[2] (char*)   pointer to the filepath string of m1
#   a1[3] (char*)   pointer to the filepath string of input matrix
#   a1[4] (char*)   pointer to the filepath string of output file
#   a2 (int)        silent mode, if this is 1, you should not print
#                   anything. Otherwise, you should print the
#                   classification and a newline.
# Returns:
#   a0 (int)        Classification
# Exceptions:
#   - If there are an incorrect number of command line args,
#     this function terminates the program with exit code 31
#   - If malloc fails, this function terminates the program with exit code 26
#
# Usage:
#   main.s <M0_PATH> <M1_PATH> <INPUT_PATH> <OUTPUT_PATH>
classify:
    li t0,5
    beq a0,t0,check_args_ok
    li a0,31
    j exit

check_args_ok:
    addi sp,sp,-64
    sw ra,0(sp)
    sw s0,4(sp)
    sw s1,8(sp)
    sw s2,12(sp)
    sw s3,16(sp)
    sw s4,20(sp)
    sw s5,24(sp)
    sw s6,28(sp)
    sw s7,32(sp)
    sw s8,36(sp)
    sw s9,40(sp)
    sw s10,44(sp)
    sw s11,48(sp)
    
    sw a2 52(sp)     #print_flag(a2)
    
    mv s0,a0  #argc
    mv s1,a1  #argv
    

    # Read pretrained m0

    lw a0,4(s1)    #(argv[1]) 
    addi a1,sp,56 #row
    addi a2,sp,60 #col
    jal ra,read_matrix

    mv s3,a0

    lw s4,56(sp)   #s4=m0_rows
    lw s5,60(sp)   #s5=m0_cols


    # Read pretrained m1
    # (argv[2])
    lw a0,8(s1)   
    addi a1,sp,56 #row
    addi a2,sp,60 #col
    jal ra,read_matrix
    mv s6,a0
    lw s7,56(sp)
    lw s8,60(sp)

    # Read input matrix
    # (argv[3])
    lw a0,12(s1)               
    addi a1,sp,56 #row
    addi a2,sp,60 #col
    jal ra,read_matrix
    mv s9,a0
    lw s10,56(sp)
    lw s11,60(sp)

    # Compute h = matmul(m0, input)
    mul a0,s4,s11
    slli a0,a0,2
    jal ra,malloc
    beq a0,x0,malloc_errror
    mv s2,a0

    mv a0,s3
    mv a1,s4
    mv a2,s5
    mv a3,s9
    mv a4,s10
    mv a5,s11
    mv a6,s2
    jal ra,matmul

    # Compute h = relu(h)
    mv a0,s2
    mul a1,s4,s11
    jal ra relu

    # Compute o = matmul(m1, h)
    mul a0,s7,s11
    slli a0,a0,2
    jal ra malloc
    beq a0,x0,malloc_errror
    mv s0,a0

    mv a0,s6
    mv a1,s7
    mv a2,s8
    mv a3,s2
    mv a4,s4
    mv a5,s11
    mv a6,s0
    jal ra,matmul

    # Write output matrix o
    lw a0,16(s1)
    mv a1,s0
    mv a2,s7
    mv a3,s11
    jal ra,write_matrix

    # Compute and return argmax(o)
    mv a0,s0
    mul a1,s7,s11
    jal ra,argmax
    mv s1,a0

    # If enabled, print argmax(o) and newline
    lw t0,52(sp)
    bne t0,x0,skip_print
    mv a0,s1
    jal ra,print_int
    li a0,'\n'
    jal ra print_char

skip_print:
    mv a0,s3
    jal ra,free
    mv a0,s6
    jal ra,free
    mv a0,s9
    jal ra,free
    mv a0,s2
    jal ra,free
    mv a0,s0
    jal ra,free
    
    mv a0,s1

    lw ra 0(sp)
    lw s0 4(sp)
    lw s1 8(sp)
    lw s2 12(sp)
    lw s3 16(sp)
    lw s4 20(sp)
    lw s5 24(sp)
    lw s6 28(sp)
    lw s7 32(sp)
    lw s8 36(sp)
    lw s9 40(sp)
    lw s10 44(sp)
    lw s11 48(sp)
    addi sp sp 64
    ret


malloc_errror:
    li a0 26
    j exit

    jr ra
