#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   do_grid.sh                                                 */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Main script to automatize secondary flux calculations and  */
# /*           run simulations in LAGO-GRID                               */
# /*                                                                      */
# /************************************************************************/
# /* 
#  
# Copyright 2013
# Hernán Asorey
# Lab DPR (CAB-CNEA), Argentina
# Grupo Halley (UIS), Colombia
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
# official policies, either expressed or implied, of Lab DPR.
# 
# */
# /************************************************************************/
#
VERSION="v3r0";
# Tue Aug  6 15:43:52 COT 2013

# In this new version, rain.pl includes ctarain mode (-z) ctarain usage is now deprecated

# v3r0: Wed Oct  9 15:14:14 COT 2013
# changes in genEspectra.pl and showers.cc. Including geomagnetic effects
# v2r3; # Fri Jun 14 09:45:11 COT 2013
# This is the first version of do_halley.sh, added as part of v2r3 CrkTools release
# Implied modifications on genEspectra.pl, rain.pl and ctarain.pl

# v2r2 Fri Jun 14 09:45:11 COT 2013
# do_halley added
# in this version all stuff is separated in two different scripts

# v2r2 (Fri May 10 09:39:30 COT 2013)
# Major release of full crktools package
# -y option added for volumetric of flat detector flux calculations in genEspectra.pl
# v2r1 (Tue Apr 16 17:17:12 COT 2013)
# OAR server usage improved. Run up to $procs (4, should be divisor of 60) simultaneously in
# a single OAR node. Produces a script that produces 15 scrips to run 15*4=60 showers.

# v2r0
# OAR server compatibilities, and other new features. See showhelp()

# lot's of new features

showhelp() {
  echo
  echo -e "$0 version $VERSION"
  echo
  echo -e "USAGE $0:"
  echo
  echo -e "  -p <project name>              : Project name (suggested format: NAMEXX)"
  echo -e "  -t <flux time>                 : Flux time (in seconds) for simulations"
  echo -e "  -v <CORSIKA version>           : CORSIKA version"
  echo -e "  -h <HE Int Model (EPOS|QGSII)> : Define the high interaction model to be used"
  echo -e "  -u <user name>                 : User Name."
  echo -e "  -s <site>                      : Location (several options)"
  echo -e "  -y                             : Select volumetric detector mode (default=flat array)"
  echo -e "  -d                             : Enable DEBUG mode"
  echo -e "  -a                             : Enable high energy cuts for secondaries"
  echo -e "  -k <altitude, in cm>           : Fix altitude, even for predefined sites"
  echo -e "  -?                             : Shows this help and exit."
  echo
}
debug=false;
highsec=false;
sites=false;
usr="HgAsorey";
vol=false;
alt=false;
altitude=0.;

echo
wdir="${HOME}/grid"

while getopts ':k:p:t:v:u:h:s:?ayd' opt; do
  case $opt in
    p)
      prj=$OPTARG
      echo -e "#  Project name                  = $prj"
      ;;
    t)
      tim=$OPTARG
      echo -e "#  Flux time                     = $tim"
      ;;
    v)
      ver="$OPTARG"
      echo -e "#  CORSIKA version               = $ver"
      ;;
    u)
      usr="$OPTARG"
      echo -e "#  User name                     = $usr"
      ;;
    k)
      alt=true
      altitude=$OPTARG
      echo -e "#  Altitude                      = $altitude"
      ;;
    h)
      hig=$OPTARG
      echo -e "#  High Energy Interaction Model = $hig"
      ;;
    s)
      site=$OPTARG
      sites=true
      echo -e "#  Site location                 = $site"
      ;;
    y)
      vol=true
      echo -e "#  Volumetric detector mode for  = $site"
      ;;
    a)
      highsec=true
      ;;
    d)
      debug=true
      ;;
    ?)
      showhelp
      exit 1;
      ;;
  esac
done

#helium -> Usually for 1 hour flux, 4 different procces is enough
prcHe=4

#protons -> we need at least 32 times helium, so multPr=8
multPr=8
prcPr=$[${prcHe}*${multPr}] # now prcPr=32

# Should be divisor of 60, since we are running 60 process: 32(protons)+4(helium)+24(single nuclei)=60
procs=4
shows=60
max=$[$shows/$procs]
shows=$[$shows-1]

##################################################
## YOU SHOULD NOT EDIT ANYTHING BELOW THIS LINE ##
##################################################

if [ "X$prj" == "X" ]; then
  echo; echo -e "ERROR: You have to provide a project name (suggested format: NAMEXX, where XX is a number between 0 and 99)"
  showhelp
  exit 1;
fi

if [ "X$tim" == "X" ]; then
  tim=3600
  echo -e "#  WARNING: Time was not provided. Using default time: $tim s"
fi

if [ "X$ver" == "X" ]; then
  ver="73500"
  echo -e "#  WARNING: CORSIKA version was not provided. Using default: $ver"
fi

if [ "X$hig" == "X" ]; then
  hig="QGSII"
  echo -e "#  WARNING: High energy interaction model was not provided. Using default: $hig"
fi

if $debug; then
  echo -e "#  WARNING: You are running in DEBUG mode."
fi

if $highsec; then
  echo -e "#  WARNING: High energy cuts for secondaries will be used."
fi

echo; echo -e "#  WARNING: I will create the directory $wdir/$prj where the grid files will be created."; echo

#codename=$(echo $wdir | sed -e 's/\/home\/h0\///' | sed -e 's/\///')
#home=$wdir
#direct=$home/$prj
basecrktools=${PWD}
if ! [ -f $basecrktools/genEspectra.dat ]; then
  echo
  echo -e "#  ERROR: genEspectra.dat not found."
  echo -e "#  ERROR: You should run this script from the sims base directory."
  showhelp
  exit 1
fi
##############
options="-w ${wdir} -t ${tim} -p ${prj} "
if $sites; then
  options=${options}"-s ${site} "
fi
options=${options}"-u ${usr} "
if $highsec; then
  options=${options}"-a "
fi
if $vol; then
  options=${options}"-y "
fi
if $alt; then
   options=${options}"-k $altitude "
fi
options=${options}"-f $basecrktools/genEspectra.dat" 
$basecrktools/genEspectra.pl ${options}
##############

a=$(echo $prj)
#all

rain="./rain.pl"
rain="$rain -i" # enable halley mode (not use PLOTSH and COMOUT)
rain="$rain -g" # enable grid mode

if $sites; then
  rain="$rain -s ${site}"
fi
if $debug; then
  rain="$rain -d"
fi
if $highsec; then
  rain="$rain -a"
fi
rain="$rain -r $wdir -v $ver -h $hig"
clear

t=0
for i in 001206 001608 000703 002412 001105 002814 001407 002010 005626 000904 003216 002713 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521; do
  t=$[t+1];
  echo "#  STATUS: Please wait, I'm processing input for DAT$i ($t/60)."
  $rain -b $wdir/$prj/$i-*.run
done

#helium
b=$(basename $(ls -1 $wdir/$prj/000402-*) .run | sed -e "s/000402-//" | awk '{print $1*1.0}')
c=$(basename $(ls -1 $wdir/$prj/000402-*) .run | sed -e "s/000402-//" | awk -v p=${prcHe} '{print int($1/p+0.5)}')
printf -v k "%06d" $c

for i in $(seq 1 $prcHe); do
  u="0${i}0402"
  cat $wdir/$prj/000402-*.run | sed -e "s/000402/$u/" | sed -e "s/$b/$c/" > $wdir/$prj/$u-$k.run
done
rm $wdir/$prj/000402-*.run

for j in $(seq 1 $prcHe); do
  t=$[t+1]
  i="0${j}0402"
  echo "#  STATUS: Please wait, I'm processing input for DAT$i ($t/60)."
  $rain -b $wdir/$prj/$i-*.run
done

b=$(basename $(ls -1 $wdir/$prj/000014-*) .run | sed -e "s/000014-//" | awk '{print $1*1.0}')
c=$(basename $(ls -1 $wdir/$prj/000014-*) .run | sed -e "s/000014-//" | awk -v p=${prcPr} '{print int($1/p+0.5)}')
printf -v k "%06d" $c

for i in $(seq 1 $prcPr); do
  printf -v n "%02d" $i
  u=${n}'0014'
  cat $wdir/$prj/000014-*.run | sed -e "s/000014/$u/" | sed -e "s/$b/$c/" > $wdir/$prj/$u-$k.run
done
rm $wdir/$prj/000014-*.run

for j in $(seq 1 $prcPr); do
  t=$[t+1];
  printf -v n "%02d" $j
  i=${n}'0014'
  echo "#  STATUS: Please wait, I'm processing input for DAT$i ($t/60)."
  $rain -b $wdir/$prj/$i-*.run
done

echo "#  STATUS: Done, $t/60 input processed. Compresing..."
mkdir ${basecrktools}/$prj
cp -v $wdir/$prj/DAT*input $prj/
tar cfvz $wdir/$prj/$prj-$tim-$usr.tar.gz $prj/*
rm -r ${basecrktools}/$prj
echo -e "#  STATUS: Done. Now upload the compressed file"
echo -e "#  STATUS: $wdir/$prj/$prj-$tim-$usr.tar.gz at"
echo -e "#  STATUS: https://science-gateway.chain-project.eu/run-corsika"
