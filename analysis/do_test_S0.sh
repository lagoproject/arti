#!/bin/bash
# /************************************************************************/
# /*                                                                      */
# /* Package:  ARTI                                                       */
# /* Module:   do_test.sh                                                 */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernanasorey@iteda.cnea.gov.ar                             */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Script to automatize the test of S0                        */
# /*                                                                      */
# /************************************************************************/
# /*
# 
#  
# Copyright 2021
# Hernán Asorey
# ITeDA (CNEA), Argentina
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
# 
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of Lab DPR.
# 
# */
# /************************************************************************/
# 

wdir="${PWD}"
odir=""
dirlw=0
error=0
metadata=1

showhelp() {
	echo
	echo -e "$0 version $VERSION"
	echo
	echo -e "USAGE $0:"
	echo
	echo -e "  -o <origin directory>     : Origin dir, where the DAT files are located"
	echo -e "  -w <workding directory>   : Working dir, where the analysis will be done (default is current directory, ${wdir})"
	echo -e "  -m                        : If selected, would not check for metadata consistency. Default = Check"
	echo -e "  -?                        : Shows this help and exit."
	echo
}

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[0;1m'
NC='\033[0m' # No Color

echo

while getopts ':w:o:m?' opt; do
	case $opt in
		w)
			wdir=${OPTARG%/}
			;;
		o)
			odir=${OPTARG%/}
			;;
		m)
			metadata=0
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

# ERRORS
# are the DAT files in the data directory?
file=$(ls -1 $odir/DAT??????.bz2 | wc -l)
if [ ! $file -gt 0 ]; then
	echo; echo -e "#  ERROR: DAT files not found in $odir. Please check and try again"
	echo
	showhelp
	exit 1
fi

# is working really local? for now just check for /mnt 
if [[ $wdir == *"/mnt/"* ]]; then 
	echo; echo -e "#  ERROR: working dir (-w) should be local, not mounted. Please check and try again"
	echo
	showhelp
	exit 1
fi

# WARNINGS

if [ "X$wdir" == "X$odir" ]; then
	echo; echo -e "#  WARNING: We are running where DAT files are located. Analysis results will be in the same directory."
	echo -e "#           $wdir"
	dirlw=1
fi

# Project name 
prj=$(basename $odir)

if [[ "$prj" == "S0"* ]]; then
	echo -n
else
	echo; echo -e "#  WARNING: Catalogue should start with S0, and project name is $prj."
fi

## finally...
echo -e "#  Path to DAT files             = $odir"
echo -e "#  Project name                  = $prj"
echo -e "#  Path to running directory     = $wdir"
echo -e "#  Check for metadata?           = $metadata"
# TESTS

echo
echo
echo "For project $prj:"
echo

# DATA
# 1) Number of DAT, lst and input files should be the same
dat=$(ls -1 $odir/DAT??????.bz2 | wc -l)
lst=$(ls -1 $odir/DAT??????-*.lst.bz2 | wc -l)
inp=$(ls -1 $odir/DAT??????-*.input | wc -l)
echo -e -n "1. Number of files (DAT/lst/input):  $dat/$lst/$inp - "
if (( $dat == $lst )); then
	echo -n -e "${GREEN}DAT==LST${NC} && "
else
	echo -n -e "${RED}DAT!=LST${NC} && "
	((error++))
fi
if (( $dat == $inp )); then
	echo -n -e "${GREEN}DAT==LST${NC} && "
else
	echo -n -e "${RED}DAT!=INP${NC} && "
	((error++))
fi
if (( $lst == $inp )); then
	echo -n -e "${GREEN}LST==INP${NC} "
else
	echo -n -e "${RED}LST!=INC${NC}"
	((error++))
fi
if (( $error > 0 )); then 
	echo -e "${RED} => ERROR $NC"
else
	echo -e "${GREEN} => OK ${NC}"
fi

# 2. zero size files
echo -e -n "2. Number of size 0 files  : "
zfiles=$(find $odir -maxdepth 1 -type f -size 0 | wc -l)
if [[ $zfiles -gt 0 ]]; then
	echo -e "${RED}$zfiles ERROR${NC}"
	for i in $(find $odir -type f -maxdepth 1 -size 0); do
		j=$(basename $i)
		echo -e $j
	done
	((error++))
else
	echo -e "${GREEN}$zfiles OK${NC}"
fi

# 3. End of run
count=0
good=0
for i in $odir/*.lst.bz2; do 
	while ! cp -a $i $wdir/; do
		sleep 5
	done
	j=$(basename $i)
	p=$((100* ++count / lst))
	echo -n -e "End of run check: ${BOLD}$count / $lst (${p}%)${NC}\r"
	tst=$(bzcat $j | tail -1 | grep -c "END OF RUN")
	if [ $tst -gt 0 ]; then
		((good++))
	fi
	rm $j
done
echo -en "3. 'END OF RUN' : " 
if [ $count -ne $lst ]; then
	echo -e "${RED}Failed: some files were not analyzed${NC}"
	((error++))
elif [ $good -ne $lst ]; then
	fail=$((lst - good))
	echo -e "${RED}Failed: $fail runs didn't end properly${NC}"
	((error++))
else
	echo -e "${GREEN}All runs ended properly ($good/$lst)${NC}"
fi

if [ $metadata -eq 0 ]; then
	echo -e "Not cheking for metadata consistency. End"
	if [ $error -gt 0 ]; then 
		echo -e "${RED} $error ERRORS${NC}"
	else
		echo -e "${GREEN} $error ERRORS${NC}"
	fi
	echo
	exit $error
fi

# METADATA 
# 4) check if the metadata directory exists
echo -n "4. Metadata directory:  "
if [ -d "$odir/.metadata/" ]; then
	echo -e "${GREEN}exists - OK.${NC}"
else
	echo -e "${RED}don't exist - ERROR.${NC}"
	((error++))
fi

# 5. zero size metadata files
echo -e -n "5. Number of size 0 files in metadata  : "
zfiles=$(find $odir/.metadata/ -maxdepth 1 -type f -size 0 | wc -l)
if [[ $zfiles -gt 0 ]]; then
	echo -e "${RED}$zfiles ERROR${NC}"
	for i in $(find $odir/.metadata/ -type f -maxdepth 1 -size 0); do
		j=$(basename $i)
		echo -e $j
	done
	((error++))
else
	echo -e "${GREEN}$zfiles OK${NC}"
fi

# 6. number of metadata files
expected=$((dat + lst + inp + 1)) # 1 per file + 1 per catalogue
echo -e -n "6. Number of files in metadata, real/expected : "
mfiles=$(ls -1 ${odir}/.metadata/.*jsonld | wc -l)
if [[ $mfiles -ne $expected  ]]; then
	echo -e "${RED} $mfiles/$expected ERROR${NC}"
	((error++))
else
	echo -e "${GREEN} $mfiles/$expected OK${NC}"
fi
echo
echo -en "${BOLD}done - status: ${NC}"
if [[ $error -gt 0 ]]; then 
	echo -e "${RED} $error ERRORS${NC}"
else
	echo -e "${GREEN} $error ERRORS${NC}"
fi
echo
exit $error
