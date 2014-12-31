#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   newprj-halley.sh                                           */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: This script automates the analysis and collection of final */
# /*           simulated results in the halley cluster                    */
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
VERSION="v3r0"; # Wed Dec  4 21:53:57 COT 2013
# first version


h=$(hostname | awk '{if ($1=="frontend") {print 0} else {print $0}}' | sed -e 's/halley0//')

showhelp() {
  echo 
  echo -e "$0 version $VERSION"
  echo 
  echo -e "Note: You should run this script at the node where you want to collect the data"
  echo -e "      Now, you are on halley0${h}"
  echo
  echo -e "USAGE $0:"
  echo
  echo -e "  -p <project name>   : Project base name (suggested format: nnn)"
  echo -e "  -r <run name>       : Cluster user name."
  echo -e "  -a                  : Collect all the files (by default, ignore binary CORSIKA files)"
  echo -e "  -f                  : Force analysis (don't check if analyzed files are present)"
  echo -e "  -?                  : Shows this help and exit."
  echo
}

prj="";
run="";
all=false
frc=false

echo

while getopts ':p:r:af?' opt; do
  case $opt in
    p)
      prj=$OPTARG
      echo -e "#  Project base name             = ${prj} (Files are located on /home/hX/${prj})"
      ;;
    r)
      run=$OPTARG
      echo -e "#  You will collect files of run = $run on halley0${h} (/home/h${h}/${prj}/final-${run})"
      ;;
    a)
      all=true
      echo -e "#  WARNING: will collect all the data (could be several GiBs)"
      ;;
    f)
      frc=true
      echo -e "#  WARNING: will reanalyze al this run data"
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

if [ "X${prj}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide a project name"
  showhelp
  exit 1;
fi

if [ "X${run}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide the run you want to collect"
  showhelp
  exit 1;
fi

## Check if project and run exists. 
## If exists in one node, then exists in the whole cluster

if [ ! -d /home/h${h}/${prj} ]; then
  echo; echo -e "#  ERROR: Project ${prj} does not exists on this node!"
  showhelp
  exit 1;
fi

if [ ! -d /home/h${h}/${prj}/${run} ]; then
  echo; echo -e "#  ERROR: Project ${prj} exists but not the ${run} run!"
  showhelp
  exit 1;
fi


#### First... check if data is analyzed at the nodes
#### If not, analyze instead of collect

toana=""
nodes="0 1 2 3 5"; ##  h4 is down, for now $(seq 0 5); do

if ${frc}; then
  toana="${nodes}"
else
  for i in $nodes; do 
    if ls /home/h${i}/${prj}/${run}/*.sec.bz2 > /dev/null 2>&1; then
      echo -e "#  READY: Files are analyzed on node ${i}"
    else
      toana="${toana} $i"
    fi
  done
fi

echo
if [ "X${toana}" != "X" ]; then
  echo -e "#  WARNING: Need to analyze run on nodes ${toana}"
  # Creating script
  for i in $toana; do
    echo "PATH=/home/asoreyh/crktools:\${PATH}" > ~/an-$prj-$run-h0$i.sh
    echo "h=\$(hostname | awk '{if (\$1==\"frontend\") {print 0} else {print \$0}}' | sed -e 's/halley0//')" >> ~/an-$prj-$run-h0$i.sh
    echo "cd /home/h${i}/${prj}/${run}/" >> ~/an-$prj-$run-h0$i.sh
    echo "for i in DAT??????.bz2; do" >> ~/an-$prj-$run-h0$i.sh
    echo "  u=\$(basename \$i .bz2)" >> ~/an-$prj-$run-h0$i.sh
    echo "  n=\$(echo \$u | sed -e 's/DAT//')" >> ~/an-$prj-$run-h0$i.sh
    echo "  bunzip2 -9kv \$i" >> ~/an-$prj-$run-h0$i.sh
    echo "  echo \$u | lagocrkread | analysis -p -v \$n" >> ~/an-$prj-$run-h0$i.sh
    echo "  rm \$u" >> ~/an-$prj-$run-h0$i.sh
    echo "done" >> ~/an-$prj-$run-h0$i.sh
    echo "rm ~/an-$prj-$run-h0$i.sh" >> ~/an-$prj-$run-h0$i.sh
    chmod 744 ~/an-$prj-$run-h0$i.sh
    rsync -aq ~/an-$prj-$run-h0$i.sh h$i:
    ssh h$i screen -m -d -S ${prj}-${run} ~/an-$prj-$run-h0$i.sh && echo -e "#  READY: Analyzing data on halleyh0$i. Screen launched"
  done
  echo -e "#  READY: Once analysis are done, re-run this script"
  exit 0
fi

# last check... see if there are analysis running
tst=$(for i in ${nodes}; do ssh h$i screen -ls; done | grep ${prj}-${run})
if [ "X${tst}" != "X" ]; then
  echo -e "#  ERROR: There are some analysis still running for this run"
  echo -e "#         Try again in a few minutes. See you"
  echo
  exit 1
else
  echo -e "#  READY: No analysis running for this run"
  echo
fi

tst=$(ls -1 /home/h?/${prj}/${run}/*.sec.bz2 | wc -l)
if [ ! "X${tst}" == "X60" ]; then
  echo -e "#  WARNING: I found $tst DAT files instead of 60"
fi
echo; echo -e "#  READY: Press enter to continue, <ctrl-c> to abort!"

read
## everything fine... let's work
# erase possible temporal files from previous run
rm ~/an-$prj-$run-h0$i.sh > /dev/null 2>&1
##############

mkdir /home/h${h}/${prj}/final-${run}

for i in $nodes; do
  if ${all}; then
    rsync -aPv h${i}:/home/h${i}/${prj}/${run}/* /home/h${h}/${prj}/final-${run}/
  else
    rsync -aPv h${i}:/home/h${i}/${prj}/${run}/*.pri.bz2 /home/h${h}/${prj}/final-${run}/
    rsync -aPv h${i}:/home/h${i}/${prj}/${run}/*.sec.bz2 /home/h${h}/${prj}/final-${run}/
    rsync -aPv h${i}:/home/h${i}/${prj}/${run}/*.input /home/h${h}/${prj}/final-${run}/
    rsync -aPv h${i}:/home/h${i}/${prj}/${run}/*.dbase /home/h${h}/${prj}/final-${run}/
  fi
done

# checking if everything was fine
tst=$(ls -1 /home/h${h}/${prj}/final-${run}/*.sec.bz2 | wc -l)
if [ ! "X${tst}" == "X60" ]; then
  echo -e "#  ERROR: Some data was not collected"
  echo -e "#         I found $tst DAT files instead of 60" 
  echo -e "#         Please check and run this script again"
  # ls -1 /home/h${h}/${prj}/final-${run}/*.sec.bz2
fi

# Erasing temporal files
rm ~/an-$prj-$run-h0$i.sh > /dev/null 2>&1
echo
echo
echo -e "#  DONE: Run ${run} of project ${prj} has been collected on:"
echo -e "#        h${h}:[/home/h${h}/${prj}/final-${run}/]"
echo
