#include <stdint.h>
#include "../assets/converted/logo_f3.h"

/* Bloque de información de modo VBE (VBE 2.0+), tal como lo deja el
 * cargador en la dirección física fija 0x9000 tras la llamada BIOS
 * int 0x10, AX=0x4F01. Offsets según la especificación VBE. */
typedef struct __attribute__((packed)) {
    uint16_t attributes;
    uint8_t  winA, winB;
    uint16_t granularity;
    uint16_t winsize;
    uint16_t segmentA, segmentB;
    uint32_t realFctPtr;
    uint16_t pitch;
    uint16_t xres, yres;
    uint8_t  wchar, ychar, planes, bpp, banks;
    uint8_t  memory_model, bank_size, image_pages;
    uint8_t  reserved0;
    uint8_t  red_mask, red_position;
    uint8_t  green_mask, green_position;
    uint8_t  blue_mask, blue_position;
    uint8_t  rsv_mask, rsv_position;
    uint8_t  directcolor_attributes;
    uint32_t physbase;
    uint32_t reserved1;
    uint16_t reserved2;
} vbe_mode_info_t;

#define VBE_INFO_ADDR 0x9000u

/* Escribe un píxel usando el formato que realmente informó VBE (posición
 * de los campos R/G/B y bytes por píxel), en vez de asumir un formato
 * fijo. En este equipo, el modo 0x112 resultó ser 24 bpp (no 32 bpp). */
static inline void put_pixel(const vbe_mode_info_t *mi, uint32_t x, uint32_t y,
                              uint8_t r, uint8_t g, uint8_t b) {
    uint32_t val = ((uint32_t)r << mi->red_position)
                 | ((uint32_t)g << mi->green_position)
                 | ((uint32_t)b << mi->blue_position);
    uint8_t *fb = (uint8_t *)(uintptr_t)mi->physbase;
    uint32_t bpp_bytes = (uint32_t)mi->bpp / 8u;
    uint32_t offset = y * (uint32_t)mi->pitch + x * bpp_bytes;
    uint8_t *p = fb + offset;

    p[0] = (uint8_t)(val & 0xFFu);
    p[1] = (uint8_t)((val >> 8) & 0xFFu);
    p[2] = (uint8_t)((val >> 16) & 0xFFu);
    if (bpp_bytes == 4) {
        p[3] = (uint8_t)((val >> 24) & 0xFFu);
    }
}

void kmain(void) {
    const vbe_mode_info_t *mi = (const vbe_mode_info_t *)(uintptr_t)VBE_INFO_ADDR;

    /* Validar los parámetros del framebuffer antes de escribir en memoria. */
    int valido = mi->physbase != 0
              && mi->pitch != 0
              && mi->xres != 0
              && mi->yres != 0
              && (mi->bpp == 24 || mi->bpp == 32); /* Formatos que este kernel sabe escribir. */

    if (valido) {
        /* 1) Color sólido uniforme: confirma que el framebuffer responde
         *    antes de intentar dibujar la imagen final. */
        for (uint32_t y = 0; y < mi->yres; y++) {
            for (uint32_t x = 0; x < mi->xres; x++) {
                put_pixel(mi, x, y, 23, 50, 77); /* Azul UTEM #17324D. */
            }
        }

        /* Espera activa breve para que el color sólido sea observable
         * si se graba en video, antes de superponer la imagen. */
        for (volatile uint32_t i = 0; i < 25000000u; i++) { }

        /* 2) Imagen convertida (ver assets/original y assets/converted),
         *    centrada en la pantalla. */
        uint32_t ox = (mi->xres - LOGO_F3_WIDTH) / 2;
        uint32_t oy = (mi->yres - LOGO_F3_HEIGHT) / 2;
        for (uint32_t y = 0; y < LOGO_F3_HEIGHT; y++) {
            for (uint32_t x = 0; x < LOGO_F3_WIDTH; x++) {
                uint32_t idx = (y * LOGO_F3_WIDTH + x) * 3u;
                put_pixel(mi, ox + x, oy + y,
                          logo_f3_rgb[idx + 0],
                          logo_f3_rgb[idx + 1],
                          logo_f3_rgb[idx + 2]);
            }
        }
    }

    for (;;) {
        __asm__ volatile ("hlt");
    }
}
