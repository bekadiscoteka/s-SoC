#ifndef TX_EXP 
#define TX_EXP "Hello from C program"
#endif

#define led	(volatile char*)0x10000000
#define uart	(volatile char*)0x20000000
#define status	(volatile char*)0x20000004

typedef unsigned int size_t; 


const char str[] = TX_EXP;

static size_t strlen(const char *s) {
	size_t i = 0;
	while (*s++ != '\0') 
		i++;
	return i;
}


int main(void) {
	*led = 0xF0;
	for (size_t i=0; i < strlen(str); i++) {
		*uart = str[i]; 
		while ((*status >> 1) != 0)
			;
	}
	return 0;
}
