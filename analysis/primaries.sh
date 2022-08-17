#!/bin/bash
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   primaries.sh                                               */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Generates the injected primary distribution per primary    */
# /************************************************************************/
# /*
# LICENSE BSD-3-Clause
# Copyright (c) 2015
# The LAGO Collaboration
# https://lagoproject.net
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# 
#    2. Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
# NO EVENT SHALL LAB DPR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of the LAGO Collaboration.
# 
# */
# /************************************************************************/
# 
VERSION="v1r9";

wdir=${PWD}
arti_path=${ARTI}
prj=""
prims=10

showhelp() {
	echo
	echo -e "$0 version $VERSION"
	echo
	echo -e "USAGE $0:"
	echo
	echo -e "  -w <working directory>    : Working directory, where the pri.bz2 iles are located"
	echo -e "  -r <ARTI directory>       : ARTI installation directory, generally pointed by \$ARTI (default)"
	echo -e "  -m <bins per decade>      : Produce files with the energy distribution of the primary flux per nuclei. Not compatible with parallel"
	echo -e "  -?                        : Shows this help and exit."
	echo
}
echo
while getopts 'w:r:p:m:?' opt; do
	case $opt in
		w)
 			wdir=$OPTARG
			;;
		r)
			arti_path=$OPTARG
			;;
		m)
			prims=$OPTARG
			;;
		?)
			showhelp
			exit 1;
			;;
	esac
done

##################################################
## YOU SHOULD NOT EDIT ANYTHING BELOW THIS LINE ##
##################################################

# ERRORS
file=$(ls -1 $wdir/*.pri.bz2 | head -1)
echo $file
if [ ! -f "$file" ]; then
	echo; echo -e "#  ERROR: pri.bz2 files not found in $wdir. Please check and try again"
	echo
	showhelp
	exit 1
fi

file=$arti_path/analysis/analysis
if [ ! -f "$file" ]; then
	echo; echo -e "#  ERROR: ARTI analysis executable files not found in $arti_path. Please check and try again"
	echo
	showhelp
	exit 1;
fi

# WARNINGS

pass=1
if [ "X$PWD" == "X$wdir" ]; then
	pass=0
else
	echo; echo -e "#  WARNING: Not running where pri.bz2 files are located. At the end will move all files to $wdir"
fi

## finally...
echo
echo -e "#  Path to ARTI directory        = $arti_path"
echo -e "#  Path to DAT files             = $wdir"
echo -e "#  Energy bins for primaries     = $prims"

# primaries histograms
ids=$(for i in *.pri.bz2; do j=${i/.pri.bz2/}; k=${j:2}; echo $k; done | sort | uniq)
echo ${ids}
echo
for i in $ids; do
	echo -n "${i} "
	bzcat ??${i}.pri.bz2 | grep -v "#" | awk '{print log($2)/log(10.)}' | sort -g |	awk -v bins=${prims} -v id=${i} 'BEGIN{n=0; mine=100000; maxe=-100000; bins = bins * 1.}{t[int($1*bins)]++; n++; if ($1 < mine) mine=$1; if ($1 > maxe) maxe=$1;}END{printf("# # # prt\n");printf("# # Primary energy histogram for %06d using %d bins per decade\n", id, bins);printf("# # Three column format is:\n# # energy_bin total_per_bin fraction_per_bin\n"); for (i in t) {print 10**(i/bins), t[i], t[i]*1./n; frc+=t[i]*1./n;} printf("# # Total primaries: %ld (%.2f) Emin=%.2f GeV; Emax=%.2f GeV\n", n, frc, 10**mine, 10**maxe);}' > "00${i}.prt"
done
echo
if [ $pass -gt 0 ]; then 
	mv *.prt $wdir
fi
