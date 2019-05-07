all:
	riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O0 -c main.c
	riscv32-unknown-elf-as -march=rv32i -mabi=ilp32 start.S -o start.o
#lgcc, libgcc, contains functions such as mulsi3, soft implementation of a mult
#nostartfiles avoid having ctr0 linked with is a "default" _start function
	riscv32-unknown-elf-gcc -T script.lds -lgcc -nostartfiles start.o main.o -o main.oo
	riscv32-unknown-elf-objcopy -O binary main.oo main

objdump:
	riscv32-unknown-elf-objdump -d main.oo
