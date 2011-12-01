#!/bin/bash

export SLEEP_DURATION=60
SETTLE_DURATION=10
TEST_ITERATIONS=5
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
if [ -z $ITERATIONS_PER_TEST ]; then
	ITERATIONS_PER_TEST=5
fi

if [ ! -d instrument-lib ]; then
        git clone git://kernel.ubuntu.com/sconklin/instrument-lib
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
				for K in {1..$TEST_ITERATIONS}
				do
					#
					# Flush dirty pages and drop caches
					#
					sync; sleep 1
					sync; sleep 1
					echo 1 > /proc/sys/vm/drop_caches
					echo 2 > /proc/sys/vm/drop_caches
					echo 3 > /proc/sys/vm/drop_caches
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
