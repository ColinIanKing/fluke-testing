#!/bin/bash
if [ -z $LOG_HOST ]; then
	LOG_HOST=lenovo.local
fi
if [ -z $TAGPORT ]; then
	TAGPORT=9999
	# currently this is to udp-relay
fi
if [ -z $SENDTAG ]; then
	SENDTAG=`pwd`/instrument-lib/sendtag
fi
if [ -z $ITERATIONS_PER_TEST ]; then
	ITERATIONS_PER_TEST=5
fi

if [ ! -d instrument-lib ]; then
        git clone git://kernel.ubuntu.com/ubuntu/instrument-lib
fi

info=`uname -r -m -n`

for I in *-test
do
	if [ -d $I ]; then
		echo "TEST: $I"
		pushd $I >& /dev/null
		for J in test*.sh
		do
			if [ -x $J ]; then
				$SENDTAG $LOG_HOST $TAGPORT "TEST_CLIENT $info"
				$SENDTAG $LOG_HOST $TAGPORT "TEST_BEGIN $J"
				K=0
				while [ $K -lt $ITERATIONS_PER_TEST ] 
				do
					if [ -x prepare.sh ]; then
						bash prepare.sh
					fi
					#sync; sleep 1
					#sync; sleep 1
					#echo 1 > /proc/sys/vm/drop_caches
					#echo 2 > /proc/sys/vm/drop_caches
					#echo 3 > /proc/sys/vm/drop_caches
					sync; sleep 1
					sleep 20

					$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_BEGIN $J"
					bash $J		
					$SENDTAG $LOG_HOST $TAGPORT "TEST_RUN_END $J"
					if [ -x tidy.sh ]; then
						bash tidy.sh
					fi
					K=$((K + 1))
				done
				$SENDTAG $LOG_HOST $TAGPORT "TEST_END $J"
			fi
		done
		popd >& /dev/null
		echo " "
	fi
done
