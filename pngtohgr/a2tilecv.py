#!/usr/bin/env python3
import os, sys, argparse
from PIL import Image, ImageChops

BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
MAGENTA = (178, 89, 191)
GREEN = (77, 166, 64)
BLUE = (77, 141, 191)
ORANGE = (178, 114, 64)

def parse_argv(argv):
    p = argparse.ArgumentParser()
    p.add_argument("image")
    return p.parse_args(argv[1:])

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
    residue_s = residue_l.resize(smresidue_size, Image.BOX)
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
    print(attrs.hex())
    masks = [
        bytes(255 if a == target else 0 for a in attrs)
        for target in rangelen
    ]
    for m in masks:
        print(m.hex())

    # next steps:
    # stuff each mask into an image and scale it to full size
    # use point() to add the subpalette base to each trial result
    # use paste(trialplusbase, mask=scaledmask) to build an overall image
    # convert bit 1 of even columns and bit 0 of odd columns to bytes
    # stuff this in an HGR file for viewing

if __name__=='__main__':
    if 'idlelib' in sys.modules:
        import shlex
        main(shlex.split("""./a2tilecv.py spritesheet.png
"""))
    else:
        main()
