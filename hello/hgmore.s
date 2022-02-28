.include "hardware.inc"
.import __CODE_LOAD__, __CODE_RUN__, __CODE_SIZE__
CODE_LOAD_LAST = __CODE_LOAD__ + __CODE_SIZE__ - 1
FILE_BUFFER = $1C00

FIELD_W = 8
FIELD_H = 8
SCRN_H = 192

.bss
.align 256
preshift_left: .res 256*7
preshift_right: .res 256*7

hbas_hi: .res SCRN_H
field:   .res FIELD_W * FIELD_H
hbas_lo: .res SCRN_H

TEXT_BASE = $0400
HGR_BASE  = $2000

.segment "STARTUP"
;;
; Unpacks lookup tables and relocates the program to areas that
; don't overlap the OS or the frame buffer.
;
; Our initial programs are meant to run as a BRUN program in DOS 3.3
; or ProDOS BASIC or as a ProDOS system program.  ProDOS loads a
; system program to $2000, which overlaps the HGR frame buffer.
; DOS 3.3 or ProDOS BASIC sits at $9600 and may misbehave if asm
; code overlaps the NEW program at $0800 or the string pool at
; $9500-$95FF.  Areas that don't overlap include $0900-$1FFF and
; $8000-$94FF, which gives us up to 24K of program.
;
; To make the most of the HGR loader, we construct some lookup tables
; that the rest of the program will use.
;
; Once I gain enough confidence to cast off BASIC, we can extend
; all the way up to $BFEF and down to $0800.  Then we can use
; $0800-$1FFF for up to 6 open files.  (ProDOS needs a 1024-byte
; buffer in RAM for each open file.)
.proc start
  lda #<__CODE_LOAD__
  sta zA1+0
  lda #>__CODE_LOAD__
  sta zA1+1
  lda #<CODE_LOAD_LAST
  sta zA2+0
  lda #>CODE_LOAD_LAST
  sta zA2+1
  lda #<__CODE_RUN__
  sta zA4+0
  lda #>__CODE_RUN__
  sta zA4+1
  ldy #0
  jsr MemMove

  ; Calculate base of each hires line
  ldy #0
  hbasloop:
    tya
    lsr a
    lsr a
    lsr a
    jsr GrBasCalc
    ;lda zGBASL
    sta hbas_lo,y
    tya
    and #$07
    asl a
    asl a
    eor #>(TEXT_BASE ^ HGR_BASE)
    eor zGBASH
    sta hbas_hi,y
    iny
    cpy #SCRN_H
    bne hbasloop

  ; Calculate tables for shifting graphics, as per
  ; Bill Budge, Gregg Williams, and Rob Moore. "Preshift-Table Graphics
  ; on Your Apple". Byte, December 1984, pp. A23-A29 and A127-A132.
  ; https://www.apple.asimov.net/documentation/programming/6502assembly/Preshift.pdf

  ldy #0
  makepsh_loop0:
    tya
    sta preshift_left,y
    lda #0
    sta preshift_right,y
    iny
    bne makepsh_loop0

shiftLsrc = zA1
shiftRsrc = zA2
shiftLdst = zA3
shiftRdst = zA4

  sty shiftLsrc
  sty shiftRsrc
  sty shiftLdst
  sty shiftRdst
  ldx #>preshift_left
  stx shiftLsrc+1
  inx
  stx shiftLdst+1
  ldx #>preshift_right
  stx shiftRsrc+1
  inx
  stx shiftRdst+1

  ldy #0
  makepsh_loop1:
    lda (shiftLsrc),y
    asl a
    cmp #$80           ; put rightmost pixel in carry
    eor (shiftLsrc),y  ; combine with previous high bit
    and #$7F
    eor (shiftLsrc),y
    sta (shiftLdst),y
    lda (shiftRsrc),y  ; shift previous rightmost pixel to right byte
    rol a
    sta (shiftRdst),y
    iny
    bne makepsh_loop1
    ldy #0
    inc shiftLsrc+1
    inc shiftLdst+1
    inc shiftRsrc+1
    inc shiftRdst+1
    lda shiftLsrc+1
    cmp #>preshift_left + 6
    bcc makepsh_loop1

  jmp main
.endproc

.segment "CODE"
.proc main
  lda #20
  jsr SetWnd
  lda #>msg1
  ldy #<msg1
  jsr puts

  ldy #$00
  sty zGBASL
  ldx #$20
  stx zGBASH
  lda #$D5
  clrloop:
    sta (zGBASL),y
    eor #$7F
    iny
    bne clrloop
    inc zGBASH
    dex
    bne clrloop
  sta rSETMIXED
  sta rCLRTEXT
  sta rSETHIRES
  lda #>msg2
  ldy #<msg2
  jsr puts

  lda #<tiledata
  sta zA1+0
  lda #>tiledata
  sta zA1+1
  lda #0  ; L
  sta zA2+0
  lda #0  ; T
  sta zA2+1
  lda #2  ; W
  sta zA3+0
  lda #12 ; H
  sta zA3+1
  jsr blit_tile


  lda #>msg
  ldy #<msg
  jsr puts
  keywait:
    lda rKEYBOARD
    bpl keywait
  bit rKEYSTROBE
  jmp prodos_exit
;  cmp #('Q' - 64) | $80
;  beq prodos_exit  ; Ctrl-Q: bye; other key: return to BASIC
;  rts
.endproc

.proc prodos_exit
  jsr ProDOS
  .byte ProDOS_EXIT
  .addr args
args:
  .byte 4
  .res 6, $00
.endproc

.proc puts
src = zA1
  sty src
  sta src+1
  ldy #0
  loop:
    lda (src),y
    beq done
    ora #$80
    jsr COUT
    iny
    bne loop
    inc zA1+1
    bne loop
  done:
  rts
.endproc

.proc pascal_puts
src = zA1
  sty src
  sta src+1
  ldy #0
  lda (src),y
  beq done
  tax
  loop:
    iny
    lda (src),y
    ora #$80
    jsr COUT
    dex
    bne loop
  done:
  rts
.endproc

;;
; @param zA1 source address
; @param zA2+0 destination left
; @param zA2+1 destination top
; @param zA3+0 width
; @param zA3+1 height
.proc blit_tile
src = zA1
left = zA2+0
top = zA2+1
width = zA3+0
height = zA3+1
  ldx top
  rowloop:
    clc
    lda left
    adc hbas_lo,x
    sta zGBASL
    lda hbas_hi,x
    inx
    sta zGBASH
    ldy width
    dey
    byteloop:
      lda (src),y
      sta (zGBASL),y
      dey
      bpl byteloop
    lda src
    clc
    adc width
    sta src
    bcc :+
      inc src+1
    :
    dec height
    bne rowloop
  rts
.endproc

msg1: .byte "CLEARING,", $00
msg2: .byte "LOADING,", $0D, $00
msg: .byte "APPLE II forever", $0D, $00
cwd_before: .byte "CWD: ", $00
; For some reason, when run in ProDOS BASIC, the PREFIX is set to ""
; instead of the volume name.  Work around this for now
; until I go full SYSTEM
tiledata:
  .byte %01000000, %00000001
  .byte %01100000, %00000011
  .byte %01110000, %00000111
  .byte %01111100, %00011111
  .byte %01111110, %00111111
  .byte %01111111, %01111111
  .byte %00101010, %01010101
  .byte %00101010, %01010101
  .byte %00101000, %00010101
  .byte %00100000, %00000101
  .byte %00100000, %00000101
  .byte %00000000, %00000001
