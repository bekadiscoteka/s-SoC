# Тестовая программа для tb_boot: печатает "OK!" и возвращается в загрузчик.
# Без crt0 и стека, поэтому линкуется прямо на 0x80000000 (см. test/Makefile).

	.section .text
	.globl	_start
_start:
	li	t0, 0x20000000		# UART
	la	t2, msg
next:
	lbu	t1, 0(t2)
	beqz	t1, done
busy:
	lbu	t3, 4(t0)		# статус, бит 1: занят отправкой
	andi	t3, t3, 2
	bnez	t3, busy
	sb	t1, 0(t0)
	addi	t2, t2, 1
	j	next
done:
	ret

msg:	.asciz	"OK!"
