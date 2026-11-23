ENTRY(_start)

MEMORY
{
    ROM (rx) : ORIGIN = 0x0, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 32K
    BOOTRAM (rwx) : ORIGIN = ORIGIN(RAM) + LENGTH(RAM) - 1K, LENGTH = 1K
}

SECTIONS {
	rom_origin = ORIGIN(ROM);
	ram_origin = ORIGIN(RAM);
	.text : 
	{
		*(.text.init)
		*(.text)	
		*(.text.*)
	} > ROM

	.rodata :
	{
		*(.rodata) 
		*(.rodata.*)
		*(.srodata)
		*(.srodata.*)
		. = ALIGN(4);
	} > ROM

	.data :
	{
		data_start = .;
		*(.data)
		*(.sdata)
		*(.sdata.*)
		*(.data.*)
		. = ALIGN(4);
		data_end = .;

	} > BOOTRAM AT> ROM

	dataLMA_start = LOADADDR(.data);

	.bss :
	{
		. = ALIGN(4);
		bss_start = .;
		*(.bss)
		*(.bss.*)
		*(.sbss)
		*(.sbss.*)
		. = ALIGN(4);
		bss_end = .;

	} > BOOTRAM 

	stack_start = ORIGIN(BOOTRAM);
}


