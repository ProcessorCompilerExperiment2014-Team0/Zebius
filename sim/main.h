#ifndef __MAIN_H__
#define __MAIN_H__

#include <stdint.h>

#define NUM_OF_GPR 16
#define NUM_OF_FR 16
#define SIZE_OF_SRAM (1 << 22)

#define OPTION_D 0
#define OPTION_M 1
#define OPTION_W 2
#define OPTION_N 3

typedef union {
  float f;
  int i;
  uint32_t u;
} data_t;

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
} state_t;

typedef struct {
  int valid;
  data_t v;
} test_t;

typedef struct {
  int opt;
  test_t gpr[NUM_OF_GPR];
  test_t fr[NUM_OF_FR];
} option_t;

void show_status(state_t *st);

#endif
