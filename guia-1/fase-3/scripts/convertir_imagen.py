"""Convierte assets/original/logo_f3.png a pixeles RGB24 sin compresion.

Uso: python convertir_imagen.py
Genera:
  - assets/converted/logo_f3.raw  (bytes crudos R,G,B por pixel, fila por fila)
  - assets/converted/logo_f3.h    (arreglo C generado desde el .raw)

El kernel NO asume un formato de framebuffer fijo: recibe estos valores RGB
puros y los recompone al formato real (posicion de los campos R/G/B) que
informa VBE en tiempo de ejecucion, validado antes de escribir en memoria.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ORIGINAL = ROOT / "assets" / "original" / "logo_f3.png"
RAW_OUT = ROOT / "assets" / "converted" / "logo_f3.raw"
HEADER_OUT = ROOT / "assets" / "converted" / "logo_f3.h"

img = Image.open(ORIGINAL).convert("RGB")
w, h = img.size
pixels = img.tobytes()  # RGB RGB RGB..., fila por fila, sin compresion.

RAW_OUT.write_bytes(pixels)

with HEADER_OUT.open("w") as f:
    f.write("/* Generado por scripts/convertir_imagen.py a partir de\n")
    f.write(" * assets/original/logo_f3.png. No editar a mano. */\n")
    f.write("#ifndef LOGO_F3_H\n#define LOGO_F3_H\n\n")
    f.write(f"#define LOGO_F3_WIDTH  {w}\n")
    f.write(f"#define LOGO_F3_HEIGHT {h}\n\n")
    f.write("static const unsigned char logo_f3_rgb[")
    f.write(f"{w*h*3}] = {{\n")
    for i, b in enumerate(pixels):
        f.write(f"{b},")
        if (i + 1) % 20 == 0:
            f.write("\n")
    f.write("\n};\n\n#endif\n")

print(f"Imagen {w}x{h}, {len(pixels)} bytes RGB -> {RAW_OUT} y {HEADER_OUT}")
