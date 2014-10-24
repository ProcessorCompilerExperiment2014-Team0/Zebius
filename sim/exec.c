#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "main.h"
#include "exec.h"
#include "fpu.h"

/* sign extend v as (len) bits integer */
int extend(int v, int len) {
  if(v >> (len - 1) & 1) {
    v |= ~((1 << len) - 1);
  }
  return v;
}

void mem_st_dw(char *mem, int addr, int *s) {
  int old;
  memcpy(&old, mem+addr, 4);
  memcpy(mem+addr, s, 4);
  fprintf(stderr, "st: addr = %08X    value = %08X -> %08X\n", addr, old, *s);
}

void mem_ld_dw(char *mem, int addr, int *d) {
  memcpy(d, mem+addr, 4);
  fprintf(stderr, "ld: addr = %08X    value = %08X\n", addr, *d);
}

void inc_pc(state_t *st) {
  st->pc.i += 2;
}

void i_write(state_t *st, int n) {
  printf("%02X\n", st->gpr[n].i & 0xFF);
  inc_pc(st);
}

void i_read(state_t *st, int n) {
  int v;
  fprintf(stderr, "read into R%d: ", n);
  if(scanf("%X", &v) == EOF) {
    perror("read");
    return;
  }
  st->gpr[n].i = v & 0xFF;
  fprintf(stderr, "read: value = %08X\n", st->gpr[n].i);
  inc_pc(st);
}

void i_mov_i(state_t *st, int imm, int n) {
  st->gpr[n].i = extend(imm, 8);
  inc_pc(st);
}

void i_mov(state_t *st, int m, int n) {
  st->gpr[n].i = st->gpr[m].i;
  inc_pc(st);
}

void i_mov_l_disp(state_t *st, int disp, int n) {
  int addr = disp*4 + (st->pc.i & 0xFFFFFFFC) + 4;
  mem_ld_dw(st->mem, addr, &st->gpr[n].i);
  inc_pc(st);
}

void i_mov_l_st(state_t *st, int m, int n) {
  mem_st_dw(st->mem, st->gpr[n].i, &st->gpr[m].i);
  inc_pc(st);
}

void i_sts_pr(state_t *st, int n) {
  st->gpr[n].i = st->pr.i;
  inc_pc(st);
}

void i_mov_l_ld(state_t *st, int m, int n) {
  mem_ld_dw(st->mem, st->gpr[m].i, &st->gpr[n].i);
  inc_pc(st);
}

void i_add(state_t *st, int m, int n) {
  st->gpr[n].i += st->gpr[m].i;
  inc_pc(st);
}

void i_add_i(state_t *st, int imm, int n) {
  st->gpr[n].i += extend(imm, 8);
  inc_pc(st);
}

void i_cmp_eq(state_t *st, int m, int n) {
  if(st->gpr[n].i == st->gpr[m].i) {
    st->sr.i |= 1;
  } else {
    st->sr.i &= ~1;
  }
  inc_pc(st);
}

void i_cmp_gt(state_t *st, int m, int n) {
  if(st->gpr[n].i > st->gpr[m].i) {
    st->sr.i |= 1;
  } else {
    st->sr.i &= ~1;
  }
  inc_pc(st);
}

void i_sub(state_t *st, int m, int n) {
  st->gpr[n].i -= st->gpr[m].i;
  inc_pc(st);
}

void i_and(state_t *st, int m, int n) {
  st->gpr[n].i &= st->gpr[m].i;
  inc_pc(st);
}

void i_not(state_t *st, int m, int n) {
  st->gpr[n].i = ~st->gpr[m].i;
  inc_pc(st);
}

void i_or(state_t *st, int m, int n) {
  st->gpr[n].i |= st->gpr[m].i;
  inc_pc(st);
}

void i_xor(state_t *st, int m, int n) {
  st->gpr[n].i ^= st->gpr[m].i;
  inc_pc(st);
}

void i_shld(state_t *st, int m, int n) {
  if(st->gpr[m].i >= 0) {
    st->gpr[n].i <<= st->gpr[m].i;
  } else {
    st->gpr[n].i >>= -st->gpr[m].i;
  }
  inc_pc(st);
}

void i_fldi0(state_t *st, int n) {
  st->fr[n].i = 0x00000000;
  inc_pc(st);
}

void i_fldi1(state_t *st, int n) {
  st->fr[n].i = 0x3F800000;
  inc_pc(st);
}

void i_fmov(state_t *st, int m, int n) {
  st->fr[n].i = st->fr[m].i;
  inc_pc(st);
}

void i_fmov_s_ld(state_t *st, int m, int n) {
  mem_ld_dw(st->mem, st->gpr[m].i, &st->fr[n].i);
  inc_pc(st);
}

void i_fmov_s_st(state_t *st, int m, int n) {
  mem_st_dw(st->mem, st->gpr[n].i, &st->fr[m].i);
  inc_pc(st);
}

void i_fadd(state_t *st, int m, int n) {
  /* st->fr[n].f += st->fr[m].f; */
  st->fr[n].u = fadd(st->fr[n].u, st->fr[m].u);
  inc_pc(st);
}

void i_fcmp_eq(state_t *st, int m, int n) {
  if(st->fr[n].f == st->fr[m].f) {
    st->sr.i |= 1;
  } else {
    st->sr.i &= ~1;
  }
  inc_pc(st);
}

void i_fcmp_gt(state_t *st, int m, int n) {
  if(st->fr[n].f > st->fr[m].f) {
    st->sr.i |= 1;
  } else {
    st->sr.i &= ~1;
  }
  inc_pc(st);
}

void i_fdiv(state_t *st, int m, int n) {
  st->fr[n].f /= st->fr[m].f;
  inc_pc(st);
}

void i_fmul(state_t *st, int m, int n) {
  /* st->fr[n].f *= st->fr[m].f; */
  st->fr[n].u = fmul(st->fr[n].u, st->fr[m].u);
  inc_pc(st);
}

void i_fneg(state_t *st, int n) {
  /* st->fr[n].f = -st->fr[n].f; */
  st->fr[n].u = fneg(st->fr[n].u);
  inc_pc(st);
}

void i_fsqrt(state_t *st, int n) {
  st->fr[n].f = sqrtf(st->fr[n].f);
  inc_pc(st);
}

void i_fsub(state_t *st, int m, int n) {
  /* st->fr[n].f -= st->fr[m].f; */
  st->fr[n].u = fsub(st->fr[n].u, st->fr[m].u);
  inc_pc(st);
}

void i_bf(state_t *st, int disp) {
  if(!(st->sr.i & 1)) {
    st->pc.i += extend(disp, 8)*2 + 4;
  } else {
    inc_pc(st);
  }
}

void i_bt(state_t *st, int disp) {
  if(st->sr.i & 1) {
    st->pc.i += extend(disp, 8)*2 + 4;
  } else {
    inc_pc(st);
  }
}

void i_bra(state_t *st, int disp) {
  st->pc.i += extend(disp, 12)*2 + 4;
}

void i_jmp(state_t *st, int n) {
  st->pc.i = st->gpr[n].i;
}

void i_jsr(state_t *st, int n) {
  st->pr.i = st->pc.i + 4;
  st->pc.i = st->gpr[n].i;
}

void i_rts(state_t *st) {
  st->pc.i = st->pr.i;
}

void i_lds(state_t *st, int n) {
  st->fpul.i = st->gpr[n].i;
  inc_pc(st);
}

void i_sts_fpul(state_t *st, int n) {
  st->gpr[n].i = st->fpul.i;
  inc_pc(st);
}

void i_flds(state_t *st, int n) {
  st->fpul.i = st->fr[n].i;
  inc_pc(st);
}

void i_fsts(state_t *st, int n) {
  st->fr[n].i = st->fpul.i;
  inc_pc(st);
}

void i_ftrc(state_t *st, int m) {
  st->fpul.i = (int)st->fr[m].f;
  inc_pc(st);
}

void i_float(state_t *st, int n) {
  st->fr[n].f = (float)st->fpul.i;
  inc_pc(st);
}

void inst_error(int inst) {
  fprintf(stderr, "Unknown instruction: %04X\n", inst);
}

int exec_inst(state_t *st) {
  int inst;
  memcpy(&inst, st->mem + st->pc.i, 2);
  fprintf(stderr, "exec: %04X, pc: %08X\n", inst, st->pc.i);
  
  int opcode = inst >> 12;
  if(opcode == 0x7 || opcode == 0x8 || opcode == 0x9 || opcode == 0xE) { /* 4,4,8 form */
    int param[2];
    param[0] = 0xF & (inst >> 8);
    param[1] = 0xFF & inst;
    switch(opcode) {
    case 0x7:                   /* ADD imm */
      i_add_i(st, param[1], param[0]);
      break;
    case 0x8:
      switch(param[0]) {
      case 0x9:                 /* BT */
        i_bt(st, param[1]);
        break;
      case 0xB:                 /* BF */
        i_bf(st, param[1]);
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    case 0x9:                   /* MOV.L(PC relative) */
      i_mov_l_disp(st, param[1], param[0]);
      break;
    case 0xE:                   /* MOV(imm) */
      i_mov_i(st, param[1], param[0]);
      break;
    default:
      inst_error(inst);
      return -1;
    }
  } else if(opcode == 0xA) {    /* 4,12 form */
    int param = 0xFFF & inst;
    i_bra(st, param);           /* BRA */
  } else {                      /* 4,4,4,4 form */
    int param[3];
    int i;
    for(i=0; i<3; i++) {
      param[i] = 0xF & (inst >> (8 - i * 4));
    }
    switch(opcode) {
    case 0x0:
      switch(param[2]) {
      case 0x0:                 /* WRITE */
        i_write(st, param[0]);
        break;
      case 0x1:
        i_read(st, param[0]);
        break;
      case 0xA:                 /* STS */
        switch(param[1]) {
        case 0x2:
          i_sts_pr(st, param[0]);
          break;
        case 0x5:
          i_sts_fpul(st, param[0]);
          break;
        default:
          inst_error(inst);
          return -1;
        }
        break;
      case 0xB:                 /* RTS */
        i_rts(st);
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    case 0x2:
      switch(param[2]) {
      case 0x2:                 /* MOV.L(st) */
        i_mov_l_st(st, param[1], param[0]);
        break;
      case 0x9:                 /* AND */
        i_and(st, param[1], param[0]);
        break;
      case 0xA:                 /* XOR */
        i_xor(st, param[1], param[0]);
        break;
      case 0xB:                 /* OR */
        i_or(st, param[1], param[0]);
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    case 0x3:
      switch(param[2]) {
      case 0x0:                 /* CMP/EQ */
        i_cmp_eq(st, param[1], param[0]);
        break;
      case 0x7:                 /* CMP/GT */
        i_cmp_gt(st, param[1], param[0]);
        break;
      case 0x8:                 /* SUB */
        i_sub(st, param[1], param[0]);
        break;
      case 0xC:                 /* ADD */
        i_add(st, param[1], param[0]);
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    case 0x4:
      switch(param[2]) {
      case 0xA:
        switch(param[1]) {
        case 0x5:               /* LDS */
          i_lds(st, param[0]);
          break;
        default:
          inst_error(inst);
          return -1;
        }
        break;
      case 0xB:
        switch(param[1]) {
        case 0x0:               /* JSR */
          i_jsr(st, param[0]);
          break;
        case 0x2:               /* JMP */
          i_jmp(st, param[0]);
          break;
        default:
          inst_error(inst);
          return -1;
        }
        break;
      case 0xD:                 /* SHLD */
        i_shld(st, param[1], param[0]);
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    case 0x6:
      switch(param[2]) {
      case 0x2:                 /* MOV.L(ld) */
        i_mov_l_ld(st, param[1], param[0]);
        break;
      case 0x3:                 /* MOV */
        i_mov(st, param[1], param[0]);
        break;
      case 0x7:                 /* NOT */
        i_not(st, param[1], param[0]);
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    case 0xF:
      switch(param[2]) {
      case 0x0:                 /* FADD */
        i_fadd(st, param[1], param[0]);
        break;
      case 0x1:                 /* FSUB */
        i_fsub(st, param[1], param[0]);
        break;
      case 0x2:                 /* FMUL */
        i_fmul(st, param[1], param[0]);
        break;
      case 0x3:                 /* FDIV */
        i_fdiv(st, param[1], param[0]);
        break;
      case 0x4:                 /* FCMP/EQ */
        i_fcmp_eq(st, param[1], param[0]);
        break;
      case 0x5:                 /* FCMP/GT */
        i_fcmp_gt(st, param[1], param[0]);
        break;
      case 0x8:                 /* FMOV.S(ld) */
        i_fmov_s_ld(st, param[1], param[0]);
        break;
      case 0xA:                 /* FMOV.S(st) */
        i_fmov_s_st(st, param[1], param[0]);
        break;
      case 0xD:
        switch(param[1]) {
        case 0x4:               /* FNEG */
          i_fneg(st, param[0]);
          break;
        case 0x6:               /* FSQRT */
          i_fsqrt(st, param[0]);
          break;
        case 0x8:               /* FLDI0 */
          i_fldi0(st, param[0]);
          break;
        case 0x9:               /* FLDI1 */
          i_fldi1(st, param[0]);
          break;
        default:
          inst_error(inst);
          return -1;
        }
        break;
      default:
        inst_error(inst);
        return -1;
      }
      break;
    default:
      inst_error(inst);
      return -1;
    }
  }
  return 0;
}

void run(state_t *st, int noi) {
  while(st->pc.i != noi * 2) {
#ifdef debug
    show_status(st);
#endif
    if(exec_inst(st) < 0) break;
  }
}
