#!/bin/bash -x

get_state()
{
	ethtool eth1 | grep Wake-on: | grep -v Supports | cut -d' ' -f2
}

if [[ $EUID -ne 0 ]]; then
	echo "This test needs to be run as root."
	exit 1
fi

eths=`ifconfig | grep eth | cut -d' ' -f1`

supported=0
for eth in $eths
do
	if [ x`ethtool eth1 | grep "Supports Wake-on:" | cut -d' ' -f3- | grep "g"` = "xg" ]; then
		support_g[$eth]=1
		supported=$((supported + 1))
	fi
done

if [ $supported -eq 0 ]; then
	echo "No eth device supports Wake-On-Lan mode g"
fi

#
#  Save current setting
#
for eth in $eths
do
	state[$eth]=`get_state $eth`
done

#
#  Enable
#
for eth in $eths
do
	if [ ${support_g[$eth]} -eq 1 ]; then
		ethtool -s $eth wol g
	fi
done
sleep 15

#
#  Restore original state
#
for eth in $eths
do
	if [ ${support_g[$eth]} -eq 1 ]; then
		ethtool -s $eth wol ${state[$eth]}
	fi
done
