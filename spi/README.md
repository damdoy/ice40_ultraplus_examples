# Simple SPI example for the iCE40 UltraPlus Breakout board

This example is composed of a host C program compiled on Linux communicating with the ice40 FPGA via the FTDI chip on the breakout board.

Communication is done with packets of 4 Bytes.
The first byte is the opcode on the MOSI line, on the MISO it is a status byte.
The two other bytes are used for data.

To play around with the FPGA, these opcodes are implemented:

OPCODE  | Description
0x0     | Nop, does nothing
0x1     | Init, starts the state machine on the fpga side
0x2     | Writes 16bits to be inverted on the fpga
0x3     | Reads the 16 inverted bits on the next communcation
0x4     | Writes led value to be on the breakout board. (RGB, LSB is R)
0x5     | Reads which of the RGB led is on, on the next SPI communication

The host.c example lights up leds and sends 24bits to be inverted.

One of the big drawback of this implementation is that the host have to send a read request
and then read the data by sending NOP on the SPI line. An improvement could be to do the
request and read at the same time, but we want to keep it simple.

When the master/host is reading the SPI packets, the first three bytes is the data
the last byte is the status, it is only of seven bits
bit 7 - data has been written from the fpga
bit 6 - data sent successfuly to fpga (register was free)

Most of the SPI initalisation on the host side is taken from the iceprog source code
https://github.com/cliffordwolf/icestorm/tree/master/iceprog
