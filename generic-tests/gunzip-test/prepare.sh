#!/bin/bash
gcc random.c -o random
./random > random1.dat
gzip --best random1.dat
for i in `seq 2 50`
do
	cp random1.dat.gz random${i}.dat.gz
done
sync
