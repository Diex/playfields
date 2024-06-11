;***********************************************************************
;**                                                                   **
;**           Symmetrical Playfield Left Scrolling  V1.00             **
;**                  Christian Bogey - May 12,2004                    **
;**                                                                   **
;***********************************************************************


               processor 6502 
               include "vcs.h" 
               include "macro.h" 
                
;-------------------------------------------------------------
;-                     Define Variables                      -
;-------------------------------------------------------------
; Ram Starts at address $80
PF0_L1 = $80
PF0_L2 = $81
PF0_L3 = $82
PF0_L4 = $83                      

PF1_L1 = $84
PF1_L2 = $85
PF1_L3 = $86
PF1_L4 = $87                      

PF2_L1 = $88
PF2_L2 = $89
PF2_L3 = $8A
PF2_L4 = $8B                      

Sky = $8C 
Temp = $8D
Scroll_Speed = #2                ; Higher = Slower (Min=1)

;-------------------------------------------------------------
;-                    Start of code here                     -
;-------------------------------------------------------------

               SEG 
               ORG $F000 

Reset 

;-------------------------------------------------------------
;-   Clear RAM, TIA registers and Set Stack Pointer to #$FF  -
;-------------------------------------------------------------
        
               SEI
               CLD	
               LDX #$FF
               TXS
               LDA #0
Clear_Mem
               STA 0,X
               DEX
               BNE Clear_Mem	

               LDA #$2A         ; Brown
               STA COLUPF       ; Set PF coulour
               LDA #%00000000   ; Symmetrical Playfield
               STA CTRLPF
               
       ; Tranfer Ground Datas to RAM
               LDX #$00
               STX Temp
Init_Load_Ram               
               LDA Screen_PF0,X   
               STA PF0_L1,X
               INX
               CPX #12
               BNE Init_Load_Ram
               		
;-------------------------------------------------------------
;-                    Start to Build Frame                   -
;-------------------------------------------------------------				

Start_Frame 
         
       ; Start of Vertical Blank 

               LDA #2 
               STA VSYNC 

               STA WSYNC 
               STA WSYNC 
               STA WSYNC         ; 3 scanlines of VSYNC

               LDA #0            ; 2 cycles
               STA VSYNC         ; 3 cycles   
                
       ; Start of Vertival Blank
       ; Count 37 Scanlines

               LDA  #43          ; 2 cycles
               STA  TIM64T       ; 4 cycles

;>>>> Free space for code START : 2785 cycles Free (or exactly 2792)

               LDA #$80          ; Blue
               STA Sky           ; Set Background Colour               
               STA COLUBK
               
               INC Temp          ; Scroll Speed
               LDA Temp
               CMP #Scroll_Speed     
               BNE Scroll_End
               LDA #$00
               STA Temp             

               LDX #04
Scroll          
               LSR #PF2_L1-1,X   ; Scroll Line X-1 (= 3-0)
               ROL #PF1_L1-1,X
               ROR #PF0_L1-1,X
               LDA #PF0_L1-1,X
               AND #%00001000
               BEQ Scroll_1   
               LDA #PF2_L1-1,X            
               ORA #%10000000      
               STA #PF2_L1-1,X
Scroll_1               
               DEX
               BNE Scroll

Scroll_End         


;>>>> Free space for code END

Wait_VBLANK_End
               LDA INTIM                 ; 4 cycles
               BPL Wait_VBLANK_End       ; 3 cycles (2)
               STA WSYNC         ; 3 cycles  Total Amount = 21 cycles
                                 ; 2812-21 = 2791; 2791/64 = 43.60 (TIM64T)

               LDA #0 
               STA VBLANK        ; Enable TIA Output
                                
      
       ; Display 192 Scanlines 
       
       	       LDA #$00          ; Clear Playfield
       	       STA PF0
       	       STA PF1
       	       STA PF2	
               LDY #00           ; Scanlines Counter
               LDX #00           ; Sky colour changes
Picture                 
               LDA Sky
               STA COLUBK 
               INX
               CPX #23           ; Time to change sky colour ?
               BNE Same_Sky_Colour ; No
               LDX #00           ; Yes
               INC Sky
               INC Sky
Same_Sky_Colour                                  	             	               
               STA WSYNC
               INY        
               CPY #170          ; End of empty screen (0-169) ?
               BNE Picture       ; No = Continue   
               
               LDX #$00            
Picture1:               
               LDA #PF0_L1,X
               STA PF0
               LDA #PF1_L1,X
               STA PF1
               LDA #PF2_L1,X
               STA PF2
               INX
               CPX #$04
               STA WSYNC         ; L170-171 / L172-173
               STA WSYNC         ; L174-175 / L176-177
               BNE Picture1
               
               LDA #$FF          ; Ground = Full
               STA PF0
               STA PF1
               STA PF2 
               STA WSYNC         ; L178
               LDX #13                    
Build_Ground               
               STA WSYNC         ; L179 - L191
               DEX               
               BNE Build_Ground
       

;-------------------------------------------------------------
;-                       Frame Ends Here                     -
;-------------------------------------------------------------
    		
               LDA #%00000010 
               STA VBLANK        ; Disable TIA Output 


       ; 30 Scanlines of Overscan
        
               LDX #30 
Overscan        
               STA WSYNC 
               DEX 
               BNE Overscan 

               JMP Start_Frame   ; Build Next Frame 


;-------------------------------------------------------------
;-                         Game Datas                        -
;-------------------------------------------------------------

; Playfield generated by TIA Playfield Painter
; Mode Used = SYMMETRICAL
; Playfields generated = PF0, PF1, PF2
; Datas lines are not reversed

        ALIGN 256

Screen_PF0
	.byte #%10000000	; Scanline 170
	.byte #%10000000	; Scanline 172
	.byte #%11000000	; Scanline 174
	.byte #%11100000	; Scanline 176

Screen_PF1
	.byte #%10000000	; Scanline 170
	.byte #%11000000	; Scanline 172
	.byte #%11100000	; Scanline 174
	.byte #%11110001	; Scanline 176

Screen_PF2
	.byte #%00000000	; Scanline 170
	.byte #%00001000	; Scanline 172
	.byte #%00001101	; Scanline 174
	.byte #%00011111	; Scanline 176



;-------------------------------------------------------------
;-                     Set Interrup Vectors                  -
;-------------------------------------------------------------


               ORG $FFFA 

Interrupt_Vectors 

               .word Reset       ; NMI 
               .word Reset       ; RESET 
               .word Reset       ; IRQ 

       END 
