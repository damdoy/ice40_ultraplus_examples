filename = top
pcf_file = ../common/io.pcf
riscv_folder = ./simple_riscv_cpu/simple_cpu

build:
	yosys -p "synth_ice40 -json $(filename).json -blif $(filename).blif" $(filename).v $(riscv_folder)/alu/alu.v $(riscv_folder)/register_file/register_file.v
	arachne-pnr -d 5k -P sg48 -p $(pcf_file) $(filename).blif -o $(filename).asc
	#nextpnr-ice40 --up5k --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog:
	iceprog -S $(filename).bin

prog_flash:
	iceprog $(filename).bin

clean:
	rm -rf $(filename).json $(filename).blif $(filename).asc $(filename).bin
