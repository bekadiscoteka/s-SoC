
synth: 
	yosys -m slang -l yosys.log -p "read_slang rtl/soc.sv rtl/picorv32.v rtl/ram.sv; synth_gowin -top picosoc -json netlist.json"
sim:
	iverilog -g2012 rtl/soc.sv rtl/picorv32.v rtl/ram.sv test/tb_ram.sv -o sim
	vvp sim


.PHONY: sim synth
