#!/bin/bash

# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   check-corsika.sh                                           */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: This module analyze corsika status in non-cluster array of */
# /*           nodes. To be used in combination with send-corsika-mail.sh */ 
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
VERSION="v3r0";

prjt=""
wdir=""
old=false

showhelp() {
  echo; echo -e "USAGE: $0 -w <wdir> -p <project base name> -o -s <mail direction>"; echo
}

while getopts ':w:p:o' opt; do
  case $opt in
    w)
      wdir=$OPTARG
      echo -e "#  Working dir              = $wdir"
      ;;
    p)
      prjt=$OPTARG
      echo -e "#  Project base name        = $prjt"
      ;;
    o)
      old=true
      echo -e "#  Using old output         = $prjt"
      ;;
    ?)
      showhelp
      exit 1
  esac
done

if [ "X$wdir" == "X" ]; then
  echo; echo -e "ERROR: You have to set the working directory"
  showhelp
  exit 1;
fi

if [ "X$prjt" == "X" ]; then
  echo; echo -e "ERROR: You have to provide a project base name"
  showhelp
  exit 1;
fi

# for i in $(seq 3 6); do
# sc=$(ssh asoreyh@10.73.22.10${i} screen -ls | grep $prjt | wc -l)
# echo "tep"${i}": "$sc" sessions running"
# tot=$[tot+sc]
# done
# echo "TOTAL: "$tot" sessions running"
# echo
end="lst"
if $old; then
  end="output"
fi

for k in $(seq 3 6); do
  aux=$(echo $wdir | sed -e "s/tep6/tep${k}/")
  echo $aux
  for j in $(find $aux -maxdepth 1 -iname "$prjt[0-9][0-9]"); do
    echo
    echo "STATUS" $j
    echo
    for i in $(ls -1 $j/DAT*.$end); do
      y="";
      x=$(grep "BEGIN OF EVENT" $i | tail -1 | awk '{print 1.*$10}')
      y=$(echo $(basename $i ".$end") | sed -e 's/DAT//')
      out=( $(echo $y | awk 'BEGIN{ FS = "-"}{print $0,1.*$3}') )
      rat=$(echo $x ${out[1]} | awk '{if ($2-$1 < 100) {print "100%    DONE"} else {print int(100.*($1+50.)/$2) "%    RUN" ;}}')
      echo "$j ${out[0]} : $x / ${out[1]} = $rat" >> tmp
    done
    sort -k8,8n tmp | cat -b 
    rm tmp
  done
done
