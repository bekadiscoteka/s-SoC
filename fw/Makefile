
PREFIX := riscv64-unknown-elf-

test.hex: test.ld main.c start.S | objdump 
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttest.ld -DTX_EXP='"$(TX_EXP)"' -o test.elf start.S main.c
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 test.elf test.hex  
	$(PREFIX)objdump -d test.elf > objdump/disassemble.lst 
	$(PREFIX)objdump -h test.elf > objdump/hex.lst 

objdump:
	@mkdir -p objdump

clean: 
	@rm *.elf *.hex 
	@rm -rf objdump
