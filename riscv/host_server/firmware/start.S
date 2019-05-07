.globl _start
_start:
   #stack pointer set at 0x3ffc (16KB, or half of the 32KB memory)
   lui sp, 0x4
   addi sp, sp, -4
   j main
loop: j loop
