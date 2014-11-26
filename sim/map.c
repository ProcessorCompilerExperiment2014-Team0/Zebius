#include <stdio.h>
#include <stdlib.h>
#include "map.h"

long long *lookup(map_t *map, int key) {
  node_t *node = map->n;
  node_t **p = &map->n;
  while(node) {
    if(key == node->k) {
      return &node->v;
    }
    if(key < node->k) {
      p = &node->l;
      node = node->l;
    } else {
      p = &node->r;
      node = node->r;
    }
  }
  node = (node_t*)malloc(sizeof(node_t));
  *p = node;
  node->k = key;
  node->v = INIT_VALUE;
  node->l = node->r = NULL;
  return &node->v;
}

void destruct_node(node_t *node) {
  if(node) {
    destruct_node(node->l);
    destruct_node(node->r);
    free(node);
  }
}

void destruct(map_t *map) {
  destruct_node(map->n);
}

void inspect_node(FILE *stream, node_t *node) {
  if(!node) return;
  inspect_node(stream, node->l);
  fprintf(stream, "%d\t%lld\n", node->k, node->v);
  inspect_node(stream, node->r);
}

void inspect(FILE *stream, map_t *map) {
  inspect_node(stream, map->n);
}
