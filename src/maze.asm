; 6502 assembly code for generating a random maze
; Compatible with Stella emulator

    processor 6502

    org $F000

; Entry point
start:
    ; Initialize random seed
    ldx #$12        ; Load random seed value into X register
    stx rand_seed  ; Store random seed
    lda #$34
    sta rand_seed + 1

    ; Call generateMaze function
    jsr generateMaze

    ; Infinite loop
loop:
    jmp loop

; Function to generate maze data
generateMaze:
    ldx #$00      ; Initialize loop counter in X register

x:  .byte 0

generateMazeLoop:
    lda rand_seed       ; Load random seed
    clc                 ; Clear carry flag
    adc maze_ptr        ; Add loop counter to random seed
    tax                 ; Store result in X register
    lda rand_seed + 1   ; Load second byte of random seed
    adc maze_ptr + 1    ; Add loop counter to second byte of random seed
    sta rand_seed + 1   ; Store result back in random seed
    lda random_values, x  ; Load random value from table
    sta maze_data, x   ; Store random value in maze data
    inx                 ; Increment loop counter
    cpx #128            ; Check if loop counter reached 128
    bne generateMazeLoop  ; Branch if not zero
    rts                 ; Return from subroutine

; Random values table
random_values:
    .byte 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF ; Add more random values as needed

; Random seed (initialize with non-zero value)
rand_seed:  .word $1234

; Maze data
maze_data:
    .byte 128 * 0      ; Initialize maze data with zeros

; Maze pointer
maze_ptr:   .byte 0          ; Pointer to current position in maze data

; End of program
    .end

