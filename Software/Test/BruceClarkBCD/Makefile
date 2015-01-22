TARGET=none
CC=cl65
AS=ca65 -g
LD=ld65
C1541=c1541
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=--target $(TARGET) --cpu 65c02
LDFLAGS=
GCC=gcc
GCCFLAGS=-O
PROJECT=bcdtest


%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<

%.bin: %.png %.py
	@if test \! -x $*.py; then chmod +x $*.py; fi
	./$*.py $< $@

%.i: %.png %.py
	@if test \! -x $*.py; then chmod +x $*.py; fi
	./$*.py $< $@

%.bin: %.o $(PROJECT).cfg
	$(LD) -m $*.map -C $(PROJECT).cfg --dbgfile $*.dbg -o $@ $(LDFLAGS) $<

all: $(PROJECT).bin

clean:
	rm -f $(PROJECT).o
	rm -f $(PROJECT).bin $(PROJECT).map $(PROJECT).dbg $(PROJECT).lst


distclean: clean
	rm -f *~
