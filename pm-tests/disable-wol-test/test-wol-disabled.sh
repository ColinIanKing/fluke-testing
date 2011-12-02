#!/bin/bash

. run-test.sh

#
# WoL enable/disable only works if ethtool is installed 
#
which ethtool > /dev/null
if [ $? -eq 0 ]; then
	pm-powersave false
	run_test
fi
