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
# /* Comments: This script automates the creation of a new simulation     */
# /*           project in the halley cluster                              */
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


showhelp() {
  echo 
  echo -e "$0 version $VERSION"
  echo 
  echo -e "Note: You should run this script at halley cluster frontend h0"
  echo 
  echo -e "USAGE $0:"
  echo
  echo -e "  -b <project base name>         : Project base name (suggested format: nnn)"
  echo -e "  -p <project name>              : Project name, typically nnnxx"
  echo -e "  -?                             : Shows this help and exit."
  echo
}

bsn="";
prj="";

echo

while getopts ':b:p:?' opt; do
  case $opt in
    b)
      bsn=$OPTARG
      echo -e "#  Project base name             = $bsn"
      ;;
    p)
      prj=$OPTARG
      echo -e "#  Project name                  = $prj"
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

h=$(hostname | awk '{if ($1=="frontend") {print 0} else {print $0}}' | sed -e 's/halley0//')
if [ "X${h}" != "X0" ]; then
  echo; echo -e "#  ERROR: You should run this script at halley cluster frontend (h0)"
  showhelp
  exit 1;
fi

if [ "X${bsn}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide a project base name (suggested format: nnn)"
  showhelp
  exit 1;
fi

if [ "X${prj}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide a project name (typically format: nnnxx)"
  showhelp
  exit 1;
fi


# echo; echo -e "#  READY: Press enter to continue, <ctrl-c> to abort!"
# read
##############

echo
# Test if all the processes ended correctly
tst=$(for i in $(seq 0 5); do tail -q -n 1 /home/h$i/$bsn/$prj/*.lst | grep -v "END OF RUN"; done)

if [ "X${tst}" != "X" ]; then
  echo "#  ERROR: Some processes failed:"
  for i in $(seq 0 5); do 
    tail -n 1 /home/h$i/$bsn/$prj/*.lst | grep -v "END OF RUN"
  done
  echo "#  ERROR: Please check"
  exit 1
fi
echo -e "#  Test 1: PASS: all processes ended normally"

tst=$(for i in $(seq 0 5); do ls -1 /home/h$i/$bsn/$prj/DAT??????; done | wc -l)

if [ "X${tst}" != "X60" ]; then
  for i in $(seq 0 5); do 
    ls -1 /home/h$i/$bsn/$prj/DAT??????
  done
  echo "#  ERROR: There are not $tst/60 output files"
  echo "#  ERROR: Please check"
  exit 1
fi
echo -e "#  Test 2: PASS: There are 60 output files"

echo
echo -e "#  DONE"
echo -e "#  Please run the following commands. At frontend:"
echo
echo -e "for i in \$(seq 0 5); do ssh h\$i; done"

for i in $(seq 0 5); do
  name=$prj-$i
  echo "cd /home/h$i/$bsn/$prj/; for i in DAT??????; do u=\$(echo \$i | sed -e 's/DAT//'); echo \$i | lagocrkread | analysis -p -v \$u ; done; rm /home/h$i/$bsn/$prj/$name.sh" > /home/h$i/$bsn/$prj/$name.sh
  chmod 744 /home/h$i/$bsn/$prj/$name.sh
  echo "screen -d -m -S $name /home/h$i/$bsn/$prj/$name.sh; screen -r"
done





