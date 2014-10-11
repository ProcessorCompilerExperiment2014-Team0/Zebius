#ifndef __MAIN_H__
#define __MAIN_H__

#define NUM_OF_REGISTER 16
#define SIZE_OF_SRAM (2 << 20)
#define INST_LEN 2

typedef int inst_t;

typedef union {
  float f;
  int i;
} data_t;

void show_registers(data_t *reg);

#endif
