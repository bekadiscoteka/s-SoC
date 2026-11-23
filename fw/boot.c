
#include <stdint.h>
#include <stddef.h>

#define CYCLE_50MS	( 27000000 * 0.05 )

#define RAM_ORIGIN	( 0x80000000 ) 
#define RAM_SIZE	( 30720 )

#define UART		(*(volatile uint8_t *)0x20000000)
#define UART_STATUS	(*(volatile uint8_t *)0x20000004)
#define TX_BUSY		(UART_STATUS & 2)
#define RX_VALID	(UART_STATUS & 1)
#define RX_OVER		(UART_STATUS & 4)

#define POLINOM		( 0xEDB88320 )

static const char magic[] = "listen";
static uint8_t *addr;
static size_t size;
static uint32_t crc32;
static int timeouts = 0;

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

#define TIMEOUT 1
static uint8_t uart_getc(int mode) {
	uint32_t init, now;
	__asm__ volatile ("rdcycle %0" : "=r"(init));
	now = init;	

	while (!RX_VALID) {
		if (mode & TIMEOUT) {
			if (now - init >= CYCLE_50MS) {
				timeouts++;
				return -1;
			}
			__asm__ volatile ("rdcycle %0" : "=r"(now));
		}
	}

	return UART;
}

/*
static uint8_t *uart_gets(uint8_t *s) {
	uint8_t *p = s;
	do {
		*p = uart_getc(0);
	} while ( *p++ != '\0' );

	return s;
}
*/

/* flags */
#define CRCRESET	1
#define CRCGET		2

static uint32_t zlib_crc32(uint8_t b, int mode) {

	static uint32_t crc = 0xFFFFFFFF;

	if (mode == CRCGET) 
		return ~crc;

	if (mode == CRCRESET) {
		crc = 0xFFFFFFFF;
		return 0;
	}

	crc ^= (uint32_t) b;


	for (int i=0; i<8; i++) {
		uint8_t lsb = crc & 1;		
		crc >>= 1;
		if (lsb) 
			crc ^= POLINOM;
	}

	return crc;
}

void silence(void) {
	uint32_t rdcycle_init;
	__asm__ volatile ("rdcycle %0" : "=r"(rdcycle_init));
	uint32_t rdcycle_now = rdcycle_init;

	while (rdcycle_now - rdcycle_init < CYCLE_50MS) {
		__asm__ volatile ("rdcycle %0" : "=r"(rdcycle_now));
		if (RX_VALID) {
			uint8_t temp = UART;
			rdcycle_init = rdcycle_now;
		}
	}

}



int main(void) {
	
	uart_puts("picoSoC boot v0.1\n\r");

	enum { MAGIC, ADDR, SIZE, CRC, RESET, LOAD, JUMP, FINISH } state = RESET;
	uint8_t c;
	while (1) {
		
		if (timeouts > 0) {
			timeouts = 0;
			state = RESET;
		}

		switch (state) {

			case RESET:
				addr = 0;
				size = 0;
				crc32 = 0;
				zlib_crc32(0, CRCRESET);
				uart_putc('N');
				silence();
				state = MAGIC;
			break;

			case MAGIC:
				zlib_crc32(0, CRCRESET);
				const char *magicp = magic;
				uart_putc('>');
				while ( *magicp++ == (c=uart_getc(0)) ) {
					zlib_crc32(c, 0);
					if ( *magicp == '\0' ) {
						state = ADDR;
						break;
					}
				}
			break;
			case ADDR:
				for (int i=0; i < 4; i++) {
					addr = addr + ( (c=uart_getc(TIMEOUT)) << i*8 );
					zlib_crc32(c, 0);
				}
				
				state = (void*) addr == RAM_ORIGIN ? SIZE : RESET; 
			break;

			case SIZE:
				for (int i=0; i < 2; i++) { 
					size = size + ( (c=uart_getc(TIMEOUT)) << i*8 );
					zlib_crc32(c, 0);
				}

				state = size < RAM_SIZE ? CRC : RESET;	
			break;
			case CRC: 
				
				for (int i=0; i < 4; i++) 
					crc32 = crc32 + ( uart_getc(TIMEOUT) << i*8 );

				if (crc32 == zlib_crc32(0, CRCGET)) {
					state = LOAD;
					uart_putc('Y');
				} else 
					state = RESET;

			break;

			case LOAD:
				zlib_crc32(0, CRCRESET);	
				for (size_t i=0; i<size; i++) {
					*addr++ = (c=uart_getc(TIMEOUT));
					zlib_crc32(c, 0);
					if (timeouts > 0)
						break;
				}

				if (timeouts > 0)
					break;
				
				crc32 = 0;
				for (int i=0; i<4; i++)
					crc32 += ( uart_getc(TIMEOUT) << i*8 );
					
				if (zlib_crc32(0, CRCGET) == crc32) {
					uart_putc('Y');
					state = JUMP;
				}
				else 
					state = RESET;
			break;	
			case JUMP:
				__asm__(
					"call ram_origin\n"
					"j rom_origin"
				);
				
			break;

			default: __asm__ ("ebreak");break;
		}
	}

	
}
