#!/bin/bash

#
# Copyright (C) 2011 Canonical
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

get_i8042()
{
cat /proc/interrupts | awk 'BEGIN {n=0}
{ 	
	n = n + 1
	if (n == 1) {
		fields=NF
		next
	}

	if ($(fields+3) != "i8042")
		next
	if ($1 != "12:")
		next
	count=0
	for (i=2; i<=fields+1; i++) {
		count += $i
	}
	IRQ[substr($1,1,length($1)-1)] = count
}
END { 
	for (i in IRQ )
		if (IRQ[i] > 0)
			print IRQ[i]
}
' | sort
}


#
# Need to export this to be able to run the pm power.d scripts
# outside of their normal context
#
export PM_FUNCTIONS=/usr/lib/pm-utils/pm-functions

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

#
# We need to pick up on_ac_power to fake a system running
# on battery for some of the pm power.d scripts to run
#
export PATH=`pwd`:$PATH

#
# Settings of on_ac_power return
#
export AC_POWER_ON=0
export AC_POWER_OFF=1

MACHINE_ID=`uname -r -m -n`

if [ -z $LOG_HOST ]; then
	LOG_HOST=lenovo.local
fi

if [ -z $TAGPORT ]; then
	TAGPORT=9999
	#TAGPORT=1111
	# currently this is to udp-relay
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
	$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $MACHINE_ID"
	$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $1"
	echo $1
	for K in $(seq $ITERATIONS_PER_TEST)
	do
		echo "SUBTEST: mousepad, $K of $ITERATIONS_PER_TEST"
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
		n1=`get_i8042`
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN mousepad IRQs"
		sleep ${SLEEP_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END mousepad IRQs"
		n2=`get_i8042`
		diff=$((n2-n1))
		$SENDTAG $LOG_HOST $TAGPORT "IRQS $n2 $n1 $diff"
		echo "Ended"
	done
	$SENDTAG $LOG_HOST $TAGPORT "TEST_END $1"
}

do_test "Touchpad, no movement"
do_test "Touchpad, movement"
