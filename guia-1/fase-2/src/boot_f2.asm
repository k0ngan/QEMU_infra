bits 16
org 0x7C00                 ; La BIOS carga este sector de arranque en 0x7C00.

STAGE2_SEG    equ 0x0000   ; La segunda etapa se carga en 0x0000:0x8000.
STAGE2_OFF    equ 0x8000
STAGE2_SECT   equ 4        ; Cantidad de sectores de 512 bytes de la segunda etapa.
STAGE2_START  equ 2        ; Sector (1-based) donde empieza la segunda etapa; el 1 es este sector.

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov [boot_drive], dl   ; La BIOS entrega el disco de arranque en DL.

    mov ax, 0x0003          ; Modo texto 80x25, limpia pantalla.
    int 0x10

    mov si, msg_cargando
    call imprimir

    ; Lectura CHS con int 0x13: cilindro 0, cabeza 0, sector STAGE2_START,
    ; STAGE2_SECT sectores, hacia STAGE2_SEG:STAGE2_OFF.
    mov ax, STAGE2_SEG
    mov es, ax
    mov bx, STAGE2_OFF

    mov ah, 0x02
    mov al, STAGE2_SECT
    mov ch, 0
    mov cl, STAGE2_START
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disco_error

    ; Traspaso de control a la segunda etapa.
    jmp STAGE2_SEG:STAGE2_OFF

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
msg_cargando db "Fase 2: cargando segunda etapa desde el sector 2...", 13, 10, 0
msg_error    db "Error leyendo el disco (int 13h).", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
