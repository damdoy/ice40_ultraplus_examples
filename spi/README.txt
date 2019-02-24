Simple SPI example for the ice40 ultra plus breakout board

This example is composed of a host C program compiled on Linux communicating with the ice40 FPGA via the FTDI chip on the breakout board.

Communication is done with packets of 3bytes.
The first byte is the opcode on the MOSI line, on the MISO it is a status byte.
The two other bytes are used for data.

To play around with the FPGA, these opcodes are implemented:

//0x02 write 16bits inverted
//0x03 read 16bits inverted
//0x04 write leds (16bits LSB)
//0x05 read leds (16bits LSB)

OPCODE  | Description
0x0     | Nop, does nothing
0x1     | Init, starts the state machine on the fpga side
0x2     | Writes 16bits to be inverted on the fpga
0x3     | Reads the 16 inverted bits on the next communcation
0x4     | Writes led value to be on the breakout board. (RGB, LSB is R)
0x5     | Reads which of the RGB led is on, on the next SPI communication

The host.c example lights up leds and sends 16bits to be inverted.

Most of the SPI initalisation on the host side is taken from the iceprog source code
https://github.com/cliffordwolf/icestorm/tree/master/iceprog

