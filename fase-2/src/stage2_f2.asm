bits 16
org 0x8000                 ; Dirección donde boot_f2.asm carga esta etapa.

inicio:
    xor ax, ax
    mov ds, ax
    mov es, ax

    call poner_cursor
    call imprimir_dibujo

    mov si, msg_llegada
    call imprimir

menu:
    mov si, msg_menu
    call imprimir

.leer_tecla:
    mov ah, 0x00            ; Función de BIOS: esperar y leer una tecla.
    int 0x16                ; AL queda con el código ASCII de la tecla.

    cmp al, '1'
    je opcion1
    cmp al, '2'
    je opcion2
    cmp al, '0'
    je detener

    mov si, msg_invalido
    call imprimir
    jmp menu

opcion1:
    mov si, msg_opcion1
    call imprimir
    jmp menu

opcion2:
    mov si, msg_opcion2
    call imprimir
    jmp menu

detener:
    mov si, msg_despedida
    call imprimir
    cli
.esperar:
    hlt
    jmp .esperar

; Impresión de texto normal (mensajes, menú): modo teletipo puro.
; La BIOS ya interpreta CR (13) y LF (10) dentro de este modo, así que
; los mensajes con "13,10" avanzan de línea solos, sin tocar el cursor.
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

; Impresión del dibujo ASCII: aquí SÍ se controla el cursor a mano,
; porque el dibujo sólo usa LF (10) como separador y debe quedar
; indentado en la columna 26, no en la columna 0.
poner_cursor:
    mov ah, 0x02
    mov bh, 0
    mov dh, [fila]
    mov dl, 26
    int 0x10
    ret

imprimir_dibujo:
    mov si, dibujo
.loop:
    lodsb
    test al, al
    jz .listo
    cmp al, 10
    je .nueva_linea
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp .loop
.nueva_linea:
    inc byte [fila]
    call poner_cursor
    jmp .loop
.listo:
    ret

fila db 1
dibujo:
    db '.%#*******************##.', 10
    db '.%-                   -#.', 10
    db '.%-       .@@@@@@@:   -#.', 10
    db '.%-       .@@@@@@@:   -#.', 10
    db '.%-  .....:@@@@@@@:   -#.', 10
    db '.%-  -@@@@@@@@@%.     -#.', 10
    db '.#+  .%@@@@@@@@%.     *+', 10
    db ' -%   -@@@@@@@@%.    :@:', 10
    db '  .@+   .+@@@@@%.  .#*.', 10
    db '   .#%.   :*@@@%. .%+', 10
    db '     :@*     ... .#%:', 10
    db '       :%%-.   -%#.', 10
    db '         .-#%%@*.', 10
    db ' U   U TTTTT EEEEE M   M', 10
    db ' U   U   T   E     MM MM', 10
    db ' U   U   T   EEEE  M M M', 10
    db ' U   U   T   E     M   M', 10
    db '  UUU    T   EEEEE M   M', 0

msg_llegada  db 13, 10, "Fase 2: segunda etapa cargada correctamente.", 13, 10, 0
msg_menu     db 13, 10, "Menu:", 13, 10, "  1) Info NASM", 13, 10, "  2) Info QEMU", 13, 10, "  0) Detener sistema", 13, 10, "Seleccione una opcion: ", 0
msg_opcion1  db 13, 10, "NASM ensambla el codigo fuente en un binario plano, sin cabeceras.", 13, 10, 0
msg_opcion2  db 13, 10, "QEMU emula el equipo y ejecuta el binario como si fuera un disco real.", 13, 10, 0
msg_invalido db 13, 10, "Entrada no valida. Intente de nuevo.", 13, 10, 0
msg_despedida db 13, 10, "Deteniendo el sistema de forma controlada.", 13, 10, 0

times (4*512)-($-$$) db 0
