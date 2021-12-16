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
    lda rKEYBOARD
    bpl keywait
  bit rKEYSTROBE
  cmp #('Q' - 64) | $80
  beq prodos_exit  ; Ctrl-Q: bye; other key: return to BASIC
  rts
.endproc

.proc prodos_exit
  jsr ProDOS
  .byte $65
  .addr args
args:
  .byte 4
  .res 6, $00
.endproc

msg: .byte "APPLE II forever", $0D, $00
