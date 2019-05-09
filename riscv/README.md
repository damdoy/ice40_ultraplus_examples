# RISC-V implementation on iCE40

__**Note: this is a work in progress, it compiles and works but needs some finalizations**__

This is an implementation of the simplest RISC-V CPU (rv32i) on the ice40-ultraplus fpga.

On the FPGA are implemented, in addition to the CPU and memory, a GPIO module to drive a RGB led and a SPI module to communicate with a host computer (on linux for example)

The CPU can communicate with a computer using a bidirectional spi communication. The host computer can send the following commands which will be executed on the fpga's CPU:
- Light up the RGB LED with a given colour
- Calculate a Fibonacci number
- Calculate a power of two

```
+----------------------------------+                +-------------------------+
| iCE40 UltraPlus FPGA             |                |Computer running Linux   |
| Breakout Board                   |                |                         |
| +--------------+     +---------+ |                |                         |
| |              |     |Memory   | |                |                         |
| | RISC-V CPU   +-----+SPRAM    | |                |                         |
| | R32i         |     |32K      | |                |                         |
| |              |     +---------+ |                | +----------+ +--------+ |
| |              |                 |                | |Host      | |Firmware| |
| |              |     +---------+ |  +-------+     | |Server    | |Risc-V  | |
| |              +-----+SPI      | |  |FTDI   |USB  | |x86       | |To be   | |
| |              |     |Module   +----+Chip   +-------+          | |sent    | |
| |              +--+  |         | |  |       |     | |          | |        | |
| |              |  |  +---------+ |  +-------+     | |          | |        | |
| +--------------+  |              |                | |          | |        | |
|                   |  +---------+ |                | +----------+ +--------+ |
|      +------+     +--+GPIO     | |                |                         |
|      |RGB   |        |Module   | |                |                         |
|      |LED   +--------+         | |                |                         |
|      +------+        +---------+ |                |                         |
|                                  |                |                         |
+----------------------------------+                +-------------------------+
```

## How to build

There are the following subsystems to compile:
- The FPGA bitstream itself (with the riscv cpu) using the icestorm tools
- The host program (`host server`) to be compiled with the gcc of the computer
- The firmware (`host_server/firmware`) to be compiled with the riscv toolchain

Build and run all the systems:
```
make # compiles the fpga
make prog # programs the fpga

# riscv firmware
cd host_server/firmware
make

# host program
cd host_server
make

# sends the firmware and run the example program (light leds, calculate a fibonacci and pow2 on the riscv chip)
cd host_server
./host
```

Build the gnu toolchain https://github.com/riscv/riscv-gnu-toolchain (works with commit afcc8bc655d30c, gcc 8.3.0) with
gcc and newlib with the following parameters:

```
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
make
```

## System

The system has a rv32i riscv soft cpu, a 32KB memory, a gpio module to drive a rgb led, and a memory mapped SPI module.

memory map:
```
ram 32KB : 0x0000 - 0x7fff
SPI: 256B : 0x8000 - 0x80ff
GPIO: 256B : 0x8100 - 0x81ff
```

Utilization:
```
Info: 	         ICESTORM_LC:  3262/ 5280    61%
Info: 	        ICESTORM_RAM:     4/   30    13%
Info: 	               SB_IO:    12/   96    12%
Info: 	               SB_GB:     8/    8   100%
```

SPI commands
```
0x0     | Nop, does nothing (not seen from cpu)
0x1     | init spi (not seen from cpu)
0x2     | Sends 16bits of data (incremental address) (not seen from cpu)
0x3     | Starts the cpu (not seen from cpu)
0x4     | Set LED (param R, G, B)
0x5     | Run gradient (with soft pwm from the riscv)
0x6     | Run fibonacci, next read is result
0x7     | Pow, next read is result
```

SPI MM module registers

```
0x0 status (bit 0: read buffer full, bit 1: write buffer full) (R only)
0x4 read data R only
0x8 assert read W only (write something else than 0)
0xC write data
```

Host sends the firmware to the fpga using spi, which will be saved to memory immediately
with an auto incrementing adress

<!-- ## CPU (describe the cpu, its capabilites and a small benchmark) -->
