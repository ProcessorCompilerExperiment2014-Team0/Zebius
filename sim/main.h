#ifndef __MAIN_H__
#define __MAIN_H__

#define NUM_OF_GPR 16
#define NUM_OF_FR 16
#define SIZE_OF_SRAM (2 << 22)

#define debug

typedef union {
  float f;
  int i;
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

void show_status(state_t *st);

#endif
