#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include "main.h"
#include "exec.h"

int get_inst_len(const char *file) {
  struct stat st;
  do {
    if(stat(file, &st) < 0) {
      perror("stat");
      return -1;
    }
  } while(errno == EINTR);
  return st.st_size / INST_LEN;
}

int input(FILE *inst_file, inst_t *inst, int noi) {
  int x;
  int i;
  int res;
  for(i=0; i<noi; i++) {
    res = fread(&x, 2, 1, inst_file);
    if(res < 0) {
      return 1;
    }
    inst[i] = 0xFFFF & x;
  }
  return 0;
}

int initialize(const char *inst_file_path, int *noi, inst_t **inst, data_t **mem) {
  *noi = get_inst_len(inst_file_path);
  if(*noi < 0) {
    return 1;
  }
  FILE *inst_file = fopen(inst_file_path, "r");
  if(!inst_file) {
    perror("input file");
    return 1;
  }
  *inst = malloc(sizeof(inst_t)*(*noi));
  if(input(inst_file, *inst, *noi)) {
    free(*inst);
    return 1;
  }
  fclose(inst_file);

  *mem = malloc(sizeof(data_t) * SIZE_OF_SRAM);
  return 0;
}

void show_instructions(inst_t *inst, int noi) {
  int i;
  for(i=0; i<noi; i++) {
    fprintf(stderr, "%04X\n", inst[i]);
  }
}

void show_registers(data_t *reg) {
  int i;
  for(i=0; i<NUM_OF_REGISTER; i++) {
    fprintf(stderr, "r%2d: %11d = %08X = %f\n", i, reg[i].i, reg[i].i, reg[i].f);
  }
}

int main(int argc, char **argv) {
  if(argc < 2) {
    fprintf(stderr, "usage: zsim <filename>\n");
    return 1;
  }
  data_t reg[NUM_OF_REGISTER];
  reg[0].i = 0;
  data_t *mem;
  inst_t *inst;
  int noi;
  if(initialize(argv[1], &noi, &inst, &mem)) {
    return 1;
  }

  show_instructions(inst, noi);

  mem[0].i = 0x12345678;
  run(reg, mem, inst, noi);

  show_registers(reg);

  free(inst);
  free(mem);
  return 0;
}
