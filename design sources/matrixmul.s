.data

v: .word

.text

##this instruction can be left out for our hardware version!
la x6, v #not needed for our RISC-V

###this section starts by filling the I and W matrices. 
addi x1, x0, 0  # i = 0
addi x4, x0, 20 #matrix 1 ==> 20 elements
addi x5, x0, 15 #matrix 2 ==> 15 elements
addi x31, x0, 2 #shift for word address

# loop
loop_m1:
    sll x2, x1, x31  #i ==> word address 'SSLI does not exist'
    addi x1, x1, 1 # i = i+1    
### you can leave out the following two lines in the hardware version, 
##and replace it with following single line, as x6 is not used for us!
## sw x1, 0(x2)     
    add x3, x2, x6 #address in memory
    sw x1, 0(x3)
    bne x4, x1, loop_m1


addi x7, x0, 0 #j
loop_m2:
    sll x2, x1, x31  #i ==> word address 'SSLI does not exist'
    addi x1, x1, 1 # i = i+1   
    sub x8, x5, x7  
    addi x7, x7, 1 # j = j+1      
### you can leave out the following two lines in the hardware version, 
##and replace it with following single line, as x6 is not used for us!
## sw x8, 0(x2)     
    add x3, x2, x6 #address in memory
    sw x8, 0(x3)
    bne x5, x7, loop_m2  #return to loop m2

addi x9, x9, 0
addi x10, x10, 1

##matrix multiply
## set all registers!

# Memory layout of the matrices (all elements are 32-bit words, byte addresses, 4 bytes per element):
#   I (4x5) row-major    : I[b][c] at x20 + 4*(5*b+c)   b=0..3, c=0..4   (x20 = 0)
#   W (5x3) column-major : W[c][k] at x21 + 4*(5*k+c)   c=0..4, k=0..2   (x21 = 80)
#   O (4x3) row-major    : O[b][k] at x22 + 4*(3*b+k)   b=0..3, k=0..2   (x22 = 140)
# Reference results: O[0][0] = 185 at byte address 140; O[3][2] = 260 at byte address 184 (= 140 + 4*11).
addi x20, x0, 0  # I input address starting point
addi x21, x0, 80 # W input address starting point
addi x22, x0, 140 # O output address starting point
addi x4, x0, 5   # C loop size
addi x5, x0, 3   #k loop size
addi x11, x0, 4   #B loop size
addi x23, x0, 0  ## C loop index starts with 0
addi x24, x0, 0  ## K loop index starts with 0
addi x25, x0, 0  ## B loop index starts with 0
addi x10, x0, 0  ## acc result

####### we don't need to have the next three lines in our HW version!!
add x20, x20, x6
add x21, x21, x6
add x22, x22, x6


#### Program starts!! 
addi x27, x0, 1  ##program start          

##### START COUNTING CYCLES FROM HERE (in HW version!!!)
### as long as x27 = high!
## INSERT YOUR OWN CODE HERE!
## Do not change the code above!






#######  STOP COUNTING CYCLES 
addi x27, x0, 0  #indication of program end!  