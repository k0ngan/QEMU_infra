/* El cargador coloca el kernel en 0x20000 (físico) antes de saltar a modo
   protegido; el código corre con segmentos planos, así que la dirección
   física y la dirección lineal coinciden. */
ENTRY(_start)

SECTIONS
{
    . = 0x20000;

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        *(COMMON)
        *(.bss*)
    }
}
