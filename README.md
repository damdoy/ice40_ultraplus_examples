# iCE40 UltraPlus FPGA examples on the Breakout Board

Collection of examples for the ice40 ultraplus fpga, each example tests a feature of the fpga (such as spram) and is independent from the others.

All the examples are running on the ice40 ultraplus breakout board from lattice (https://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40UltraPlusBreakoutBoard)
which contains a ice40 ultraplus fpga (iCE40UP5K), a flash, a ftdi usb-to-spi chip and a rgb led.

Some of the examples include:
- Blinking of the RGB led
- PWM on the RGB led
- Read and write to SPRAM modules from the FPGA
- SPI communication with a host computer
- Read and write to BRAM
- Reading the flash (N25Q032A) from the FPGA
- DSP (`SB_MAC16`) example with MAC (multiply and accumulate) operations
- A RISC-V implementation running on the FPGA
   - the RISC-V groups all of the above examples to make a complete working system able to do matrix multiplications, fibonacci and multiplcations, all on a RISC-V soft CPU communicating with a Linux computer.

All the examples are synthetized and programmed on the breakout board using the open souce tools from the icestorm project (http://www.clifford.at/icestorm/).

# How to build

Each example can be compiled with a `make` which will create the bitstream using the icestorm opensource tools, once the breakout board is plugged, `make prog` will program the fpga using the sram, `make prog_flash` will program the flash of the fpga.
