#!/bin/sh
set -e

AC="java -jar ../deps/ac.jar"
PRODOSDISK="../deps/ProDOS_2_4.dsk"
LINAPPLE="../../emulators/linapple-pie/linapple"
PICNAME="../b2d/GUS70C.BIN"
PROGNAME=hgmore

ca65 -o $PROGNAME.o $PROGNAME.s
ld65 -o $PROGNAME.bin -C $PROGNAME.cfg -m $PROGNAME.map $PROGNAME.o
$AC -pro140 run.po RUN
$AC -g $PRODOSDISK PRODOS | $AC -p run.po PRODOS sys 0x2000

# copy these for a program that runs within BASIC
$AC -g $PRODOSDISK BASIC.SYSTEM | $AC -p run.po BASIC.SYSTEM sys 0x2000
$AC -p run.po STARTUP bin 0x2000 < $PROGNAME.bin
# or these for a system program
#$AC -p run.po RUN.SYSTEM sys 0x2000 < $PROGNAME.bin

# AppleCommander's boot sector isn't bootable; ProDOS 2.4's is.
# ProDOS 2.4 also ships as a DOS 3.3-ordered image for some reason.
# Copy ProDOS 2.4 boot sector
dd conv=notrunc bs=256 if=$PRODOSDISK of=run.po count=1 skip=0 seek=0
dd conv=notrunc bs=256 if=$PRODOSDISK of=run.po count=1 skip=14 seek=1
$LINAPPLE -1 run.po -r
# Otherwise, must use this
# $LINAPPLE -1 $PRODOSDISK -2 run.po -r
