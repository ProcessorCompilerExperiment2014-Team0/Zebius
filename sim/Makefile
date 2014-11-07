CC = gcc
CFLAGS = -Wall -O2
LD = gcc
LDFLAGS = -lm
TARG = zsim

FPUS = def.o fadd.o fsub.o fmul.o fneg.o finv.o fsqrt.o ftrc.o itof.o

all: $(TARG)

zsim: main.o exec.o $(addprefix ../fpu/, $(FPUS))
	$(LD) -o $@ $^ $(LDFLAGS)

main.o: main.c main.h exec.h

exec.o: exec.c main.h exec.h fpu.h

clean:
	rm -rf $(TARG) $(addprefix ../fpu/, $(FPUS)) *.o

.PHONY: all clean
