#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  ARTI                                                       */
# /* Module:   do_showers.sh                                                 */
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

VERSION="v1r0" # First release, mar 20 abr 2021 11:00:00 CEST
VERSION="v1r1" # parallel analysis, jue 29 abr 2021 12:52:12 CEST

wdir="."
arti_path="${LAGO_ARTI}"
energy_bins=20
distance_bins=20
altitude=0
filter=0
time=0
prj=""
cmd="showers"
loc=0
parallel=0
N=4	   # number of simultaneous process for paralllel local processing

showhelp() {
  echo
  echo -e "$0 version $VERSION"
  echo
  echo -e "USAGE $0:"
  echo
  echo -e "  -w <working directory>    : Working directory, where the DAT files are located"
  echo -e "  -r <ARTI directory>       : ARTI installation directory, generally pointed by \$LAGO_ARTI (default)"
  echo -e "  -e <energy bins>          : Number of energy secondary bins (default: $energy_bins"
  echo -e "  -d <distance bins>        : Number of distance secondary bins (default: $distance_bins"
  echo -e "  -p <project base name>    : Base name for identification of S1 files (mandatory, don't use spaces)"
  echo -e "  -k <site altitude, in m>  : For curved mode (default), site altitude in m a.s.l. (mandatory)"
  echo -e "  -s <type>                 : Filter secondaries by type: 1: EM, 2: MU, 3: HD"
  echo -e "  -t <time>                 : Normalize energy distribution in particles/(m2 s bin), S=1 m2; <t> = flux time (s)."
  echo -e "  -j                        : Produce a batch file for parallel processing. Not compatible with local (-l)"
  echo -e "  -l                        : Enable parallel execution locally ($N procs). Not compatible with parallel (-j)"
  echo -e "  -?                        : Shows this help and exit."
  echo
}
echo
while getopts ':r:w:e:p:d:k:s:t:lj?' opt; do
  case $opt in
    r)
      arti_path=$OPTARG
      ;;
    w)
      wdir=$OPTARG
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
    t)
      time=$OPTARG
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
file=$wdir/DAT000703.bz2
if [ ! -f "$file" ]; then
  echo; echo -e "#  ERROR: DAT files not found in $wdir. Please check and try again"
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

if [ $altitude -eq 0 ]; then
  echo; echo -e "#  ERROR: Altitude was not provided. It is mandatory for automatic analysis (curved mode)"
  echo
  showhelp
  exit 1
fi

if [ "X$prj" == "X" ]; then
  echo; echo -e "#  ERROR: Project base name not provided."
  echo
  showhelp
  exit 1
fi

if [ $parallel -gt 0 -a $loc -gt 0 ]; then
  echo; echo -e "#  ERROR: Parallel and local modes are not compatible. Look for -j or -l options."
  echo
  showhelp
  exit 1
fi

# command
cmd+=" -a $energy_bins"
cmd+=" -d $distance_bins"
cmd+=" -c $altitude"

# WARNINGS

if [ $time -gt 0 ]; then
  echo; echo -e "#  WARNING: Will normalize the secondary flux, S=1 m2; t=$time"
  cmd+=" -n 1. $time"
fi

if [ $filter -gt 0 ]; then
  echo; echo -e "#  WARNING: Will filter by secondary type $filter (1: EM, 2: MU, 3: HD)"
  cmd+=" -s $filter"
fi

cmd+=" $prj"

pass=1
if [ "X$PWD" == "X$wdir" ]; then
	pass=0
else
	echo; echo -e "#  WARNING: Not running where DAT files are located. At the end will move all files to $wdir"
fi

## finally...
echo
echo -e "#  Path to ARTI directory        = $arti_path"
echo -e "#  Path to DAT files             = $wdir"
echo -e "#  Project base_name             = $prj"
echo -e "#  Energy bins                   = $energy_bins"
echo -e "#  Distance bins                 = $distance_bins"
echo -e "#  Altitude                      = $altitude"
echo -e "#  Filtering by type             = $filter"
echo -e "#  Normalize flux, S=1 m2; time  = $time"
echo -e "#  Parallel mode (local)         = $loc"
echo -e "#  Parallel mode (remote)        = $parallel"

# primaries
for i in $wdir/DAT??????.bz2; do
	j=$(echo $i | sed -e 's/.bz2//')
 	u=$(echo $j | sed -e 's/DAT//')
 	run="bzip2 -d -k $i; echo $j | ${arti_path}/analysis/lagocrkread | ${arti_path}/analysis/analysis -p ${u}; rm ${j}"
	echo $run >> $prj.run
done
nl=$(cat $prj.run | wc -l)
if [ $parallel -gt 0 ]; then
	# parallel mode, just produce the shower analysis file and exit
    echo "bzcat ${wdir}/*.sec.bz2 | ${arti_path}/analysis/${cmd}" > $prj.shw.run
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

# showers
run="bzcat ${wdir}/*.sec.bz2 | ${arti_path}/analysis/${cmd}"
eval ${run}
if [ $pass -gt 0 ]; then
	mv $PWD/$prj* $wdir/
fi
rm $prj.run
rm *.log
