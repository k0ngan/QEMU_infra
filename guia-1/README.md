# Guía 1: Boot de Micro S.O. en QEMU

Asignatura: INFB6074 · Infraestructura para Ciencia de Datos (UTEM, 2026-2).

Entrega: 04 de noviembre de 2026, 23:59 hrs. Presentación: 05 de noviembre de 2026, telemática.

## Estado

| Fase | Estado | Contenido |
| --- | --- | --- |
| [Fase 1](fase-1/README.md) | Implementada y probada en QEMU | Sector BIOS, logo ASCII y captura |
| [Fase 2](fase-2/README.md) | Implementada y probada en QEMU | Arranque en dos etapas, menú interactivo |
| [Fase 3](fase-3/README.md) | Implementada y probada en QEMU | Kernel C freestanding, modo gráfico VBE, imagen propia |

Pendiente: `informe_guia1.pdf` (máx. 5 páginas, integra las tres fases), vídeo único de
presentación (`evidencias/video_guia1.mp4`), repositorio personal en GitHub y entrega del
enlace en el canal indicado.

## Herramientas

Se usaron NASM, QEMU y `mingw-w64-ucrt-x86_64-gcc` (para la Fase 3), todos disponibles en
`C:\msys64\ucrt64\bin` en este equipo. Git registra los cambios; GitHub alojará el repositorio
personal de entrega.

## Revisión rápida por fase

- **Fase 1** — [instrucciones](fase-1/README.md). Sector de arranque con logo ASCII del
  escudo UTEM. Evidencia: `fase-1/evidencias/arranque_f1-qemu.png`.
- **Fase 2** — [instrucciones](fase-2/README.md). Arranque en dos etapas con menú interactivo
  (3 opciones, entrada inválida con reintento). Evidencias: `fase-2/evidencias/*.png`.
- **Fase 3** — [instrucciones](fase-3/README.md). Kernel C freestanding cargado por un
  cargador propio (sin GRUB), modo gráfico VBE 640×480, imagen propia convertida a píxeles.
  Evidencia: `fase-3/evidencias/arranque_f3-qemu.png`.

Para grabar la demostración, ver el [guion de video](evidencias/guion_video_fase1.md) (cubre
la Fase 1; falta ampliarlo con las Fases 2 y 3 antes de grabar el video único de la guía).

## Reconstrucción desde cero

Cada fase tiene su propio `scripts/build.sh` (o equivalente) que ensambla/compila desde los
fuentes y arma la imagen de disco correspondiente; ver el README de cada fase para los
comandos exactos de compilación y ejecución en QEMU.
