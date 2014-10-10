#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "main.h"

void add(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i + reg[t].i;
}

void shl(data_t *reg, int s, int t, int d) {
  if(reg[t].i >= 0) {
    reg[d].i = reg[s].i << reg[t].i;
  } else {
    reg[d].i = reg[s].i >> reg[t].i;
  }
}

void and(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i & reg[t].i;
}

void or(data_t *reg, int s, int t, int d) {
  reg[d].i = reg[s].i | reg[t].i;
}

void cmp(data_t *reg, int s, int t, int d) {
  if(reg[s].i > reg[t].i) {
    reg[d].i = 1;
  } else if(reg[s].i < reg[t].i) {
    reg[d].i = -1;
  } else {
    reg[d].i = 0;
  }
}

/* void sub(data_t *reg, int s, int t, int d) { */
/*   reg[d].i = reg[s].i - reg[t].i; */
/* } */

/* void mul(data_t *reg, int s, int t, int d) { */
/*   reg[d].i = reg[s].i * reg[t].i; */
/* } */

void neg(data_t *reg, int s, int d) {
  reg[d].i = -reg[s].i;
}

void not(data_t *reg, int s, int d) {
  reg[d].i = ~reg[s].i;
}

void fadd(data_t *reg, int s, int t, int d) {
  reg[d].f = reg[s].f + reg[t].f;
}

void fmul(data_t *reg, int s, int t, int d) {
  reg[d].f = reg[s].f * reg[t].f;
}
  
void fcmp(data_t *reg, int s, int t, int d) {
  if(reg[s].f > reg[t].f) {
    reg[d].i = 1;
  } else if(reg[s].f < reg[t].f) {
    reg[d].i = -1;
  } else {
    reg[d].i = 0;
  }
}

void fneg(data_t *reg, int s, int d) {
  reg[d].f = -reg[s].f;
}
  
void finv(data_t *reg, int s, int d) {
  reg[d].f = 1.0 / reg[s].f;
}

void fsqrt(data_t *reg, int s, int d) {
  /* reg[d].f = sqrtf(reg[s].f); */
  printf("sqrt is not implemented\n");
}

int get_addr(int disp, int rv) {
  if(disp >> 3 & 1) {
    disp |= 0xFFFFFFF0;
  }
  return rv + disp;
}

void exec_inst(data_t *reg, data_t *mem, inst_t *insts, int *pc) {
  int inst = insts[*pc];
  printf("exec: %04X\n", inst);
  int opcode = inst >> 12;
  if(opcode < 11) {
    int operand[3];
    int i;
    for(i=0; i<3; i++) {
      operand[i] = 0xF & (inst >> (8 - i * 4));
    }
    printf("operands = (%X, %X, %X)\n", operand[0], operand[1], operand[2]);
    switch(opcode) {
    case 0:                     /* add */
      add(reg, operand[0], operand[1], operand[2]);
      break;
    case 1:                     /* shl */
      shl(reg, operand[0], operand[1], operand[2]);
      break;
    case 2:                     /* and */
      and(reg, operand[0], operand[1], operand[2]);
      break;
    case 3:                     /* or */
      or(reg, operand[0], operand[1], operand[2]);
      break;
    case 4:                     /* cmp */
      cmp(reg, operand[0], operand[1], operand[2]);
      break;
    case 5:                     /* fadd */
      fadd(reg, operand[0], operand[1], operand[2]);
      break;
    case 6:                     /* fmul */
      fmul(reg, operand[0], operand[1], operand[2]);
      break;
    case 7:                     /* fcmp */
      fcmp(reg, operand[0], operand[1], operand[2]);
      break;
    case 8:                     /* unary */
      switch(operand[1]) {
      case 0:
        neg(reg, operand[0], operand[2]);
        break;
      case 1:
        not(reg, operand[0], operand[2]);
        break;
      case 2:
        finv(reg, operand[0], operand[2]);
        break;
      case 3:
        fneg(reg, operand[0], operand[2]);
        break;
      case 4:
        fsqrt(reg, operand[0], operand[2]);
        break;
      case 5:                   /* wr */
        printf("write\n");
        break;
      case 6:                   /* rd */
        printf("read\n");
        break;
      default:
        break;
      }
      break;
    case 9:                     /* ld */
      operand[1] = get_addr(operand[1], operand[2]);
      printf("load from %05X\n", operand[1]);
      reg[operand[0]] = mem[operand[1]];
      break;
    case 10:                    /* st */
      operand[1] = get_addr(operand[1], operand[2]);
      printf("store to %05X\n", operand[1]);
      mem[operand[1]] = reg[operand[0]];
      break;
    default:
      printf("unknown instruction: %04X\n", inst);
      break;
    }
    (*pc)++;
  } else if(opcode < 13) {
    int operand = 0xF & (inst >> 8);
    int immd = 0xFF & inst;
    switch(opcode) {
    case 11:                    /* beq */
      if(!reg[operand].i) {     /* taken */
        *pc += immd;
      } else {                  /* not taken */
        (*pc)++;
      }
      break;
    case 12:                    /* bgt */
      if(reg[operand].i > 0) {  /* taken */
        *pc += immd;
      } else {                  /* not taken */
        (*pc)++;
      }
      break;
    default:
      printf("unknown instruction: %04X\n", inst);
      break;
    }
  } else if(opcode == 13) {     /* jmp */
    int addr = 0xFFF & inst;
    *pc = addr;
  } else {
    printf("unknown instruction: %04X\n", inst);
  }
}

void run(data_t *reg, data_t *mem, inst_t *inst, int noi) {
  int pc = 0;
  while(pc < noi) {
    exec_inst(reg, mem, inst, &pc);
  }
}
