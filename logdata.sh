#!/bin/bash -x
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
        LOGMETER=/home/king/power-benchmarking/instrument-lib/logmeter
fi
if [ -Z $INTERVAL] ; then
	INTERVAL=1.0
fi
SAMPLES=10000000
LOG=samples.log

rm -f $LOG
$LOGMETER --addr=$METER_ADDR --port=$PORT --tagport=$TAGPORT --measure=hc --acdc=DC --interval=$INTERVAL --samples=$SAMPLES --out=$LOG

