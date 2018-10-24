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


## To watch out
- Make sure the stack offset is good
- Make sure every operation can't overflow it's integer
- Make sure the cycles are synced
- Make sure the mirrors work
- Make sure the cpu addressing is working (mostly indirect)

```swift
enum Operation {
    case nop     // nothing

    // math
    case adc    // addition
    case sbc    // substraction
    case inc    // increment a
    case inx    // increment x
    case iny    // increment y
    case dec    // decrement a
    case dex    // decrement x
    case dey    // decrement y

    // bit manipulation
    case bit
    case and    // and
    case ora    // or
    case eor    // xor
    case asl    // left shift by 1
    case lsr    // right shift by 1
    case rol    // rotate left by 1
    case ror    // rotate right by 1

    // accumulator
    case asla   // left shift a by 1
    case lsra   // right shift a by 1
    case rola   // rotate left a by 1
    case rora   // rotate right a by 1

    // flags
    case clc    // clear carry
    case cld    // clear decimal mode
    case cli    // clear interupt disable status
    case clv    // clear overflow
    case sec    // set carry
    case sed    // set decimal mode
    case sei    // set interupt disable status

    // comparison
    case cmp    // compare with A
    case cpx    // compare with X
    case cpy    // compare with Y

    // branch
    case beq    // branch if result == 0
    case bmi    // branch if result < 0
    case bne    // branch if result != 0
    case bpl    // branch if result > 0

    // flag branch
    case bcc    // branch if carry == 0
    case bcs    // branch if carry == 1
    case bvc    // branch if overflow == 0
    case bvs    // branch if overflow == 1

    // jump
    case jmp    // jump to location

    // subroutines
    case jsr    // push PC, jmp
    case rts    // return from subroutine

    // interuptions
    case rti    // return from interrupt
    case brk    // force break

    // stack
    case pha    // push A
    case php    // push P
    case pla    // pop A
    case plp    // pop P

    // loading
    case lda    // load into A
    case ldx    // load into X
    case ldy    // load into Y

    // storing
    case sta    // store from A
    case stx    // store from X
    case sty    // store from Y

    // transfering
    case tax    // mov  X, A
    case tay    // mov  Y, A
    case tsx    // mov  X, S
    case txa    // mov  A, X
    case txs    // mov  S, X
    case tya    // mov  A, Y
}
```
