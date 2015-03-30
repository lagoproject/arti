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
  echo -e "  -s <source bin directory>      : Where corsika binary files are located"
  echo -e "  -p <project name>              : Project base name (suggested format: nnn)"
  echo -e "  -u <user name>                 : Cluster user name."
  echo -e "  -d <project name>              : Erase project from cluster. WARNING: Can't not be undone"
  echo -e "  -?                             : Shows this help and exit."
  echo
}

src="";
usr="";
prj="";

echo

while getopts ':s:p:u:d:?' opt; do
  case $opt in
    s)
      src=$OPTARG
      echo -e "#  Source bin directory          = $src"
      ;;
    p)
      prj=$OPTARG
      echo -e "#  Project base name             = $prj"
      ;;
    d)
      prj=$OPTARG
      echo -e "#  WARNING: You will erase project ${prj}"
      echo -e "#  WARNING: This action can not be undone"
      echo -e "#  WARNING: Press enter to continue, ctrl-c to abort"
      read
      for i in $(seq 0 5); do
        echo -e "#  erasing project on halley$i"
        ssh h${i} rm -r /home/h$i/${prj}
      done
      echo -e "#  ALL DONE. Exit"
      exit 0;
      ;;
    u)
      usr="$OPTARG"
      echo -e "#  User name                     = $usr"
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

if [ "X${prj}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide a project name (suggested format: nnn)"
  showhelp
  exit 1;
fi

if [ "X${src}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to inform where corsika bin files are located"
  showhelp
  exit 1;
fi

if [ "X${usr}" == "X" ]; then
  usr=${USER}
  echo; echo -e "#  WARNING: user name don't provided. Using system user name: ${usr}"
fi

echo; echo -e "#  READY: Press enter to continue, <ctrl-c> to abort!"
read
##############

mkdir /home/h0/${prj}
cp -r ${src}/run/* /home/h0/${prj}/
for i in $(seq 1 5); do
  rsync -aP /home/h0/${prj} h${i}:/home/h${i}
done

#### Adding this project to .bashrc
echo "alias ${prj}=\"cd /home/h\${hn}/${prj}; ls -l\"" >> ~/.bashrc
for i in $(seq 1 5); do
    rsync -aP ~/.bashrc h${i}:
done
source ~/.bashrc

echo
echo
echo -e "#  DONE: Project ${prj} has been created. You can access the project folder"
echo -e "#        by just typing ${prj} anywhere."
echo -e "#"
echo -e "#        Run do_halley.sh to continue"
echo
