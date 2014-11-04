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

const char *inst_name[] = {
  "WRITE Rn            ",
  "READ Rn             ",
  "MOV #imm,Rn         ",
  "MOV.L @(disp*,PC),Rn",
  "MOV Rm,Rn           ",
  "MOV.L Rm,@Rn        ",
  "MOV.L @Rm,Rn        ",
  "STS PR,Rn           ",
  "ADD Rm,Rn           ",
  "ADD #imm,Rn         ",
  "CMP/EQ Rm,Rn        ",
  "CMP/GT Rm,Rn        ",
  "SUB Rm,Rn           ",
  "AND Rm,Rn           ",
  "NOT Rm,Rn           ",
  "OR Rm,Rn            ",
  "XOR Rm,Rn           ",
  "SHLD Rm,Rn          ",
  "BF label            ",
  "BT label            ",
  "BRA label           ",
  "JMP @Rn             ",
  "JSR @Rn             ",
  "RTS                 ",
  "FLDI0 FRn           ",
  "FLDI1 FRn           ",
  "FMOV FRm,FRn        ",
  "FMOV.S @Rm,FRn      ",
  "FMOV.S FRm,@Rn      ",
  "FADD FRm,FRn        ",
  "FCMP/EQ FRm,FRn     ",
  "FCMP/GT FRm,FRn     ",
  "FDIV FRm,FRn        ",
  "FMUL FRm,FRn        ",
  "FNEG FRn            ",
  "FSQRT FRn           ",
  "FSUB FRm,FRn        ",
  "LDS FRm,FPUL        ",
  "STS FPUL,Rn         ",
  "FLDS FRm,FPUL       ",
  "FSTS FPUL,FRn       ",
  "FTRC FRm,FPUL       ",
  "FLOAT FPUL,FRn      ",
};

void print_usage() {
  fprintf(stderr,
          "usage: zsim code [testfile] [options]\n"
          "  --help option for more information\n");
}

void print_options() {
  fprintf(stderr, "usage: zsim code [testfile] [options]\n");
  fprintf(stderr,
          "options:\n"
          "  --help    Display this information\n"
          "  -d        Show PCs and codes in every execution\n"
          "  -r        Show contents of all the registers in every execution\n"
          "  -m        Show addresses and values in every memory access\n"
          "  -w        Output in detail text form in WRITE instructions\n"
          "            (if not designated, output in binary)\n"
          "  -n        Use native operations in floating-point instructions\n"
          "  -l <n>    Stop execution in at most n instructions\n");
}

int set_test(const char *test_file_path, state_t *st) {
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
        st->t_gpr[n].valid = 1;
        st->t_gpr[n].v.i = v;
      } else {
        fprintf(stderr, "zsim: testfile format error:\n%s\n", buf);
        return 1;
      }
      break;
    case 'F':
      if(sscanf(buf, "FR%d %X", &n, &v) == 2) {
        st->t_fr[n].valid = 1;
        st->t_fr[n].v.i = v;
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

int set_option(int argc, char **argv, state_t *st) {
  int i, j;
  st->opt = 0;
  st->i_count = 0LL;
  st->i_limit = -1LL;
  for(i=0; i<I_SENTINEL; i++) {
    st->i_stat[i] = 0;
  }
  for(i=0; i<NUM_OF_GPR; i++) {
    st->t_gpr[i].valid = 0;
  }
  for(i=0; i<NUM_OF_FR; i++) {
    st->t_fr[i].valid = 0;
  }
  if(argc < 3) return 0;
  i = 2;
  if(argv[2][0] != '-') {
    if(set_test(argv[2], st)) return 1;
    i++;
  }
  for(; i<argc; i++) {
    if(argv[i][0] != '-') {
      fprintf(stderr, "zsim: too many arguments\n");
      print_usage();
      return 1;
    }
    int jbrk = 0;
    for(j=1; argv[i][j] && !jbrk; j++) {
      switch(argv[i][j]) {
      case 'd':
        st->opt |= 1 << OPTION_D;
        break;
      case 'm':
        st->opt |= 1 << OPTION_M;
        break;
      case 'w':
        st->opt |= 1 << OPTION_W;
        break;
      case 'n':
        st->opt |= 1 << OPTION_N;
        break;
      case 'r':
        st->opt |= 1 << OPTION_R;
        st->opt |= 1 << OPTION_D;
        break;
      case 'l':
        if(++i < argc) {
          if(sscanf(argv[i], "%lld", &st->i_limit) != 1) {
            fprintf(stderr, "zsim: option format error\n");
            print_usage();
            return 1;
          }
        } else {
          fprintf(stderr, "zsim: option format error\n");
          print_usage();
          return 1;
        }
        jbrk = 1;
        break;
      default:
        fprintf(stderr, "zsim: unknown option: -%c\n", argv[i][j]);
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
  fprintf(stderr, "total executed instructions: %lld\n", st->i_count);
  for(i=0; i<I_SENTINEL; i++) {
    fprintf(stderr, "%s       : %lld\n", inst_name[i], st->i_stat[i]);
  }
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

int verify(state_t *st) {
  int res = 0;
  int i;
  for(i=0; i<NUM_OF_GPR; i++) {
    if(st->t_gpr[i].valid && st->gpr[i].i != st->t_gpr[i].v.i) {
      fprintf(stderr, "test failed: R%d\n"
              "expected: %08X\n"
              "actual  : %08X\n", i, st->t_gpr[i].v.i, st->gpr[i].i);
      res = 1;
    }
  }
  for(i=0; i<NUM_OF_FR; i++) {
    if(st->t_fr[i].valid && st->fr[i].i != st->t_fr[i].v.i) {
      fprintf(stderr, "test failed: FR%d\n"
              "expected: %08X\n"
              "actual  : %08X\n", i, st->t_fr[i].v.i, st->fr[i].i);
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
    print_options();
    return 0;
  }
  state_t st;
  if(set_option(argc, argv, &st)) {
    return 1;
  }
  int noi;
  if(initialize(argv[1], &noi, &st)) {
    return 1;
  }

  run(&st, noi);

  show_status(&st);
  free(st.mem);
  return verify(&st);
}
