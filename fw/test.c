
#ifndef TX_EXP 
#define TX_EXP "Hello from C program"
#endif

#ifndef LED_EXP
#define LED_EXP 0xF0
#endif

#define FREQ	27000000

#define led		(volatile char*)0x10000000
#define uart		(volatile char*)0x20000000
#define status_addr	(volatile char*)0x20000004
#define UART_BUSY	( *status_addr >> 1 ) 



typedef unsigned int size_t; 


const char str[] = TX_EXP;

static size_t strlen(const char *s) {
	size_t i = 0;
	while (*s++ != '\0') 
		i++;
	return i;
}

static size_t puts(const char *s) {
	while (UART_BUSY)
		;
	for (size_t i=0; i < strlen(str); i++) {
		*uart = str[i]; 
		while (UART_BUSY)
			;
	}
}

int main(void) {
	puts(TX_EXP);
	*led = LED_EXP;
	
	return 0;
}
