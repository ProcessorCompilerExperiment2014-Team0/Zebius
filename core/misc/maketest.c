#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "maketest.h"

void write(char *filename, enum Inst inst, data_t *arg) {
  FILE *file = fopen(filename, "wb");
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
  printf("Expected: %08X = %d = %f\n", res.u, res.i, res.f);
  fwrite(&res.u, sizeof(uint32_t), 1, file);
  fclose(file);
}

/*
format:
  0x.* : hexadecimal
  [0-9\+\-]* : decimal
  .* : float
*/
void read(char *buf, data_t *d) {
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

int main(int argc, char **argv) {
  if(argc < 2) {
    fprintf(stderr, "Usage: maketest <filename>\n");
    return 1;
  }
  char buf[100];
  data_t arg[2];
  enum Inst inst;
  printf("Instruction: ");
  scanf("%99s", buf);
  if(!strcmp(buf, "ADD")) {
    inst = I_ADD;
  } else if(!strcmp(buf, "SUB")) {
    inst = I_SUB;
  } else if(!strcmp(buf, "SHLD")) {
    inst = I_SHLD;
  } else if(!strcmp(buf, "FADD")) {
    inst = I_FADD;
  } else if(!strcmp(buf, "FDIV")) {
    inst = I_FDIV;
  } else if(!strcmp(buf, "FMUL")) {
    inst = I_FMUL;
  } else if(!strcmp(buf, "FNEG")) {
    inst = I_FNEG;
  } else if(!strcmp(buf, "FSQRT")) {
    inst = I_FSQRT;
  } else if(!strcmp(buf, "FSUB")) {
    inst = I_FSUB;
  } else if(!strcmp(buf, "FTRC")) {
    inst = I_FTRC;
  } else if(!strcmp(buf, "FLOAT")) {
    inst = I_FLOAT;
  } else {
    printf("Unknown instruction: %s\n", buf);
    return 1;
  }
  switch (inst) {
  case I_FSQRT:
  case I_FTRC:
  case I_FLOAT:
    printf("Input: ");
    scanf("%99s", buf);
    read(buf, &arg[0]);
    break;
  default:
    printf("Input 1: ");
    scanf("%99s", buf);
    read(buf, &arg[0]);
    printf("Input 2: ");
    scanf("%99s", buf);
    read(buf, &arg[1]);
    break;
  }

  write(argv[1], inst, arg);
  return 0;
}
