#!/usr/bin/python
# -*- coding: utf-8 -*-


import sys
import argparse


def print8(*args):
    print " ".join(unicode(x).encode(u"utf-8") for x in args)


def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument(u"-v", u"--verbose", action=u"store_true",
                   help=u"Verbose output.")
    p.add_argument(u"table")
    args = p.parse_args([x.decode(u"utf-8") for x in argv[1:]])
    
    allcodes = list()
    allmodes = list()
    with open(args.table) as f:
        for msb in xrange(0, 256, 16):
            opcodes = f.readline().rstrip().split(u"\t")
            allcodes += opcodes
            addrmodes = f.readline().rstrip().split(u"\t")
            allmodes += addrmodes
            for lsb in xrange(0, 16):
                print8(u"%s\t%s\t0x%02x" % (opcodes[lsb], addrmodes[lsb], msb + lsb))
    
    for item in sorted(set(allcodes)):
        print8(item)
    for item in sorted(set(allmodes)):
        print8(item)
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    
