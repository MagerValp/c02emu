#!/usr/bin/python
# -*- coding: utf-8 -*-


import sys
import argparse
import png


def print8(*args):
    print " ".join(unicode(x).encode(u"utf-8") for x in args)


def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument(u"-v", u"--verbose", action=u"store_true",
                   help=u"Verbose output.")
    p.add_argument(u"source")
    p.add_argument(u"outprefix")
    args = p.parse_args([x.decode(u"utf-8") for x in argv[1:]])
    
    r = png.Reader(filename=args.source)
    width, height, pixels, metadata = r.asRGBA8()
    lines = list(pixels)
    
    w = 8
    h = 8
    for i in xrange(0, 256):
        y = int(i / 32)
        x = i % 32
        char = list()
        for dy in xrange(0, 8):
            char.append(lines[y * 8 + dy][x * 4 * 8:(x + 1) * 4 * 8])
        w = png.Writer(width=8, height=8, alpha=True)
        with open(u"%s%03d.png" % (args.outprefix, i), u"w") as f:
            w.write(f, char)
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    
