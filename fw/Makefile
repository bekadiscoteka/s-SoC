
PREFIX := riscv64-unknown-elf-
PROG := wait.S main.c
TEST := test.c 

boot.hex: boot.ld boot.S boot.c | objdump
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Tboot.ld -o boot.elf boot.S boot.c
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 boot.elf $@  
	$(PREFIX)objdump -d boot.elf > objdump/boot_dis.lst 
	$(PREFIX)objdump -h boot.elf > objdump/boot_hex.lst 

crt0_test.hex: boot.ld boot.S crt0_test.c | objdump
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Tboot.ld -o crt0_test.elf boot.S crt0_test.c
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 crt0_test.elf $@
	$(PREFIX)objdump -d crt0_test.elf > objdump/crt0_test_dis.lst
	$(PREFIX)objdump -h crt0_test.elf > objdump/crt0_test_hex.lst

program.hex: link.ld start.S $(PROG) | objdump 
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Tlink.ld -DTX_EXP='"$(TX_EXP)"' -DLED_EXP='0x$(LED_EXP)' -o program.elf start.S $(PROG)
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 program.elf $@  
	$(PREFIX)objdump -d program.elf > objdump/dis.lst 
	$(PREFIX)objdump -h program.elf > objdump/hex.lst 

test.hex: boot.ld boot.S $(TEST) | objdump
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Tboot.ld -DTX_EXP='"$(TX_EXP)"' -DLED_EXP='0x$(LED_EXP)' -o test.elf boot.S $(TEST)
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 test.elf $@  
	$(PREFIX)objdump -d test.elf > objdump/test_dis.lst 
	$(PREFIX)objdump -h test.elf > objdump/test_hex.lst 

objdump:
	@mkdir -p objdump

clean: 
	@rm *.elf *.hex 
	@rm -rf objdump
