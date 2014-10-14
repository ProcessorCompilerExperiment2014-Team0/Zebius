CC = gcc
CFLAGS = -Wall -O2
LD = gcc
LDFLAGS = -lm
TARG = zsim

all: $(TARG)

zsim: main.o exec.o
	$(LD) -o $@ $^ $(LDFLAGS)

main.o: main.c main.h exec.h

clean:
	rm -rf $(TARG) *.o

.PHONY: all clean
