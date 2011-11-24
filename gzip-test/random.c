#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#define SAMPLES (1024 * 1024)

static inline unsigned long simple_random(void)
{
	static unsigned long  r = 1;
 
	r = (r * 32719 + 3) % 32749;

	return r;
}

int main(int argc, char **argv)
{
	static uint32_t buffer[SAMPLES];

	int i;
	int j;

	for (j=0; j < 8; j++) {
		for (i=0; i < SAMPLES; i++) {
			buffer[i] = simple_random();
		}
		write(1, buffer, sizeof(buffer));
	}
}
