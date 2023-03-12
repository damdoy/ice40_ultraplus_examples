filename1 = timed_lights
filename2 = car_waiting
pcf_file = ../common/io.pcf

build_timed:
	yosys -p "synth_ice40 -top timed_lights -json $(filename1).json" $(filename1).v
	nextpnr-ice40 --u4k --package sg48 --json $(filename1).json --pcf $(pcf_file) --asc $(filename1).asc
	icepack $(filename1).asc $(filename1).bin

build_cars:
	yosys -p "synth_ice40 -top car_waiting -json $(filename2).json" $(filename2).v
	nextpnr-ice40 --u4k --package sg48 --json $(filename2).json --pcf $(pcf_file) --asc $(filename2).asc
	icepack $(filename2).asc $(filename2).bin

prog_timed: #for sram
	iceprog $(filename2).bin

prog_cars:
	iceprog $(filename2).bin

clean:
	rm -rf $(filename*).blif $(filename*).asc $(filename*).bin