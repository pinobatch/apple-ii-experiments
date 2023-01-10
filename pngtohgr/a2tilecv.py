#!/usr/bin/env python3
import os, sys, argparse
from PIL import Image, ImageChops

descriptionStart="""
Converts a bitmap image to a format usable by Apple II software.
"""
descriptionEnd="""
If -W and -H given, output bytes are left-to-right, top-to-bottom
within each tile.  If -W and -H not given, output is an 8192-byte
interleaved HGR image and input should be 280x192 pixels.
"""

BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
MAGENTA = (178, 89, 191)
GREEN = (77, 166, 64)
BLUE = (77, 141, 191)
ORANGE = (178, 114, 64)

# the first of each of these pairs works in Pillow 9.1 and later
# and fails in Pillow 9.0 and earlier; the second works in
# Pillow 9.x and earlier and fails in Pillow 10 and later
try:
    NEAREST = Image.Resampling.NEAREST
except AttributeError:
    NEAREST = Image.NEAREST
try:
    BOX = Image.Resampling.BOX
except AttributeError:
    BOX = Image.BOX

def hbascalc(y):
    """Calculate the base address of each scanline of an HGR screen"""
    return (y & 0x07) * 1024 + (y & 0x38) * 16 + (y >> 6) * 40

def parse_argv(argv):
    p = argparse.ArgumentParser(description=descriptionStart,
                                epilog=descriptionEnd)
    p.add_argument("image",
                   help="input image")
    p.add_argument("output")
    p.add_argument("-W", "--tile-width", type=int,
                   help="width in bytes (7 pixels) of each tile")
    p.add_argument("-H", "--tile-height", type=int,
                   help="height in pixels of each tile")

    parsed = p.parse_args(argv[1:])
    if parsed.tile_width is None and parsed.tile_height is not None:
        parser.error("height %d without width" % parsed.tile_height)
    if parsed.tile_width is not None:
        if parsed.tile_height is None:
            parser.error("width %d without height" % parsed.tile_width)
        if parsed.tile_height < 1:
            parser.error("height %d is not positive" % parsed.tile_height)
        if parsed.tile_width < 1:
            parser.error("width %d is not positive" % parsed.tile_width)
    return parsed

def trypalette(im, colors, errscale=(8, 8)):
    colorweights = (1, 1.5, 1, 0)
    smresidue_size = tuple(n // d for n, d in zip(im.size, errscale))
    colors = list(colors)
    colors.extend([colors[0]] * (256 - len(colors)))
    colors = b"".join(bytes(c) for c in colors)

    pim = Image.new("P", (4, 4))
    pim.putpalette(colors)
    trial = im.quantize(palette=pim, dither=0)
    residue = ImageChops.difference(im, trial.convert("RGB"))
    residue_l = residue.convert("L", matrix=colorweights)
    residue_s = residue_l.resize(smresidue_size, BOX)
    return trial, residue, residue_s

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    im = Image.open(args.image).convert("RGB")
    palettes = [
        # these are in the order of HCOLOR=
        [BLACK, GREEN, MAGENTA, WHITE],
        [BLACK, ORANGE, BLUE, WHITE]
    ]
    trials = [trypalette(im, p, (7, 1)) for p in palettes]
    residue_levels = [result[2].tobytes() for result in trials]

    # Choose the smallest residue for each area
    # we may not have numpy available for np.argmin
    # so we adapt gg349's solution at
    # https://stackoverflow.com/a/11825864/2738262
    rangelen = range(len(residue_levels))
    attrs = bytes(min(rangelen, key=row.__getitem__)
                  for row in zip(*residue_levels))

    # Paste them together for preview
    combined = Image.new('P', im.size)
    combopalette = [c for p in palettes for c in p]
    combopalette.extend([BLACK] * (256 - len(combopalette)))
    combopalette = bytes(level for rgb in combopalette for level in rgb)
    combined.putpalette(combopalette)
    attrsize = trials[0][2].size
    for subpalid, (result, _, _) in enumerate(trials):
        maskdata = bytes(255 if a == subpalid else 0 for a in attrs)
        maskim = Image.new("L", attrsize)
        maskim.putdata(maskdata)
        maskim = maskim.resize(im.size, NEAREST)
        subpalbase = subpalid * len(palettes[0])
        ptlut = bytes(range(subpalbase, subpalbase + len(palettes[0])))
        ptlut += bytes(256 - len(ptlut))
        combined.paste(result.point(ptlut, "P"), mask=maskim)
    maskdata = maskim = subpalbase = ptlut = None

    # Convert to a linear-order bitmap with (w, h) = attrsize
    # Sample bits 1, 0, 1, 0, 1, 0, ... of each pixel
    # (assuming width in pixels is a multiple of 14)
    pixels = combined.tobytes()
    bits = iter((b >> (~i & 1) & 1) for i, b in enumerate(pixels))
    phase = 1
    linearbits = bytearray()
    for attr in attrs:
        bytevalue = attr << 7
        for bshift in range(7):
            bytevalue |= next(bits) << bshift
            phase ^= 1
        linearbits.append(bytevalue)

    # stuff it into an HGR file for viewing
    if args.tile_width is None:
        hgrout = bytearray(8192)
        for y in range(attrsize[1]):
            srcoffset, dstoffset = attrsize[0] * y, hbascalc(y)
            hgrout[dstoffset:dstoffset + attrsize[0]] = linearbits[srcoffset:srcoffset + attrsize[0]]
    else:
        hgrout = bytearray()
        for yt in range(0, attrsize[1], args.tile_height):
            for xt in range(0, attrsize[0], args.tile_width):
                for y in range(yt, yt + args.tile_height):
                    srcoffset = attrsize[0] * y + xt
                    hgrout.extend(linearbits[srcoffset:srcoffset + args.tile_width])
    with open(args.output, "wb") as outfp:
        outfp.write(hgrout)

    # next steps:
    # convert bit 1 of even columns and bit 0 of odd columns to bytes
    # stuff this in an HGR file for viewing

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        import shlex
        main(shlex.split("""
./a2tilecv.py spritesheet.png a2tilecv.hgr
"""))
        main(shlex.split("""
./a2tilecv.py -W2 -H12 spritesheet.png a2tilecv.chr
"""))
    else:
        main()
