#!/bin/bash

#
#  Need to configure this up to the IP address of your Fluke meter
#
if [ -z $METER_ADDR ]; then
	METER_ADDR=192.168.0.2
fi

#
#  Fluke meter port (default)
#
if [ -z $PORT ]; then
        PORT=3490
fi

#
#  Tag messages from client, receive on this port
#
if [ -z $TAGPORT ]; then
	TAGPORT=9999
fi

#
#  We need instrument lib's logmeter command to do the logging
#
if [ -z $LOGMETER ]; then
	# assume instrument lib is cloned under this tree
        LOGMETER=`pwd`/instrument-lib/logmeter
fi

#
#  Default 1 Hz sampling rate
#
if [ -Z $INTERVAL] ; then
	INTERVAL=1.0
fi

#
#  Number of samples
#
SAMPLES=10000000

#
#  Log file
#
LOG=samples.log
if [ $# -eq 1 ]; then
	LOG=$1
fi

#
#  No intstrument-lib? Go and clone it
#
if [ ! -d instrument-lib ]; then
	git clone git://kernel.ubuntu.com/ubuntu/instrument-lib
fi

rm -f $LOG
$LOGMETER --addr=$METER_ADDR --port=$PORT --tagport=$TAGPORT --measure=hc --acdc=DC --interval=$INTERVAL --samples=$SAMPLES --out=$LOG

