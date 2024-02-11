filename = usb
pcf_file = ../common/io.pcf

build:
	yosys -p "synth_ice40 -top usb -json $(filename).json" $(filename).v
	nextpnr-ice40 --u4k --package sg48 --json $(filename).json --pcf-allow-unconstrained --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog:
	iceprog $(filename).bin