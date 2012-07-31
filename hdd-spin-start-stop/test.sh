#!/bin/bash

#
# Copyright (C) 2011-2012 Canonical
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

which smartctl >& /dev/null
if [ $? -ne 0 ]; then
	sudo apt-get install smartmontools
fi

get_start_stop()
{
	sudo smartctl -A /dev/sda | grep "Start_Stop_Count" | awk '{print $10}'
}

#
# Need to export this to be able to run the pm power.d scripts
# outside of their normal context
#
export PM_FUNCTIONS=/usr/lib/pm-utils/pm-functions

#
# Default for tests in idle mode is to sleep for SLEEP_DURATION
#
export SLEEP_DURATION=1800
#
# Default for tests is to wait SETTLE_DURATION before kicking
# of a new test. Seems to help for some reason.  Need to 
# find out why.
#
SETTLE_DURATION=15

MACHINE_ID=`uname -r -m -n`

if [ -z $LOG_HOST ]; then
	LOG_HOST=lenovo.local
fi

if [ -z $TAGPORT ]; then
	TAGPORT=9999
fi

if [ -z $SENDTAG ]; then
	SENDTAG=`pwd`/instrument-lib/sendtag
fi

#
# Default to 5 iterations per test to get solid
# statistical data out of the tests
#
if [ -z $ITERATIONS_PER_TEST ]; then
	ITERATIONS_PER_TEST=2
fi

#
# We need instrument lib to send TAG messages back to the host
#
if [ ! -d instrument-lib ]; then
        git clone git://kernel.ubuntu.com/ubuntu/instrument-lib
fi

do_test()
{
	$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $MACHINE_ID"
	$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $1"
	echo $1
	for K in $(seq $ITERATIONS_PER_TEST)
	do
		echo "SUBTEST: $1, $K of $ITERATIONS_PER_TEST"
		#
		# Flush dirty pages and drop caches
		#
		sync; sleep 1
		sync; sleep 1
		(echo 1 | sudo tee /proc/sys/vm/drop_caches) > /dev/null
		(echo 2 | sudo tee /proc/sys/vm/drop_caches) > /dev/null
		(echo 3 | sudo tee /proc/sys/vm/drop_caches) > /dev/null
		sync; sleep 1
		n1=`get_start_stop`
		#
		# Wait a little to settle
		#
		echo "Starting in ${SETTLE_DURATION} seconds.."
		sleep ${SETTLE_DURATION}
		#
		# Run the tests...
		#
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN $1"
		sleep ${SLEEP_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END $1"
		n2=`get_start_stop`
		diff=$((n2-n1))
		$SENDTAG $LOG_HOST $TAGPORT "HDD $1: Start Stop Delta: $n2 $n1 $diff"
		echo "Ended"
	done
	$SENDTAG $LOG_HOST $TAGPORT "TEST_END $1"
}

sudo hdparm -B 127 -S 12 /dev/sda
do_test "hdparm -B 127 -S 12"

sudo hdparm -B 127 -S 24 /dev/sda
do_test "hdparm -B 127 -S 24"

sudo hdparm -B 127 -S 36 /dev/sda
do_test "hdparm -B 127 -S 36"

sudo hdparm -B 127 -S 48 /dev/sda
do_test "hdparm -B 127 -S 48"

sudo hdparm -B 127 -S 60 /dev/sda
do_test "hdparm -B 127 -S 60"

sudo hdparm -B 127 -S 120 /dev/sda
do_test "hdparm -B 127 -S 120"
