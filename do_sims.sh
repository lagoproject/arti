#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   do_sims.sh                                                */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Main script to automatize secondary flux calculations and  */
# /*           run simulations in OAR cluster and non-cluster modes       */
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

# v3r0: Wed Oct  9 15:14:14 COT 2013
# changes in genEspectra.pl and showers.cc. Including geomagnetic effects
# v2r4 Tue Aug  6 15:43:52 COT 2013
# rain.pl now includes ctarain functionality. ctarain.pl usage is now deprecated

# v2r3 Fri Jun 14 09:45:11 COT 2013
# New realease for do_halley.sh

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
  echo -e "  -t <flux time>                 : Flux time for simulations" 
  echo -e "  -v <CORSIKA version>           : CORSIKA version"
  echo -e "  -h <HE Int Model (EPOS|QGSII)> : Define the high interaction model to be used"
  echo -e "  -u <user name>                 : User Name."
  echo -e "  -s <site>                      : Location (several options)"
  echo -e "  -y                             : Select volumetric detector mode (default=flat array)"
  echo -e "  -e                             : Enable CHERENKOV mode"
  echo -e "  -d                             : Enable DEBUG mode"
  echo -e "  -a                             : Enable high energy cuts for secondaries"
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

echo

while getopts ':w:p:t:v:u:h:s:l:aycde?' opt; do
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
  echo -e "#  WARNING: Cluster mode is enabled."
  echo -e "#  WARNING: User name was overrided. Using cluster user name: $clsname ;)"
  usr=$clsname
fi

if $highsec; then
  echo -e "#  WARNING: High energy cuts for secondaries will be used."
fi

codename=$(echo $wdir | sed -e 's/\/data\/tep6\/asoreyh\///' | sed -e 's/\///')
home=$wdir
if $cluster; then
  home="/home/$usr"
fi
direct=$home/$prj

##############
options="-w ${wdir} -t ${tim} -p ${prj} "
if $sites; then
  options=${options}"-s ${site} "
fi
if $cluster; then
  options=${options}"-l ${usr} "
else
  options=${options}"-u ${usr} "
fi
if $highsec; then
  options=${options}"-a "
fi
if $vol; then
  options=${options}"-y "
fi
options=${options}"-f genEspectra.dat"

./genEspectra.pl $options
##############

a=$(echo $prj)

#all

# cluster mode
if $cluster; then
  if $cta; then
    cp $home/crktools/rain.pl $home
    rain="$home/rain.pl -z -l ${usr}"
  else
    cp $home/crktools/rain.pl $home
    rain="$home/rain.pl -l ${usr}"
  fi
  if $sites; then
    rain="$rain -s ${site}"
  fi
  if $debug; then
    rain="$rain -d"
  fi
  if $highsec; then
    rain="$rain -a"
  fi
  rain="$rain -r $wdir -v $ver -h $hig -b" 
  
  #helium
  b=$(basename $(ls -1 $direct/000402-*) .run | sed -e "s/000402-//" | awk '{print $1*1.0}')
  c=$(basename $(ls -1 $direct/000402-*) .run | sed -e "s/000402-//" | awk -v p=${prcHe} '{print int($1/p+0.5)}')
  printf -v k "%06d" $c
  
  for i in $(seq 1 $prcHe); do
    u="0${i}0402"
    cat $direct/000402-*.run | sed -e "s/000402/$u/" | sed -e "s/$b/$c/" > $direct/$u-$k.run
  done
  rm $direct/000402-*.run
  
  #protons
  b=$(basename $(ls -1 $direct/000014-*) .run | sed -e "s/000014-//" | awk '{print $1*1.0}')
  c=$(basename $(ls -1 $direct/000014-*) .run | sed -e "s/000014-//" | awk -v p=${prcPr} '{print int($1/p+0.5)}')
  printf -v k "%06d" $c
  
  ff=0
  for i in $(seq 1 $multPr); do
    l=$[$i-1]
    for j in $(seq 1 $prcHe); do
      m=$[$l*$prcHe+$j]
      printf -v n "%02d" $m
      u=${n}'0014'
      cat $direct/000014-*.run | sed -e "s/000014/$u/" | sed -e "s/$b/$c/" > $direct/$u-$k.run
    done
    ii=$[$ff+1]
    ff=$[$ii+$prcHe-1]
  done
  rm $direct/000014-*.run

  echo "#!/bin/bash
showers=(010014 020014 030014 040014 050014 060014 070014 080014 090014 100014 110014 120014 130014 140014 150014 160014 170014 180014 190014 200014 210014 220014 230014 240014 250014 260014 270014 280014 290014 300014 310014 320014 010402 020402 030402 040402 001206 001608 000703 002412 001105 002814 001407 002010 005626 000904 003216 002713 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521)
idp=17
for i in \$(seq 0 $procs $shows); do
  job=\`printf \"%02d\" \$i\`;
  network=\"quimica\"
  name=\"$home/go-$prj-\$job.sh\"
  echo \"#!/bin/bash\" > \$name
  echo \"echo \\\"Starting simulations for job \$job using script\" >> \$name
  echo \"\$name\\\"\" >> \$name
  echo \"date\" >> \$name
  echo \"echo\" >> \$name
  echo \"cp $home/rain.pl $wdir/\" >> \$name
  echo \"cd $wdir\" >> \$name
  echo \"$rain $direct/\${showers[\$i+0]}-*.run &\" >> \$name
  echo \"$rain $direct/\${showers[\$i+1]}-*.run &\" >> \$name
  echo \"$rain $direct/\${showers[\$i+2]}-*.run &\" >> \$name
  echo \"$rain $direct/\${showers[\$i+3]}-*.run  \" >> \$name
  echo \"chmod 644 \$name\" >> \$name
  echo \"mv \$name \$name.done\" >> \$name
  chmod 777 \$name
  # launching job 
  oarsub -l nodes=1,walltime=999:00:00 -p \"cluster='\$network'\" \$name
done
mv $home/go-$prj.sh $home/go-$prj.run
chmod 644 $home/go-$prj.run
" > $home/go-$prj.sh
  chmod 744 $home/go-$prj.sh
else
##### end cluster mode
  if $cta; then
    for i in $(seq 3 6); do 
      u=$(echo $wdir | sed -e "s/tep6/tep${i}/")
      cp /work/asoreyh/crktools/rain.pl $u/
      rain="./rain.pl -z"
    done
  else
    for i in $(seq 3 6); do 
      u=$(echo $wdir | sed -e "s/tep6/tep${i}/")
      cp /work/asoreyh/crktools/rain.pl $u/
      rain="./rain.pl "
    done
  fi
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
  #Stuff!
  h=\$(hostname | sed -e 's/cab//')
  d=\$(hostname | sed -e 's/cabtep//')
  t=0
  for i in 001206 001608 000703 002412 001105 002814 001407 002010 005626 000904 003216 002713 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521; do
    r=\"$(echo $rain | sed -e 's/tep6/\${h}/')\"
    if [ \$t -gt 4 ]; then t=19; fi
    nice -n \$t \${r}
    t=\$[t+1];
  done
  for x in \$(seq 3 6); do
    chmod 644 /data/tep\${x}/asoreyh/$codename/go-${prj}-all.sh
    mv /data/tep\${x}/asoreyh/$codename/go-${prj}-all.sh /data/tep\${x}/asoreyh/$codename/go-${prj}-all-\${h}.run
  done" > $wdir/go-$prj-all.sh
  chmod 744 $wdir/go-$prj-all.sh
  
  
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
  h=\$(hostname | sed -e 's/cab//')
  d=\$(hostname | sed -e 's/cabtep//')
  t=0
  for j in \$(seq 1 $prcHe); do
    i="0\${j}0402"
    r=\"$(echo $rain | sed -e 's/tep6/\${h}/')\"
    if [ \$t -gt 4 ]; then t=19; fi
    nice -n \$t \$r
    t=\$[t+1];
  done
  for x in \$(seq 3 6); do
    chmod 644 /data/tep\${x}/asoreyh/$codename/go-${prj}-he.sh
    mv /data/tep\${x}/asoreyh/$codename/go-${prj}-he.sh /data/tep\${x}/asoreyh/$codename/go-${prj}-he-\${h}.run
  done" > $wdir/go-$prj-he.sh
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
  h=\$(hostname | sed -e 's/cab//')
  d=\$(hostname | sed -e 's/cabtep//')
  t=0
  for j in \$(seq $ii $ff); do
    printf -v n "%02d" \$j
    i="\${n}0014"
    if [ \$t -gt 4 ]; then t=19; fi
    r=\"$(echo $rain | sed -e 's/tep6/\${h}/')\"
    nice -n \$t \${r}
    t=\$[t+1];
  done
  
  for x in \$(seq 3 6); do
    chmod 644 /data/tep\${x}/asoreyh/$codename/go-${prj}-pr-$i.sh
    mv /data/tep\${x}/asoreyh/$codename/go-${prj}-pr-$i.sh /data/tep\${x}/asoreyh/$codename/go-${prj}-pr-$i-\${h}.run
  done" > $wdir/go-${prj}-pr-$i.sh
  done
  
  rm $wdir/$prj/000014-*.run
  for i in $(seq 1 $multPr); do
    chmod 744 $wdir/go-${prj}-pr-$i.sh
  done
  
  for i in $(seq 3 5); do
    echo "Copying scripts to tep${i}"
    cp -r $wdir/${prj} /data/tep${i}/asoreyh/$codename/
    cp -r $wdir/go-${prj}-*.sh /data/tep${i}/asoreyh/$codename/
  done
fi
