#!/usr/bin/python
# -*- coding: utf-8 -*-


import sys
import argparse


def print8(*args):
    print " ".join(unicode(x).encode(u"utf-8") for x in args)


ADDRMODE = {
    u"":        u"IMP",
    u"2":       u"IMP",
    u"3":       u"IMP",
    u"4":       u"IMP",
    u"6":       u"IMP",
    u"7":       u"IMP",
    u"abs 3":   u"ABS",
    u"abs 4":   u"ABS",
    u"abs 6":   u"ABS",
    u"abx 4*":  u"ABX",
    u"abx 5":   u"ABX",
    u"abx 6*":  u"ABX",
    u"aby 4*":  u"ABY",
    u"aby 5":   u"ABY",
    u"iax 6":   u"IAX",
    u"imm 2":   u"IMM",
    u"ind 6":   u"IND",
    u"izp 5":   u"IZP",
    u"izx 6":   u"IZX",
    u"izy 5*":  u"IZY",
    u"izy 6":   u"IZY",
    u"rel 2*":  u"REL",
    u"rel 3*":  u"REL",
    u"zp 3":    u"ZP",
    u"zp 5":    u"ZP",
    u"zpr 5":   u"ZPR",
    u"zpx 4":   u"ZPX",
    u"zpx 6":   u"ZPX",
    u"zpy 4":   u"ZPY",
}


def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument(u"-v", u"--verbose", action=u"store_true",
                   help=u"Verbose output.")
    p.add_argument(u"table")
    args = p.parse_args([x.decode(u"utf-8") for x in argv[1:]])
    
    opcodes = list()
    addrmodes = list()
    with open(args.table) as f:
        for msb in xrange(0, 256, 16):
            opcodes.extend(x.lower() for x in f.readline().rstrip().split(u"\t"))
            addrmodes.extend(f.readline().rstrip().split(u"\t"))

    print8("    enum AddrMode {")
    for addrmode in sorted(set(ADDRMODE[x] for x in addrmodes)):
        print8("        case %s" % addrmode)
    print8("    }")
    
    def adjustedcomma(s):
        if len(s) < 3:
            return s + ", "
        else:
            return s + ","
    
    print8("    let addrModes: [AddrMode] = [")
    for offset in xrange(0, 255, 8):
        print8('        .%s' % ' .'.join(adjustedcomma(ADDRMODE[x]) for x in addrmodes[offset:offset + 8]))
    print8("    ]")
    
    print8("    let opCodes = [")
    for offset in xrange(0, 255, 8):
        print8('        "%s",' % '", "'.join(opcodes[offset:offset + 8]))
    print8("    ]")
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    
