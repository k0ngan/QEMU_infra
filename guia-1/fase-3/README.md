# Guía 1 · Fase 3: kernel C/C++ con imagen gráfica

## Objetivo

Avanzar desde el arranque en dos etapas de la Fase 2 hasta la ejecución de un kernel mínimo
en C, compilado para un entorno *freestanding*, que valide los parámetros del framebuffer
entregados por el cargador y dibuje una imagen propia en modo gráfico.

## Arquitectura elegida

Se reutilizó y extendió la cadena de arranque propia (Fase 1 → Fase 2) en lugar de usar
GRUB + Multiboot2, porque este equipo no tiene instalados `grub-mkrescue` ni `xorriso`
(necesarios para construir una imagen ISO arrancable con GRUB) y el enunciado permite
explícitamente reutilizar el cargador propio. La cadena completa:

1. **`boot/boot_f3.asm`** (sector de arranque, 512 bytes): carga `loader_f3.bin` con lectura
   extendida por LBA (`int 0x13`, `AH=0x42`) y le transfiere el control.
2. **`boot/loader_f3.asm`** (segunda etapa, 2048 bytes, todavía en modo real):
   - Carga el kernel compilado (`kernel.bin`) desde disco con la misma lectura extendida LBA.
   - Consulta la información del modo gráfico VBE con `int 0x10`, `AX=0x4F01` (función
     *Return VBE Mode Info*) **antes** de activarlo, y la guarda en la dirección física fija
     `0x9000`.
   - Activa el modo gráfico VBE 640×480 con buffer lineal (`int 0x10`, `AX=0x4F02`,
     `BX=0x4112`, bit `0x4000` = *linear framebuffer*).
   - Habilita A20, construye una GDT plana (código y datos de 4 GB, base 0) y conmuta a modo
     protegido de 32 bits (`CR0.PE=1`).
   - En modo protegido, configura los segmentos de datos y la pila, y salta a la dirección
     física `0x20000`, donde quedó cargado el kernel.
3. **`kernel/entry.asm`**: punto de entrada en 32 bits (`_start`), fija la pila y llama a
   `kmain()` (C).
4. **`kernel/kernel.c`**: lee el bloque de información VBE desde `0x9000`, valida sus campos y
   dibuja en el framebuffer.

## Interfaz con el cargador

El cargador deja en la dirección física fija `0x9000` una copia completa del *VBE Mode Info
Block* (256 bytes, formato estándar VBE 2.0+) para el modo solicitado. El kernel lo interpreta
con una estructura `vbe_mode_info_t` (`kernel/kernel.c`) que replica los offsets oficiales:
dirección física del framebuffer (`physbase`), bytes por línea (`pitch`), resolución
(`xres`/`yres`), bits por píxel (`bpp`) y la posición de cada canal de color
(`red_position`, `green_position`, `blue_position`).

## Formato de píxeles (hallazgo durante el desarrollo)

Se asumió inicialmente que el modo VBE `0x112` (640×480) usaría 32 bits por píxel, como en
varios tutoriales de referencia. Al inspeccionar en vivo el *Mode Info Block* real que entrega
la BIOS de este equipo (con el monitor de QEMU, volcando la memoria física en `0x9000`), se
detectó que en realidad informa **24 bits por píxel** (`pitch = 1920 = 640×3`), con los campos
de color en `red_position=16`, `green_position=8`, `blue_position=0` (orden `RGB` en 3 bytes).

La primera versión del kernel validaba `bpp == 32` y, al no cumplirse, se saltaba todo el
dibujo (pantalla en negro, sin señal de error visible). La corrección fue dejar de asumir un
formato fijo: `put_pixel()` ahora compone el valor del píxel usando las posiciones de color
que realmente informó la BIOS, y escribe 3 u 4 bytes según `bpp/8`, soportando tanto 24 como
32 bpp. Esto es, en los hechos, la validación de parámetros que pide la guía antes de escribir
en memoria: sin ella, el kernel habría escrito con un formato incorrecto o simplemente no
habría dibujado nada.

## Imagen

- `assets/original/logo_f3.png`: imagen propia (96×64 px), creada para esta actividad con
  Pillow (`scripts/convertir_imagen.py` documenta el proceso); representa un emblema
  simplificado con los colores institucionales UTEM.
- `assets/converted/logo_f3.raw`: los mismos píxeles en RGB24 sin compresión, fila por fila.
- `assets/converted/logo_f3.h`: el mismo arreglo de bytes, generado automáticamente como
  arreglo de C para incluirlo directamente en `kernel.c`.
- El kernel dibuja primero un color sólido uniforme (azul UTEM `#17324D`) en toda la pantalla
  —paso recomendado por la guía para confirmar que el framebuffer responde antes de intentar
  la imagen final— y luego superpone la imagen convertida, centrada.

## Construcción

Compilador usado: `mingw-w64-ucrt-x86_64-gcc` (gcc normal de 64 bits con soporte `-m32`),
ensamblador NASM, y el enlazador del mismo paquete de binutils. Como este `ld` sólo soporta
las emulaciones PE (`i386pe`/`i386pep`), el kernel se enlaza como imagen PE32 con
`-Ttext=0x20000` y luego se convierte a binario plano con `objcopy -O binary`, descartando las
cabeceras PE — el resultado son únicamente las secciones cargables en las direcciones
correctas, igual que con un enlazador ELF tradicional.

```bash
bash scripts/build.sh
qemu-system-i386 -drive file=build/disco_f3.img,format=raw,if=ide
```

**Importante:** la imagen debe montarse como disco IDE (`if=ide`), no como disquete
(`if=floppy`). Se verificó que la BIOS de disquete emulada por QEMU no implementa la lectura
extendida por LBA (`int 0x13`, `AH=0x42`), necesaria porque el kernel ocupa más sectores de los
que permite una lectura CHS clásica dentro de una sola pista (18 sectores).

## Pruebas, resultados y evidencias

| Caso | Acción | Resultado esperado | Resultado observado | Evidencia |
| --- | --- | --- | --- | --- |
| Cargador encuentra y ejecuta el kernel | Arrancar la imagen en QEMU | El cargador llega a modo protegido y transfiere el control a `0x20000` | Confirmado con el monitor de QEMU (`info registers`): CPU en modo protegido, `EIP` dentro del rango del kernel, `HLT=1` al terminar | — (verificación por monitor, no visual) |
| Framebuffer válido antes de escribir | Revisar el *Mode Info Block* en `0x9000` | `physbase`, `pitch`, `xres`, `yres` y `bpp` coherentes con el modo solicitado | `physbase=0xfd000000`, `pitch=1920`, `640x480`, `bpp=24` | Volcado de memoria vía monitor de QEMU |
| Imagen con dimensiones, orientación y colores coherentes | Arrancar y esperar a que el kernel dibuje | Pantalla con fondo azul UTEM y el logo centrado, sin distorsión de color | Captura idéntica a lo esperado | `evidencias/arranque_f3-qemu.png` |
| Reconstrucción desde los fuentes | Borrar `build/` y correr `scripts/build.sh` de nuevo | El kernel y la imagen de disco se regeneran igual, con el mismo tamaño | Reproducible | — |

## Límites del prototipo

- Sólo soporta modos VBE de 24 o 32 bits por píxel; no implementa decodificación de formatos
  comprimidos (PNG/JPEG) dentro del kernel — la conversión a píxeles planos se hace antes,
  fuera del kernel, como indica la guía.
- No implementa teclado, interrupciones ni ningún controlador adicional: el kernel dibuja una
  vez y queda detenido (`hlt`) esperando indefinidamente.
- El tamaño máximo del kernel está acotado por `KERNEL_SECT` en `boot/loader_f3.asm` (64
  sectores = 32 KB); si el kernel compilado creciera más allá de ese límite, `scripts/build.sh`
  lo detecta y falla explícitamente en vez de truncar silenciosamente.
