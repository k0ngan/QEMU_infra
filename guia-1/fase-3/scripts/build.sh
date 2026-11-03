#!/usr/bin/env bash
# Ensambla el cargador, compila el kernel y arma la imagen de disco de la Fase 3.
# Ejecutar desde la carpeta fase-3: bash scripts/build.sh
set -euo pipefail
cd "$(dirname "$0")/.."

KERNEL_SECT=64
KERNEL_BYTES=$((KERNEL_SECT * 512))

mkdir -p build

nasm -f bin boot/boot_f3.asm   -o build/boot_f3.bin
nasm -f bin boot/loader_f3.asm -o build/loader_f3.bin

nasm -f win32 kernel/entry.asm -o build/entry.o
gcc -m32 -ffreestanding -O2 -Wall -Wextra -fno-pic -fno-pie -fno-stack-protector \
    -c kernel/kernel.c -o build/kernel.o
ld -m i386pe -Ttext=0x20000 -e _start --oformat pei-i386 \
   -o build/kernel.exe build/entry.o build/kernel.o
objcopy -O binary build/kernel.exe build/kernel.bin

KSIZE=$(wc -c < build/kernel.bin)
echo "boot_f3.bin:   $(wc -c < build/boot_f3.bin) bytes (debe ser 512)"
echo "loader_f3.bin: $(wc -c < build/loader_f3.bin) bytes (debe ser 2048)"
echo "kernel.bin:    ${KSIZE} bytes (limite ${KERNEL_BYTES}, KERNEL_SECT=${KERNEL_SECT} en loader_f3.asm)"

if [ "$KSIZE" -gt "$KERNEL_BYTES" ]; then
  echo "ERROR: el kernel excede KERNEL_SECT. Aumenta la constante en boot/loader_f3.asm" >&2
  exit 1
fi

cp build/kernel.bin build/kernel_padded.bin
PAD=$((KERNEL_BYTES - KSIZE))
if [ "$PAD" -gt 0 ]; then
  dd if=/dev/zero bs=1 count="$PAD" >> build/kernel_padded.bin 2>/dev/null
fi

cat build/boot_f3.bin build/loader_f3.bin build/kernel_padded.bin > build/disco_f3.img

echo "Imagen de disco generada en build/disco_f3.img"
echo "Firma de arranque (bytes 510-511, debe ser 55 aa):"
od -An -tx1 -j510 -N2 build/boot_f3.bin
