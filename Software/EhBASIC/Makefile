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
PROJECT=ehbasic


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


all: $(PROJECT).bin


OBJS = \
	ehbasic.o \
	min_mon.o \
	display.o

$(PROJECT).bin: $(OBJS) $(PROJECT).cfg
	$(LD) -o $@ -m $(PROJECT).map -C $(PROJECT).cfg --dbgfile $(PROJECT).dbg $(LDFLAGS) $(OBJS)


clean:
	rm -f $(OBJS)
	rm -f $(PROJECT).bin $(PROJECT).map $(PROJECT).dbg


distclean: clean
	rm -f *~
