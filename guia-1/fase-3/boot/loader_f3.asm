bits 16
org 0x8000                 ; Dirección donde boot_f3.asm carga este cargador.

VBE_INFO_SEG equ 0x0000    ; El bloque de información VBE queda en 0x0000:0x9000.
VBE_INFO_OFF equ 0x9000
VBE_MODE     equ 0x112     ; Modo VBE 640x480, 32 bpp.
VBE_MODE_LFB equ 0x4112    ; Mismo modo + bit de buffer lineal (0x4000).

KERNEL_SEG  equ 0x2000     ; El kernel se carga en 0x2000:0x0000 = físico 0x20000.
KERNEL_OFF  equ 0x0000
KERNEL_LBA  equ 5          ; LBA 5 en adelante (0=boot, 1-4=este cargador).
KERNEL_SECT equ 64         ; 64 sectores = 32768 bytes; el kernel compilado mide ~28 KB.

CODE_SEG equ 0x08
DATA_SEG equ 0x10

inicio:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov [boot_drive], dl

    mov si, msg_cargando_kernel
    call imprimir

    ; --- Cargar el kernel con lectura extendida (LBA) ---
    mov word [dap_count], KERNEL_SECT
    mov word [dap_off],   KERNEL_OFF
    mov word [dap_seg],   KERNEL_SEG
    mov dword [dap_lba_lo], KERNEL_LBA
    mov dword [dap_lba_hi], 0

    mov si, dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc error_disco

    mov si, msg_modo_grafico
    call imprimir

    ; --- Consultar información del modo VBE (antes de activarlo) ---
    mov ax, VBE_INFO_SEG
    mov es, ax
    mov di, VBE_INFO_OFF
    mov cx, VBE_MODE
    mov ax, 0x4F01
    int 0x10
    cmp ax, 0x004F
    jne error_vbe

    ; --- Activar el modo gráfico con buffer lineal (LFB) ---
    mov bx, VBE_MODE_LFB
    mov ax, 0x4F02
    int 0x10
    cmp ax, 0x004F
    jne error_vbe

    jmp activar_pmode

error_disco:
    mov si, msg_error_disco
    call imprimir
    jmp detener

error_vbe:
    mov si, msg_error_vbe
    call imprimir
    jmp detener

detener:
    cli
.hang:
    hlt
    jmp .hang

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

activar_pmode:
    cli

    ; Habilitar A20 mediante el "fast A20 gate" del puerto 0x92.
    in al, 0x92
    or al, 2
    out 0x92, al

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:proteg_entry

bits 32
proteg_entry:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000        ; Pila por debajo de 640 KB, lejos del kernel y del info VBE.

    jmp 0x20000              ; Traspaso de control al kernel (ver kernel/entry.asm).

bits 16
msg_cargando_kernel db "Fase 3: cargando kernel...", 13, 10, 0
msg_modo_grafico     db "Fase 3: activando modo grafico VBE 640x480x32...", 13, 10, 0
msg_error_disco      db "Error leyendo el kernel del disco (int 13h extendido).", 13, 10, 0
msg_error_vbe        db "Error: el modo VBE solicitado no esta disponible.", 13, 10, 0

boot_drive db 0

align 4
dap:
    db 0x10
    db 0
dap_count:  dw 0
dap_off:    dw 0
dap_seg:    dw 0
dap_lba_lo: dd 0
dap_lba_hi: dd 0

align 8
gdt_inicio:
    dq 0                                  ; Descriptor nulo, obligatorio.
    ; Código: base 0, límite 4 GB, presente, ejecutable/legible, 32 bits.
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00
    ; Datos: base 0, límite 4 GB, presente, escribible, 32 bits.
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt_fin:

gdt_descriptor:
    dw gdt_fin - gdt_inicio - 1
    dd gdt_inicio

times (4*512)-($-$$) db 0
