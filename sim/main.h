#ifndef __MAIN_H__
#define __MAIN_H__

#include <stdint.h>

#define NUM_OF_GPR 16
#define NUM_OF_FR 16
#define SIZE_OF_SRAM (1 << 22)
#define SIZE_OF_BLOCKRAM (1 << 10)

enum Opt {
  OPTION_D, OPTION_M, OPTION_W, OPTION_R, OPTION_N,
  OPTION_N_FADD, OPTION_N_FDIV, OPTION_N_FMUL, OPTION_N_FNEG,
  OPTION_N_FSQRT, OPTION_N_FSUB,
  OPTION_SENTINEL,
};

enum Inst {
  I_WRITE, I_READ, I_MOV_I, I_MOV_L_DISP, I_MOV, I_MOV_L_ST, I_MOV_L_LD,
  I_STS_PR, I_ADD, I_ADD_I, I_CMP_EQ, I_CMP_GT, I_SUB, I_AND, I_NOT, I_OR,
  I_XOR, I_SHLD, I_BF, I_BT, I_BRA, I_JMP, I_JSR, I_RTS, I_FLDI0, I_FLDI1,
  I_FMOV, I_FMOV_S_LD, I_FMOV_S_ST, I_FADD, I_FCMP_EQ, I_FCMP_GT, I_FDIV,
  I_FMUL, I_FNEG, I_FSQRT, I_FSUB, I_LDS, I_STS_FPUL, I_FLDS, I_FSTS, I_FTRC,
  I_FLOAT, I_SENTINEL
};

typedef union {
  float f;
  int i;
  uint32_t u;
} data_t;

typedef struct {
  int valid;
  data_t v;
} test_t;

typedef struct {
  data_t gpr[NUM_OF_GPR];       /* General Purpose Register */
  data_t gbr;                   /* Global Base Register */
  data_t sr;                    /* Status Register */
  data_t pr;                    /* Procedure Register */
  data_t pc;                    /* Program Counter */

  data_t fr[NUM_OF_FR];         /* Floating Point Register */
  data_t fpul;
  data_t fpscr;
  
  char *mem;                    /* SRAM */

  int opt;
  test_t t_gpr[NUM_OF_GPR];
  test_t t_fr[NUM_OF_FR];
  long long i_count;
  long long i_limit;
  long long i_stat[I_SENTINEL];
} state_t;

void show_status(state_t *st);
void show_status_honly(state_t *st);

#endif
