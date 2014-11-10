CC = gcc
CFLAGS = -Wall -O2
LD = gcc
LDFLAGS = -lm
TARGET = maketest

FPUS = def.o fadd.o fsub.o fmul.o fneg.o finv.o fsqrt.o ftrc.o itof.o
FPUDIR = ../../fpu/

all: $(TARGET)

maketest: maketest.o $(addprefix $(FPUDIR), $(FPUS))
	$(LD) -o $@ $^ $(LDFLAGS)

clean:
	rm -rf $(TARG) $(addprefix ../fpu/, $(FPUS)) *.o

.PHONY: all clean
