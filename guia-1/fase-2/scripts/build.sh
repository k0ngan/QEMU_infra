#!/usr/bin/env bash
# Ensambla la Fase 2 y arma la imagen de disco (boot sector + segunda etapa).
# Ejecutar desde la carpeta fase-2: bash scripts/build.sh
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build

nasm -f bin src/boot_f2.asm   -o build/boot_f2.bin
nasm -f bin src/stage2_f2.asm -o build/stage2_f2.bin

SIZE_BOOT=$(wc -c < build/boot_f2.bin)
SIZE_STAGE2=$(wc -c < build/stage2_f2.bin)
echo "boot_f2.bin:   ${SIZE_BOOT} bytes (debe ser 512)"
echo "stage2_f2.bin: ${SIZE_STAGE2} bytes (debe ser 2048 = 4 sectores de 512)"

cat build/boot_f2.bin build/stage2_f2.bin > build/disco_f2.img

echo "Imagen de disco generada en build/disco_f2.img"
echo "Firma de arranque (bytes 510-511, debe ser 55 aa):"
od -An -tx1 -j510 -N2 build/boot_f2.bin
