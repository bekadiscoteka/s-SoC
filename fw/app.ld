
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 30K
}

SECTIONS {
	.text : 
	{
		*(.text.init)
		*(.text)	
		*(.text.*)
	} > RAM

	.rodata :
	{
		*(.rodata) 
		*(.rodata.*)
		*(.srodata)
		*(.srodata.*)
	} > RAM

	.data :
	{
		*(.data)
		*(.sdata)
		*(.sdata.*)
		*(.data.*)

	} > RAM

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

	} > RAM 

	stack_start = ORIGIN(RAM) + LENGTH(RAM);
}


