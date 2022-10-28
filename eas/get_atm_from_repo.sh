#!/bin/bash
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   get_atm_from_repo.sh                                       */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Get GDAS monthly averaged atmopsheric profiles produced by */ 
# /*           LAGO foreach of the sites described at in the LAGO DMP     */
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

url_base="https://raw.githubusercontent.com/lagoproject/atmospheres/main/atmprof"
[ -z "$1" ] && { echo "Usage: $0 <siteId> <year>" ; exit 99; }
[ -z "$2" ] && { echo "Usage: $0 <siteId> <year (YY)>" ; exit 99; }
if [ "$2" -lt 0 ] || [ $2 -gt 99 ]; then
	echo "Year should be given in YY format (00 to 99). Usage: $0 <siteId> <year (YY)>" 
	exit 99
fi
site=$1
year=$(printf "%02d" $2)
n=0
for m in $(seq -w 1 12); do
	file="atmprof${site}${year}${m}.dat"
	url_file="$url_base/${site}/${file}"
	if $(wget -q $url_file); then
		echo "File $file retrived"
		n=$(( n + 1 ))
	else
		echo "Failed to retrieve $file"
	fi
done
if [ "$n" -eq 12 ]; then
	echo "Success retrieving site:${site} for year:$year"
else
	echo "Failed to retrieve some files. $n files extracted"
	echo "Perhaps files does not be already produced. Please check at https://github.com/lagoproject/atmospheres/"
	exit 99
fi
