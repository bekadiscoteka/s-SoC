
PREFIX := riscv64-unknown-elf-

test.hex: test_uart.S 
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0 -DTX_EXP='"Hello, World!"' -o test.elf test_uart.S
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 test.elf test.hex
	$(PREFIX)objdump -d test.elf > test.lst

clean: 
	@rm *.elf *.hex *.lst
