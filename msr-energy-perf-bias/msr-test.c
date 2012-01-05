#include <unistd.h>
#include <stdlib.h>
#include <stdbool.h>
#include <signal.h>
#include <stdio.h>

volatile bool keep_running = true;

void sighandler(int dummy)
{
	keep_running = false;
}

killcycles(void)
{
	double dummy = 0.000001;
        unsigned long long i = 0;

        while (i++ < 1000000) {
                dummy += ((double)random() / 1000000.0);
        }
}

pid_t consume(void)
{
	pid_t pid;
	useconds_t  us = 5000;

	signal(SIGUSR1, sighandler);

	pid = fork();
	switch (pid) {
	case 0:	
		while (keep_running) {
			usleep(us);
			killcycles();
			us += 2000;
			if (us > 100000)
				us = 5000;
		}
		exit(0);
	case -1:
		fprintf(stderr, "fork() failed\n");
		exit(1);
	default:
		break;
	}
	return pid;
}

int main(int argc, char **argv)
{
	pid_t pids[8];
	int i;
	int duration = 60;

	if (argc > 1)
		duration = atoi(argv[1]);

	for (i = 0; i<8; i++)
		pids[i] = consume();

	sleep(duration);
	for (i = 0; i<8; i++)
		kill(pids[i], SIGUSR1);

	exit(0);
}
