#!/usr/bin/env python3
"""
hgrview
Viewer and decoder for Apple II HGR (high-resolution) images

Copyright 2021 Damian Yerrick

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you
       must not claim that you wrote the original software.  If you
       use this software in a product, an acknowledgment in the
       product documentation would be appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and
       must not be misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
       distribution.
"""
import os, sys, argparse
from itertools import cycle
from PIL import Image

colors_1248 = [
    (114, 38, 64),
    ( 64, 51,127),
    ( 13, 90, 64),
    ( 64, 76,  0)
]

helpText = "Viewer and decoder for Apple II HGR (high-resolution) images"
versionText = '%(prog)s 0.01'

def parse_argv(argv):
    p = argparse.ArgumentParser(description=helpText)
    p.add_argument("hgrfile",
                   help="path of an 8192-byte HGR image")
    p.add_argument("outimage", nargs='?',
                   help="where to write the 560x192 decoded image "
                   "(default: display)")
    p.add_argument('--version', action='version', version=versionText)
    p.add_argument("-m", "--monochrome", action="store_true",
                   help="decode without color burst")
    p.add_argument("--par", dest='par_correction', default=None,
                   action="store_const", const=True,
                   help="resize to square pixel aspect ratio "
                        "(default for no outimage)")
    p.add_argument("--no-par", dest='par_correction',
                   action="store_const", const=False,
                   help="write nonsquare DPI instead of resizing "
                        "(default for outimage)")
    return p.parse_args(argv[1:])

def decode_hgr_line(row):
    """Decode a line of HGR to a monochrome signal.

row -- an iterable of HGR bytes, each of which represents 14 pixels
    bit 0: signal level for leftmost 2 pixels
    bit 6: signal level for rightmost 2 pixels
    bit 7: 0 to latch signal on even pixels (magenta/green)
        or 1 on odd (blue/orange)

Return a byteslike of signal samples, 14 per input byte
"""
    signal, out = 0, bytearray()
    for b in row:
        bbits, blueorange = b & 0x7F, b & 0x80
        for i in range(7):
            if not blueorange: signal = b & 1
            out.append(signal)
            if blueorange: signal = b & 1
            out.append(signal)
            b >>= 1
    return out

def decode_ntsc_line(row):
    pixel, phase, out = 0, 0x01, bytearray()
    for signal, phase in zip(row, cycle((1, 2, 4, 8))):
        pixel = (pixel & ~phase) | (phase if signal else 0)
        out.append(pixel)
    return out

def hbascalc(y):
    """Calculate the base address of each scanline of an HGR screen"""
    return (y & 0x07) * 1024 + (y & 0x38) * 16 + (y >> 6) * 40

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    par_correction = args.par_correction
    if par_correction is None: par_correction = not args.outimage
    with open(args.hgrfile, "rb") as infp:
        screen = infp.read(8192)
    offsets = (hbascalc(y) for y in range(192))
    pixels = [decode_hgr_line(screen[i:i + 40]) for i in offsets]

    if args.monochrome:
        palette = [0, 0, 0, 255, 255, 255]
    else:
        pixels = [decode_ntsc_line(row + bytes(1))[1:] for row in pixels]
        palette = [0, 0, 0]
        for rgb in colors_1248:
            rgbcyc = rgb * (len(palette)// len(rgb))
            palette.extend([a + b for a, b in zip(palette, rgbcyc)])
    palette.extend([0] * (768 - len(palette)))
    im = Image.new("P", (560, 192))
    im.putpalette(palette)
    im.putdata(b"".join(pixels))

    if par_correction:
        im = im.resize((560, 384), Image.NEAREST)
        im = im.convert("RGB").resize((480, 384), Image.HAMMING)
    if args.outimage:
        saveopts = {} if par_correction else {'bits': 4, 'dpi': (168, 72)}
        im.save(args.outimage, **saveopts)
    else:
        im.show()

def test():
    main("./hgrview.py -m ../b2d/GUS70C.BIN Gus70hm.png".split())
    main("./hgrview.py ../b2d/GUS70C.BIN Gus70h.png".split())
    main("./hgrview.py --par ../b2d/GUS70C.BIN Gus70hp.png".split())
    main("./hgrview.py ../b2d/GUS70C.BIN".split())
    main("./hgrview.py --par ../b2d/GUS70C.BIN".split())
    main("./hgrview.py --no-par ../b2d/GUS70C.BIN".split())

if __name__=="__main__":
    if "idlelib" in sys.modules:
        test()
    else:
        main()
