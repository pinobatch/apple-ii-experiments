.include "hardware.inc"
.import __CODE_LOAD__, __CODE_RUN__, __CODE_SIZE__
CODE_LOAD_LAST = __CODE_LOAD__ + __CODE_SIZE__ - 1
FILE_BUFFER = $1C00

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
  lda #$55
  clrloop:
    sta (zGBASL),y
    eor #$77
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
  jsr bload_gus_hgr

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

.proc bload_gus_hgr
  jsr ProDOS
  .byte ProDOS_GETCWD
  .addr getcwdargs
  bcc :+
    pha
    lda #'p'|$80
    jsr COUT
    pla
    jmp PrByte
  :
  lda #>cwd_before
  ldy #<cwd_before
  jsr puts
  lda #>FILEBUF0
  ldy #<FILEBUF0
  jsr pascal_puts
  jsr CROut

  jsr ProDOS
  .byte ProDOS_OPEN
  .addr openargs
  ldx FILEBUF0
  
  bcc :+
    pha
    lda #'o'|$80
    jsr COUT
    pla
    jmp PrByte
  :
  lda handle
  sta readargs+1
  jsr ProDOS
  .byte ProDOS_READ
  .addr readargs
  bcc success_close
  
fail_close:
    pha
    lda #'r'|$80
    jsr COUT
    pla
  jsr PrByte
success_close:
  lda #1
  sta handle-1
  jsr ProDOS
  .byte ProDOS_CLOSE
  .addr handle-1
  rts

getcwdargs:
  .byte 1
  .addr FILEBUF0
openargs:
  .byte 3
  .addr filename, FILEBUF0
handle:
  .byte 0  ; handle
readargs:
  .byte 4
  .byte 0  ; handle goes here
  .addr $2000  ; address: frame buffer
  .word 8192  ; size
  .word 0  ; size out
.endproc

msg1: .byte "CLEARING,", $00
msg2: .byte "LOADING,", $0D, $00
msg: .byte "APPLE II forever", $0D, $00
cwd_before: .byte "CWD: ", $00
; For some reason, when run in ProDOS BASIC, the PREFIX is set to ""
; instead of the volume name.  Work around this for now
; until I go full SYSTEM
filename: .byte @end-*-1, "/RUN/GUS.HGR"
  @end:
