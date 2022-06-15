; Readable I/O registers
rKEYBOARD   := $C000  ; 7: key waiting; 6-0: code
rKEYSTROBE  := $C010  ; 7: key held; read: clear rKEYBOARD bit 7
rTAPEIN     := $C060  ; 7: cassette input (II, II Plus, IIe), joystick button 3 (IIGS)
rCMDKEY     := $C061  ; 7: command key (IIe, IIGS), joystick button 0
rBTN0       := $C061
rOPTIONKEY  := $C062  ; 7: option key (IIe, IIGS), joystick button 1
rBTN1       := $C062
rBTN2       := $C063  ; 7: shift key (IIe, IIGS, II+ mod), joystick button 2
rPADDLE0    := $C064  ; 7: paddle 0 timer charged
rPADDLE1    := $C065  ; 7: paddle 1 timer charged
rPADDLE2    := $C066  ; 7: paddle 2 timer charged
rPADDLE3    := $C067  ; 7: paddle 3 timer charged
rPDLTRIG    := $C070  ; read: restart paddle timers

; Writable I/O registers
rTAPEOUT    := $C020  ; toggle cassette output
rSPEAKER    := $C030  ; toggle speaker output
rJOYSTROBE  := $C040  ; send low pulse on game strobe (II Plus, IIe)
rCLRTEXT    := $C050  ; graphics mode
rSETTEXT    := $C051  ; text mode
rCLRMIXED   := $C052  ; bottom of graphics mode is graphics
rSETMIXED   := $C053  ; bottom of graphics mode is text
rPAGE1      := $C054  ; select text/graphics page 1 ($0400, $2000)
rPAGE2      := $C055  ; select text/graphics page 1 ($0800, $4000)
rCLRHIRES   := $C056  ; lo-res graphics
rSETHIRES   := $C057  ; hi-res graphics
rSETAN0     := $C058  ; Set joystick output 0 to 0 V
rCLRAN0     := $C059  ; Set joystick output 0 to +5 V
rSETAN1     := $C05A  ; Set joystick output 1 to 0 V
rCLRAN1     := $C05B  ; Set joystick output 1 to +5 V
rSETAN2     := $C05C  ; Set joystick output 2 to 0 V
rCLRAN2     := $C05D  ; Set joystick output 2 to +5 V
rSETAN3     := $C05E  ; Set joystick output 3 to 0 V or enable double hires if IOUDIS on
rSETDHIRES  := rSETAN3
rCLRAN3     := $C05F  ; Set joystick output 3 to 1 or disable double hires if IOUDIS on
rCLRDHIRES  := rCLRAN3
rSETIOUDIS  := $C07E  ; $C058-$C05F control double hires
rCLRIOUDIS  := $C07E  ; $C058-$C05F control joystick outputs

; Bank switching status registers (R bit 7)
rRDLCBNK2   := $C011  ; reading extra 4K of RAM in $D000-$DFFF
rRDLCRAM    := $C012  ; reading from LC RAM
rRDRAMRD    := $C013  ; reading from aux/alt 48K
rRDRAMWR    := $C014  ; writing to aux/alt 48K
rRDCXROM    := $C015  ; using internal Slot ROM
rRDAUXZP    := $C016  ; using Slot zero page, stack, & LC
rRDC3ROM    := $C017  ; using external (Slot) C3 ROM
rRD80COL    := $C018  ; 80STORE is On- using 80-column memory mapping
rRDVBLBAR   := $C019  ; not VBL (VBL signal low)
rRDTEXT     := $C01A  ; using text mode
rRDMIXED    := $C01B  ; using mixed mode
rRDPAGE2    := $C01C  ; using text/graphics page2
rRDHIRES    := $C01D  ; using Hi-res graphics mode
rRDALTCH    := $C01E  ; using alternate character set
rRD80VID    := $C01F  ; using 80-column display mode

; Bank switching control registers (W)
rCLR80STORE := $C000  ; disable 80-column memory mapping
rSET80STORE := $C001  ; enable 80-column memory mapping
rCLRAUXRD   := $C002  ; read 48K bank $00
rSETAUXRD   := $C003  ; read 48K bank $01
rCLRAUXWR   := $C004  ; write 48K bank $00
rSETAUXWR   := $C005  ; write 48K bank $01
rCLRCXROM   := $C006  ; read ROM on cards
rSETCXROM   := $C007  ; read internal ROM
rCLRAUXZP   := $C008  ; use bank $00 zero page, stack, & LC (WR-only)
rSETAUXZP   := $C009  ; use bank $01 zero page, stack, & LC (WR-only)
rCLRC3ROM   := $C00A  ; use internal Slot 3 ROM (WR-only)
rSETC3ROM   := $C00B  ; use external Slot 3 ROM (WR-only)
rCLR80VID   := $C00C  ; disable 80-column display mode (WR-only)
rSET80VID   := $C00D  ; enable 80-column display mode (WR-only)
rCLRALTCH   := $C00E  ; use main char set- norm LC, Flash UC (WR-only)
rSETALTCH   := $C00F  ; use alt char set- norm inverse, LC; no Flash (WR-only)

; Language card bank switching (R)
rROMIN      := $C081  ; put ROM in $D000-$FFFF
rLCBANK2    := $C083  ; put RAM 2 in $D000-$FFFF (two reads: enable writing)
rLCBANK1    := $C08B  ; put RAM 1 in $D000-$FFFF (two reads: enable writing)
rCLRC8ROM   := $CFFF  ; disable Slot card C8 ROM

; System Monitor (BIOS) calls
GrPlot      := $F800  ; plot a lores block at (Y, A) in color COLOR
                     ; side effect: GR_MASK set to (A & 1) ? $F0 : $0F
GrPlot1     := $F80E  ; plot a lores block (same GBASL, same MASK, diff Y)
GrHLine     := $F819  ; draw horizontal lores line from (Y, A) to (H2, A)
GrVLine     := $F828  ; draw vertical lores line from (Y, A) to (Y, V2)
GrCls48     := $F832  ; clear lores page 1 to color 0
GrCls40     := $F836  ; clear top 40 rows of lores page 1 to color 0
GrBasCalc   := $F847  ; set zGBASL to base address of text line A
GrSetColor  := $F864  ; write (A & $0F) & 17 to zGR_COLOR
GrScrn      := $F871  ; read lores pixel at (Y, A)
PrintYX     := $F940  ; print Y then X as hexadecimal
PrintAX     := $F941  ; print A then X as hexadecimal
PrintXHex   := $F944  ; print X as hexadecimal
PrXSpaces   := $F94A  ; print X spaces
PaddleRead  := $FB1E  ; Read paddle X (0-3) into Y
TextInit    := $FB2F  ; Clear STATUS, turn off graphics, set page 1, then...
SetTxt      := $FB39  ; ...set text mode, and set fullscreen window
SetGr       := $FB40  ; Set graphics, clear top 40 rows, and set 40x4 window
SetWnd      := $FB4B  ; Set window to (A, 0)-(40, 24) and move to bottom
TABV        := $FB5B  ; Set CV (cursor Y) to A and do VTabZ
SetPwrC     := $FB6F  ; Mark Ctrl+Reset vector ($3F4) as valid
VidWait     := $FB78  ; If A=$8D and Ctrl+S is pressed, pause, then do VidOut
KbdWait     := $FB88  ; Wait for keypress, print it, and ack (unless Ctrl+C)
BasCalc     := $FBC1  ; set zBASL to base address of text line A
Bell1       := $FBDD  ; Wait then beep, saving X
Bell12      := $FBE2  ; Beep for 192 half-periods, saving X
Bell2       := $FBE4  ; Beep for Y half-periods, saving X
StorAdv     := $FBF0  ; Write printable character A to screen, saving X
Advance     := $FBF4  ; Move cursor to right (or to start of next line), saving X
VidOut      := $FBFD  ; Write printable or control character A to screen, saving X:
BackSpace   := $FC10  ; Move cursor left (or to end of prev line), saving X
CursorUp    := $FC1A  ; Move cursor up, saving XY
VTab        := $FC22  ; Set BASL to (WNDLEFT, CV)
VTabZ       := $FC24  ; Set BASL to (A, CV)
ClrEOP      := $FC42  ; Clear from cursor to end of text window
TextCls     := $FC58  ; Move cursor to top left and then ClrEOP
TextCRLF    := $FC62  ; Move cursor to left then LF
TextLF      := $FC66  ; Move down a line or scroll if not possible
ScrollText  := $FC70  ; Move all text in window up a line
ClrEOL      := $FC9C  ; Clear from cursor to window right side
ClrEOLZ     := $FC9E  ; Clear from Y to window right side
Wait        := $FCA8  ; Wait A*A*2.5 + A*13.5 + 7 cycles
RdKey1      := $FD18  ; Read a character from standard input (KSWL vector)
KeyIn       := $FD1B  ; Read a character from the keyboard and randomize RNDL
RdChar      := $FD35  ; Read a character from keyboard and process Esc sequences
GetLnZ      := $FD67  ; Print newline and PROMPT then read a line of text
GetLn       := $FD6A  ; Print PROMPT then read a line of text from standard input
GetLn0      := $FD6C  ; Print char A then read a line of text from standard input
GetLn1      := $FD6F  ; Read a line of text from standard input
CROut       := $FD8E  ; Write $8D to standard output
PrByte      := $FDDA  ; Print A in hex
PrHex       := $FDE3  ; Print nibble A (00-0F) in hex
COUT        := $FDED  ; Write character to standard output
COUT1       := $FDF0  ; Write character to screen
MemMove     := $FE2C  ; Copies A1+Y through A2+Y inclusive to A4+Y
TextSetInv  := $FE80  ; Enable inverse text
TextSetNorm := $FE84  ; Disable inverse text
SetKbd      := $FE89  ; Point standard input at keyboard
InPort      := $FE8B  ; Point standard input at a slot (1-7)
SetVid      := $FE93  ; Point standard output at the screen
OutPort     := $FE95  ; Point standard output at a slot (1-7)
Bell        := $FF3A  ; Write ASCII BEL ($87) to standard output

; Zero page locations whose semantics are defined by Monitor

zLOC0       := $00
zLOC1       := $01
zWNDLFT     := $20  ; Text window
zWNDWDTH    := $21
zWNDTOP     := $22
zWNDBTM     := $23
zCH         := $24  ; Text cursor X position (relative to WNDLFT)
zCV         := $25  ; Text cursor Y position (absolute)
zGBASL      := $26  ; pointer to left side of last GR row PLOTted to
zGBASH      := $27
zBASL       := $28  ; pointer to left side of TEXT row at CV, plus WNDLFT
zBASH       := $29
zH2         := $2C  ; right side of GrHLine
zV2         := $2D  ; right side of GrVLine
zMASK       := $2E  ; $0F if last GrPlot pixel was top; $F0 if bottom
zGR_COLOR   := $30  ; last GrSetColor value in both nibbles
zMONMODE    := $31  ; used internally by Monitor
zINVFLG     := $32  ; $3F black on white, $FF white on black
zPROMPT     := $33  ; Character to print before reading a line of text
zINPUTPOS   := $34  ; Monitor: Position within INPUT
zYSAV1      := $35  ; COUT saves Y here
zCSWL       := $36  ; Standard output (COUT) handler
zKSWL       := $38  ; Standard input (RDKEY) handler
zPC         := $3A  ; Monitor program counter
zA1         := $3C  ; Monitor argument 1
zA2         := $3E  ; Monitor argument 2
zA3         := $40  ; Monitor argument 3
zA4         := $42  ; Monitor argument 4
zA5L        := $44  ; Monitor argument 5
zACC        := $45  ; A is saved here on IRQ
zXREG       := $46
zYREG       := $47
zSTATUS     := $48  ; P register
zSPNT       := $49  ; Stack pointer
; 4A-4D unused?
zRNDL       := $4E  ; time spent in KeyIn, for use as random seed
zRNDH       := $4F
wINPUT      := $0200
wBRKVector  := $03F0  ; BRK does JMP (wBRKVector)
wResetVector:= $03F2  ; Ctrl+Reset does JMP (wResetVector) if SetPwrV called
wAmpEntry   := $03F5  ; Applesoft & jumps here
wCtrlYEntry := $03F8  ; Applesoft USR() or Ctrl+Y jumps here
wNMIEntry   := $03FB  ; NMI jumps here
wIRQVector  := $03FE  ; IRQ does JMP (wIRQVector)


FILEBUF0 := $1C00

ProDOS := $BF00
ProDOS_SETCWD = $C6
ProDOS_GETCWD = $C7
ProDOS_EXIT = $65
ProDOS_OPEN = $C8  ; 3, ptr to path (pascal), ptr to 1K buffer, handle (out)
ProDOS_READ = $CA  ; 4, handle, dest ptr, count (16 bit), actual count (16 bit out)
ProDOS_WRITE = $CB  ; 4, handle, src ptr, count (16 bit), actual count (16 bit out)
ProDOS_CLOSE = $CC  ; 1, handle

; You can expect ProDOS calls to clobber memory areas:
; - Disk drivers trash A1 and A2 (TN ?)
; - AppleShare driver trashes a lot of zero page (TN ?)
; - Clock driver trashes INPUT at $0200-$0210 (TN ?)
; Don't put arguments in INPUT or on zero page
