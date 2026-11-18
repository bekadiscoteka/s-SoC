
.globl _start
.section .text.init
_start:
	la t0, bss_start
	la t1, bss_end
	la t2, data_start
	la t3, data_end
	la t4, dataLMA_start
bss_loop:
	bgeu t0, t1, data_loop
	sw zero, 0(t0)
	addi t0, t0, 4
	j bss_loop
data_loop:
	bgeu t2, t3, stack_setup
	lw t5, 0(t4)
	sw t5, 0(t2)
	addi t2, t2, 4
	addi t4, t4, 4
	j data_loop
stack_setup:
	la sp, stack_start
call_main:
	call main
	ebreak	

