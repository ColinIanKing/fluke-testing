#!/bin/bash
gcc random.c -o random
./random > random1.dat
gzip --best random1.dat
cp random1.dat.gz random2.dat.gz
cp random1.dat.gz random3.dat.gz
cp random1.dat.gz random4.dat.gz
cp random1.dat.gz random5.dat.gz
sync
