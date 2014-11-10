#ifndef __MAKETEST_H__
#define __MAKETEST_H__

enum Inst {
  I_ADD, I_SUB, I_SHLD, I_FADD, I_FDIV, I_FMUL, I_FNEG, I_FSQRT, I_FSUB,
  I_FTRC, I_FLOAT,
  I_SENTINEL
};

typedef union {
  float f;
  int i;
  uint32_t u;
} data_t;

uint32_t fadd(uint32_t, uint32_t);
uint32_t fsub(uint32_t, uint32_t);
uint32_t fmul(uint32_t, uint32_t);
uint32_t fneg(uint32_t);
uint32_t finv(uint32_t);
uint32_t fsqrt(uint32_t);
uint32_t ftrc(uint32_t);
uint32_t itof(uint32_t);

#endif
