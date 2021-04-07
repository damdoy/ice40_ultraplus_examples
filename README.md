# iCE40 UltraPlus FPGA examples on the Breakout Board

Collection of examples for the ice40 ultraplus fpga, each example tests a feature of the fpga (such as spram) and is independent from the others.

All the examples are running on the ice40 ultraplus breakout board from lattice (https://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40UltraPlusBreakoutBoard)
which contains a ice40 ultraplus fpga (iCE40UP5K), a flash, a ftdi usb-to-spi chip and a rgb led.

Some of the examples include:
- Blinking of the RGB led
- PWM on the RGB led
- Read and write to SPRAM modules from the FPGA
- SPI communication with a host computer
   - Using a soft-IP module
   - Using the hardware SPI module on the iCE40
- Read and write to BRAM
- Reading the flash (N25Q032A) from the FPGA
- DSP (`SB_MAC16`) example with MAC (multiply and accumulate) operations
- A RISC-V implementation running on the FPGA
   - the RISC-V groups all of the above examples to make a complete working system able to do matrix multiplications, fibonacci and multiplcations, all on a RISC-V soft CPU communicating with a Linux computer.
- PLL and use of internal clock

All the examples are synthetized and programmed on the breakout board using the open souce tools from the icestorm project (http://www.clifford.at/icestorm/).

Most of the examples use the 12MHz external clock from the breakout board. The PLL example shows how to use the internal 48MHz clock.

# How to build

Each example can be compiled with a `make` which will create the
bitstream using the icestorm opensource tools, once the breakout board
is plugged.

`make prog` will program the fpga using the internal sram based condiguration memory in
the Ice40 Ultraplus device. Since this memory is volatile, it will get
erased every time the board is powered down.

`make prog_flash` will will write the FPGA configuration to the separate
flash chip on the breakout board. However the FPGA will not be able to
communicate with the host through the USB using the SPI in this mode. A
power cycle may be also be needed for the FPGA to read the configuration
from the flash memory.

Note that the access to the Flash memory and the SPI interface is
controlled by jumpers on the breakout board. The jumper settings are
described in the [Lattice iCE40
UltraPlus Breakout Board User Guide
(pdf)](https://www.latticesemi.com/view_document?document_id=51987).

For `make prog` to work, the jumpers at J6 should be in vertically
oriented. For `make prog_flash` to work, the jumpers at J6 should be in
horizontal orientation.

### Versions used

Yosys 0.9
arachne-pnr 0.1+325+0
nextpnr-ice40 (git sha1 c365dd1)
gcc version 5.4.0
Built on Linux Mint 18.2
