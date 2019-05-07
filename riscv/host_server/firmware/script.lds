MEMORY
{
   ram (rwxa)  : ORIGIN = 0x0, LENGTH = 32K
}

SECTIONS
{
   .text : { *(.text) } > ram
   .data : { *(.data) } > ram
}
