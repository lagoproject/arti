#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  ARTI                                                       */
# /* Module:   do_showers.sh                                              */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernanasorey@cnea.gob.ar                                   */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Script to automatize the analysis of simulated showers     */
# /*                                                                      */
# /************************************************************************/
# /* 
#  
#  
# Copyright 2021
# Hernán Asorey
# ITeDA (CNEA), Argentina
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
# 
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of Lab DPR.
# 
# */
# /************************************************************************/
# 

arti_path="${LAGO_ARTI}"
odir=""
wdir="${PWD}"
dirlw=0
energy_bins=20
distance_bins=20
altitude=0
filter=0
tim=0
prj=""
cmd="showers"
loc=0
parallel=0
prims=0
N=$(/usr/bin/nproc)   # number of simultaneous process for paralllel local processing
N=$((N / 2)) # number of simultaneous process for paralllel local processing
if [ $N -gt 8 ]; then
        N=8
fi
showhelp() {
	echo
	echo -e "$0 version $VERSION"
	echo
	echo -e "USAGE $0:"
	echo
	echo -e "  -o <origin directory>     : Origin dir, where the DAT files are located"
	echo -e "  -r <ARTI directory>       : ARTI installation directory, generally pointed by \$LAGO_ARTI (default)"
	echo -e "  -w <workding directory>   : Working dir, where the analysis will be done (default is current directory, ${wdir})"
	echo -e "  -e <energy bins>          : Number of energy secondary bins (default: $energy_bins)"
	echo -e "  -d <distance bins>        : Number of distance secondary bins (default: $distance_bins)"
	echo -e "  -p <project base name>    : Base name for identification of S1 files (don't use spaces). Default: odir basename"
	echo -e "  -k <site altitude, in m>  : For curved mode (default), site altitude in m a.s.l. (mandatory)"
	echo -e "  -s <type>                 : Filter secondaries by type: 1: EM, 2: MU, 3: HD"
	echo -e "  -t <time>                 : Normalize energy distribution in particles/(m2 s bin), S=1 m2; <t> = flux time (s)."
	echo -e "  -m <bins per decade>      : Produce files with the energy distribution of the primary flux per nuclei."
	echo -e "  -j                        : Produce a batch file for parallel processing. Not compatible with local (-l)"
	echo -e "  -l                        : Enable parallel execution locally ($N procs). Not compatible with parallel (-j)"
	echo -e "  -?                        : Shows this help and exit."
	echo
}
echo
while getopts ':r:w:o:e:p:d:k:s:t:m:lj?' opt; do
	case $opt in
		r)
			arti_path=${OPTARG%/}
			;;
		w)
			wdir=${OPTARG%/}
			;;
		o)
			odir=${OPTARG%/}
			;;
		p)
			prj=$OPTARG
			;;
		e)
 			energy_bins=$OPTARG
			;;
		d)
			distance_bins=$OPTARG
			;;
		k)
			altitude=$OPTARG
			;;
		s)
			filter=$OPTARG
			;;
		m)
			prims=$OPTARG
			;;
		t)
			tim=$OPTARG
			;;
		l)
			loc=1
			;;
		j)
			parallel=1
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

# is ARTI installed? 
file=$arti_path/analysis/analysis
if [ ! -f "$file" ]; then
	echo; echo -e "#  ERROR: ARTI analysis executable files not found in $arti_path. Please check and try again"
	echo
	showhelp
	exit 1;
fi

# are the DAT files in the data directory?
file=$(ls -1 $odir/DAT??????.bz2 | wc -l)
if [ ! $file -gt 0 ]; then
	echo; echo -e "#  ERROR: DAT files not found in $odir. Please check and try again"
	echo
	showhelp
	exit 1
fi

# is working really local? for now just check for /mnt 
if [[ $wdir == *"/mnt/"* ]]; then 
	echo; echo -e "#  ERROR: working dir (-w) should be local, not mounted. Please check and try again"
	echo
	showhelp
	exit 1
fi

# is altitude is given? 
if [ ${altitude} -eq 0 ]; then
	echo; echo -e "#  ERROR: Altitude was not provided. It is mandatory for automatic analysis (curved mode)"
	echo
	showhelp
	exit 1
fi

# both parallels are not compatible?
if [ $parallel -gt 0 ] && [ $loc -gt 0 ]; then
	echo; echo -e "#	ERROR: Parallel and local modes are not compatible. Look for -j or -l options."
	echo
	showhelp
	exit 1
fi

# No errors found, so 
cmd+=" -a $energy_bins"
cmd+=" -d $distance_bins"
cmd+=" -c $altitude"

# WARNINGS

if [ $tim -gt 0 ]; then
	echo; echo -e "#  WARNING: Will normalize the secondary flux, S=1 m2; t=$tim"
	cmd+=" -n 1. $tim"
fi

if [ $filter -gt 0 ]; then
	echo; echo -e "#  WARNING: Will filter by secondary type $filter (1: EM, 2: MU, 3: HD)"
	cmd+=" -s $filter"
fi

if [ $prims -gt 0 ]; then
	echo; echo -e "#  WARNING: Will produce energy histograms of primaries with ${prims} per decade"
fi

if [ "X$prj" == "X" ]; then
	prj=$(basename $odir)
	prj=${prj/S0/S1}
	echo; echo -e "#  WARNING: Project base name not provided. Using $prj"
fi

cmd+=" $prj"

if [ "X$wdir" == "X$odir" ]; then
	echo; echo -e "#  WARNING: We are running where DAT files are located. Analysis results will be in the same directory."
	echo -e "#           $wdir"
	dirlw=1
fi

if [ $loc -gt 0 ]; then 
	if [ $N -gt $file ]; then
		echo; echo -e "#  WARNING: You don't have enough files to analyze in local parallel model (at least $N). Turning off parallel mode."
		loc=0
	fi
fi

## finally...
wdir=$wdir/$prj
mkdir $wdir
cd $wdir
echo
echo -e "#  Path to ARTI directory        = $arti_path"
echo -e "#  Path to DAT files             = $odir"
echo -e "#  Path to running directory     = $wdir"
echo -e "#  Project base_name             = $prj"
echo -e "#  Energy bins                   = $energy_bins"
echo -e "#  Distance bins                 = $distance_bins"
echo -e "#  Altitude                      = $altitude"
echo -e "#  Filtering by type             = $filter"
echo -e "#  Normalize flux, S=1 m2; time  = $tim"
echo -e "#  Energy bins for primaries     = $prims"
echo -en "#  Parallel mode (local)         = "
if [ $loc -gt 0 ]; then
	echo -e "Local - $N processes"
else
	echo -e "Remote"
fi

# primaries
for i in ${odir}/DAT??????.bz2; do
	j=$(basename $i .bz2)
 	u=${j/DAT/}
	if [ $dirlw -gt 0 ]; then 
		run="bzip2 -d -k $i; echo $j | ${arti_path}/analysis/lagocrkread | ${arti_path}/analysis/analysis -p ${u}; rm ${j}"
	else
		run="while ! cp -a $i $wdir/; do sleep 5; done; bzip2 -d $j.bz2; echo $j | ${arti_path}/analysis/lagocrkread | ${arti_path}/analysis/analysis -p ${u}; rm $wdir/${j}"
	fi	
	echo $run >> $prj.run
done
nl=$(cat $prj.run | wc -l)
if [ $parallel -gt 0 ]; then
	# parallel mode, just produce the shower analysis file and exit
	echo "bzcat ${wdir}/*.sec.bz2 | ${arti_path}/analysis/${cmd}" > $prj.shw.run
	if [ $prims -gt 0 ]; then 
		echo "primaries.sh -w ${wdir} -r ${arti_path} -m ${prims}" > $prj.pri.run
	fi
	exit 0
elif [ $loc -gt 0 ]; then
	# parallel and local
	while IFS= read -r line; do
		((nr++))
		((n=n%N)); ((n++==0)) && wait
		echo $nr/$nl
		eval ${line} &>> $nr.log &
	done < $prj.run
else
	# it's local and not parallel
	while IFS= read -r line; do 
		((nr++))
		echo $nr/$nl
		eval ${line} &>> $nr.log
	done < $prj.run
fi
if [ $loc -gt 0 ]; then
	echo "Wait for parallel execution termination..."
	while true; do
		f=$(find . -iname 'DAT??????' | wc -l)
		if [ $f -eq 0 ]; then
			break
		fi
	done
fi
echo "Shower analysis ..."
# showers
echo "Showers: $cmd"
bzcat ${wdir}/*.sec.bz2 | ${arti_path}/analysis/${cmd}

# primaries histograms
if [ $prims -gt 0 ]; then
	echo "Primary analysis ..."
	primaries.sh -w ${wdir} -r ${arti_path} -m ${prims}
fi

# final remarks
# rm $prj.run
rm *.log
