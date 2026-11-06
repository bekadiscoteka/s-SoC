
RTL := rtl/soc.sv rtl/picorv32.v rtl/uart.sv rtl/ram.sv
PREFIX := riscv64-unknown-elf-

build/test_uart.vvp: test/tb_uart.sv rtl/uart.sv | build
	iverilog -g2012 $^ -o $@


build/test_soc.vvp: test/tb_soc.sv $(RTL) fw/test.hex | build
	iverilog -g2012 test/tb_soc.sv -DTX_EXP='"Hello, World!"' $(RTL) -o $@ 

fw/test.hex: 
	make -C fw/

build: 
	@mkdir -p build/

fw:
	@mkdir -p  fw/

clean: 
	@rm -rf build/
	@rm *.vcd
	make clean -C fw/

tests: build/test_uart.vvp build/test_soc.vvp
	vvp build/test_uart.vvp
	vvp build/test_soc.vvp

.PHONY: tests clean
