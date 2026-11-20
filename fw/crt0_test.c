/*
 * Проверка crt0 (boot.S): .data копируется из ROM, .bss обнуляется,
 * и то же самое происходит снова после сброса посреди работы.
 *
 * Протокол с test/tb_crt0.sv: каждая проверка печатает в UART '1' (globals
 * в начальном состоянии) или '0' (нет). За один запуск две проверки:
 *   1) сразу после старта, ждём '1';
 *   2) после порчи всех globals, ждём '0', то есть проверка не слепая.
 * Затем программа крутится в цикле, testbench жмёт reset, и всё повторяется.
 * Ожидаемый поток: "10" + сброс + "10".
 */
#include <stdint.h>

#define UART        (*(volatile uint8_t *)0x20000000)
#define UART_STATUS (*(volatile uint8_t *)0x20000004)
#define TX_BUSY     (UART_STATUS & 2)

/* По одной переменной на каждую входную секцию из boot.ld (gcc кладёт
 * объекты до 8 байт в .sdata/.sbss, крупнее в .data/.bss). */
int     x = 5;                          /* .sdata */
int     arr[8] = {1, 2, 3, 4, 5, 6, 7, 8}; /* .data */
int     z;                              /* .sbss */
uint8_t buf[32];                        /* .bss */

static void uart_putc(char c)
{
	while (TX_BUSY)
		;
	UART = c;
	while (TX_BUSY)
		;
}

static int globals_initial(void)
{
	if (x != 5 || z != 0)
		return 0;
	for (int i = 0; i < 8; i++)
		if (arr[i] != i + 1)
			return 0;
	for (int i = 0; i < 32; i++)
		if (buf[i] != 0)
			return 0;
	return 1;
}

int main(void)
{
	uart_putc(globals_initial() ? '1' : '0');

	x = 7;
	z = 9;
	arr[7] = 0;
	buf[31] = 0xAA;

	uart_putc(globals_initial() ? '1' : '0');

	for (;;)
		;
}
