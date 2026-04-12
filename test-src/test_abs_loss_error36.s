.import ../src/utils.s
.import ../src/../coverage-src/abs_loss.s

.data

.globl main_test
.text
# main_test function for testing
main_test:

    # load 0 into a2
    li a2 0

    # call abs_loss function
    jal ra abs_loss
    # we expect abs_loss to exit early with code 36

    # exit normally
    li a0 0
    jal exit
