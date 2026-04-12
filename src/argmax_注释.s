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
    li,a0,36
    j exit
start_logic:
    li t0,0            #初始化这么来做，t0是计数器，也是数组索引
    lw t1 0(a0)        #这里t1读取存储在a0的数组值，也就是a[0]，t1将成为max_value
    li t2,0            #t2是max_index的值，就是最大值到底是多少
loop_start:
    beq t0,a1,loop_end    #超出索引了，要结束了
    lw t3,0(a0)           #读取t3，t3就是遍历数组的东西
    bge t1,t3,skip_update #如果t1>=t3,说明t1是大的，不应该换，直接跳过
    mv t1,t3             #执行到这，说明t1<t3,那么直接t1=t3 这是更新值
    mv t2,t0             #这里也是 t2=t0,这是更新索引

skip_update:
    addi t0,t0,1        #跳过也得继续增加计数器
    addi a0,a0,4
    j loop_start
loop_continue:
    

loop_end:
    # Epilogue
    mv a0,t2         #这句话是a0=t2,把最终的索引确定下来，t2就是max_index,a0是真正的数组索引
    jr ra
