# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Atari 2600 development project focused on experimenting with playfield graphics, display kernels, and visual effects. The code is written in 6502 assembly language and targets the Atari VCS/2600 console using the DASM assembler.

## Architecture

### Display Architecture

The Atari 2600 uses a scanline-based rendering system with strict timing constraints:
- **NTSC**: 262 scanlines at 60 Hz
- **PAL**: 312 scanlines at 50 Hz
- Each scanline requires exactly 76 machine cycles
- The TIA (Television Interface Adaptor) generates video in real-time

### Frame Structure

Every frame consists of three main sections:

1. **Vertical Sync (3 scanlines)**: Signal the TV to start a new frame
2. **Vertical Blank (37 scanlines)**: Off-screen preparation time for game logic
3. **Visible Display (192 scanlines)**: The playfield kernel draws the visible frame
4. **Overscan (30 scanlines)**: Bottom margin and cleanup

### Hardware Components

- **6502 CPU**: 1.19 MHz processor with 128 bytes of RAM
- **TIA**: Graphics chip with registers for playfield, sprites, colors
- **PIA/RIOT (6532)**: Peripheral Interface Adaptor with timers and I/O ports

## File Organization

### Core Assembly Files

- `kernel_*.asm` - Display kernel experiments (numbered versions track development)
  - `kernel_01.asm` through `kernel_19.asm` - Progressive kernel development
  - `kernel_06.x.asm` - Sub-versions exploring different approaches
  - `kernel_10.x.asm` - Color manipulation experiments
- `playfield_*.asm` - Playfield pattern experiments
- `boilerplate.asm` - Template for new projects

### Include Files

- `vcs.h` - TIA and RIOT hardware register definitions (standard Atari 2600 header)
- `macro.h` - Standard DASM macros (VERTICAL_SYNC, CLEAN_START, SLEEP, SET_POINTER)
- `macros2.h` - Extended 16-bit arithmetic macros (_INC16, _ADD16, _MUL16, _ASL16, _ROR16, _EOR16, etc.)
- `math.h` - 6502 mathematical algorithms library
- `digits.h` - Number display routines
- `build.h` - Build configuration

### Output Directory

- `bin/` - Contains assembled binaries and listing files
  - `*.bin` - 4KB ROM images (Atari 2600 cartridge format)
  - `*.lst` - Assembly listing files with cycle counts and addresses
  - `*.sym` - Symbol tables for debugging

### Pattern Library

- `playfields/` - Reusable playfield patterns
  - `pf_activision.asm` - Activision-style patterns
  - `pf_atari.asm` - Atari-style patterns
  - `pf_combat.asm` - Combat game patterns
  - `pf_pattern.asm` - Generic patterns

## Development Workflow

### Building

The project uses DASM (6502 assembler) with custom compiler settings configured in `.vscode/settings.json`. The typical build command format is:

```bash
dasm <source>.asm -f3 -v5 -o bin/<source>.asm.bin -l bin/<source>.asm.lst -s bin/<source>.asm.sym
```

Where:
- `-f3` - Output format 3 (raw binary)
- `-v5` - Verbosity level 5
- `-o` - Output binary file
- `-l` - Generate listing file
- `-s` - Generate symbol file

### Memory Map

```
$0080-$009F: Temporary variables (temp segment)
$0090-$00FF: Program variables (vars segment)
$F000-$FFFF: Program ROM (main segment)
$FFFA-$FFFF: Interrupt vectors (NMI, RESET, IRQ)
```

### Common Patterns

#### Frame Loop Structure

```assembly
reset:
    CLEAN_START              ; Initialize system

nextframe:
    VERTICAL_SYNC            ; 3 scanlines

    ; Vertical blank (37 scanlines)
    lda #44
    sta TIM64T               ; Start timer
    ; ... game logic ...
    lda INTIM
    bne .-3                  ; Wait for timer

    ; Display kernel (192 scanlines)
    lda #0
    sta WSYNC
    sta VBLANK               ; Enable display

    ldy #PF_H
kernel:
    sta WSYNC                ; Each scanline
    ; ... draw graphics ...
    dey
    bne kernel

    ; Overscan (30 scanlines)
    lda #35
    sta TIM64T
    lda #$2
    sta VBLANK               ; Disable display
    ; ... cleanup ...
    lda INTIM
    bne .-3

    jmp nextframe
```

#### Timing with Timers

The PIA timer can use four intervals:
- `TIM1T` - 1 clock cycle intervals
- `TIM8T` - 8 clock cycle intervals
- `TIM64T` - 64 clock cycle intervals (most common)
- `T1024T` - 1024 clock cycle intervals

Read the current value with `INTIM`. Timer reaches 0, holds for one interval, then wraps to $FF and decrements each cycle.

## Kernel Development

### Active Development Areas

Recent work focuses on:
- Color animation effects (kernel_10.2 with modified colors)
- Background color manipulation with fire effects (kernel_06.8)
- Joystick interaction for speed control (kernel_06.x series)
- Bytebeat audio experiments (kernel_17)
- 16-bit counter implementations (kernel_15, kernel_16)
- Sound integration (kernel_14)

### Cycle-Counted Kernels

Display kernels must be precisely cycle-counted to stay synchronized with the TIA. Each visible scanline has exactly 76 cycles (68 visible + 8 for WSYNC/overhead). Use `SLEEP` macro for precise delays.

### Color and Playfield Registers

- `COLUBK` - Background color
- `COLUPF` - Playfield color
- `COLUP0/COLUP1` - Player sprite colors
- `PF0/PF1/PF2` - Playfield pattern registers (20-bit total, mirrored or repeated)
- `CTRLPF` - Playfield control (mirroring, priority, ball size)

### Key Macros

From `macro.h`:
- `CLEAN_START` - Initialize all RAM and registers to 0
- `VERTICAL_SYNC` - Generate proper 3-scanline vertical sync
- `SLEEP n` - Burn exactly n cycles (n > 1)
- `SET_POINTER ptr, addr` - Load 16-bit address into RAM pointer

From `macros2.h`:
- `_INC16 addr` - Increment 16-bit value
- `_ADD16 src1, src2, dest` - Add two 16-bit values
- `_MUL16 val1, val2, result` - Multiply 16-bit values
- `_ASL16 val, result` - Arithmetic shift left 16-bit
- `_ROR16 val, result` - Rotate right 16-bit
- `_EOR16 val1, val2, result` - XOR two 16-bit values
- `_REVBITS val` - Reverse bit order (uses reversedOrderBits lookup table)

## Version Control Conventions

Commit messages follow the pattern:
- `dev: <description>` for development commits
- Focus on kernel version numbers and key features being tested
- Examples: "dev: kernel_10.2 modified colors", "dev: kernel_06.8 plays background color on fire"

## Important Constants

```assembly
PF_H        equ 192     ; Standard playfield height
MIN_SPEED   equ 8-16    ; Speed control ranges (varies by kernel)
MAX_COLORS  equ 8       ; Color palette size
```

## Testing and Debugging

Listing files (`.lst`) in `bin/` show:
- Assembled addresses
- Cycle counts for instructions
- Full source with macro expansions

Symbol files (`.sym`) list all labels and their addresses for debugging with emulators.

## Educational Context

This project is associated with 8blit educational content (Email: 8blit0@gmail.com, YouTube videos linked in some source files). The code explores low-level graphics programming and precise timing control on 1970s hardware.
