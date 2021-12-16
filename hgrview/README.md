hgrview
=======

Viewer and decoder for Apple II HGR (high-resolution) images.
Takes an 8192 byte `BSAVE` from `HGR` or `HGR2` mode, calculates
the composite signal that the Apple II generates, optionally decodes
it based on a quick-and-dirty emulation of an NTSC decoder, and
produces a 560×192-pixel PNG image.  The DPI for the resulting image
is set at 168 across by 72 down to represent the 3:7 pixel aspect
ratio resulting from sampling at 14.32 MHz (four times color burst).

usage: `hgrview.py [-h] [-m] hgrfile [outimage]`

positional arguments:

- `hgrfile`: path of an 8192-byte HGR image
- `outimage`: where to write the 560x192 decoded image
  (default: display)

optional arguments:

- `-m`, `--monochrome`: decode without color burst

