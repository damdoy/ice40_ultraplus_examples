# iCE40 UltraPlus FPGA examples on the Breakout Board

Collection of examples for the ice40 ultraplus fpga, each example tests a feature of the fpga (such as spram) and is independent from the others.

All the examples are running on the IcyBlue FPGA Feather,
which contains a ice5lp4k fpga, a flash, a ftdi usb-to-spi chip an rgb led, and 2 user LEDs in a feather form factor.

### Pinout
<image src="https://github.com/skerr92/ice5lp4k_examples/blob/master/images/IcyBlue%20Pinout.jpg">

Most samples should build. If they don't please open an issue.

Some of the examples include:
- Blinking of the RGB led
- PWM on the RGB led
- SPI communication with a host computer
   - Using a soft-IP module
   - Using the hardware SPI module on the iCE40
- Read and write to BRAM
- Reading the flash (W25Q16) from the FPGA (This example might not work and may need updating)
- DSP (`SB_MAC16`) example with MAC (multiply and accumulate) operations
- PLL and use of internal clock

All the examples are synthetized and programmed on the breakout board using the open souce tools from the icestorm project (http://www.clifford.at/icestorm/).

The PLL example shows how to use the internal 48MHz clock.

# How to build

### if you haven't worked with IceStorm before, please follow these instructions

1. Go to [Yosys oss_cad_suite_build](https://github.com/YosysHQ/oss-cad-suite-build) and download the latest release for your system.
2. If you are on a Mac, exporting the path doesn't seem to work all the time but using the `source` command specified in the oss_cad_suite README seems to be the trick. Otherwise follow the instructions in the README.
3. go to the [Switch Example](https://github.com/skerr92/ice5lp4k_examples/tree/master/switch) in terminal (macOS/Linux). You may need to use a WSL2 instance on windows for this to build with Make commands.
4. run `make build` to build the example to ensure your system can reach the required files/applications. If you are on a Mac, you will likely need to go to `Privacy and Security` to allow each application that needs to be run to build the examples.

If the build is successful, you should see a `top.bin` file in the example directory.

Then follow the commands below to program the flash on the IcyBlue Feather FLASH chip.

Each example can be compiled with a `make` which will create the
bitstream using the icestorm opensource tools, once the breakout board
is plugged.

`make prog_flash` will write the FPGA configuration to the separate
flash chip on the breakout board. However the FPGA will not be able to
communicate with the host through the USB using the SPI in this mode. A
power cycle may be also be needed for the FPGA to read the configuration
from the flash memory.

Note that the IcyBlue Feather can only be programmed through SPI Flash. This means you will need to use the `prog_flash` make command or use another tool like [Adafruit's FTDIflash](https://learn.adafruit.com/programming-spi-flash-prom-with-an-ft232h-breakout) program to write the flash chip.

For `make prog` to work, the jumpers at J6 should be in vertically
oriented. For `make prog_flash` to work, the jumpers at J6 should be in
horizontal orientation.

### Versions used

- icestorm suite (git sha1 9f66f9ce16941c)
- yosys 0.15
- nextpnr-ice40 0.2
- gcc version 5.4.0  

Built on MacOS Ventura 13.2.1
