; Punto de entrada del kernel en modo protegido de 32 bits.
; El cargador (loader_f3.asm) ya activó modo protegido, configuró los
; segmentos planos y la pila antes de saltar aquí.
bits 32

section .text
global _start
extern _kmain

_start:
    mov esp, 0x9F000       ; Pila de respaldo, por si el cargador no la dejó fijada.
    call _kmain              ; Punto de entrada en C (con prefijo "_" por la ABI cdecl PE32).
.detener:
    cli
    hlt
    jmp .detener
