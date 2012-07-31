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

if [ `cat /proc/cpuinfo | grep epb | wc -l` -lt 1 ]; then
	echo "CPU does not support Intel Energy Perf Bias MSR"
	exit 1
fi

#
# Build msr-test
#
rm -f msr-test
gcc msr-test.c -o msr-test

# Removing flavour from version i.e. generic or server.
full_version=`uname -r`
flavour_abi=${full_version#*-}
flavour=${flavour_abi#*-}
version=${full_version%-$flavour}
x86_energy_perf_policy="x86_energy_perf_policy_$version"

modprobe msr
if [ x`cat /proc/modules | grep msr | cut -d' ' -f1` != "xmsr" ]; then
	echo "module msr did not load"
	exit
fi

if ! which "$x86_energy_perf_policy" > /dev/null ; then
	echo "$x86_energy_perf_policy not found"
	echo "Now installing.."
	apt-get install linux-tools-$version
	if ! which "$x86_energy_perf_policy" > /dev/null ; then
		echo "Failed to install, aborting"
		exit
	fi
fi



#
# Default for tests in idle mode is to sleep for SLEEP_DURATION
#
export SLEEP_DURATION=60
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
	ITERATIONS_PER_TEST=5
fi

#
# We need instrument lib to send TAG messages back to the host
#
if [ ! -d instrument-lib ]; then
        git clone git://kernel.ubuntu.com/ubuntu/instrument-lib
fi

do_test()
{
	name="MSR_IA32_ENERGY_PERF_BIAS=$1"
	$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $MACHINE_ID"
	$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $name"
	echo $name
	for K in $(seq $ITERATIONS_PER_TEST)
	do
		echo "SUBTEST: $name, $K of $ITERATIONS_PER_TEST"
		#
		# Flush dirty pages and drop caches
		#
		$x86_energy_perf_policy -v $1
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
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		./msr-test ${SLEEP_DURATION} &
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN $name"
		sleep ${SLEEP_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END $name"
		echo "Ended"
		sleep 5
	done
	$SENDTAG $LOG_HOST $TAGPORT "TEST_END $1"
}

do_test "performance"
do_test "powersave"
do_test "normal"

#
# And signal test is quitting
#
$SENDTAG $LOG_HOST $TAGPORT "TEST_QUIT"
