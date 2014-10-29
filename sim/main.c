#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include "main.h"
#include "exec.h"

#define LINE_LEN 128

void print_usage() {
  fprintf(stderr, "usage: zsim code [testfile] [options]\n");
}

void print_options() {
  fprintf(stderr,
          "options:\n"
          "  --help    Display this information\n"
          "  -d        Show PCs and codes in every execution\n"
          "  -r        Show contents of all the registers in every execution\n"
          "  -m        Show addresses and values in every memory access\n"
          "  -w        Output in detail text form in WRITE instructions\n"
          "            (if not designated, output in binary)\n"
          "  -n        Use native operations in floating-point instructions\n");
}

int set_test(const char *test_file_path, option_t *opt) {
  FILE *test_file = fopen(test_file_path, "r");
  if(!test_file) {
    perror("test file");
    return 1;
  }
  char buf[LINE_LEN];
  int n, v;
  while(fgets(buf, LINE_LEN, test_file) != NULL) {
    switch(buf[0]) {
    case '\n':
      continue;
    case 'R':
      if(sscanf(buf, "R%d %X", &n, &v) == 2) {
        opt->gpr[n].valid = 1;
        opt->gpr[n].v.i = v;
      } else {
        fprintf(stderr, "zsim: testfile format error:\n%s\n", buf);
        return 1;
      }
      break;
    case 'F':
      if(sscanf(buf, "FR%d %X", &n, &v) == 2) {
        opt->fr[n].valid = 1;
        opt->fr[n].v.i = v;
      } else {
        fprintf(stderr, "zsim: testfile format error:\n%s\n", buf);
        return 1;
      }
      break;
    default:
      fprintf(stderr, "zsim: testfile format error:\n%s\n", buf);
      return 1;
    }
  }
  return 0;
}

int set_option(int argc, char **argv, option_t *opt) {
  opt->opt = 0;
  int i, j;
  for(i=0; i<NUM_OF_GPR; i++) {
    opt->gpr[i].valid = 0;
  }
  for(i=0; i<NUM_OF_FR; i++) {
    opt->fr[i].valid = 0;
  }
  if(argc < 3) return 0;
  i = 2;
  if(argv[2][0] != '-') {
    if(set_test(argv[2], opt)) return 1;
    i++;
  }
  for(; i<argc; i++) {
    if(argv[i][0] != '-') {
      fprintf(stderr, "zsim: too many arguments\n");
      print_usage();
      return 1;
    }
    for(j=1; argv[i][j]; j++) {
      switch(argv[i][j]) {
      case 'd':
        opt->opt |= 1 << OPTION_D;
        break;
      case 'm':
        opt->opt |= 1 << OPTION_M;
        break;
      case 'w':
        opt->opt |= 1 << OPTION_W;
        break;
      case 'n':
        opt->opt |= 1 << OPTION_N;
        break;
      case 'r':
        opt->opt |= 1 << OPTION_R;
        opt->opt |= 1 << OPTION_D;
        break;
      default:
        fprintf(stderr, "zsim: unknown option: -%c\n", argv[i][j]);
        print_usage();
        print_options();
        return 1;
      }
    }
  }
  return 0;
}

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

int initialize(const char *inst_file_path, int *noi, state_t *st) {
  *noi = get_inst_len(inst_file_path);
  if(*noi < 0) {
    return 1;
  }
  FILE *inst_file = fopen(inst_file_path, "rb");
  if(!inst_file) {
    perror("input file");
    return 1;
  }
  st->mem = malloc(SIZE_OF_SRAM);

  char *p = st->mem;
  int rest = *noi;
  int len;
  while(rest > 0) {
    len = fread(p, 2, rest, inst_file);
    p += len*2;
    rest -= len;
  }

  fclose(inst_file);
  st->pc.i = 0;
  st->sr.i = 0;
  st->pr.i = 0;
  st->fpul.i = 0;
  int i;
  for(i=0; i<NUM_OF_GPR; i++) {
    st->gpr[i].i = 0;
  }
  for(i=0; i<NUM_OF_FR; i++) {
    st->fr[i].i = 0;
  }

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
  fprintf(stderr, "PR   : %08X\n", st->pr.i);
  fprintf(stderr, "T    : %d\n", st->sr.i & 1);
  for(i=0; i<NUM_OF_GPR; i++) {
    fprintf(stderr, "R  %2d: %08X = %11d\n", i, st->gpr[i].i, st->gpr[i].i);
  }
  for(i=0; i<NUM_OF_FR; i++) {
    fprintf(stderr, "FR %2d: %08X = %f\n", i, st->fr[i].i, st->fr[i].f);
  }
  fprintf(stderr, "FPUL : %08X = %f\n", st->fpul.i, st->fpul.f);
}

void show_status_honly(state_t *st) {
  int i;
  fprintf(stderr, "PC   : %08X\n", st->pc.i);
  fprintf(stderr, "PR   : %08X\n", st->pr.i);
  fprintf(stderr, "T    : %d\n", st->sr.i & 1);
  for(i=0; i<NUM_OF_GPR; i++) {
    fprintf(stderr, "R  %2d: %08X\n", i, st->gpr[i].i);
  }
  for(i=0; i<NUM_OF_FR; i++) {
    fprintf(stderr, "FR %2d: %08X\n", i, st->fr[i].i);
  }
  fprintf(stderr, "FPUL : %08X\n\n", st->fpul.i);
}

int verify(state_t *st, option_t *opt) {
  int res = 0;
  int i;
  for(i=0; i<NUM_OF_GPR; i++) {
    if(opt->gpr[i].valid && st->gpr[i].i != opt->gpr[i].v.i) {
      fprintf(stderr, "test failed: R%d\n"
              "expected: %08X\n"
              "actual  : %08X\n", i, opt->gpr[i].v.i, st->gpr[i].i);
      res = 1;
    }
  }
  for(i=0; i<NUM_OF_FR; i++) {
    if(opt->fr[i].valid && st->fr[i].i != opt->fr[i].v.i) {
      fprintf(stderr, "test failed: FR%d\n"
              "expected: %08X\n"
              "actual  : %08X\n", i, opt->fr[i].v.i, st->fr[i].i);
      res = 1;
    }
  }
  return res;
}

int main(int argc, char **argv) {
  if(argc < 2) {
    fprintf(stderr, "zsim: no input files\n");
    print_usage();
    return 1;
  } else if(!strcmp(argv[1], "--help")) {
    print_usage();
    print_options();
    return 0;
  }
  option_t opt;
  if(set_option(argc, argv, &opt)) {
    return 1;
  }
  state_t st;
  int noi;
  if(initialize(argv[1], &noi, &st)) {
    return 1;
  }

  run(&st, noi, &opt);

  show_status(&st);
  free(st.mem);
  return verify(&st, &opt);
}
