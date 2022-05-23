#!/bin/bash
# Parameters

#
# This scrip create a file .g4mac from table-base.g4mac, setting
# the proper Tsyganenkov parameters for a specific date, and then
# run MAGNETOCOSMICS. These former parameters are taken form
# wghour.d
# 


ini=441085
fin=441085

for i in $(seq $ini $fin);do

	cp table-base.g4mac tmptable.g4mac

	t=$(head -$i wghour.d | tail -1 | awk '{print $1"-d"$2"-h"$3}')

	Pdyn=$(head -$i wghour.d | tail -1 | awk '{print $8}')

	Dst=$(head -$i wghour.d | tail -1 | awk '{print $15}') 

	By=$(head -$i wghour.d | tail -1 | awk '{print $4}')

	Bz=$(head -$i wghour.d | tail -1 | awk '{print $5}')

	G1=$(head -$i wghour.d | tail -1 | awk '{print $9}')

	G2=$(head -$i wghour.d | tail -1 | awk '{print $10}')
	
	cat tmptable.g4mac | sed -e "s/SetPdyn [0-9].[0-9]/SetPdyn $Pdyn/; s/SetDst [0-9].[0-9]/SetDst $Dst/; s/SetImfBy [0-9].[0-9]/SetImfBy $By/; s/SetImfBz [0-9].[0-9]/SetImfBz $Bz/; s/SetG1 [0-9].[0-9]/SetG1 $G1/; s/SetG2 [0-9].[0-9]/SetG2 $G2/; s/panini.out/brc-table-$t.out/" > maketable-$t.g4mac

	STATIC_MAGNETOCOSMICS maketable-$t.g4mac
	
#	sleep 2
echo "Running: "$t
rm tmptable.g4mac
rm maketable-$t.g4mac
done
