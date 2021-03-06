/*
 * Copyright (C) 2011-2012 Canonical
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
#include <time.h>

#define MAX_TEST_RUNS		(128)

#define STATE_TEST_BEGIN	(0x0000001)
#define STATE_TEST_RUN_BEGIN	(0x0000002)

#define DATA_STATS_INTEGRAL		(0)
#define DATA_STATS_DURATION		(1)
#define DATA_STATS_AVERAGE_CURRENT	(2)
#define DATA_STATS_STD_DEV		(3)
#define DATA_STATS_MAX			(4)

#define OPTS_EXTRACT_RESULTS	(0x0000001)
#define OPTS_TABBED_COLUMNS	(0x0000002)
#define OPTS_STATS_ALL_SAMPLES	(0x0000004)
#define OPTS_TAGGED_OUTPUT	(0x0000008)
#define OPTS_STATS_SUMMARY	(0x0000010)
#define OPTS_STATS_PER_TEST	(0x0000020)
#define OPTS_DEFAULT		(0x0000000)

/* Single point of data, optionally a tag */
typedef struct point_t {
	struct point_t *next;
	double x;
	double y;
} point_t;

typedef struct {
	/* Data set min/max */
	double x_min;
	double x_max;
	double y_min;
	double y_max;

	point_t *head;		/* Point data list head */
	point_t *tail;		/* Point data list tail */

	double stats[DATA_STATS_MAX];

	int samples;		/* Number of samples */
} data_t;

static int opts = OPTS_DEFAULT;

double scale_by = 1.0;

static inline double parse_timestamp(const char *buffer)
{
	struct tm tm;
	double seconds;

	/* Time stamp in format: 2011-12-02T01:03:41.720551 */
	sscanf(buffer, "%d-%d-%d%*c%d:%d:%lf",
		&tm.tm_year, &tm.tm_mon, &tm.tm_mday,
		&tm.tm_hour, &tm.tm_min, &seconds);

	tm.tm_sec = (int)seconds;

	return seconds - tm.tm_sec + (unsigned int)mktime(&tm);
}

static void data_append_point(data_t *data, point_t *p)
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

static void data_free(data_t *data, const int n)
{
	int i;

	for (i = 0; i < n; i++) {
		point_t *p = data[i].head;

		while (p) {
			point_t *p_next = p->next;
			free(p);
			p = p_next;
		}
	}
}

static void calc_average_stddev(const data_t *data, const int n,
	double *average, double *stddev)
{
	int i;
	int j;
	double total;

	for (j = 0; j < DATA_STATS_MAX; j++) {
		total = 0.0;
		for (i = 0; i < n; i++)
			total += data[i].stats[j];
		average[j] = total / (double)n;

		total = 0.0;
		for (i = 0; i < n; i++) {
			double diff = (data[i].stats[j]) - average[j];
			diff = diff * diff;
			total += diff;
		}
		stddev[j] = sqrt(total / (double)n);
	}
}

static void data_analyse(FILE *fp, data_t *data, const int n)
{
	int i;
	double average[DATA_STATS_MAX];
	double stddev[DATA_STATS_MAX];
	double total;
	int    samples;

	if (!(opts & OPTS_TAGGED_OUTPUT)  &&
	    (opts & (OPTS_STATS_PER_TEST | OPTS_STATS_SUMMARY))) {
		if (opts & OPTS_TABBED_COLUMNS) {
			fprintf(fp, "\tIntegral\tDuration\tAverage\tStd.Dev\n");
			fprintf(fp, "\t\t(Secs)\t(mA)\t(mA)\n");
		} else {
			fprintf(fp, "                Integral  Duration   Average   Std.Dev.\n");
			fprintf(fp, "                           (Secs)     (mA)       (mA)\n");
		}
	}

	for (i = 0; i < n; i++) {
		point_t *p = data[i].head;
		data[i].stats[DATA_STATS_INTEGRAL] = 0.0;

		while (p) {
			if (p->next) {
				double dt = p->next->x - p->x;
				double y  = ((p->y + p->next->y) / 2.0);
				data[i].stats[DATA_STATS_INTEGRAL] += (y * dt);
			}
			p = p->next;
		}

		data[i].stats[DATA_STATS_DURATION] = data[i].x_max - data[i].x_min;
		data[i].stats[DATA_STATS_AVERAGE_CURRENT] = 
			data[i].stats[DATA_STATS_INTEGRAL] /
			data[i].stats[DATA_STATS_DURATION];

		p = data[i].head;
		total = 0.0;
		samples = 0;
		while (p) {
			if (p->next) {
				double y  = ((p->y + p->next->y) / 2.0);
				double diff = y - data[i].stats[DATA_STATS_AVERAGE_CURRENT];
				diff = diff * diff;
				total += diff;
				samples++;
			}
			p = p->next;
		}
		data[i].stats[DATA_STATS_STD_DEV] = sqrt(total / (double)samples);

		if (opts & OPTS_STATS_PER_TEST) {
			if (opts & OPTS_TAGGED_OUTPUT) {
				fprintf(fp, "info:test_iteration:%d\n", i + 1);
				fprintf(fp, "metric:test_duration_seconds_average:%f\n",
					data[i].stats[DATA_STATS_DURATION]);
				fprintf(fp, "metric:current_drawn_mA_average:%f\n",
					1000.0 * data[i].stats[DATA_STATS_AVERAGE_CURRENT]);
				fprintf(fp, "metric:current_drawn_mA_stddev:%f\n",
					1000.0 * data[i].stats[DATA_STATS_STD_DEV]);
			} else {
				fprintf(fp,
					opts & OPTS_TABBED_COLUMNS ?
					"Test run %2d\t%8.4f\t%7.3f\t%8.4f\n\t%8.4f\n" :
					"Test run %2d     %8.4f    %7.3f  %8.4f  %8.4f\n",
					i + 1,
					data[i].stats[DATA_STATS_INTEGRAL],
					data[i].stats[DATA_STATS_DURATION],
					1000.0 * data[i].stats[DATA_STATS_AVERAGE_CURRENT],
					1000.0 * data[i].stats[DATA_STATS_STD_DEV]);
			}
		}
	}

	if (opts & OPTS_STATS_SUMMARY) {
		/* Dump out stats from all the runs */
		calc_average_stddev(data, n, average, stddev);

		if (opts & OPTS_TAGGED_OUTPUT) {
			fprintf(fp, "info:total_number_of_tests:%d\n", n);
			fprintf(fp, "metric:test_duration_seconds_average:%f\n",
				average[DATA_STATS_DURATION]);
			fprintf(fp, "metric:test_duration_seconds_stddev:%f\n",
				stddev[DATA_STATS_DURATION]);
			fprintf(fp, "metric:current_drawn_mA_average:%f\n",
				average[DATA_STATS_AVERAGE_CURRENT] * 1000.0);
			fprintf(fp, "metric:current_drawn_mA_stddev:%f\n",
				stddev[DATA_STATS_AVERAGE_CURRENT] * 1000.0);
		} else {
			if (! (opts & OPTS_TABBED_COLUMNS))
				fprintf(fp, "-------         --------    -------  --------\n");
			fprintf(fp, opts & OPTS_TABBED_COLUMNS ?
				"Average\t%8.4f\t%7.3f\t%8.4f\n" :
				"Average         %8.4f    %7.3f  %8.4f\n",
				average[DATA_STATS_INTEGRAL],
				average[DATA_STATS_DURATION],
				1000.0 * average[DATA_STATS_AVERAGE_CURRENT]);
			fprintf(fp, opts & OPTS_TABBED_COLUMNS ?
				"Std.Dev.\t%8.4f\t%7.3f\t%8.4f\n" :
				"Std.Dev.        %8.4f    %7.3f  %8.4f\n",
				stddev[DATA_STATS_INTEGRAL],
				stddev[DATA_STATS_DURATION],
				1000.0 * stddev[DATA_STATS_AVERAGE_CURRENT]);
			if (!(opts & OPTS_TABBED_COLUMNS))
				fprintf(fp, "-------         --------    -------  --------");
	
			fprintf(fp, "\n\n");
		}
	}
}

static int test_run_begin(int *state, int *index, data_t *data)
{
	int i = (*index) + 1;

	if (i >= MAX_TEST_RUNS) {
		fprintf(stderr, "Too many test runs, maximum allowed %d\n", MAX_TEST_RUNS);
		return -1;
	}
	*index = i;

	*state |= STATE_TEST_RUN_BEGIN;
	data = &data[i];

	memset(data, 0, sizeof(data_t));
	data->head = NULL;
	data->tail = NULL;
	data->x_min = 1E6;
	data->x_max = -1E6;
	data->y_min = 1E6;
	data->y_max = -1E6;

	return 0;
}

static inline void test_run_end(int *state)
{
	*state &= ~STATE_TEST_RUN_BEGIN;
}

static int data_parse(const char *filename)
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

	double start_secs = -1.0;

	if ((fp = fopen(filename, "r")) == NULL)
		return -1;

	hostname[0] = '\0';
	kernel[0] = '\0';
	test[0] = '\0';

	while (fgets(buffer, sizeof(buffer), fp) != NULL) {
		double sec;
		point_t *p;

		buffer[strlen(buffer)-1] = '\0';

		sec = parse_timestamp(buffer);
		if (start_secs < 0.0)
			start_secs = sec;
		sec = sec - start_secs;

		if (strstr(buffer+27, "TAG:")) {
			char *ptr = buffer+32;
			char *s;

			if ((s = strstr(ptr, "TEST_CLIENT")) != NULL) {
				char buf[64];
				if (!(opts & OPTS_EXTRACT_RESULTS)) {
					if (opts & OPTS_TAGGED_OUTPUT)
						printf("info:client:%s\n", s + 12);
					else
						printf("Client: %s\n",s + 12);
				}
				sscanf(s + 12, "%s %s %s", hostname, kernel, buf);
				if (strncmp(buf, "x86_64", 6) == 0)
					arch = "amd64";
				else if (strncmp(buf, "i", 1) == 0)
					arch = "i386";
				else
					arch = "unknown";
			}

			if ((s = strstr(ptr, "TEST_BEGIN")) != NULL) {
				if (!(opts & OPTS_EXTRACT_RESULTS)) {
					if (opts & OPTS_TAGGED_OUTPUT)
						printf("info:test-name:%s\n", ptr + 11);
					else
						printf("Test:   %s\n", ptr + 11);
				}
				sscanf(ptr + 11, "%s", test);
				state |= STATE_TEST_BEGIN;
			}

			if (strstr(ptr, "TEST_END")) {
				state &= ~STATE_TEST_BEGIN;
				if (opts & OPTS_EXTRACT_RESULTS) {
					FILE *output;
					char name[PATH_MAX];
					snprintf(name, sizeof(name), "%s-%s-%s-%s.txt",
						hostname, kernel, test, arch);
					if ((output = fopen(name, "w"))) {
						fprintf(output, "%s %s (%s), %s\n\n",
							hostname, kernel, arch, test);
						data_analyse(output, data, index+1);
						fclose(output);
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

			if (strstr(ptr, "TEST_RUN_BEGIN"))
				test_run_begin(&state, &index, data);

			if (strstr(ptr, "TEST_RUN_END"))
				test_run_end(&state);
		}

		if (strstr(buffer+27, "SAMPLE:")) {
			if ((opts & OPTS_STATS_ALL_SAMPLES) &&
			    (!(state & STATE_TEST_RUN_BEGIN))) {
				test_run_begin(&state, &index, data);
			}

			if (state & STATE_TEST_RUN_BEGIN) {
				if ((p = calloc(1, sizeof(point_t))) == NULL) {
					fprintf(stderr, 
						"Out of memory allocating a data point\n");
					break;
				}
				p->x = sec;
				sscanf(buffer + 34, "%lf", &p->y);

				p->y *= scale_by;

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

	if ((opts & OPTS_STATS_ALL_SAMPLES) && (state & STATE_TEST_RUN_BEGIN)) {
		test_run_end(&state);
		data_analyse(stdout, data, index+1);
	}

	return 0;
}

static void show_help(const char *name)
{
	fprintf(stderr, "Usage %s: [-h] [-x] [-t] [-a] [-T] [-S] [-s] [-X scale] logfile(s)\n", name);
	fprintf(stderr, "\t-h help\n");
	fprintf(stderr, "\t-x extract per-test results and each to a file.\n");
	fprintf(stderr, "\t-t dump tabbed columns for importing data into a spreadsheet.\n");
	fprintf(stderr, "\t-a run stats on all the log, ignore any TAGs.\n");
	fprintf(stderr, "\t-T Tagged output (for autotest integration).\n");
	fprintf(stderr, "\t-X Scale values by a given value.\n");
	fprintf(stderr, "\t-S Statistics summary for all test runs.\n");
}

int main(int argc, char *argv[])
{
	int i;
	int opt;

	while ((opt = getopt(argc, argv, "axhtsSTX:")) != -1) {
		switch (opt) {
		case 'h':
			show_help(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'x':
			opts |= OPTS_EXTRACT_RESULTS;
			break;
		case 't':
			opts |= OPTS_TABBED_COLUMNS;
			break;
		case 'a':
			opts |= OPTS_STATS_ALL_SAMPLES;
			break;
		case 'T':
			opts |= OPTS_TAGGED_OUTPUT;
			break;
		case 'X':
			scale_by = atof(optarg);
			break;
		case 's':
			opts |= OPTS_STATS_SUMMARY;
			break;
		case 'S':
			opts |= OPTS_STATS_PER_TEST;
			break;
		default:
			show_help(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (!(opts & (OPTS_STATS_SUMMARY | OPTS_STATS_PER_TEST)))
		opts |= (OPTS_STATS_SUMMARY | OPTS_STATS_PER_TEST);

	for (i = optind; i < argc; i++)
		data_parse(argv[i]);

	exit(EXIT_SUCCESS);
}
