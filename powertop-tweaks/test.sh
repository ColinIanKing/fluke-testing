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

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

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
fi

if [ -z $SENDTAG ]; then
	SENDTAG=`pwd`/instrument-lib/sendtag
fi

#
# Default to 5 iterations per test to get solid
# statistical data out of the tests
#
if [ -z $ITERATIONS_PER_TEST ]; then
	ITERATIONS_PER_TEST=3
fi

#
# We need instrument lib to send TAG messages back to the host
#
if [ ! -d instrument-lib ]; then
        git clone git://kernel.ubuntu.com/ubuntu/instrument-lib
fi

#
# We also need the cmdline tweaked powertop from my PPA
#

set_good()
{
		powertop --good $1 >& /dev/null
}

set_bad()
{
		powertop --bad $1 >& /dev/null
}

get_all_good()
{
	powertop --show | grep "Good : "
}

get_all_bad()
{
	powertop --show | grep "Bad : "
}

set_all_bad()
{
	get_all_good | while read index
	do
		set_bad $index
	done

	echo "Cannot set the following options to bad:"
	get_all_good
}


set_all_bad

$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $MACHINE_ID"
while read index state description
do
	echo TEST: $description
	#
	#  Check if we can toggle this state
	#
	set_good $index
	if [ `get_all_good | grep "^${index} " | grep -c "Good :"` -ne 1 ]; then
		echo Ignoring, cannot set to Good: $description
	fi
	set_bad $index
	if [ `get_all_bad | grep "^${index} " | grep -c "Bad :"` -ne 1 ]; then
		echo Ignoring, cannot set to Bad: $description
	fi
	
	#
	#  Do the "Bad" Setting first
	#
	$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $description (Bad)"
	for K in $(seq $ITERATIONS_PER_TEST)
	do
		set_bad $index
		#
		# Wait a little to settle
		#
		echo "TEST_RUN_BEGIN $description (Bad) $K"
		sleep ${SETTLE_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN $description (Bad) $K"
		sleep ${SLEEP_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END $description (Bad) $K"
	done
	$SENDTAG $LOG_HOST $TAGPORT "TEST_END $description (Bad)"

	#
	#  Do the "Good" Setting next
	#
	$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $description (Good)"
	for K in $(seq $ITERATIONS_PER_TEST)
	do
		set_good $index
		#
		# Wait a little to settle
		#
		echo "TEST_RUN_BEGIN $description (Good) $K"
		sleep ${SETTLE_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN $description (Good) $K"
		sleep ${SLEEP_DURATION}
		$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END $description (Good) $K"
	done
	$SENDTAG $LOG_HOST $TAGPORT "TEST_END $description (Good)"
	$SENDTAG $LOG_HOST $TAGPORT "TEST_DELTA"
	#
	#  And set  back to Bad Setting
	#
	set_bad $index
done < <( get_all_bad)
