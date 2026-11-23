.globl _start
.section .text.init
_start:
	la t0, bss_start
	la t1, bss_end
bss_loop:
	bgeu t0, t1, stack_setup
	sw zero, 0(t0)
	addi t0, t0, 4
	j bss_loop
stack_setup:
	la sp, stack_start
call_main:
	addi sp, sp, -16      # выделить место; sp остаётся кратным 16
	sw   ra, 12(sp)
	call main
	lw   ra, 12(sp)       # достать
	addi sp, sp, 16	
	ret

	
