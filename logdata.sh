#!/bin/bash
if [ -z $METER_ADDR ]; then
	METER_ADDR=FLUKE_8846A_1811019.local
	METER_ADDR=192.168.1.13
fi
if [ -z $PORT ]; then
        PORT=3490
fi
if [ -z $TAGPORT ]; then
	TAGPORT=3500
fi
if [ -z $LOGMETER ]; then
	# assume instrument lib is cloned under this tree
        LOGMETER=`pwd`/instrument-lib/logmeter
fi
if [ -Z $INTERVAL] ; then
	INTERVAL=1.0
fi
SAMPLES=10000000
LOG=samples.log

if [ $# -eq 1 ]; then
	LOG=$1
fi

if [ ! -d instrument-lib ]; then
	git clone git://kernel.ubuntu.com/sconklin/instrument-lib
fi

rm -f $LOG
$LOGMETER --addr=$METER_ADDR --port=$PORT --tagport=$TAGPORT --measure=hc --acdc=DC --interval=$INTERVAL --samples=$SAMPLES --out=$LOG

