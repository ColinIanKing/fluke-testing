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

BACKLIGHT_PATH=/sys/class/backlight/acpi_video0

#
# Default for tests in idle mode is to sleep for SLEEP_DURATION
#
export SLEEP_DURATION=10
#
# Default for tests is to wait SETTLE_DURATION before kicking
# of a new test. Seems to help for some reason.  Need to 
# find out why.
#
SETTLE_DURATION=20

#
# We need to pick up on_ac_power to fake a system running
# on battery for some of the pm power.d scripts to run
#
export PATH=`pwd`:$PATH

MACHINE_ID=`uname -r -m -n`

get_levels()
{	
	if [ -e $BACKLIGHT_PATH/max_brightness ]; then
		cat $BACKLIGHT_PATH/max_brightness
	else
		echo 0
	fi
}

set_level()
{
	if [ -e $BACKLIGHT_PATH/max_brightness ]; then
		echo $1 > $BACKLIGHT_PATH/brightness
	fi
}

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
	ITERATIONS_PER_TEST=5
fi

#
# We need instrument lib to send TAG messages back to the host
#
if [ ! -d instrument-lib ]; then
        git clone git://kernel.ubuntu.com/ubuntu/instrument-lib
fi

max=`get_levels`

$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $MACHINE_ID"

for L in $(seq 0 $max)
do
	echo Brightness Level $L of $max
	$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN Brightness Level $L"

	for K in $(seq $ITERATIONS_PER_TEST)
	do
		echo "SUBTEST: Brightness Level $L, $K of $ITERATIONS_PER_TEST"
		set_level $L
		#
		# Flush dirty pages and drop caches
		#
		sync; sleep 1
		sync; sleep 1
		(echo 1 | sudo tee /proc/sys/vm/drop_caches) > /dev/null
		(echo 2 | sudo tee /proc/sys/vm/drop_caches) > /dev/null
		(echo 3 | sudo tee /proc/sys/vm/drop_caches) > /dev/null
		sync; sleep 1
		#
		# Wait a little to settle
		#
		echo "Starting in ${SETTLE_DURATION} seconds.."
		sleep ${SETTLE_DURATION}
		#
		# Run the tests...
		#
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN Brightness Level $L"
		sleep ${SLEEP_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END Brightness Level $L"
	done
	$SENDTAG $LOG_HOST $TAGPORT "TEST_END Brightness Level $L"
done
#
# And signal test is quitting
#
$SENDTAG $LOG_HOST $TAGPORT "TEST_QUIT"
