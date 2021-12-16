Hello World for Apple II
========================

To get rolling:

1. Download AppleCommander, LinApple, and ProDOS
2. Install cc65 and LinApple
3. Edit `mk.sh` for where you built LinApple
4. `mk.sh`
4. If needed, from ProDOS BASIC, `BRUN A2HELLO,D2`

The program waits for a keypress.  Ctrl+Q quits to ProDOS's
program chooser; any other key returns to BASIC.

AppleCommander
--------------

[AppleCommander] (https://applecommander.github.io/) is a program
written in Java to build Apple II disk images.

DO files are Apple DOS 3.3 disk images, and PO files are ProDOS
disk images.  ac.jar is the command-line version of AppleCommander,
an archiver that writes these images.

Format a ProDOS disk with a volume label

    java -jar ac.jar -pro140 Documents.po PINOS.PR0N

Get info about a disk

    java -jar ac.jar -i Spellevator.po

List files on a disk (increasing verbosity: `-ls`, `-l`, `-ll`)

    java -jar ac.jar -ls Spellevator.po

Try to print a file on the disk (text and BASIC become text,
pictures become PNG, and binary becomes a hex dump)

    java -jar ac.jar -e Documents.po fred

Extract a raw file

    java -jar ac.jar -g Documents.po fred > fred.bin

Add a file

    java -jar ac.jar -p Documents.po fred bin 0x800 < fred.bin

Add a text file, translating newline to ProDOS/GS-OS/old Mac ($0D)

    java -jar ac.jar -ptx Documents.po readme < readme.txt

Delete a file

    java -jar ac.jar -d Documents.po fred

LinApple
--------

We use Mark Ormond's fork of [LinApple](https://github.com/dabonetn/linapple-pie)

Building requires SDL 1.2, SDL Image, libzip, zlib, and libcurl

    sudo apt install libsdl-image1.2-dev zlib1g-dev libzip-dev libcurl4-gnutls-dev
    git clone https://github.com/dabonetn/linapple-pie
    cd linapple-pie/src
    make

ProDOS
------

Using the [ProDOS 2.4](https://prodos8.com/releases/prodos-24/)
operating system.

BASIC uses [most of the zero page](https://stason.org/TULARC/pc/apple2/programmer/017-Which-Zero-Page-locations-are-likely-to-be-in-use.html).
If your program is `BRUN` from BASIC, the following zero page ranges
should be free: $06-$09, $EB-$EF, $FA-$FD.  If it runs directly on
ProDOS as a SYS file, everything from $56 to $FF is free.  Monitor
variables (A1L through A5L and GBASL/GBASH) should be safe as well,
though some ProDOS device drivers calls trash A1L through A2H.
