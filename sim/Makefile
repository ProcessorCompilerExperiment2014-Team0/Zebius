CC = gcc
CFLAGS = -Wall -O2
LD = gcc
LDFLAGS = -lm
TARG = zsim

FPUS = fpu/def.o fpu/fadd.o fpu/fsub.o fpu/fmul.o fpu/fneg.o \
       fpu/finv.o fpu/fsqrt.o

all: $(TARG)

zsim: main.o exec.o $(FPUS)
	$(LD) -o $@ $^ $(LDFLAGS)

main.o: main.c main.h exec.h

exec.o: exec.c main.h exec.h fpu.h

clean:
	rm -rf $(TARG) $(FPUS) *.o

.PHONY: all clean
