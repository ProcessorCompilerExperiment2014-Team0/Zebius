#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "main.h"

void add(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i + reg[t].i;
}

void cmp(data_t *reg, int s, int t, int d) {
  if(reg[s].i == reg[t].i) {
    reg[d].i = 1;
  } else if(reg[s].i > reg[t].i) {
    reg[d].i = 2;
  } else {
    reg[d].i = 0;
  }
}

void shl(data_t *reg, int s, int t, int d) {
  if(reg[t].i >= 0) {
    reg[d].i = reg[s].i << reg[t].i;
  } else {
    reg[d].i = reg[s].i >> -reg[t].i;
  }
}

void and(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i & reg[t].i;
}

void or(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i | reg[t].i;
}

void xor(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i ^ reg[t].i;
}

void neg(data_t *reg, int s, int d) {
  reg[d].i = -reg[s].i;
}

void not(data_t *reg, int s, int d) {
  reg[d].i = ~reg[s].i;
}
  
void finv(data_t *reg, int s, int d) {
  reg[d].f = 1.0 / reg[s].f;
}

void fneg(data_t *reg, int s, int d) {
  reg[d].f = -reg[s].f;
}

void fsqrt(data_t *reg, int s, int d) {
  /* reg[d].f = sqrtf(reg[s].f); */
  fprintf(stderr, "sqrt is not implemented\n");
}

void read(data_t *reg, int d) {
  char buf[64];
  printf("read into r%d: ", d);
  int res = scanf("%63s", buf);
  if(res == EOF) {
    perror("read");
    return;
  }
  buf[63] = '\0';
  if(buf[0] == '0' && (buf[1] == 'x' || buf[1] == 'X')) {
    sscanf(buf+2, "%x", &reg[d].i);
    return;
  }
  char *p = buf;
  int is_int = 1;
  if(buf[0] == '+' || buf[0] == '-') {
    p++;
  }
  while(*p) {
    if(*p < '0' || *p > '9') {
      is_int = 0;
      break;
    }
    p++;
  }
  if(is_int) {
    sscanf(buf, "%d", &reg[d].i);
  } else {
    sscanf(buf, "%f", &reg[d].f);
  }
}

void write(data_t *reg, int s) {
  printf("write: %11d = %08X = %f\n", reg[s].i, reg[s].i, reg[s].f);
}

void fadd(data_t *reg, int s, int t, int d) {
  reg[d].f = reg[s].f + reg[t].f;
}

void fmul(data_t *reg, int s, int t, int d) {
  reg[d].f = reg[s].f * reg[t].f;
}
  
void fcmp(data_t *reg, int s, int t, int d) {
  if(reg[s].f == reg[t].f) {
    reg[d].i = 1;
  } else if(reg[s].f > reg[t].f) {
    reg[d].i = 2;
  } else {
    reg[d].i = 0;
  }
}

/* sign extend v as (len) bits integer */
int extend(int v, int len) {
  if(v >> (len - 1) & 1) {
    v |= ~((1 << len) - 1);
  }
  return v;
}

/* int get_addr(int disp, int rv) { */
/*   if(disp >> 3 & 1) { */
/*     disp |= 0xFFFFFFF0; */
/*   } */
/*   return rv + disp; */
/* } */

void ld(data_t *reg, data_t *mem, int s, int disp, int r1) {
  int addr = extend(reg[disp].i, 4) + reg[s].i;
  fprintf(stderr, "load from %05X\n", addr);
  reg[r1].i = mem[addr].i;
}

void st(data_t *reg, data_t *mem, int s, int disp, int r1) {
  int addr = extend(reg[disp].i, 4) + reg[s].i;
  fprintf(stderr, "store to %05X\n", addr);
  mem[addr].i = reg[r1].i;
}

void exec_inst(data_t *reg, data_t *mem, inst_t *insts, int *pc) {
  int inst = insts[*pc];
  /* fprintf(stderr, "exec: %04X\n", inst); */
  int opcode = inst >> 12;
  if(opcode < 0xC) {
    int operand[3];
    int i;
    for(i=0; i<3; i++) {
      operand[i] = 0xF & (inst >> (8 - i * 4));
    }
    /* fprintf(stderr, "operands = (%X, %X, %X)\n", operand[0], operand[1], operand[2]); */
    switch(opcode) {
    case 0x0:                   /* add */
      add(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x1:                   /* cmp */
      cmp(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x2:                   /* shl */
      shl(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x3:                   /* and */
      and(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x4:                   /* or */
      or(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x5:                   /* xor */
      xor(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x6:                   /* unary */
      switch(operand[1]) {
      case 0x0:                 /* neg */
        neg(reg, operand[0], operand[2]);
        break;
      case 0x1:                 /* not */
        not(reg, operand[0], operand[2]);
        break;
      case 0x2:                 /* finv */
        finv(reg, operand[0], operand[2]);
        break;
      case 0x3:                 /* fneg */
        fneg(reg, operand[0], operand[2]);
        break;
      case 0x4:                 /* fsqrt */
        fsqrt(reg, operand[0], operand[2]);
        break;
      case 0x5:                 /* read */
        read(reg, operand[2]);
        break;
      case 0x6:                 /* write */
        write(reg, operand[0]);
        break;
      default:
        fprintf(stderr, "unknown instruction: %04X\n", inst);
        break;
      }
      break;
    case 0x7:                   /* fadd */
      fadd(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x8:                   /* fmul */
      fmul(reg, operand[0], operand[1], operand[2]);
      break;
    case 0x9:                   /* fcmp */
      fcmp(reg, operand[0], operand[1], operand[2]);
      break;
    case 0xA:                   /* ld */
      ld(reg, mem, operand[0], operand[1], operand[2]);
      break;
    case 0xB:                   /* st */
      st(reg, mem, operand[0], operand[1], operand[2]);
      break;
    default:
      fprintf(stderr, "unknown instruction: %04X\n", inst);
      break;
    }
    (*pc)++;
  } else if(opcode < 0xE) {
    int operand = 0xF & (inst >> 8);
    int immd = 0xFF & inst;
    switch(opcode) {
    case 0xC:                   /* beq */
      if(reg[operand].i & 1) {  /* taken */
        *pc += extend(immd, 8);
      } else {                  /* not taken */
        (*pc)++;
      }
      break;
    case 0xD:                   /* bgt */
      if(reg[operand].i & 2) {  /* taken */
        *pc += extend(immd, 8);
      } else {                  /* not taken */
        (*pc)++;
      }
      break;
    default:
      fprintf(stderr, "unknown instruction: %04X\n", inst);
      break;
    }
  } else if(opcode == 0xE) {    /* jmp */
    int addr = 0xFFF & inst;
    *pc = addr;
  } else {
    fprintf(stderr, "unknown instruction: %04X\n", inst);
  }
}

void run(data_t *reg, data_t *mem, inst_t *inst, int noi) {
  int pc = 0;
  while(pc < noi) {
    exec_inst(reg, mem, inst, &pc);
  }
}
