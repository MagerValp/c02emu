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
    u"abx 7":   u"ABX",
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

OPCLASS = {
    u"ADC":     u"RD_",
    u"AND":     u"R_",
    u"ASL":     u"RMW_",
    u"BBR0":    u"B_",
    u"BBR1":    u"B_",
    u"BBR2":    u"B_",
    u"BBR3":    u"B_",
    u"BBR4":    u"B_",
    u"BBR5":    u"B_",
    u"BBR6":    u"B_",
    u"BBR7":    u"B_",
    u"BBS0":    u"B_",
    u"BBS1":    u"B_",
    u"BBS2":    u"B_",
    u"BBS3":    u"B_",
    u"BBS4":    u"B_",
    u"BBS5":    u"B_",
    u"BBS6":    u"B_",
    u"BBS7":    u"B_",
    u"BCC":     u"B_",
    u"BCS":     u"B_",
    u"BEQ":     u"B_",
    u"BIT":     u"R_",
    u"BMI":     u"B_",
    u"BNE":     u"B_",
    u"BPL":     u"B_",
    u"BRA":     u"B_",
    u"BRK":     u"BRK_",
    u"BVC":     u"B_",
    u"BVS":     u"B_",
    u"CLC":     u"I_",
    u"CLD":     u"I_",
    u"CLI":     u"I_",
    u"CLV":     u"I_",
    u"CMP":     u"R_",
    u"CPX":     u"R_",
    u"CPY":     u"R_",
    u"DEC":     u"RMW_",
    u"DEX":     u"I_",
    u"DEY":     u"I_",
    u"EOR":     u"R_",
    u"INC":     u"RMW_",
    u"INX":     u"I_",
    u"INY":     u"I_",
    u"JMP":     u"JMP_",
    u"JSR":     u"JSR_",
    u"LDA":     u"R_",
    u"LDX":     u"R_",
    u"LDY":     u"R_",
    u"LSR":     u"RMW_",
    u"NOP":     u"R_",
    u"ORA":     u"R_",
    u"PHA":     u"PUSH_",
    u"PHP":     u"PUSH_",
    u"PHX":     u"PUSH_",
    u"PHY":     u"PUSH_",
    u"PLA":     u"PULL_",
    u"PLP":     u"PULL_",
    u"PLX":     u"PULL_",
    u"PLY":     u"PULL_",
    u"RMB0":    u"RMW_",
    u"RMB1":    u"RMW_",
    u"RMB2":    u"RMW_",
    u"RMB3":    u"RMW_",
    u"RMB4":    u"RMW_",
    u"RMB5":    u"RMW_",
    u"RMB6":    u"RMW_",
    u"RMB7":    u"RMW_",
    u"ROL":     u"RMW_",
    u"ROR":     u"RMW_",
    u"RTI":     u"RTI_",
    u"RTS":     u"RTS_",
    u"SBC":     u"RD_",
    u"SEC":     u"I_",
    u"SED":     u"I_",
    u"SEI":     u"I_",
    u"SMB0":    u"RMW_",
    u"SMB1":    u"RMW_",
    u"SMB2":    u"RMW_",
    u"SMB3":    u"RMW_",
    u"SMB4":    u"RMW_",
    u"SMB5":    u"RMW_",
    u"SMB6":    u"RMW_",
    u"SMB7":    u"RMW_",
    u"STA":     u"W_",
    u"STP":     u"STOP_",
    u"STX":     u"W_",
    u"STY":     u"W_",
    u"STZ":     u"W_",
    u"TAX":     u"I_",
    u"TAY":     u"I_",
    u"TRB":     u"RMW_",
    u"TSB":     u"RMW_",
    u"TSX":     u"I_",
    u"TXA":     u"I_",
    u"TXS":     u"I_",
    u"TYA":     u"I_",
    u"WAI":     u"WAIT_",
}


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
            print8(u"    // %02x - %02x" % (msb, msb + 15))
            for lsb in xrange(0, 16):
                addr_macro = ADDRMODE[addrmodes[lsb]]
                op_macro = OPCLASS[opcodes[lsb]]
                macro = u"%s%s(%s)," % (op_macro, addr_macro, opcodes[lsb])
                print8(u"    %-15s // %s %s" % (macro, opcodes[lsb], addrmodes[lsb]))
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    
