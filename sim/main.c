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
  return st.st_size / 2;
}

int initialize(const char *inst_file_path, int *noi, char **mem) {
  *noi = get_inst_len(inst_file_path);
  if(*noi < 0) {
    return 1;
  }
  FILE *inst_file = fopen(inst_file_path, "rb");
  if(!inst_file) {
    perror("input file");
    return 1;
  }
  *mem = malloc(SIZE_OF_SRAM);

  char *p = *mem;
  int rest = *noi;
  int len;
  while(rest > 0) {
    len = fread(p, 2, rest, inst_file);
    p += len*2;
    rest -= len;
  }
  /* fprintf(stderr, "noi = %d\n", *noi); */
  /* fprintf(stderr, "initialize.res = %d\n", res); */

  fclose(inst_file);

  return 0;
}

void show_instructions(char *mem, int noi) {
  int i;
  for(i=0; i<noi; i++) {
    fprintf(stderr, "%02X%02X\n", 0xFF & mem[2*i+1], 0xFF & mem[2*i]);
  }
}

void show_status(state_t *st) {
  int i;
  fprintf(stderr, "PC   : %08X = %11d\n", st->pc.i, st->pc.i);
  for(i=0; i<NUM_OF_GPR; i++) {
    fprintf(stderr, "R  %2d: %08X = %11d\n", i, st->gpr[i].i, st->gpr[i].i);
  }
  for(i=0; i<NUM_OF_FR; i++) {
    fprintf(stderr, "FR %2d: %08X = %f\n", i, st->fr[i].i, st->fr[i].f);
  }
}

int main(int argc, char **argv) {
  if(argc < 2) {
    fprintf(stderr, "usage: zsim <filename>\n");
    return 1;
  }
  state_t st;
  int noi;
  if(initialize(argv[1], &noi, &st.mem)) {
    return 1;
  }

  show_instructions(st.mem, noi);

  run(&st, noi);

  show_status(&st);
  free(st.mem);
  return 0;
}
