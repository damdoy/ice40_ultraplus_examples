filename = top
pcf_file = ../common/io.pcf

build:
	yosys -p "synth_ice40 -top top -json $(filename).json" $(filename).v
	nextpnr-ice40 --u4k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

program:
	iceprog $(filename).bin

clean:
	rm -f top*.asc top*.bin top*.json