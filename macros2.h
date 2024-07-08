    MAC _CLR16 
        LDA #0
        STA {1}+0
        STA {1}+1
    ENDM


;------------------------------------------------
; Arithmetic Operations
;------------------------------------------------

; Increment the 16 bit value at location MEM
; by one.
;
; On exit: A, X & Y are unchanged.

    MAC _INC16      ;MACRO MEM
      INC {1}+0
      BNE _DONE
      INC {1}+1
_DONE      EQU *
      ENDM

; Add two 16 bit numbers together and store the
; result in another memory location. RES may be
; the same as either VLA or VLB.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _ADD16      ;MACRO VLA,VLB,RES
      IF {1} != {2}
        CLC
        LDA {1}+0
       ADC {2}+0
       STA {3}+0
       LDA {1}+1
       ADC {2}+1
       STA {3}+1
      ELSE
       _ASL16 {1},{3}
      ENDIF
      ENDM

      


; Calculate the 16 bit product of two 16 bit
; unsigned numbers. Any overflow during the
; calculation is lost. The number at location
; VLA is destroyed.
;
; On exit: A = ??, X = $FF, Y is unchanged.

  MAC _MUL16      ;MACRO VLA,VLB,RES
    _CLR16 {3}
    LDX #16
._LOOP
    _ASL16 {3},{3}
    _ASL16 {1},{1}
    BCC ._NEXT
    _ADD16 {2},{3},{3}
._NEXT
    DEX
    BPL ._LOOP
  ; Count cycles for macro calls
  ; _CLR16: 6 cycles
  ; _ASL16: 6 cycles
  ; _ASL16: 6 cycles
  ; _ADD16: 12 cycles
  ; Total cycles: 30 cycles
  ENDM


;------------------------------------------------
; Shift Operations
;------------------------------------------------

; Perform an arithmetic shift left on the 16 bit
; number at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _ASL16      ;MACRO VLA,RES
      IF {1} != {2}
       LDA {1}+0
       ASL 
       STA {2}+0
       LDA {1}+1
       ROL 
       STA {2}+1
      ELSE
       ASL {1}+0
       ROL {1}+1
      ENDIF
      ENDM

; Perform a right rotation on the 16 bit number
; at location VLA and store the result at
; location RES. If VLA and RES are the same then
; the operation is applied directly to the memory
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

      MAC _ROR16
      IF {1} != {2}
       LDA {1}+1
       ROR 
       STA {2}+1
       LDA {1}+0
       ROR 
       STA {2}+0
      ELSE
       ROR {1}+1
       ROR {1}+0
      ENDIF
      ENDM

; Perform a left rotation on the 16 bit number at
; location VLA and store the result at location
; RES. If VLA and RES are the same then the
; operation is applied directly to the memory,
; otherwise it is done in the accumulator.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _ROL16      ;MACRO VLA,RES
      IF {1} != {2}
       LDA {1}+0
       ROL 
       STA {2}+0
       LDA {1}+1
       ROL 
       STA {2}+1
      ELSE
       ROL {1}+0
       ROL {1}+1
      ENDIF
      ENDM

; Calculate the logical OR of the two 16 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _XFR16.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _ORA16      ;MACRO VLA,VLB,RES
      IF {1} != {2}
       LDA {1}+0
       ORA {2}+0
       STA {3}+0
       LDA {1}+1
       ORA {2}+1
       STA {3}+1
      ELSE
       _XFR16 {1},{3}
      ENDIF
      ENDM



      MAC _REV8 ;reverseBits:
          ldx {1}+0
          lda {2},x      ; Load the value to be reversed from memory
      ENDM   

; Transfer 2 bytes of memory from one location to
; another using the accumulator. The order in
; which the bytes are moved depends on the
; relative positions of SRC and DST. If SRC and
; DST are the same then no code is generated.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _XFR16      ;MACRO SRC,DST
      IF {1} != {2}
       IF {1} > {2}
        LDA {1}+0
        STA {2}+0
        LDA {1}+1
        STA {2}+1
       ELSE
        LDA {1}+1
        STA {2}+1
        LDA {1}+0
        STA {2}+0
       ENDIF
      ENDIF
      ENDM


; Calculate the exclusive OR of a 16 value at
; location VLA with a constant value and
; store the result at location RES.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _EOR16I      ;MACRO VLA,NUM,RES
       LDA {1}+0
       EOR <{2}
       STA {3}+0
       LDA {1}+1
       EOR >{2}
       STA {3}+1
      ENDM

    MAC _REVBITS     
                ldx {1}+0
                lda reversedOrderBits,x      ; Load the value to be reversed from memory
                sta {1}+0 
                ldx {1}+1
                lda reversedOrderBits,x      ; Load the value to be reversed from memory
                sta {1}+1 
            ENDM


; Calculate the exclusive OR of the two 16 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _CLR16.
;
; On exit: A = ??, X & Y are unchanged.

    MAC _EOR16      ;MACRO VLA,VLB,RES
      IF {1} != {2}
       LDA {1}+0
       EOR {2}+0
       STA {3}+0
       LDA {1}+1
       EOR {2}+1
       STA {3}+1
      ELSE
       _CLR16 {3}
      ENDIF
      ENDM




; Calculate the logical AND of the two 16 bit
; values at locations VLA and VLB. The result is
; stored in location RES. If VLA and VLB are the
; same the macro expands to a _XFR16.
;
; On exit: A = ??, X & Y are unchanged.

      MAC _AND16      ;MACRO VLA,VLB,RES
      IF {1} != {2}
       LDA {1}+0
       AND {2}+0
       STA {3}+0
       LDA {1}+1
       AND {2}+1
       STA {3}+1
      ELSE
       _XFR16 {1},{3}
      ENDIF
      ENDM