#!/usr/bin/python
# -*- coding: utf-8 -*-


import sys
import argparse


def print8(*args):
    print " ".join(unicode(x).encode(u"utf-8") for x in args)


def scancode(s):
    if not s:
        return None
    if u"," in s:
        return None
    code = int(s, 16)
    if code == 0x83:
        return 0x63
    else:
        return code

def convert(name):
    for mod in [u"Shift", u"Alt", u"Control", u"GUI", u"Apps", u"Caps"]:
        if mod in name:
            return "0"
    if name.startswith(u"Digit"):
        return "'%s'" % name[5:]
    if name.startswith(u"Keypad") and len(name) == 7:
        return "'%s'" % name[6:]
    if len(name) == 1 and name >= "A" and name <= "Z":
        return "'%s'" % name
    if name.startswith(u"F"):
        return "0"
    return name

def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument(u"-v", u"--verbose", action=u"store_true",
                   help=u"Verbose output.")
    p.add_argument(u"table")
    args = p.parse_args([x.decode(u"utf-8") for x in argv[1:]])
    
    codes = ["0"] * 128
    with open(args.table) as f:
        for line in f:
            name, make, brk = line.decode(u"utf-8").rstrip(u"\n").split(u"\t")
            code = scancode(make)
            if code:
                codes[code] = convert(name)
    
    stride = 8
    for offset in xrange(0, len(codes), stride):
        print8(u"\t.byte %s" % u", ".join("%4s" % x for x in codes[offset:offset+stride]))
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    
