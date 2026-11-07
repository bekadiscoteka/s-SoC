
.section .text.init
.globl _start
_start:
	la t0, _sbss
	la t1, _ebss
loop:
	bgeu t0, t1, end
	sw zero, 0(t0)
	addi t0, t0, 4
	j loop
end:
	li sp, 0x2000
	call main
	ebreak
