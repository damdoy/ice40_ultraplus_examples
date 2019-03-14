The goal of this example is to read, from the ice40 ultraplus some data in the flash with SPI.

The flash_master folder contains the script and image to write in the flash at 1MB or 0x100000 offset

The FPGA will read the data in the flash starting from 0x100000 and display it on the LED.s

TODO finish README

flash chip: N25Q032A13ESC40F

minimal erase cycle: 100k

Needs ~833Kb for the fpga bitstream

The flash chip has 32Mb or 4MB

Write data starting from the first MB using the flash_master/flash_program.sh
