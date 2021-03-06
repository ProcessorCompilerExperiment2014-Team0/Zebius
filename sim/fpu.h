#ifndef __FPU_H__
#define __FPU_H__

#include <stdint.h>

uint32_t fadd(uint32_t, uint32_t);
uint32_t fsub(uint32_t, uint32_t);
uint32_t fmul(uint32_t, uint32_t);
uint32_t fneg(uint32_t);
uint32_t finv(uint32_t);
uint32_t fsqrt(uint32_t);
uint32_t ftrc(uint32_t);
uint32_t itof(uint32_t);

#endif
