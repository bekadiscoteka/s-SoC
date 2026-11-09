.section .text
.globl wait

wait:
	mv t0, zero
loop:	
	addi t0, t0, 1
	blt t0, a0, loop
	ret

			
