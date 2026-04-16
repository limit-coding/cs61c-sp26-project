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

在 RISC-V 中，寄存器的命名有两种方式：一种是**编号（x0-x31）**，另一种是**别名（如 s0, a0, t0）**。

`s` 系列寄存器（Saved Registers）在神经网络这个项目里被赋予了特定的“逻辑身份”。为了让你更有参与感，我把它们分为三类来解释：

### 1. 核心指针类（Memory Anchors）
这几个寄存器保存的是矩阵在**堆（Heap）**内存中的首地址。你可以把它们想象成指向大脑不同“知识区”的指针。

| 寄存器 | 逻辑含义 | 为什么用 `s`？ |
| :--- | :--- | :--- |
| **`s3`** | **矩阵 $m0$ 的首地址** | $m0$ 是第一层权重，在整个 `classify` 运行期间都需要访问它，必须用 `s` 寄存器保护起来。 |
| **`s6`** | **矩阵 $m1$ 的首地址** | 第二层权重，逻辑同上。 |
| **`s9`** | **`input` 矩阵的首地址** | 用户输入的数据，是所有运算的起点。 |
| **`s2`** | **中间层 $h$ 的首地址** | 它是第一层算的输出，又是第二层的输入。 |
| **`s0`** | **输出层 $o$ 的首地址** | 最终算出的原始得分（Scores），靠它来做最后的 `argmax`。 |

---

### 2. 维度管理类（Dimension Metadata）
神经网络最怕的就是“维度不匹配”（Dimension Mismatch）。这几个寄存器记录了矩阵的形状。

| 寄存器 | 对应含义 | 协作关系 |
| :--- | :--- | :--- |
| **`s4`, `s5`** | **$m0$ 的行数和列数** | $s5$ 必须等于 $input$ 的行数 ($s10$)，否则 `matmul` 会出错。 |
| **`s7`, `s8`** | **$m1$ 的行数和列数** | $s8$ 必须等于 $h$ 的列数。 |
| **`s10`, `s11`** | **$input$ 的行数和列数** | 决定了输入图片的规模。 |

---

### 3. 状态与结果类（State & Result）
| 寄存器 | 逻辑含义 |
| :--- | :--- |
| **`s1`** | **最终结果 / 临时暂存** | 在代码最后，它存的是 `argmax` 算出来的那个数字（比如 `2`）。 |
| **`s0`** | **argc (初始状态)** | 程序刚开始时 `s0` 存的是命令行参数个数。但因为寄存器紧缺，我们在算出 $o$ 指针后覆盖了它。 |

---

### 深入思考：为什么非要用 `s` 寄存器？

这是你在这个项目里最有“参与感”的地方——**契约精神**。

在 RISC-V 调用约定中：
* **`a` (Argument) 和 `t` (Temporary) 寄存器**：是“公共汽车”。你调用一次 `matmul` 或 `malloc`，里面的值就可能被人家改得面目全非。
* **`s` (Saved) 寄存器**：是“私人包间”。根据规定，如果你调用了一个函数（比如 `read_matrix`），这个函数在返回时，必须保证 `s` 寄存里的值和进去前一模一样。

**想象一下：**
如果你用 `t0` 存矩阵 $m0$ 的指针，然后调用 `malloc` 给 $h$ 开空间。`malloc` 内部为了计算内存大小，极大概率会随手把 `t0` 改成别的值。等你从 `malloc` 回来，想拿 `t0` 去算乘法时，发现指针丢了！程序直接崩溃。



所以，你在 `classify.s` 开头写的那一长串 `sw s0, s1...`，其实是在**买保险**：
1.  **保存**：先把调用者（main函数）的数据存到栈里。
2.  **尽情使用**：在 `classify` 内部你可以放心大胆地用 `s0-s11` 存指针。
3.  **恢复**：走之前用 `lw` 把人家原来的值还回去。


classify:
    li t0,5
    beq a0,t0,check_args_ok
    li a0,31
    j exit

check_args_ok:
##1.栈帧分配和上下文保存
    addi sp,sp,-64
    sw ra,0(sp)  #返回地址，否则执行jal以后回不到main
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
    
    sw a2 52(sp)     #print_flag(a2)存入栈中，a2稍后会被替代
    
    mv s0,a0  #argc s0=argc
    mv s1,a1  #argv s1=argv
     

    # Read pretrained m0

    lw a0,4(s1)    #(a0=argv[1]) 
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
    mv s9,a0   #s9是指针
    lw s10,56(sp)  #s10=行
    lw s11,60(sp)  #s11=列


    # ------------------------------------------------------------------
    # 3. 第一层运算：Hidden Layer = ReLU(m0 * input)
    # ------------------------------------------------------------------
    # Compute h = matmul(m0, input)
    mul a0,s4,s11  # h_rows = m0_rows(s4), h_cols = input_cols(s11)
    slli a0,a0,2
    jal ra,malloc
    beq a0,x0,malloc_errror  # 健壮性检查：内存分配失败直接跳走
    mv s2,a0  # s2 = h 指针

    # 执行矩阵乘法 h = m0 * input
    mv a0,s3  # 矩阵 A: m0
    mv a1,s4  # rows A
    mv a2,s5  # cols A
    mv a3,s9  # 矩阵 B: input
    mv a4,s10 # rows B
    mv a5,s11 # cols B
    mv a6,s2 # 目标地址: h
    jal ra,matmul

    # Compute h = relu(h)
    # 执行 ReLU 激活：h = max(0, h)
    mv a0,s2  # 传入 h 的指针
    mul a1,s4,s11 # 传入元素总数
    jal ra relu  # ReLU 是原位(In-place)修改，不产生新内存

    # Compute o = matmul(m1, h)
    # ------------------------------------------------------------------
    # 4. 第二层运算：Output Layer = m1 * h
    # ------------------------------------------------------------------
    mul a0,s7,s11  # o_rows = m1_rows(s7), o_cols = h_cols(s11)
    slli a0,a0,2
    jal ra malloc
    beq a0,x0,malloc_errror
    mv s0,a0  # s0 = o 指针

    mv a0,s6  # 矩阵 A: m1
    mv a1,s7 # rows A
    mv a2,s8  # cols A
    mv a3,s2  # 矩阵 B: h
    mv a4,s4  # rows B (即 m0_rows)
    mv a5,s11  # cols B
    mv a6,s0  # 目标地址: o
    jal ra,matmul


    # ------------------------------------------------------------------
    # 5. 结果处理与收尾 (Result & Cleanup)
    # ------------------------------------------------------------------
    # Write output matrix o
    lw a0,16(s1)  # a0 = argv[4] (输出路径)
    mv a1,s0     # 矩阵指针
    mv a2,s7     # 行数
    mv a3,s11    # 行数
    jal ra,write_matrix



    # 计算分类索引：argmax(o)
    # Compute and return argmax(o)
    mv a0,s0  # o 矩阵指针
    mul a1,s7,s11 # 元素个数
    jal ra,argmax
    mv s1,a0  # s1 = 最终预测的数字 (0-9)

    # If enabled, print argmax(o) and newline
    # 判断是否静默模式
    lw t0,52(sp)  # 从栈里取回保存的 a2 (print_flag)
    bne t0,x0,skip_print
    mv a0,s1
    jal ra,print_int  # 打印分类数字
    li a0,'\n'
    jal ra print_char  # 打印换行

skip_print:
# 内存释放：这是底层开发的必修课。Python有GC，汇编全靠你自己。
    mv a0,s3 # 释放 m0
    jal ra,free
    mv a0,s6 # 释放 m1
    jal ra,free
    mv a0,s9 # 释放 input
    jal ra,free
    mv a0,s2 # 释放隐藏层 h
    jal ra,free
    mv a0,s0 # 释放输出层 o
    jal ra,free
    
    mv a0,s1 # 设置返回值 (a0 是规定的返回值寄存器)


    # 恢复环境：把刚才存在栈里的东西全部原样搬回寄存器
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


