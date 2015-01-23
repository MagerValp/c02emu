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


all: rom.bin


ROM_OBJS = \
	rom.o \
	display.o \
	keyboard.o

rom.bin: $(ROM_OBJS) rom.cfg
	$(LD) -m rom.map -C rom.cfg --dbgfile rom.dbg -o $@ $(LDFLAGS) $(ROM_OBJS)


clean:
	rm -f $(ROM_OBJS)
	rm -f rom.bin rom.map rom.dbg


distclean: clean
	rm -f *~
