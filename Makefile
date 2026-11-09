
DEVICE := GW2AR-LV18QN88C8/I7
FAMILY := GW2A-18C
BOARD  := tangnano20k
CST := tangnano20k.cst

RTL := rtl/soc.sv rtl/picorv32.v rtl/uart.sv rtl/ram.sv
TX_EXP ?= Hello, World!
LED_EXP ?= F0 

export TX_EXP
export LED_EXP

build/test_soc.vvp: test/tb_soc.sv $(RTL) fw/test.hex | build
	iverilog -g2012 test/tb_soc.sv -DTX_EXP='"$(TX_EXP)"' -DLED_EXP='8'\''h$(LED_EXP)' -DINIT_FILE='"fw/test.hex"' $(RTL) -o $@ 

build/test_uart.vvp: test/tb_uart.sv rtl/uart.sv | build
	iverilog -g2012 $^ -o $@

fw/test.hex: FORCE
	$(MAKE) test.hex -C fw/

fw/program.hex: FORCE
	$(MAKE) program.hex -C fw/


fw:
	@mkdir -p  fw/



ysys/netlist.json: $(RTL) fw/program.hex | ysys
	yosys -m slang -l ysys/ysys.log -p "read_slang $(RTL); synth_gowin -top picosoc -json ysys/netlist.json; stat"

nxtpnr/top_pnr.json: ysys/netlist.json $(CST) | nxtpnr
	nextpnr-himbaechel --json $< --write $@ \
		--device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST) \
		--freq 27 --log nxtpnr/nxtpnr.log --quiet

top.fs: nxtpnr/top_pnr.json
	gowin_pack -d $(FAMILY) -o top.fs $<



build: 
	@mkdir -p build/

ysys: 
	@mkdir -p ysys/
nxtpnr: 
	@mkdir -p nxtpnr/

clean: 
	@rm -rf build/
	@rm -f *.vcd *.fs
	$(MAKE) clean -C fw/

tests: build/test_uart.vvp build/test_soc.vvp
	vvp build/test_uart.vvp
	vvp build/test_soc.vvp

load: top.fs
	openFPGALoader -b $(BOARD) top.fs


.PHONY: tests clean FORCE load
