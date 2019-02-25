The goal of this repo is to share some of the tests I did on the ice40 ultraplus FPGA from lattice.

All the examples are running on the ice40 ultraplus breakout board from lattice (https://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40UltraPlusBreakoutBoard)
which contains a ice40 ultraplus fpga (iCE40UP5K), a flash, a ftdi usb-to-spi chip and a rgb led.

Some of the examples include:
- Blinking of the rgb led
- PWM on the rgb led
- Use of the spram modules within the fpga
- SPI communication with a host computer
- A RISC-V implementation running on the fpga

All the examples are synthetized and programmed on the breakout board using the open souce tools from the icestorm project (http://www.clifford.at/icestorm/)
