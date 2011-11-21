#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define	MEM_SIZE	(64*1024*1024)

main()
{
	int i;
	unsigned char *ptr;

	if ((ptr = malloc(MEM_SIZE)) == NULL) {
		fprintf(stderr, "Cannot allocate %d K\n", MEM_SIZE / (1024));
		exit(EXIT_FAILURE);
	}

	for (i=0; i<255; i++) {
		int j;
		unsigned char *p = ptr;

		memset(ptr, i, MEM_SIZE);
	
		for (j=0; j<MEM_SIZE; j++)
			*p++ = i;
	}

	free(ptr);
	exit(EXIT_SUCCESS);
}
