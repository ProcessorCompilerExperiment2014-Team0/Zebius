#ifndef __MAP_H__
#define __MAP_H__

#include <stdio.h>

#define INIT_VALUE 0LL;

struct node_st {
  int k;
  long long v;
  struct node_st *l, *r;
};

typedef struct node_st node_t;

typedef struct {
  node_t *n;
} map_t;

long long *lookup(map_t*, int);
void inspect(FILE*, map_t*);
void destruct(map_t*);

#endif
