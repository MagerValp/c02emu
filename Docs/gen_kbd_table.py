#!/usr/bin/python
# -*- coding: utf-8 -*-


import sys
import argparse


def print8(*args):
    print " ".join(unicode(x).encode(u"utf-8") for x in args)


def bytelist(s):
    if not s:
        return "[]"
    return u"[%s]" % u", ".join(u"0x%s" % x.lower() for x in s.split(u","))
    

def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument(u"-v", u"--verbose", action=u"store_true",
                   help=u"Verbose output.")
    p.add_argument(u"table")
    args = p.parse_args([x.decode(u"utf-8") for x in argv[1:]])
    
    ps2make = list()
    ps2break = list()
    names = list()
    with open(args.table) as f:
        for line in f:
            name, make, brk = line.decode(u"utf-8").rstrip(u"\n").split(u"\t")
            names.append(name)
            ps2make.append((name, bytelist(make)))
            ps2break.append((name, bytelist(brk)))
    
    print8(u"    enum KeyCode {")
    for name in names:
        print8(u"        case %s" % name)
    print8(u"    }\n")
    
    print8(u"    let ps2make: [KeyCode:[UInt8]] = [")
    for name, bytes in ps2make:
        print8(u"        %-16s%s," % (u".%s:" % name, bytes))
    print8(u"    ]\n")
    
    print8(u"    let ps2break: [KeyCode:[UInt8]] = [")
    for name, bytes in ps2break:
        print8(u"        %-16s%s," % (u".%s:" % name, bytes))
    print8(u"    ]\n")
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    
