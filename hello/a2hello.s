; This program reads a key. If Ctrl+Q, it runs Bitsy Bye.
; Otherwise, it exits to BASIC.

.include "hardware.inc"

.proc start
  jsr CROut
  ldx #0
  prloop:
    lda msg,x
    beq prdone
    ora #$80
    jsr COUT
    inx
    bne prloop
  prdone:

  keywait:
    ; Write controller state
    jsr read_pad
    sec
    rol a
    wrloop:
      pha
      lda #'.'|$80
      bcc :+
        lda #'*'|$80
      :
      jsr COUT
      pla
      asl a
      bne wrloop
    lda #0
    sta zCH

    lda rKEYBOARD
    bpl keywait

  bit rKEYSTROBE
  cmp #('Q' - 64) | $80
  beq prodos_exit  ; Ctrl-Q: bye; other key: return to BASIC

  ; exit with newline
  lda #$8D
  jmp COUT
.endproc

.proc prodos_exit
  jsr ProDOS
  .byte $65
  .addr args
args:
  .byte 4
  .res 6, $00
.endproc

rPTRIG  = $C070
rBUTTON = $C061
rPADDLE = $C064

PADF_SHIFT  = $40
PADF_OPTION = $20
PADF_CMD    = $10
PADF_LEFT   = $08
PADF_UP     = $04
PADF_RIGHT  = $02
PADF_DOWN   = $01

;;
; Reads the first two axes and three buttons as a joystick.
;
; The Apple II paddle is a potentiometer (variable resistor) that
; charges a capacitor on the computer's main logic board.  Time to
; charge is proportional to how far it is turned, from 0 to 3.2 ms.
; Converts 2 axes and 3 buttons to a button press bitfield.
; @return A: which directions are pressed; XY unspecified
; 7654 3210
;  ||| |||+- 1: joystick pressed down
;  ||| ||+-- 1: joystick pressed right
;  ||| |+--- 1: joystick pressed up
;  ||| +---- 1: joystick pressed left
;  ||+------ 1: button 1 (Command) held
;  |+------- 1: button 2 (Option) held
;  +-------- 1: button 3 (Shift) held
.proc read_pad
result = zA1
  lda rPTRIG  ; begin charging capacitor
  ldy #0
  ldx #2
  btnloop:
    lda rBUTTON,x
    asl a
    tya
    rol a
    tay
    dex
    bpl btnloop
  jsr wait1kthenread
  ; A bit 1: not left; bit 0: not up
  eor #%00000011  ; convert them to positive logic
  
wait1kthenread:
  ldy #200
  :
    dey
    bne :-
  tay
  lda rPADDLE+0
  asl a
  tya
  rol a
  tay
  lda rPADDLE+1
  asl a
  tya
  rol a
  rts
.endproc

msg:
  .byte "APPLE II forever", $0D
  .byte "Ctrl+Q: ProDOS; Space: BASIC",$0D
  .byte ".SOCLURD Joystick and Apple keys",$0D
  .byte $00
