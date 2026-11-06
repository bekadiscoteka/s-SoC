#define RAM_ADDR	0x00000000
#define LED_ADDR	0x10000000
#define	UART_ADDR	0x20000000
#define UART_STATUS_ADDR UART_ADDR + 4
#define UART_BUSY_MASK	2

.text
.globl _start

_start:
	mv t3, zero
loop:
	li t0, UART_STATUS_ADDR
	li t1, UART_BUSY_MASK
	lbu t2, 0(t0)
	and t2, t2, t1
	beqz t2, writeByte
	j loop

writeByte:
	la t0, hello
	li t1, UART_ADDR
	add t0, t0, t3
	lbu t2, 0(t0)

	beqz t2, trap

	sb t2, 0(t1)
	addi t3, t3, 1
	j loop
trap:
	ebreak

.data
hello:
	.asciz TX_EXP
	
