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

#
# We need ethtool for the WoL tests
#
which ethtool > /dev/null
if [ $? -ne 0 ]; then
	apt-get install ethtool
fi

gconftool-2 --type bool --set /apps/gnome-power-manager/backlight/idle_dim_battery false

for I in *-test
do
	if [ -d $I ]; then
		echo "TEST: $I"
		pushd $I >& /dev/null
		for J in test*.sh
		do
			if [ -x $J ]; then
				$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $MACHINE_ID"
				$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $J"
				for K in $(seq $ITERATIONS_PER_TEST)
				do
					echo "SUBTEST: $J, $K of $ITERATIONS_PER_TEST"
					#
					# Flush dirty pages and drop caches
					#
					sync; sleep 1
					sync; sleep 1
					echo 1 | sudo tee /proc/sys/vm/drop_caches
					echo 2 | sudo tee /proc/sys/vm/drop_caches
					echo 3 | sudo tee /proc/sys/vm/drop_caches
					sync; sleep 1
					#
					# Wait a little to settle
					#
					sleep ${SETTLE_DURATION}
					#
					# Run the tests...
					#
					export SENDTAG_BEGIN="$SENDTAG $LOG_HOST $TAGPORT 'TEST_RUN_BEGIN $J'"
					export SENDTAG_END="$SENDTAG $LOG_HOST $TAGPORT 'TEST_RUN_END $J'"
					pushd `dirname $J` >& /dev/null
					bash `basename $J` &> /dev/null
					popd >& /dev/null
				done
				$SENDTAG $LOG_HOST $TAGPORT "TEST_END $J"
			fi
		done
		popd >& /dev/null
		echo " "
	fi
done
