#!/bin/bash

# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   check-halley.sh                                            */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: This module analyze corsika status in non-clusterized      */
# /*           halley array of nodes                                      */ 
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
VERSION="v3r0";
proc=$1
all=false
crk=false
if [ "X$proc" == "Xall" ]; then
  all=true
fi
if ! $all; then
  if [ "X$proc" == "X" ]; then
    proc="corsika"
    crk=true
  fi
fi

st=0
en=5
tot=0
nodes='0 1 2 3 4 5'

if $all; then
  for i in $nodes; do
    echo; echo "halley0$i: "; echo 
    ssh h${i} ps -af | grep -v "grep" | grep -v "ps" | grep -v "crktools" | grep -v "bash" # | grep --colour "^halley" 
  done
else
  if $crk; then
    for i in $nodes; do
      echo -n "halley0$i: "
      ssh h${i} ps -af | grep "${proc}" | grep -v "grep" | grep -v "crktools" > tmp
      loc=$(cat tmp | wc -l)
      echo "$loc sessions running"
      cat tmp
      tot=$[ $tot + $loc ]
      echo
    done
    echo "TOTAL: $tot sessions running"
    rm tmp
  else
    for i in $nodes; do
      echo "halley0$i: "
      echo
      ssh h${i} ls /home/h${i}/${proc}/run* | awk 'BEGIN{FS="/"}{print $5}' | awk 'BEGIN{FS="-"}{print $2, $3}' | tee -a sessions
      echo
    done
    echo -n "Total for project ${proc}: "
    wc -l sessions
    rm sessions
  fi
fi
