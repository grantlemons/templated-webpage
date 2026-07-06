#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int32_t pygmentize_file(char *path, char *output_path) {
  char *command = calloc(sizeof(char), 100);
  sprintf(command, "pygmentize -f html -O style=solarized-light -o %s %s",
          output_path, path);
  int32_t res = system(command);
  free(command);

  return res;
}
