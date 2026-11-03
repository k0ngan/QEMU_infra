# Guía 1 · Fase 2: arranque en dos etapas e interacción

## Objetivo

Ampliar el sector de arranque de la Fase 1 para que localice y cargue una **segunda etapa**
desde una imagen de disco, le transfiera el control, y que esa segunda etapa conserve el logo
ASCII y agregue un **menú interactivo** que responda a la entrada del teclado.

## Mapa de disco

| Sector (1-based, CHS: cilindro 0, cabeza 0) | Contenido | Tamaño |
| --- | --- | --- |
| 1 | `boot_f2.bin` — sector de arranque | 512 bytes |
| 2–5 | `stage2_f2.bin` — segunda etapa | 2048 bytes (4 sectores) |

La imagen final `build/disco_f2.img` es la concatenación exacta de ambos binarios
(`boot_f2.bin` + `stage2_f2.bin`), sin relleno adicional entre ellos.

## Interfaz entre etapas

- El sector de arranque (`boot_f2.asm`) usa `int 0x13`, función `AH=0x02` (leer sectores),
  con lectura **CHS**: cilindro 0, cabeza 0, sector inicial 2, 4 sectores. El disco de arranque
  (`DL`) lo entrega la BIOS en el registro `DL` al momento de transferir el control al sector
  de arranque; se guarda en la variable `boot_drive` y se reutiliza para la lectura.
- La segunda etapa se carga en la dirección física `0x0000:0x8000` (segmento 0, offset
  `0x8000`), fuera del área de 512 bytes del sector de arranque, con margen suficiente antes
  de la pila (`SP=0x7C00`) y después del propio sector de arranque.
- Tras una lectura exitosa, el sector de arranque hace `jmp 0x0000:0x8000` para transferir el
  control sin retorno. Si `int 0x13` falla (`carry flag` activo), se muestra un mensaje de
  error y el sistema se detiene con `cli; hlt`.
- La segunda etapa (`stage2_f2.asm`) usa `org 0x8000` para que todas sus direcciones
  coincidan con la dirección real de carga.

## Menú e interacción

La segunda etapa muestra el logo ASCII (reutilizado de la Fase 1) y luego un menú con tres
opciones, leídas con `int 0x16`, función `AH=0x00` (esperar y leer tecla):

- `1` → muestra información sobre NASM.
- `2` → muestra información sobre QEMU.
- `0` → detiene el sistema de forma controlada (`cli; hlt`).
- Cualquier otra tecla → mensaje "Entrada no válida. Intente de nuevo." y vuelve a mostrar el
  menú (no se bloquea el sistema).

Después de cada opción válida (`1` o `2`), el menú se vuelve a mostrar para permitir elegir
otra opción, hasta que se selecciona `0`.

## Archivos

- `src/boot_f2.asm`: sector de arranque (512 bytes).
- `src/stage2_f2.asm`: segunda etapa (2048 bytes, logo + menú).
- `scripts/build.sh`: ensambla ambas etapas y arma `build/disco_f2.img`.
- `build/`: binarios generados (no versionados; se reconstruyen con el script).
- `evidencias/`: capturas de cada caso de prueba.

## Compilar y ejecutar

Desde la carpeta `fase-2`, con `nasm` y `qemu-system-i386` disponibles en el `PATH`
(en este equipo están en `C:\msys64\ucrt64\bin`):

```bash
bash scripts/build.sh
qemu-system-i386 -drive file=build/disco_f2.img,format=raw,if=floppy
```

El script de build también imprime los tamaños de cada binario y la firma de arranque
(`55 aa`) para verificación rápida.

## Pruebas, resultados y evidencias

| Caso | Acción | Resultado esperado | Resultado observado | Evidencia |
| --- | --- | --- | --- | --- |
| Arranque normal | Iniciar la imagen en QEMU | Llega a la segunda etapa, muestra el logo ASCII y el menú | Logo y menú visibles correctamente | `evidencias/arranque_f2-qemu.png` |
| Opción `1` | Presionar `1` en el menú | Muestra información de NASM y vuelve al menú | Mensaje mostrado correctamente, menú reaparece | `evidencias/opcion1_f2-qemu.png` |
| Opción `2` | Presionar `2` en el menú | Muestra información de QEMU y vuelve al menú | Mensaje mostrado correctamente, menú reaparece | `evidencias/opcion2_f2-qemu.png` |
| Entrada no válida | Presionar una tecla distinta de `0`, `1`, `2` (por ejemplo `x`) | Muestra mensaje de entrada no válida y vuelve al menú, sin bloquearse | Mensaje mostrado, menú reaparece, sistema sigue respondiendo | `evidencias/entrada_invalida_f2-qemu.png` |
| Detención controlada | Presionar `0` | Muestra mensaje de despedida y detiene el sistema (`hlt`) | Mensaje mostrado, sistema detenido | `evidencias/detener_f2-qemu.png` |

Las capturas se generaron con el monitor de QEMU en modo headless (`-display none -monitor
tcp:...`), enviando teclas con `sendkey` y capturando pantalla con `screendump`, lo que permite
automatizar y reproducir exactamente esta misma secuencia de pruebas.

## Problema encontrado y corregido

La primera versión reutilizó, para los mensajes del menú, la misma rutina de impresión que
usa el logo ASCII — una rutina que reposiciona manualmente el cursor en la columna 26 cada vez
que encuentra un salto de línea (`10`). Como los mensajes normales ya traen `13,10` (retorno de
carro + salto de línea) para que la BIOS los maneje sola en modo teletipo, esa reposición manual
pisaba el cursor y cortaba caracteres (por ejemplo, "Seleccione" aparecía como "eleccione"). La
corrección fue separar dos rutinas: `imprimir_dibujo` (con control manual de cursor, sólo para
el logo) e `imprimir` (teletipo puro, para todo el texto normal, dejando que la BIOS interprete
`13` y `10`). Se verificó visualmente con las capturas de esta carpeta que el texto ya no se
corta en ningún caso.
