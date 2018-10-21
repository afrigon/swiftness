#  NES Specification

[http://nesdev.com/NESDoc.pdf]

## Core Processing Unit (cpu)
- MOS 6502 chip
- 8-bit microprocessor
- 1.79 MHz clock speed (1.789773)
- 151 Opcodes

## Memory Map
- 16-bit address space (64KB possible)

### Layout
- 2KB of RAM 0x0000 - 0x0800

## Picture Processing Unit (ppu)
- 3x the clock speed of the cpu
- Renders 1 pixel per cycle
- Background layer + 64 sprites
- Sprite are 8x8 or 8x16
- Background scrolling 1 pixel at the time
- Fixed resolution 256x240 (32x30 of these 8x8 tiles)
- Pattern tables in the ROM define these tiles
- 256 bytes of Object Attribute Memory (used to store the sprite attributes of the 64 sprites)
- The attributes include the X and Y coordinate of the sprite, the tile number for the sprite and a set of flags that specified two bits of the sprite’s color, specified whether the sprite appears in front of or behind the background layer and allowed flipping the sprite vertically and/or horizontally.
- The NES supported a DMA copy from the CPU to quickly copy a chunk of 256 bytes to the entire OAM.


## Audio Processing Unit (apu)
