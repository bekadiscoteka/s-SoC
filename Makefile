
RTL := rtl/soc.sv rtl/picorv32.v rtl/uart.sv rtl/ram.sv
TX_EXP ?= Hello, World!
export TX_EXP

build/test_soc.vvp: test/tb_soc.sv $(RTL) fw/test.hex | build
	iverilog -g2012 test/tb_soc.sv -DTX_EXP='"$(TX_EXP)"' $(RTL) -o $@ 

build/test_uart.vvp: test/tb_uart.sv rtl/uart.sv | build
	iverilog -g2012 $^ -o $@

fw/test.hex: FORCE
	$(MAKE) -C fw/

build: 
	@mkdir -p build/

fw:
	@mkdir -p  fw/

clean: 
	@rm -rf build/
	@rm *.vcd
	$(MAKE) clean -C fw/

tests: build/test_uart.vvp build/test_soc.vvp
	vvp build/test_uart.vvp
	vvp build/test_soc.vvp

.PHONY: tests clean FORCE
