#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  ARTI                                                       */
# /* Module:   do_ iafe.sh                                                 */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernan Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Main script to automatize secondary flux calculations and  */
# /*           run simulations in Soleil IAFE cluster                     */
# /*                                                                      */
# /************************************************************************/
# /* 
#  
# Copyright 2013
# Hernán Asorey
# the LAGO Collaboration (CAB-CNEA), Argentina
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
# official policies, either expressed or implied, of the LAGO Collaboration.
# 
# */
# /************************************************************************/
# 
VERSION="v3r0"; # Tue Aug  6 15:43:52 COT 2013

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
  echo -e "  -w <working dir>               : Working directory, where bin files are located"
  echo -e "  -p <project name>              : Project name (suggested format: NAMEXX)"
  echo -e "  -t <flux time>                 : Flux time (in seconds) for simulations"
  echo -e "  -v <CORSIKA version>           : CORSIKA version"
  echo -e "  -h <HE Int Model (EPOS|QGSII)> : Define the high interaction model to be used"
  echo -e "  -u <user name>                 : User Name."
  echo -e "  -s <site>                      : Location (several options)"
  echo -e "  -y                             : Select volumetric detector mode (default=flat array)"
  echo -e "  -e                             : Enable CHERENKOV mode"
  echo -e "  -d                             : Enable DEBUG mode"
  echo -e "  -a                             : Enable high energy cuts for secondaries"
  echo -e "  -k <altitude, in cm>           : Fix altitude, even for predefined sites"
  echo -e "  -l <cluster user name>         : Enable OAR cluster compatibility, use \$USER"
  echo -e "  -?                             : Shows this help and exit."
  echo
}
cta=false
debug=false
highsec=false
cluster=false
sites=false
usr="HgAsorey";
vol=false
alt=false
altitude=0.

echo

while getopts ':w:k:p:t:v:u:h:s:l:?ayde' opt; do
  case $opt in
    w)
      wdir=$OPTARG
      echo -e "#  Working dir                   = $wdir"
      ;;
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
    e)
      cta=true
      echo -e "#  Cherenkov mode enabled for    = $site"
      ;;
    y)
      vol=true
      echo -e "#  Volumetric detector mode for  = $site"
      ;;
    l)
      clsname=$OPTARG
      cluster=true
      echo -e "#  Cluster mode enable for user  = $clsname"
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

# cores per node in OAR cluster
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

if [ "X$wdir" == "X" ]; then
  echo; echo -e "ERROR: You have to set the working directory (where corsika bin files are located)"
  showhelp
  exit 1;
fi

if [ "X$tim" == "X" ]; then
  tim=3600;
  echo -e "#  WARNING: Time was not provided. Using default time: $tim s"
fi


if [ "X$ver" == "X" ]; then
  ver="75600"
  echo -e "#  WARNING: CORSIKA version was not provided. Using default: $ver"
fi

if [ "X$hig" == "X" ]; then
  hig="QGSII"
  echo -e "#  WARNING: High energy interaction model was not provided. Using default: $hig"
fi

if $debug; then
  echo -e "#  WARNING: You are running in DEBUG mode."
fi

if $cta; then
  if $sites; then
    echo -e "#  WARNING: Cherenkov mode is enabled."
  else
    echo; echo -e "ERROR: You have to provide a site location in CHERENKOV mode"
    showhelp
    exit 1;
  fi
fi

if $cluster; then
  echo -e "#  ERROR: Please use do_sims for OAR CLUSTER mode."
  exit
fi

if $highsec; then
  echo -e "#  WARNING: High energy cuts for secondaries will be used."
fi

#codename=$(echo $wdir | sed -e 's/\/home\/h0\///' | sed -e 's/\///')
codename=$(echo $wdir | sed -e 's/\/home\/sdasso\/corsika\/pruebas_sep2016\/run_master\///' | sed -e 's/\///')

home=$wdir
direct=$home/$prj
basecrktools=${HOME}/arti/sims/

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
  
options=${options}"-f $basecrktools/spectra.dat"

$basecrktools/generate_spectra.pl ${options}

##############

a=$(echo $prj)

#all

st=0
en=5

if $cta; then
  #for i in $(seq $st $en); do
    #u=$(echo $wdir | sed -e "s/h0/h${i}/")
    u=$(echo $wdir)
    #scp $basecrktools/rain.pl h${i}:$u/
    cp $basecrktools/rain.pl $u/
    rain="./rain.pl -z"
  #done
else
  #for i in $(seq $st $en); do 
   # u=$(echo $wdir | sed -e "s/h0/h${i}/")
   # scp $basecrktools/rain.pl h${i}:$u/
   u=$(echo $wdir)
   cp $basecrktools/rain.pl $u/
    rain="./rain.pl "
  #done
fi

rain="$rain -i" # enable halley mode (not use PLOTSH and COMOUT)

if $sites; then
  rain="$rain -s ${site}"
fi

if $debug; then
  rain="$rain -d"
fi

if $highsec; then
  rain="$rain -a"
fi
rain="$rain -r $wdir -v $ver -h $hig -b $prj/\$i-*.run"

echo "#!/bin/bash
#Stuff-01!
#h=\$(hostname | awk '{if (\$1==\"frontend\") {print 0} else if (\$1==\"hernan\") {print 5} else {print \$0}}' | sed -e 's/halley0//')
t=19
for i in 001206 001608 000703 002412 001105; do
#  r=\"$(echo $rain | sed -e 's/h0/h\${h}/')\"
  r=\"$(echo $rain)\"
  if [ \$t -gt 3 ]; then t=19; fi
  nice -n \$t \${r}
  t=\$[t+1];
done
#for i in \$(seq $st $en); do
#  echo \"Updating script go-$prj-all-01.sh in halley0\${i}\"
#  ssh h\${i} chmod 644 /home/h\${i}/$codename/go-$prj-all-01.sh
chmod 644 $wdir/go-$prj-all-01.sh
#  ssh h\${i} mv /home/h\${i}/$codename/go-$prj-all-01.sh /home/h\${i}/$codename/go-$prj-all-01-halley0\${h}.run
#done
" > $wdir/go-$prj-all-01.sh
chmod 744 $wdir/go-$prj-all-01.sh

echo "#!/bin/bash
#Stuff-02!
#h=\$(hostname | awk '{if (\$1==\"frontend\") {print 0} else if (\$1==\"hernan\") {print 5} else {print \$0}}' | sed -e 's/halley0//')
t=19
for i in 002814 001407 002010 005626 000904 003216 002713; do
  #r=\"$(echo $rain | sed -e 's/h0/h\${h}/')\"
  r=\"$(echo $rain)\"
  if [ \$t -gt 4 ]; then t=19; fi
  nice -n \$t \${r}
  t=\$[t+1];
done
#for i in \$(seq $st $en); do
  echo \"Updating script go-$prj-all-02.sh in halley0\${i}\"
  #ssh h\${i} chmod 644 /home/h\${i}/$codename/go-$prj-all-02.sh
  chmod 644 $wdir/go-$prj-all-02.sh
  #ssh h\${i} mv /home/h\${i}/$codename/go-$prj-all-02.sh /home/h\${i}/$codename/go-$prj-all-02-halley0\${h}.run
#done
" > $wdir/go-$prj-all-02.sh
chmod 744 $wdir/go-$prj-all-02.sh

echo "#!/bin/bash
#Stuff-03!
#h=\$(hostname | awk '{if (\$1==\"frontend\") {print 0} else if (\$1==\"hernan\") {print 5} else {print \$0}}' | sed -e 's/halley0//')
t=19
for i in 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521; do
  #r=\"$(echo $rain | sed -e 's/h0/h\${h}/')\"
  r=\"$(echo $rain)\"
  if [ \$t -gt 4 ]; then t=19; fi
  nice -n \$t \${r}
  t=\$[t+1];
done
#for i in \$(seq $st $en); do
  #echo \"Updating script go-$prj-all-03.sh in halley0\${i}\"
  #ssh h\${i} chmod 644 /home/h\${i}/$codename/go-$prj-all-03.sh
  chmod 644 $wdir/go-$prj-all-03.sh
  #ssh h\${i} mv /home/h\${i}/$codename/go-$prj-all-03.sh /home/h\${i}/$codename/go-$prj-all-03-halley0\${h}.run
#done
" > $wdir/go-$prj-all-03.sh
chmod 744 $wdir/go-$prj-all-03.sh

#helium
b=$(basename $(ls -1 $wdir/$prj/000402-*) .run | sed -e "s/000402-//" | awk '{print $1*1.0}')
c=$(basename $(ls -1 $wdir/$prj/000402-*) .run | sed -e "s/000402-//" | awk -v p=${prcHe} '{print int($1/p+0.5)}')
printf -v k "%06d" $c

for i in $(seq 1 $prcHe); do
  u="0${i}0402"
  cat $wdir/$prj/000402-*.run | sed -e "s/000402/$u/" | sed -e "s/$b/$c/" > $wdir/$prj/$u-$k.run
done

echo "#!/bin/bash
#Helium
#h=\$(hostname | awk '{if (\$1==\"frontend\") {print 0} else if (\$1==\"hernan\") {print 5} else {print \$0}}' | sed -e 's/halley0//')

t=19
for j in \$(seq 1 $prcHe); do
  i="0\${j}0402"
  #r=\"$(echo $rain | sed -e 's/h0/h\${h}/')\"
  r=\"$(echo $rain)\"
  if [ \$t -gt 4 ]; then t=19; fi
  nice -n \$t \$r
  t=\$[t+1];
done
#for i in \$(seq $st $en); do
  #echo \"Updating script go-$prj-he.sh in halley0\${i}\"
  #ssh h\${i} chmod 644 /home/h\${i}/$codename/go-$prj-he.sh
  chmod 644 $wdir/go-$prj-he.sh
  #ssh h\${i} mv /home/h\${i}/$codename/go-$prj-he.sh /home/h\${i}/$codename/go-$prj-he-halley0\${h}.run
#done
" > $wdir/go-$prj-he.sh
chmod 744 $wdir/go-${prj}-he.sh
rm $wdir/$prj/000402-*.run

#protons
b=$(basename $(ls -1 $wdir/$prj/000014-*) .run | sed -e "s/000014-//" | awk '{print $1*1.0}')
c=$(basename $(ls -1 $wdir/$prj/000014-*) .run | sed -e "s/000014-//" | awk -v p=${prcPr} '{print int($1/p+0.5)}')
printf -v k "%06d" $c

ff=0
for i in $(seq 1 $multPr); do
  l=$[$i-1]
  for j in $(seq 1 $prcHe); do
    m=$[$l*$prcHe+$j]
    printf -v n "%02d" $m
    u=${n}'0014'
    cat $wdir/$prj/000014-*.run | sed -e "s/000014/$u/" | sed -e "s/$b/$c/" > $wdir/$prj/$u-$k.run
  done
  ii=$[$ff+1]
  ff=$[$ii+$prcHe-1]
echo "#!/bin/bash 
# Protons!
#h=\$(hostname | awk '{if (\$1==\"frontend\") {print 0} else if (\$1==\"hernan\") {print 5} else {print \$0}}' | sed -e 's/halley0//')
t=19
for j in \$(seq $ii $ff); do
  printf -v n "%02d" \$j
  i="\${n}0014"
  if [ \$t -gt 4 ]; then t=19; fi
  #r=\"$(echo $rain | sed -e 's/h0/h\${h}/')\"
  r=\"$(echo $rain)\"
  nice -n \$t \${r}
  t=\$[t+1];
done
#for k in \$(seq $st $en); do
  #echo \"Updating script go-$prj-pr-$i.sh in halley0\${k}\"
  #ssh h\${k} chmod 644 /home/h\${k}/$codename/go-$prj-pr-$i.sh
  chmod 644 $wdir/go-$prj-pr-$i.sh
  #ssh h\${k} mv /home/h\${k}/$codename/go-$prj-pr-$i.sh /home/h\${k}/$codename/go-$prj-pr-$i-halley0\${h}.run
#done
" > $wdir/go-${prj}-pr-$i.sh
done

rm $wdir/$prj/000014-*.run
for i in $(seq 1 $multPr); do
  chmod 744 $wdir/go-${prj}-pr-$i.sh
done

st=$((st+1))
#for i in $(seq $st $en); do
#  echo "Copying scripts to halley0${i}"
#  scp -r $wdir/${prj} h${i}:/home/h${i}/$codename/
#  scp -r $wdir/go-${prj}-*.sh h${i}:/home/h${i}/$codename/
#done
