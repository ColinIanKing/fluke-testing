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

DURATION=60
HERE=$(pwd)
STRESS_NG=${HERE}/stress-ng/stress-ng
POWERSTAT=${HERE}/powerstat/powerstat
TESTS=5

setup()
{
	if [ ! -d stress-ng ]; then
		sudo apt-get build-dep stress-ng --assume-yes
		git clone git://kernel.ubuntu.com/cking/stress-ng
		cd stress-ng
		git reset --hard V0.05.18
		make clean
		make -j $(nproc)
		cd ..
	fi

	if [ ! -d powerstat ]; then
		sudo apt-get build-dep powerstat --assume-yes
		git clone git://kernel.ubuntu.com/cking/powerstat
		cd powerstat
		#git reset --hard V0.05.18
		make clean
		make -j $(nproc)
		cd ..
	fi
}

run_test()
{
	for I in $(seq $TESTS)
	do
		echo "Test run #$I"
		($STRESS_NG -t ${DURATION} $1 --metrics-brief -Y yaml-$I.log &) &> /dev/null
		pid=$!
		sudo $POWERSTAT -RDgst 1 ${DURATION} > stat-$I.log
		wait $pid
	done

	rel=$(uname -r)
	echo "Release: $rel, Test: $1"
	heading=$(grep "Time" stat-1.log | cut -c10-)
	echo "$heading Bogos/S"
	for I in $(seq $TESTS)
	do
		bogos=$(grep bogo-ops-per-second-real-time yaml-$I.log | awk '{print $2}')
		if [ -z $bogos ]; then
			bogos="0.0"
		fi
		stats=$(grep "Average" stat-$I.log | cut -c10-)
		echo "$stats $bogos"
	done

	for I in $(seq $TESTS)
	do
		rm yaml-$I.log stat-$I.log
	done
}

setup

run_test "--cpu 0 --cpu-load 0"
run_test "--cpu 0 --cpu-load 1"
exit 0
run_test "--cpu 0 --cpu-load 25"
run_test "--cpu 0 --cpu-load 50"
run_test "--cpu 0 --cpu-load 75"
run_test "--cpu 0 --cpu-load 100"
run_test "--dentry 0"
run_test "--itimer 0"
run_test "--mmap 0"
run_test "--msg 0"
run_test "--shm 0"
run_test "--sock 0"
run_test "--udp 0"
run_test "--zlib 0"
run_test "--switch 0"
run_test "--fault 0"
run_test "--futex 0"
run_test "--hdd 0"
run_test "--vm 0"
