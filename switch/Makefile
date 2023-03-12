filename = switch
pcf_file = ../common/io.pcf

build:
	yosys -p "synth_ice40 -top switch -json $(filename).json" $(filename).v
	nextpnr-ice40 --u4k --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog: #for sram
	iceprog -S $(filename).bin

prog_flash:
	iceprog $(filename).bin

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin
