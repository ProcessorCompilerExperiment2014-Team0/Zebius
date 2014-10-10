CC = gcc
CFLAGS = -Wall -O2
LD = gcc
TARG = zsim

all: $(TARG)

zsim: main.o exec.o
	$(LD) $(LDFLAGS) -o $@ $^

main.o: main.c main.h exec.h

clean:
	rm -rf $(TARG) *.o

.PHONY: all clean
