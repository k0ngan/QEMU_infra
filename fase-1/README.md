# Guía 1 · Fase 1: sector de arranque

## Objetivo

Arrancar un sector BIOS de 512 bytes y mostrar una adaptación en modo texto del logo UTEM proporcionado para esta guía.

El arte ASCII de referencia fue aportado para el proyecto. Lo reduje y ajusté a caracteres que caben en un sector y en la pantalla de texto BIOS; el diseño de referencia se generó con «Image to ASCII Art». La procedencia de la imagen original usada en esa conversión debe identificarse antes de la entrega.

## Requisitos

NASM y `qemu-system-i386` disponibles en `PATH`. Esta fase usa arranque BIOS tradicional en modo real. La versión comprobada fue NASM 2.16.03 y QEMU 11.0.92 para Windows x64. Git sirve para registrar los cambios y GitHub para publicar el repositorio de entrega; ninguno interviene al arrancar el sector.

## Archivos

- `boot_f1.asm`: código fuente del sector de arranque.
- `build/boot_f1.bin`: binario generado al compilar.
- `evidencias/arranque_f1-qemu.png`: captura del arranque, una vez ejecutado en QEMU.

## Abrir los archivos

Desde PowerShell, situado en la carpeta `guia-1`, entra a esta fase:

```powershell
cd .\fase-1
```

Para leer y editar el código, abre `boot_f1.asm` con un editor de texto. Por ejemplo:

```powershell
notepad .\boot_f1.asm
```

Para ver el resultado que obtuve en QEMU, abre la captura:

```powershell
Start-Process .\evidencias\arranque_f1-qemu.png
```

`build/boot_f1.bin` es el sector compilado, así que se ejecuta en QEMU con el comando de abajo; al abrirlo como texto no se verá el dibujo.

## Compilar y ejecutar

Ejecutar desde `guia-1/fase-1` en PowerShell:

```powershell
New-Item -ItemType Directory -Force build
nasm -f bin boot_f1.asm -o build/boot_f1.bin
qemu-system-i386 -drive file=build/boot_f1.bin,format=raw,if=floppy
```

## Verificación

Comprobar que el binario mide exactamente 512 bytes:

```powershell
(Get-Item .\build\boot_f1.bin).Length
```

Comprobar la firma de arranque, que debe mostrar `55 AA`:

```powershell
$sector = [IO.File]::ReadAllBytes((Resolve-Path .\build\boot_f1.bin))
'{0:X2} {1:X2}' -f $sector[510], $sector[511]
```

Resultado observado: el binario mide 512 bytes, termina en `55 AA` y QEMU muestra el logo completo en pantalla. La captura de esa ejecución está en `evidencias/arranque_f1-qemu.png` y corresponde al fuente incluido. La emulación permitió probar el arranque sin escribir el sector en un disco físico.

## Cómo funciona

La BIOS carga el sector en `0x7C00`. La interrupción `int 0x10`, con `AH=0x0E`, imprime cada carácter. Cuando encuentra el byte `10`, el programa baja una fila y vuelve a la columna inicial para dibujar la siguiente línea del logo. Los últimos dos bytes del sector son la firma de arranque `55 AA`.
