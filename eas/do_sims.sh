#!/bin/bash
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   do_sims.sh										                              */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Main script to automatize secondary flux calculations      */
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
showhelp() {
  echo -e "$0 version $VERSION"
  echo 
  echo -e "USAGE $0:"
  echo -e
  echo -e "Simulation parameters"
  echo -e "  -w <working dir>                   : Working directory, where bin (run) files are located"
  echo -e "  -p <project name>                  : Project name (suggested format: NAMEXX)"
  echo -e "  -v <CORSIKA version>               : CORSIKA version"
  echo -e "  -h <HE Int Model (EPOS|QGSII)>     : Define the high energy interaction model to be used. Default: QGSJET-II-04"
  echo -e "  -f <LE Int Model (gheisha|fluka)>  : Define the lown energy interaction model to be used. Default: gheisha"
  echo -e "  -u <user name>                     : User Name."
  echo -e "  -j <procs>                         : Number of processors to use"
  echo -e
  echo -e "Physical parameters"
  echo -e "  -t <flux time>                     : Flux time (in seconds) for simulations"
  echo -e "  -m <Low edge zenith angle>         : Low edge of zenith angle."
  echo -e "  -n <High edge zenith angle>        : High edge of zenith angle."
  echo -e "  -r <Low primary particle energy>   : Lower limit of the primary particle energy."
  echo -e "  -i <Upper primary particle energy> : Upper limit of the primary particle energy."
  echo -e "  -a <high energy ecuts>             : High energy cuts for ECUTS; (if set value in GV = enabled)."
  echo -e "  -y                                 : Select volumetric detector mode (default=flat array)"
  echo -e
  echo -e "Site parameters"
  echo -e "  -s <site>                          : Location (several options)"
  echo -e "  -k <altitude, in cm>               : Fix altitude, even for predefined sites"
  echo -e "  -c <atm_model>                     : Fix Atmospheric Model even for predefined sites."
  echo -e "  -o <BX>                            : Horizontal comp. of the Earth's mag. field."
  echo -e "  -q <BZ>                            : Vertical comp. of the Earth's mag. field."
  echo -e "  -b <rigidity cutoff>               : Rigidity cutoff; (if set value in GV = enabled, <0 = disable)."
  echo -e "  -g <Lat, Lon> *dev                 : Obtain the current values of BX and BZ for a site located at (Lat,Lon,Alt), -k option is mandatory. If -s is used, then (Lat,Lon,Alt) will be taken from the standard characterization of the site."
  echo -e
  echo -e "Modifiers"
  echo -e "  -l                                 : Enables SLURM cluster compatibility (with sbatch)."
  echo -e "  -d                                 : Enable DOCKER compatible mode"
  echo -e "  -e                                 : Enable CHERENKOV mode"
  echo -e "  -x                                 : Enable other defaults (It doesn't prompt user for unset parameters)"
  echo -e "  -?                                 : Shows this help and exit."
  echo
}
cta=false
debug=false
highsec=false
sites=false
usr="LAGO"
vol=false
alt=false
altitude=0.
procs=4
atm_m=false
rig=false
lez=false
hez=false
lppe=false
uppe=false
BXcomp=false
BZcomp=false
defaults=false
ecut=800
slurm=false
onedataBase="/mnt/datahub.egi.eu/test8/fluka"; # need to change also at rain.pl
nprocs=$(/usr/bin/nproc)   # number of simultaneous process for paralllel local processing
docker=false

echo
while getopts 'w:k:p:t:v:u:f:h:s:j:c:b:m:n:r:i:o:q:a:?lydex' opt; do
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
      ver=$OPTARG
      echo -e "#  CORSIKA version               = $ver"
      ;;
    u)
      usr=$OPTARG
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
    f)
      lemodel=$OPTARG
      echo -e "#  Lew Energy Interaction Model = $lemodel"
      ;;
    s)
      site=$OPTARG
      sites=true
      echo -e "#  Site location                 = $site"
      ;;
    a)
      highsec=true
      ecut=$OPTARG
      echo -e "#  High energy CUTS              = $ecut"
      ;;
    j)
      procs=$OPTARG
      echo -e "#  Number of processors          = $procs"
      ;;
    c)
      atm_m=true
      atm_model=$OPTARG
      echo -e "#  Atmospheric Model             = $atm_model"
      ;;
    b)
      rig=true
      rigididy=$OPTARG
      echo -e "#  Rigidity cutoff               = $rigididy"
      ;;
    m)
      lez=true
      lowez=$OPTARG
      echo -e "#  Low edge of zenith angle      = $lowez"
      ;;
    n)
      hez=true
      highez=$OPTARG
      echo -e "#  High edge of zenith angle     = $highez"
      ;;
    r)
      lppe=true
      lowppe=$OPTARG
      echo -e "#  Low primary particle energy   = $lowppe"
      ;;
    i)
      uppe=true
      upperppe=$OPTARG
      echo -e "#  High primary particle energy  = $upperppe"
      ;;
    o)
      BXcomp=true
      BX=$OPTARG
      echo -e "#  Horizontal gepmagnetic field  = $BX"
      ;;
    q)
      BZcomp=true
      BZ=$OPTARG
      echo -e "#  Vertical geomagnetic field    = $BZ"
      ;;
    e)
      cta=true
      echo -e "#  Cherenkov mode                = $cta"
      ;;
    y)
      vol=true
      echo -e "#  Volumetric detector mode      = $vol"
      ;;
    l)
      slurm=true
      ;;
    d)
	  docker=true
      ;;
    x)
      defaults=true
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

if [ "X$prj" == "X" ]; then
  echo; echo -e "ERROR: You have to provide a project name (suggested format: NAMEXX, where XX is a number between 0 and 99)"
  showhelp
  exit 1;
fi

if [ "X$ver" == "X" ]; then
  ver="77402"
  echo -e "#  INFO: CORSIKA version was not provided. Using default: $ver"
fi


if ! $docker; then
	if [ "X$wdir" == "X" ]; then
		echo; echo -e "ERROR: You have to set the working directory (where corsika bin files are located)"
		showhelp
		exit 1;
	fi
else
	wdir="/opt/corsika-${ver}/run"
	echo -e "#  INFO: Working directory fixed by DOCKER: $wdir"
fi

if [ "X$tim" == "X" ]; then
  tim=3600;
  echo -e "#  INFO: Time was not provided. Using default time: $tim s"
fi

if [ "X$procs" == "X0" ]; then
  procs=4;
  echo -e "#  INFO: Processors should be >0, using default: $procs"
fi

if [ "X$hig" == "X" ]; then
  hig="QGSII"
  echo -e "#  INFO: High energy interaction model was not provided. Using default: $hig"
fi

if [ "X$lemodel" == "X" ]; then
  lemodel="gheisha"
  echo -e "#  INFO: Low energy interaction model was not provided. Using default: $lemodel"
fi

if [ "X$atm_model" == "X" ]; then
  atm_model="E1"
  echo -e "#  INFO: Atmospheric Model was not provided. Using default: $atm_model"
fi

if [ "X$rigididy" == "X" ]; then
  rigididy="0"
  echo -e "#  INFO: Rigidity cutoff was not provided. Using default (disabled): $rigididy"
fi

if [ "X$lowez" == "X" ]; then
  lowez="0"
  echo -e "#  INFO: Low edge of zenith angle was not provided. Using default: $lowez"
fi

if [ "X$highez" == "X" ]; then
  highez="90"
  echo -e "#  INFO: High edge of zenith angle was not provided. Using default: $highez"
fi

if [ "X$lowppe" == "X" ]; then
  lowppe="5"
  lppe=true
fi

if [ "X$upperppe" == "X" ]; then
  upperppe="1e6"
  echo -e "#  INFO: Primary particle high energy limit was not provided. Using default: $upperppe"
fi

if [ "X$BX" == "X" ]; then
  BX="12.5"
  echo -e "#  INFO: Horizontal comp. Earth's mag. field was not provided. Using default: $BX"
fi

if [ "X$BZ" == "X" ]; then
  BZ="25.5"
  echo -e "#  INFO: Vertical comp. Earth's mag. field was not provided. Using default: $BZ"
fi

if $debug; then
  echo -e "#  INFO: You are running in DEBUG mode."
fi

if $defaults; then
  echo -e "#  INFO: You are using some default vaules that will not be prompted."
fi

if $cta; then
  if $sites; then
    echo -e "#  INFO: Cherenkov mode is enabled."
  else
    echo; echo -e "ERROR: You have to provide a site location in CHERENKOV mode"
    showhelp
    exit 1;
  fi
fi

if $highsec; then
	echo -e "#  INFO: High energy cuts of $ecut GeV for secondaries will be used."
	if [ $lowppe -lt $ecut ]; then
			lowppe=$ecut
			lppe=true
			echo -e "#  INFO: Primary particle low energy limit is below energy cuts for secondaries. Changing to: $lowppe"
	fi
fi

if $slurm; then
	echo -e "#  INFO: SLURM mode is enabled. Will not work in other environments."
fi
if $docker; then
	if [ ! -d $onedataBase ]; then
		echo; echo -e "ERROR: You are running in DOCKER enabled mode but onedata is not accessible"
		showhelp
		exit 1;
	fi
	echo -e "#  INFO: DOCKER mode is enabled."
fi

corsika_bin="corsika${ver}Linux_${hig}_${lemodel}"
if [ ! -e $wdir/$corsika_bin ]; then
	echo; echo -e "ERROR: Can't locate corsika executable file ($corsika_bin) in the working dir you provided. Please check."
    showhelp
    exit 1;
fi
echo -e "#  INFO: Executable file is ($corsika_bin)"

# It is important to now the total time in onedata. Adding total simulation time to the project name...
prj="${prj}_$(printf "%06d" ${tim})"
direct=$wdir/$prj
basearti=${ARTI}
#helium -> Usually for 1 hour flux, 4 different procces is enough
prcHe=$procs

#protons -> we need at least 32 times helium, so multPr=8
multPr=8
prcPr=$[${prcHe}*${multPr}] # now prcPr=32


##############
options="-w ${wdir} -t ${tim} -p ${prj} "
if $sites; then
  options=${options}"-s ${site} "
fi
options=${options}"-u ${usr} "
if $highsec; then
  options=${options}"-a $ecut "
fi
if $vol; then
  options=${options}"-y "
fi
if $alt; then
  options=${options}"-k $altitude "
fi
if $atm_m; then
  options=${options}"-c $atm_model "
fi
if $rig; then
  options=${options}"-b $rigididy "
fi
if $lez; then
  options=${options}"-m $lowez "
fi
if $hez; then
  options=${options}"-n $highez "
fi
if $lppe; then
  options=${options}"-r $lowppe "
fi
if $uppe; then
  options=${options}"-i $upperppe "
fi
if $BXcomp; then
  options=${options}"-o $BX "
fi
if $BZcomp; then
  options=${options}"-q $BZ "
fi
if $defaults; then
  options=${options}"-x "
fi
  
options=${options}"-f $basearti/sims/spectra.dat"

echo
$basearti/sims/generate_spectra.pl ${options} || exit 1
echo
##############

a=$(echo $prj)

#all

cp $basearti/sims/rain.pl $wdir/
if $cta; then 
    rain="./rain.pl -z"
else
    rain="./rain.pl "
fi

rain="$rain -i" # disable PLOT mode (not use PLOTSH and COMOUT)

if $sites; then
  rain="$rain -s ${site}"
fi

if $docker; then
  rain="$rain -d"
fi

if $highsec; then
  rain="$rain -a $ecut"
fi

if $slurm; then
	rain="$rain -l"
fi

rain="$rain -r $wdir -v $ver -h $hig -f $lemodel -b $prj/\$i-*.run"
echo -e "#  INFO   : rain command: $rain"
if $docker; then
	oneout="$onedataBase/S3_${prj}_${site}_${lemodel}"
	[[ ! -d $oneout ]] && mkdir $oneout
	while ! cp -v $wdir/$prj/inject $oneout; do 
		sleep 5
	done
	echo -e "#  INFO   : Results will be transferred to $oneout"
fi
echo -e "#  INFO   : Calculations done. Now run the go_${prj}_* scripts in $wdir/"

basenice=19
if $slurm; then
  basenice=0;
fi

if $slurm; then
	echo -e "#!/bin/bash" > $wdir/go-slurm-$prj.sh
	echo -e "# go slurm $prj" >> $wdir/go-slurm-$prj.sh
	echo -e "" >> $wdir/go-slurm-$prj.sh
    chmod 744 $wdir/go-slurm-$prj.sh
fi
if $docker; then
	echo -n > $wdir/go-docker-$prj.run
fi

stuff=(001206 001608 000703 002412 001105 002814 001407 002010 005626 000904 003216 002713 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521)
t=0
for i in $(seq 0 $procs $[${#stuff[@]}-1]); do
	nuc=""
	t=$[$t+1]
	printf -v n "%02d" $t
	for j in $(seq 0 $[${procs}-1]); do
		nuc+="${stuff[$i+$j]} "
	done
	echo "#!/bin/bash
#Stuff-$n!
for i in ${nuc}; do
	r=\"$rain \"
	nice -n $basenice \${r}
done
chmod 644 $wdir/go-$prj-all-$n.sh
mv $wdir/go-$prj-all-$n.sh $wdir/go-$prj-all-$n.run
" > $wdir/go-$prj-all-$n.sh
	chmod 744 $wdir/go-$prj-all-$n.sh
	if $slurm; then
		echo $wdir/go-$prj-all-$n.sh >> $wdir/go-slurm-$prj.sh
	fi
done
if $docker; then
	for i in $(seq 0 $[${#stuff[@]}-1]); do
		nuc=${stuff[$i]}
		r=${rain/\$i/${nuc}}
		echo -e "$r" >> $wdir/go-docker-$prj.run
	done
	rm $wdir/go-$prj-all-*.sh
fi
#helium
b=$(basename $(ls -1 $wdir/$prj/000402-*) .run | sed -e "s/000402-//" | awk '{print $1*1.0}')
c=$(basename $(ls -1 $wdir/$prj/000402-*) .run | sed -e "s/000402-//" | awk -v p=${prcHe} '{print int($1/p+0.5)}')
printf -v k "%011d" $c
for i in $(seq 1 $prcHe); do
  u="0${i}0402"
  cat $wdir/$prj/000402-*.run | sed -e "s/000402/$u/" | sed -e "s/$b/$c/" > $wdir/$prj/$u-$k.run
done

echo "#!/bin/bash
#Helium
for j in \$(seq 1 $prcHe); do
  i="0\${j}0402"
  r=\"$rain \"
  nice -n $basenice \${r}
done
chmod 644 $wdir/go-$prj-he.sh
mv $wdir/go-$prj-he.sh $wdir/go-$prj-he.run
" > $wdir/go-$prj-he.sh
chmod 744 $wdir/go-${prj}-he.sh
rm $wdir/$prj/000402-*.run
if $slurm; then
	echo $wdir/go-${prj}-he.sh >> $wdir/go-slurm-$prj.sh
fi
if $docker; then
	for i in $(seq 1 $prcHe); do
		u="0${i}0402"
        r=${rain/\$i/${u}}
        echo -e "$r" >> $wdir/go-docker-$prj.run
	done
	rm $wdir/go-$prj-he.sh
fi

#protons
b=$(basename $(ls -1 $wdir/$prj/000014-*) .run | sed -e "s/000014-//" | awk '{print $1*1.0}')
c=$(basename $(ls -1 $wdir/$prj/000014-*) .run | sed -e "s/000014-//" | awk -v p=${prcPr} '{print int($1/p+0.5)}')
printf -v k "%011d" $c

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
for j in \$(seq $ii $ff); do
  printf -v n "%02d" \$j
  i="\${n}0014"
  r=\"$rain \"
  nice -n $basenice \${r}
done
chmod 644 $wdir/go-$prj-pr-$i.sh
mv $wdir/go-$prj-pr-$i.sh $wdir/go-$prj-pr-$i.run" > $wdir/go-${prj}-pr-$i.sh
	if $slurm; then
		echo $wdir/go-${prj}-pr-$i.sh >> $wdir/go-slurm-$prj.sh
	fi
	if $docker; then
		for j in $(seq $ii $ff); do
			printf -v n "%02d" $j
			u="${n}0014"
			r=${rain/\$i/${u}}
			echo -e "$r" >> $wdir/go-docker-$prj.run
		done
	fi
done
rm $wdir/$prj/000014-*.run
for i in $(seq 1 $multPr); do
  chmod 744 $wdir/go-${prj}-pr-$i.sh
done
if $slurm; then
    echo -e "squeue -u \$USER" >> $wdir/go-slurm-$prj.sh
    echo -e "mv $wdir/go-slurm-$prj.sh $wdir/go-slurm-$prj.run" >> $wdir/go-slurm-$prj.sh
    echo -e "chmod 644 $wdir/go-slurm-$prj.run" >> $wdir/go-slurm-$prj.sh
fi
if $docker; then
	rm $wdir/go-${prj}-pr-*.sh
	rm -r 
 	echo -e "#!/bin/bash" > $wdir/go-docker-$prj.sh
 	echo -e "# go docker $prj" >> $wdir/go-docker-$prj.sh
 	echo -e "" >> $wdir/go-docker-$prj.sh
	echo -e "N=\$(/usr/bin/nproc)" >> $wdir/go-docker-$prj.sh
 	echo -e "nl=\$(cat $wdir/go-docker-$prj.run | wc -l)" >> $wdir/go-docker-$prj.sh
	echo -e "np=0" >> $wdir/go-docker-$prj.sh
	echo -e "nr=0" >> $wdir/go-docker-$prj.sh
	echo -e "while IFS= read -r line; do" >> $wdir/go-docker-$prj.sh
    echo -e "    eval \${line}" >> $wdir/go-docker-$prj.sh
	echo -e "    ((nr++))" >> $wdir/go-docker-$prj.sh
    echo -e "    np=\$(ps aux | grep corsika77402 | grep -v grep | wc -l)" >> $wdir/go-docker-$prj.sh
    echo -e "    echo \$np: \$nr/\$nl" >> $wdir/go-docker-$prj.sh
    echo -e "    while [ \$np -ge \$N ]; do" >> $wdir/go-docker-$prj.sh
	echo -e "        sleep 3;" >> $wdir/go-docker-$prj.sh
    echo -e "        np=\$(ps aux | grep corsika77402 | grep -v grep | wc -l)" >> $wdir/go-docker-$prj.sh
    echo -e "    done" >> $wdir/go-docker-$prj.sh
	echo -e "done < $wdir/go-docker-$prj.run" >> $wdir/go-docker-$prj.sh
    echo -e "mv $wdir/go-dockerslurm-$prj.sh $wdir/go-slurm-$prj.run" >> $wdir/go-slurm-$prj.sh
    echo -e "chmod 644 $wdir/go-slurm-$prj.run" >> $wdir/go-slurm-$prj.sh
	chmod 744 $wdir/go-docker-$prj.sh
	cd $wdir
	eval $wdir/go-docker-$prj.sh
	ls -l $oneout/
	cd ${HOME}
fi
