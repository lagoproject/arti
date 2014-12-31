#!/bin/bash

# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   send-corsika-mail.sh                                       */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Check simulation status in a non-cluster array of nodes    */
# /*           To be used in combination with check-corsika.sh            */ 
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
send=false
mail=""
wdir=""
prjt=""
bin=/work/asoreyh/bin
log=""

showhelp() {
  echo; echo -e "$0 version $VERSION"; echo "USAGE: $0 -w <wdir> -p <project base name> -s <mail direction>"; echo
}

while getopts ':w:p:s:' opt; do
  case $opt in
    w)
      wdir=$OPTARG
      echo -e "#  Working dir              = $wdir"
      ;;
    p)
      prjt=$OPTARG
      echo -e "#  Project base name        = $prjt"
      ;;
    s)
      send=true
      mail=$OPTARG
      echo -e "#  Status will be mailed to = $mail"
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

if $send; then
  if [ "X$mail" == "X" ]; then
    echo; echo -e "ERROR: You have to provide a valid mail direction"
    showhelp
    exit 1;
  fi
fi

log=${prjt}
rm ${wdir}/${log}.log
echo >> ${wdir}/${log}.log
echo>> ${wdir}/${log}.log
date >> ${wdir}/${log}.log
echo >> ${wdir}/${log}.log


## NOTE: This is valid only for Bariloche server structure. Please modify according to your
##       architecture

for i in $(seq 3 6); do
sc=$(ssh asoreyh@10.73.22.10${i} screen -ls | grep $prjt | wc -l)
echo "tep"${i}": "$sc" sessions running" >> ${wdir}/${log}.log
tot=$[tot+sc]
done
echo "TOTAL: "$tot" sessions running" >> ${wdir}/${log}.log

run=0
for i in $(seq 3 6); do
  tmp=$(echo $wdir | sed -e "s/tep6/tep${i}/")
  ls -1 $tmp/run*.sh >> ${wdir}/${log}.log
  b=$(ls -1 $tmp/run*.sh | wc -l)
  run=$[run+b]
done;
echo >> ${wdir}/${log}.log
echo "ALL INSTANCES RUNNING: $run." >> ${wdir}/${log}.log
echo >> ${wdir}/${log}.log
echo >> ${wdir}/${log}.log

# ll=0
# ul=50
# for i in $(seq $ll $ul); do
#   printf -v a "%02d" $i
#   [ -f ${wdir}/${prjt}${a}/inject ] && check-corsika.sh -w $wdir -p ${prjt}  
# done >> ${wdir}/${log}.log

$bin/check-corsika.sh -w $wdir -p ${prjt} >> ${wdir}/${log}.log

echo >> ${wdir}/${log}.log
# van=`for i in $(seq 1 ${ul}); do printf -v a "%02d" $i; [ -f ${wdir}/${prjt}${a}/inject ] && head -1 $wdir/${prjt}${a}/inject; done | awk '{t+=$3/60}END{printf("\n%d minutos (%.1f horas)\n\n", t, t/60)}'`
# echo $van >> ${wdir}/${log}.log
total=`for i in $wdir/${prjt}*; do head -1 $i/inject; done | awk '{t+=$3/60}END{printf("\n%d minutos (%.1f horas)\n\n", t, t/60)}'`
echo $total >> ${wdir}/${log}.log
echo >> ${wdir}/${log}.log

if $send; then
  cat ${wdir}/${log}.log | mail -s "CORSIKA simulation ${log}" $mail; sleep 1 
else
  cat ${wdir}/${log}.log
fi
