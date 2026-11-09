
PREFIX := riscv64-unknown-elf-
PROG := wait.S main.c
TEST := test.c 

program.hex: link.ld start.S $(PROG) | objdump 
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Tlink.ld -DTX_EXP='"$(TX_EXP)"' -DLED_EXP='0x$(LED_EXP)' -o program.elf start.S $(PROG)
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 program.elf $@  
	$(PREFIX)objdump -d program.elf > objdump/dis.lst 
	$(PREFIX)objdump -h program.elf > objdump/hex.lst 

test.hex: link.ld test.c start.S $(TEST) | objdump
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Tlink.ld -DTX_EXP='"$(TX_EXP)"' -DLED_EXP='0x$(LED_EXP)' -o test.elf start.S $(TEST)
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 test.elf $@  
	$(PREFIX)objdump -d test.elf > objdump/test_dis.lst 
	$(PREFIX)objdump -h test.elf > objdump/test_hex.lst 

objdump:
	@mkdir -p objdump

clean: 
	@rm *.elf *.hex 
	@rm -rf objdump
