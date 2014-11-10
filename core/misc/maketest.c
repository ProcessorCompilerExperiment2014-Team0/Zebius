#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include "maketest.h"

uint32_t
rand32()
{
//	return *(uint32_t *)&genrand_int32;
	uint32_t x;
	x = rand() & 255;
	x = (rand() & 255) + (x<<8);
	x = (rand() & 255) + (x<<8);
	x = (rand() & 255) + (x<<8);
	return x;
}

void
write(enum Inst inst, int times, char *filename) {
	FILE *file = fopen(filename, "wb");

	for (int i=0; i<times; i++) {
		data_t arg[2];
		arg[0].u = rand32();
		arg[1].u = rand32();

		switch (inst) {
		case I_FNEG:
		case I_FSQRT:
		case I_FTRC:
		case I_FLOAT:
			fwrite(&arg[0].u, sizeof(uint32_t), 1, file);
			break;
		default:
			fwrite(&arg[0].u, sizeof(uint32_t), 1, file);
			fwrite(&arg[1].u, sizeof(uint32_t), 1, file);
		}

		data_t res;
		switch (inst) {
		case I_ADD:
			res.i = arg[0].i + arg[1].i;
			break;
		case I_SUB:
			res.i = arg[0].i - arg[1].i;
			break;
		case I_SHLD:
			if(arg[1].i >= 0) {
				res.i = arg[0].i << arg[1].i & 0x1F;
			} else if((arg[1].i & 0x1F) == 0) {
				res.i = 0;
			} else {
				res.i = arg[0].i >> ((~arg[1].i & 0x1F) + 1);
			}
			break;
		case I_FADD:
			res.u = fadd(arg[0].u, arg[1].u);
			break;
		case I_FDIV:
			res.u = fmul(arg[0].u, finv(arg[1].u));
			break;
		case I_FMUL:
			res.u = fmul(arg[0].u, arg[1].u);
			break;
		case I_FNEG:
			res.u = fneg(arg[0].u);
			break;
		case I_FSQRT:
			res.u = fsqrt(arg[0].u);
			break;
		case I_FSUB:
			res.u = fsub(arg[0].u, arg[1].u);
			break;
		case I_FTRC:
			res.u = ftrc(arg[0].u);
			break;
		case I_FLOAT:
			res.u = itof(arg[0].u);
			break;
		default:
			res.u = 0u;
			break;
		}

		fwrite(&res.u, sizeof(uint32_t), 1, file);
	}

	fclose(file);
}

#if 0
/*
  format:
  0x.* : hexadecimal
  [0-9\+\-]* : decimal
  .* : float
*/
void
read(char *buf, data_t *d) {
	int l = strlen(buf);
	if(buf[0] == '0' && (buf[1] == 'x' || buf[1] == 'X')) {
		sscanf(buf+2, "%X", &d->u);
	} else {
		int i;
		int is_int = 1;
		for(i=0; i<l; i++) {
			if((buf[i] < '0' || buf[i] > '9') && buf[i] != '-' && buf[i] != '+') {
				is_int = 0;
				break;
			}
		}
		if(is_int) {
			sscanf(buf, "%d", &d->i);
		} else {
			sscanf(buf, "%f", &d->f);
		}
	}
}
#endif

int
main(int argc, char **argv) {
	if(argc != 4) {
		fprintf(stderr, "Usage: maketest <INST> <times> <filename>\n");
		return 1;
	}

	char* argi = argv[1];

	enum Inst inst;
	if(!strcmp(argi, "ADD")) {
		inst = I_ADD;
	} else if(!strcmp(argi, "SUB")) {
		inst = I_SUB;
	} else if(!strcmp(argi, "SHLD")) {
		inst = I_SHLD;
	} else if(!strcmp(argi, "FADD")) {
		inst = I_FADD;
	} else if(!strcmp(argi, "FDIV")) {
		inst = I_FDIV;
	} else if(!strcmp(argi, "FMUL")) {
		inst = I_FMUL;
	} else if(!strcmp(argi, "FNEG")) {
		inst = I_FNEG;
	} else if(!strcmp(argi, "FSQRT")) {
		inst = I_FSQRT;
	} else if(!strcmp(argi, "FSUB")) {
		inst = I_FSUB;
	} else if(!strcmp(argi, "FTRC")) {
		inst = I_FTRC;
	} else if(!strcmp(argi, "FLOAT")) {
		inst = I_FLOAT;
	} else {
		printf("Unknown instruction: %s\n", argi);
		return 1;
	}

	write(inst, atoi(argv[2]), argv[3]);
	return 0;
}

