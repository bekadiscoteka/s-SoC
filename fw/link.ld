/* Указываем архитектуру и точку входа */
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x0, LENGTH = 8K
}

SECTIONS
{
    .text : 
    {
	*(.text.init)
        *(.text)
	*(.text.*)
    } > RAM

    .data : 
    {
        . = ALIGN(4);
	*(.sdata)
        *(.data)
	*(.data.*)
	*(.rodata)
	*(.rodata.*)
        . = ALIGN(4);
    } > RAM 


    .bss : 
    {
        . = ALIGN(4);
	_sbss = .;
	*(.sbss)
        *(.bss)
	*(.bss.*)
        . = ALIGN(4);
	_ebss = .;
    } > RAM

}
