bits 16
org 0x7C00                 ; La BIOS carga este sector de arranque en 0x7C00.

LOADER_SEG  equ 0x0000     ; El cargador real-mode se carga en 0x0000:0x8000.
LOADER_OFF  equ 0x8000
LOADER_SECT equ 4          ; Sectores del cargador (2048 bytes).
LOADER_LBA  equ 1          ; LBA 1 = segundo sector (el LBA 0 es este sector).

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov [boot_drive], dl

    mov ax, 0x0003
    int 0x10

    mov si, msg_cargando
    call imprimir

    ; Lectura extendida (LBA) con int 0x13, AH=0x42, usando un Disk
    ; Address Packet (DAP). Evita el límite de 18 sectores por pista
    ; de la lectura CHS clásica, necesario porque el kernel ocupa
    ; varias decenas de sectores.
    mov word [dap_count], LOADER_SECT
    mov word [dap_off],   LOADER_OFF
    mov word [dap_seg],   LOADER_SEG
    mov dword [dap_lba_lo], LOADER_LBA
    mov dword [dap_lba_hi], 0

    mov si, dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc disco_error

    mov dl, [boot_drive]   ; El cargador reutiliza DL para leer el kernel.
    jmp LOADER_SEG:LOADER_OFF

disco_error:
    mov si, msg_error
    call imprimir
    cli
.esperar:
    hlt
    jmp .esperar

imprimir:
    lodsb
    test al, al
    jz .listo
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp imprimir
.listo:
    ret

boot_drive  db 0
msg_cargando db "Fase 3: cargando el cargador grafico...", 13, 10, 0
msg_error    db "Error leyendo el disco (int 13h extendido).", 13, 10, 0

align 4
dap:
    db 0x10             ; Tamaño del paquete (16 bytes).
    db 0                ; Reservado.
dap_count:   dw 0
dap_off:     dw 0
dap_seg:     dw 0
dap_lba_lo:  dd 0
dap_lba_hi:  dd 0

times 510-($-$$) db 0
dw 0xAA55
