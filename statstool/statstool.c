/*
 * Copyright (C) 2011 Canonical
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <limits.h>
#include <sys/types.h>
#include <unistd.h>
#include <libgen.h>
#include <math.h>

#define MAX_TEST_RUNS		(16)

#define STATE_TEST_BEGIN	(0x0000001)
#define STATE_TEST_RUN_BEGIN	(0x0000002)

#define DATA_STATS_INTEGRAL	0
#define DATA_STATS_DURATION	1
#define DATA_STATS_AVERAGE	2
#define DATA_STATS_MAX		3

#define OPTS_EXTRACT_RESULTS	(0x0000001)

/* Single point of data, optionally a tag */
typedef struct point_t {
	struct point_t *next;
	float x;
	float y;
} point_t;

typedef struct {
	/* Data set min/max */
	float x_min;
	float x_max;
	float y_min;
	float y_max;

	point_t *head;		/* Point data list head */
	point_t *tail;		/* Point data list tail */
	
	float stats[DATA_STATS_MAX];

	int samples;		/* Number of samples */
} data_t;

static int opts;

void data_append_point(data_t *data, point_t *p)
{
	if (data->head == NULL) {
		data->head = p;
		data->tail = p;
	} else {
		data->tail->next = p;
		data->tail = p;
	}
	data->samples++;
}

point_t *data_next_point(point_t *p)
{
	return p->next;
}

void data_free(data_t *data, int n)
{
	int i;

	for (i=0; i<n; i++) {
		point_t *p = data[i].head;
		
		while (p) {
			point_t *p_next = p->next;
			free(p);
			p = p_next;
		}
	}
}

void calc_average_stddev(data_t *data, int n, float *average, float *stddev)
{
	int i;
	int j;
	float total;

	for (j=0; j<DATA_STATS_MAX; j++) {
		total = 0.0;
		for (i=0; i<n; i++)
			total += data[i].stats[j];
		average[j] = total / (float)n;
	
		total = 0.0;
		for (i=0; i<n; i++) {
			float diff = (data[i].stats[j]) - average[j];
			diff = diff * diff;
			total += diff;
		}
		stddev[j] = sqrt(total / (float)n);
	}
}

void data_analyse(FILE *fp, data_t *data, int n)
{
	int i;
	float average[DATA_STATS_MAX];
	float stddev[DATA_STATS_MAX];

	fprintf(fp, "                Integral  Duration   Average\n");
	fprintf(fp, "                           (Secs)     (mA)\n");

	for (i=0; i<n; i++) {
		point_t *p = data[i].head;
		data[i].stats[DATA_STATS_INTEGRAL] = 0.0;

		while (p) {
			if (p->next) {
				float dt = p->next->x - p->x;
				float y  = ((p->y + p->next->y) / 2.0);
				/* Midnight wrap */
				/*
				if (dt < 0)
					dt += (24.0 * 60.0 * 60.0);
				*/
				data[i].stats[DATA_STATS_INTEGRAL] += (y * dt);

			}
			p = p->next;
		}

		data[i].stats[DATA_STATS_DURATION] = data[i].x_max - data[i].x_min;
		data[i].stats[DATA_STATS_AVERAGE] = data[i].stats[DATA_STATS_INTEGRAL] / data[i].stats[DATA_STATS_DURATION];

		fprintf(fp, "Test run %2d     %8.4f    %7.3f  %8.4f\n",
			i + 1,
			data[i].stats[DATA_STATS_INTEGRAL],
			data[i].stats[DATA_STATS_DURATION],
			1000.0 * data[i].stats[DATA_STATS_AVERAGE]);
	}

	calc_average_stddev(data, n, average, stddev);
	fprintf(fp, "-------         --------    -------  --------\n");
	fprintf(fp, "Average         %8.4f    %7.3f  %8.4f\n",
			average[DATA_STATS_INTEGRAL],
			average[DATA_STATS_DURATION],
			1000.0 * average[DATA_STATS_AVERAGE]);
	fprintf(fp, "Std.Dev.        %8.4f    %7.3f  %8.4f\n",
			stddev[DATA_STATS_INTEGRAL],
			stddev[DATA_STATS_DURATION],
			1000.0 * stddev[DATA_STATS_AVERAGE]);
	fprintf(fp, "-------         --------    -------  --------\n\n");
}


int data_parse(char *filename)
{
	FILE *fp;
	char buffer[4096];
	data_t data[MAX_TEST_RUNS];
	int index = -1;
	int state = 0;
	char hostname[1024];
	char kernel[1024];
	char test[1024];
	char *arch;

	float start_secs = -1.0;

	if ((fp = fopen(filename, "r")) == NULL) 
		return -1;

	hostname[0] = '\0';
	kernel[0] = '\0';
	test[0] = '\0';

	while (fgets(buffer, sizeof(buffer), fp) != NULL) {
		float hrs;
		float min;
		float sec;
		point_t *p;

		buffer[strlen(buffer)-1] = '\0';

		sscanf(buffer + 11, "%f:%f:%f", &hrs, &min, &sec);

		sec = sec + (min * 60.0) + (hrs * 3600.0);
		if (start_secs < 0.0)
			start_secs = sec;

		sec = sec - start_secs;
		
		if (strstr(buffer+27, "TAG:")) {
			char *ptr = buffer+32;
			ptr = strstr(ptr, " ");
			if (ptr) {
				if (strstr(ptr, "TEST_CLIENT")) {
					char buf[64];
					if (!(opts & OPTS_EXTRACT_RESULTS))
						printf("Client: %s\n", ptr + 13);
					sscanf(ptr + 13, "%s %s %s", hostname, kernel, buf);
					if (strncmp(buf, "x86_64", 6) == 0)
						arch = "amd64";
					else if (strncmp(buf, "i", 1) == 0) 
						arch = "i386";
					else 
						arch = "unknown";
				}
				if (strstr(ptr, "TEST_BEGIN")) {
					if (!(opts & OPTS_EXTRACT_RESULTS))
						printf("Test:   %s\n", ptr + 12);
					sscanf(ptr + 12, "%s", test);
					state |= STATE_TEST_BEGIN;
				}
				if (strstr(ptr, "TEST_END")) {
					state &= ~STATE_TEST_BEGIN;
					if (opts & OPTS_EXTRACT_RESULTS) {
						FILE *fp;
						char name[PATH_MAX];
						snprintf(name, sizeof(name), "%s-%s-%s-%s.txt",
							hostname, kernel, test, arch);
						if ((fp = fopen(name, "w"))) {
							fprintf(fp, "%s %s (%s), %s\n\n", hostname, kernel, arch, test);
							data_analyse(fp, data, index+1);
							fclose(fp);
						} else {
							fprintf(stderr, "Cannot create %s\n", name);
						}
					} else {
						data_analyse(stdout, data, index+1);
					}
					data_free(data, index+1);
					hostname[0] = '\0';
					kernel[0] = '\0';
					test[0] = '\0';
					index = -1;
				}
				if (strstr(ptr, "TEST_RUN_BEGIN")) {
					state |= STATE_TEST_RUN_BEGIN;
	
					index++;
					if (index >= MAX_TEST_RUNS) {
						fprintf(stderr, "Too many test runs, maximum allowed %d\n", MAX_TEST_RUNS);
						break;
					}
					memset(&data[index], 0, sizeof(data_t));
					data[index].head = NULL;
					data[index].tail = NULL;
					data[index].x_min = 1E6;
					data[index].x_max = -1E6;
					data[index].y_min = 1E6;
					data[index].y_max = -1E6;
				}
				if (strstr(ptr, "TEST_RUN_END")) {
					state &= ~STATE_TEST_RUN_BEGIN;
				}
			}
		}

		if (strstr(buffer+27, "SAMPLE:")) {
			if (state & STATE_TEST_RUN_BEGIN) {
				if ((p = calloc(1, sizeof(point_t))) == NULL) {
					fprintf(stderr, "Out of memory allocating a data point\n");
					break;
				}
				p->x = sec;
				sscanf(buffer + 34, "%f", &p->y);

				if (sec < data[index].x_min)
					data[index].x_min = sec;
				if (sec > data[index].x_max)
					data[index].x_max = sec;

				if (p->y < data[index].y_min)
					data[index].y_min = p->y;
				if (p->y > data[index].y_max)
					data[index].y_max = p->y;
				data_append_point(&data[index], p);
			}
		}

	}
	fclose(fp);

	return 0;
}

void show_help(char *name)
{
	fprintf(stderr, "Usage %s: [-h] [-x] logfile(s)\n", name);
	fprintf(stderr, "\t-h help\n");
	fprintf(stderr, "\t-x extract per-test results and each to a file.\n");
}

int main(int argc, char *argv[])
{	
	int i;
	int opt;

	while ((opt = getopt(argc, argv, "xh")) != -1) {
		switch (opt) {
		case 'h':
			show_help(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'x':
			opts |= OPTS_EXTRACT_RESULTS;
			break;
		default:
			show_help(argv[0]);
			exit(EXIT_FAILURE);
		}
	}


	for (i=optind; i<argc; i++)
		data_parse(argv[i]);

	exit(EXIT_SUCCESS);
}
