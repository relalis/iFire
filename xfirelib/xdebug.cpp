#include "xdebug.h"

int printferr(char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int retval = vfprintf(stderr, fmt, ap);
  va_end(ap);
  return retval;
}


