# RISC-V on ice40

__**Note: this is a work in progress, it compiles and works, but some debugging, clean and huge improvement on the doc has to be done**__

This is an implementation of the simplest RISC-V cpu (rv32i) on the ice40-ultraplus fpga

The cpu can communicate with a computer using spi communication.

The computer compiles the firmware in `host_server/firmware` using gcc in the riscv gnu toolkit and sends the compiled firmware to the fpga using tool in `host_server`

The system has a rv32i riscv soft cpu, a 32KB memory, a gpio module to drive a rgb led, and a memory mapped SPI module.

Utilization:
```
Info: 	         ICESTORM_LC:  3262/ 5280    61%
Info: 	        ICESTORM_RAM:     4/   30    13%
Info: 	               SB_IO:    12/   96    12%
Info: 	               SB_GB:     8/    8   100%
```

Building and running the system:
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

memory map:
```
ram 32KB : 0x0000 - 0x7fff
SPI: 256 0x8000 - 0x80ff
GPIO: 256 0x8100 - 0x81ff
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

Build the gnu toolchain https://github.com/riscv/riscv-gnu-toolchain with
gcc and newlib with the following parameters:

```
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
make
```
