#include <stdio.h>
#include "shift.c"

int main(void)
{
  const unsigned int init = 1;
  unsigned int v = init;
	int i = 0;
  while (i<816) {
    v = shift_lfsr(v);
		if (i%16==0){ printf("\n"); }
    putchar(((v & 0x8000) == 0) ? '0' : '1');
		i++;
  } 
}