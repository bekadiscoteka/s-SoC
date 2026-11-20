
#include <stdint.h>

#define UART        (*(volatile uint8_t *)0x20000000)
#define UART_STATUS (*(volatile uint8_t *)0x20000004)
#define TX_BUSY     (UART_STATUS & 2)

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

static void uart_puts(const char *s) {
	while ( *s != '\0')
		uart_putc(*s++);
	
}


int main(void) {
	
	uart_puts("picoSoC boot v0.1\n\r");
	uart_putc('>');

	for (;;)
		;
}
