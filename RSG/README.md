# Pseudo Random Seed Generator

This example is to make a Pseudo-Random Seed Generator. This example was generated in part as a prompt 
engineering test for ChatGPT.

This pseudorandom seed generator provides an 8 bit output seed. The output frequencies and enable signals are provided externally by a host controller such as an RP2040. 

Inputs are:

`Start/Stop Signal` - this comes in on pin 6 into the FPGA.

`reset` - This comes in on pin 4 into the FPGA

`frequency control` - A 3 bit signal that is used to select 8 different frequency of need.

Outputs are:

`seed` - an 8 bit wide pseudorandom seed.

`seed ready` - a signal indicating that the seed is stable and ready for consumption by the host.

### Notice ###
ChatGPT is not a true source of solutions for the problems that you might encounter working with FPGA.
Like all things, it is a tool that can be both wrong, overconfident, and misinterpreted. 

The user of tools are responsible for vetting all outcomes through testing and other verification means.

With great power comes great responsibility. Use wisely and use caution. It is recommended to have a good understanding of the subject area you are prompting to ensure you can modify the output to match modern standards of development.

# Building

To build, simply type `make build`

Program with `make prog_flash`