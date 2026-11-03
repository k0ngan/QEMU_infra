bits 16                    ; La BIOS inicia en modo de 16 bits.
org 0x7C00                 ; La BIOS carga este sector en la dirección 0x7C00.

start:
    ; Primero preparo los registros para que el programa use la memoria correcta.
    cli                     ; Pauso las interrupciones mientras preparo la pila.
    xor ax, ax              ; Dejo AX en cero para usarlo en los segmentos.
    mov ds, ax              ; Los datos quedan en el segmento 0.
    mov ss, ax              ; La pila también queda en el segmento 0.
    mov sp, 0x7C00          ; La pila empieza justo antes del código cargado.
    sti                     ; Vuelvo a permitir las interrupciones.
    cld                     ; Hago que LODSB avance hacia el siguiente carácter.

    ; Limpio la pantalla al entrar al modo texto de 80 por 25.
    mov ax, 0x0003
    int 0x10

    mov si, dibujo          ; SI apunta al primer carácter del logo.
    call poner_cursor       ; Empiezo a dibujar un poco más al centro.

.imprimir:
    lodsb                   ; Tomo un carácter del logo y avanzo SI.
    test al, al             ; Reviso si llegué al 0 del final.
    jz .detener             ; Si es 0, ya terminé de imprimir.
    cmp al, 10              ; El 10 separa una línea de la siguiente.
    je .siguiente_linea

    mov ah, 0x0E            ; Pido a la BIOS que muestre el carácter de AL.
    mov bx, 0x0007          ; Uso la página 0 y el color de texto normal.
    int 0x10                ; La BIOS dibuja el carácter en pantalla.
    jmp .imprimir           ; Repito hasta completar todo el dibujo.

.siguiente_linea:
    inc byte [fila]         ; Bajo una fila para continuar con el logo.
    call poner_cursor       ; Vuelvo a la misma columna en cada línea.
    jmp .imprimir

.detener:
    cli                     ; Desactivo interrupciones para dejar la imagen fija.
.esperar:
    hlt                     ; Detengo el procesador.
    jmp .esperar            ; Si continúa, vuelve a detenerse.

poner_cursor:
    mov ah, 0x02            ; Función de BIOS para mover el cursor.
    mov bh, 0               ; Trabajo en la página de pantalla 0.
    mov dh, [fila]          ; Fila donde se imprimirá la línea.
    mov dl, 26              ; Columna inicial del logo.
    int 0x10
    ret

; Adapté el escudo y las letras UTEM del dibujo original a la pantalla BIOS.
; El 10 marca el fin de cada línea; el 0 indica que terminó todo el logo.
fila db 2
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

; Relleno con ceros hasta el byte 510. Los últimos dos bytes son la firma BIOS.
times 510-($-$$) db 0
dw 0xAA55
