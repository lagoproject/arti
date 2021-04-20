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
        
VERSION="v1r0" # mar 20 abr 2021 11:00:00 CEST
wdir="."
arti_path="${LAGO_ARTI}"
energy_bins=20
distance_bins=20
altitude=0
filter=0
time=0
prj=""
cmd="showers"

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
  echo -e "  -?                        : Shows this help and exit."
  echo
}
echo
while getopts ':r:w:e:p:d:k:s:t:?' opt; do
  case $opt in
    r)
      arti_path=$OPTARG
	  echo -e "#  Path to ARTI directory        = $arti_path"
      ;;
    w)
      wdir=$OPTARG
      echo -e "#  Path to DAT files             = $wdir"
      ;;
    p)
      prj=$OPTARG
      echo -e "#  Project base_name             = $prj"
      ;;
    e)
      energy_bins=$OPTARG
      echo -e "#  Energy bins                   = $energy_bins"
      ;;
    d)
      distance_bins=$OPTARG
      echo -e "#  Distance bins                 = $distance_bins"
      ;;
    k)
      altitude=$OPTARG
      echo -e "#  Altitude                      = $altitude"
      ;;
    s)
      filter=$OPTARG
      echo -e "#  Filtering by type             = $filter"
      ;;
    t)
      time=$OPTARG
      echo -e "#  Normalize flux, S=1 m2; time  = $time"
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
## finally...
# echo $cmd
# read -n 1 -s -r -p "Ready. Press any key to continue"
# echo

# primaries and secondaries
for i in $wdir/DAT??????.bz2; do
  j=$(echo $i | sed -e 's/.bz2//')
 	u=$(echo $j | sed -e 's/DAT//')
 	bzip2 -d -k $i
 	echo $j | $arti_path/analysis/lagocrkread | $arti_path/analysis/analysis -p $u
 	rm $j
 	mv *.bz2 $wdir/
done

# showers
bzcat $wdir/*.sec.bz2 | $arti_path/analysis/${cmd} $prj
mv $prj* $wdir/