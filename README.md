# iCE40 UltraPlus FPGA examples on the Breakout Board

The goal of this repo is to share some of the tests I did on the ice40 ultraplus FPGA from lattice.

All the examples are running on the ice40 ultraplus breakout board from lattice (https://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40UltraPlusBreakoutBoard)
which contains a ice40 ultraplus fpga (iCE40UP5K), a flash, a ftdi usb-to-spi chip and a rgb led.

Some of the examples include:
- Blinking of the rgb led
- PWM on the rgb led
- Read and write to SPRAM modules from the FPGA
- SPI communication with a host computer
- Reading the flash (N25Q032A) from the FPGA
- A RISC-V implementation running on the FPGA
   - the RISC-V groups all of the above examples to make a complete working system able to do matrix multiplications, fibonacci and multiplcations, all on a RISC-V soft CPU communicating with a Linux computer.

All the examples are synthetized and programmed on the breakout board using the open souce tools from the icestorm project (http://www.clifford.at/icestorm/)
