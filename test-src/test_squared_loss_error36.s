.import ../src/utils.s
.import ../src/../coverage-src/squared_loss.s

.data

.globl main_test
.text
# main_test function for testing
main_test:

    # load 0 into a2
    li a2 0

    # call squared_loss function
    jal ra squared_loss
    # we expect squared_loss to exit early with code 36

    # exit normally
    li a0 0
    jal exit
