# Simple SPI example using the HW module on the iCE40 UltraPlus (Breakout board)

This example is very similar to the soft-IP SPI one (https://github.com/damdoy/ice40_ultraplus_examples/tree/master/spi), but this uses the hardware SPI module on the iCE40 fpga to communicate.

The host computer communicates with the FPGA using the FTDI chip on the breakout board.
The host can send commands such as lighting up the LEDS with a given color and the FPGA can answer to request from the host and send data itself.

The host is a linux computer using the `ftdi.h` lib and is configured as a master, the fpga is the slave.

Communication is done with packets of a few bytes of data.

The master sends 8bytes of data to the slave, the first byte is used as the opcode of the command.

```
OPCODE  | Description
0x0     | Nop, does nothing
0x1     | Init, starts the state machine on the fpga side
0x2     | Writes 32bits to be inverted on the fpga
0x4     | Writes led value to be on the breakout board. (RGB, LSB is R)
0x6     | The host computer will send 4*32bits values (vector)
0x7     | Reads the 4*32bits values
```

In order for the slave to be able to send data back to the master, it has to write data to a send register in the SPI module before it receives a byte, which means it cannot write useful data the first two bytes. Therefore the slave can only write 6 bytes of data back, the first byte is used as a status.

```
Packet byte                | 0      | 1     | 2     | 3     | 4     | 5     | 6     | 7     |
Master out slave in (MOSI) | opcode | parameters/data                                       |
Slave out master in (MISO) | garbage        |status | data                                  |
```

A simple state machine is implemented in the `top.v` file, its goal is to initialize the SPI module first and then read the opcode from the incoming packet and process the request.

## How to build and run

The bitstream for the fpga should be built first `make build`, then it should be programmed on the fpga `make prog`.

One the fpga is programmed, the host program in `spi_host` should be build with `make`.
Then, running `./host` should lunch the host and it should start to communicate with the fpga.

Most of the SPI initalisation on the host side is taken from the iceprog source code
https://github.com/cliffordwolf/icestorm/tree/master/iceprog
