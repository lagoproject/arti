#!/usr/bin/perl -w
# /************************************************************************/
# /*                                                                      */
# /* Package:  ARTI                                                       */
# /* Module:   generate_spectrum.pl                                       */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Simple meta script to generate input files from spectrum   */
# /*           for all nuclei (data is read from genEspectra.dat)         */
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
$VERSION="v1r1";

# defaults
use Switch;
$pi=3.1415927;

$site="unk";

$time=0;
$prj="";
$file = "spectra.dat";
$area=1e4;
#cm2
$wdir="";
$user="";
$cluster=0;
$clsname="";
$grid=0;
$highsec=0;
$batch=1;
$flat=1;
$fixalt=0.;
$ifixalt=0;
#ajrm vars
$fixmodatm=0;
$ifixmodatm=0;
$tMin = 0;
$tMax = 0;
$llimit = 0.;
$ulimit = 0.;
$rigidity = 0.;
$usedefaults=0;

# masses from stderr output of mass.pl
@mid = (0, 14, 402, 703, 904, 1105, 1206, 1407, 1608, 1909, 2010, 2311, 2412, 2713, 2814, 3115, 3216, 3517, 3919, 4018, 4020, 4521, 4822, 5123, 5224, 5525, 5626);
@mms = (0., 0.938272, 3.73338244805557, 6.53478032991106, 8.39429044902688, 10.2536061929541, 11.1787903246739, 13.045071978869, 14.898326507629, 17.6899146520668, 18.6173579550734, 21.4080199431823, 22.3362803688324, 25.1263356296296, 26.0553153433303, 28.8449660324983, 29.7745989328225, 32.5639816988633, 36.2834316370329, 37.2107457840596, 37.2142385732562, 41.8605295331555, 44.6483661801865, 47.4401999906342, 48.3681334024753, 51.1598095147594, 52.0885229269484);
%mass = ();
for ($i=0; $i<@mid; $i++) {
  $mass {$mid[$i]} = $mms[$i];
}

sub get {
  my $question = $_[0];
  my $default = $_[1];
  my $param = $_[2];
  my $var = $_[3];
  
  # '' string and 0 should return false
  unless ($var || $usedefaults){
    if ($batch) {
        print "$question?\n<$param $default>: ";
    }
    chomp (my $tmp = <STDIN>);
    $var = $tmp;
  }
  if (!$var) {
    $var=$default;
  }
  print "Fixed param: $param $var\n";
  return $var;
}

$help="
 $0 $VERSION

A simple meta script to generate input files (through rain.pl)
for a complete set of nuclei to define the comple spectra
Read spectra data from file spectra.dat unless other provided 
(C) 2013 - H. Asorey

Usage: $0 options

Mandatory:
  -w <working dir>      Where corsika run files are located
  -p <project name>     name of the project 
Recommended:
  -f <file>             Use file to calculate nuclei spectra, asuming a flux of the form: 
                             j(E) = j0 * E^(-gamma), where j0=a0 x 10^-e0.
                        Format (See genspectra.dat):
                          - First line: number of nuclei to process. 
                          - Then, for each nuclei 4 lines should be included:
                             1) corsika particle id
                             2) a0 for this nuclei
                             3) e0 for this nuclei
                             4) gamma for this nuclei
Optional:
  -u <user name>        For CORSIKA simulation (Default: none)
  -t <time in sec>      Flux time ( Default: 3600s)
  -s <site>             Choice predefined site for simulation (Default: unknow)
                          - Predefined sites: hess|sac|etn|ber|bga|lim|glr|mch|mge|and|mpc|cha|cid|mor|ccs|lsc|mbo)
                          - Predefined parameters: altitude, BX, BZ, and Atmospheric Model.
  -k <altitude>         Fix altitude even for predefined sites (It cannot be 0)
  -c <Atmosph. Model>   Fix Atmospheric Model even for predefined sites. 
                           (Note: Start number with 'E' to use external atmospheres module)
  -y                    Enable volumetric detector for flux calculations (Default: flat)
  -a                    Enable high energy cuts for secondaries
  -b <rigidity cutoff>  0 = disabled; value in GV = enabled (Default: 5.)
  -m                    Low edge of zenith angle (THETAP) [deg] (Default: 0)
  -n                    High edge of zenith angle (THETAP) [deg] (Default: 90)
  -r                    Lower limit of the primary particle energy (ERANGE) [GeV] (Default: 5e0) 
  -v                    Upper limit of the primary particle energy (ERANGE) [GeV] (Default: 1e6)
Fix parameters for unknow sites:
  -o <BX>               Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT], see values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM 
  -q <BZ>               Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT], see values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM  
Run modes:
  -g                    Enable grid mode
  -l <cluster username> Enable OAR cluster compatibility (UIS style), use -l \$USER
                        (and override -u)
Other:
  -x                    Enable defaults (It doesn't prompt user for unset parameters)
  -?                    Shows this help and exits
";

while (defined($_ = $ARGV[0]) && $_ =~ /^-/) {
  shift;
  if (/-f$/i) {
    $file = $ARGV[0];
    shift;
  }
  if (/-u$/i) {
    $user = $ARGV[0];
    shift;
  }
  if (/-w$/i) {
    $wdir = $ARGV[0];
    shift;
  }
  if (/-t$/i) {
    $time = $ARGV[0];
    shift;
  }
  if (/-s$/i) {
    $site = $ARGV[0];
    shift;
  }
  if (/-k$/i) {
    $fixalt = $ARGV[0];
    $ifixalt++;
    shift;
  }
  if (/-c$/i) {
    $fixmodatm = $ARGV[0];
    $ifixmodatm++;
    shift;
  }
  if (/-p$/i) {
    $prj = "$ARGV[0]";
    shift;
  }
  if (/-y$/i) {
    $flat=0;
  }
  if (/-a$/i) {
    $highsec++;
  }
  if (/-b$/i) {
    $rigidity = $ARGV[0];
    shift;
  }
  if (/-m$/i) {
    $tMin = $ARGV[0];
    shift;
  }
  if (/-n$/i) {
    $tMax = $ARGV[0];
    shift;
  }
  if (/-r$/i) {
    $llimit = $ARGV[0];
    shift;
  }
  if (/-v$/i) {
    $ulimit = $ARGV[0];
    shift;
  }
  if (/-o$/i) {
    $bx = $ARGV[0];
    shift;
  }
  if (/-q$/i) {
    $bz = $ARGV[0];
    shift;
  }  
  if (/-g$/i) {
    $grid++;
  }
  if (/-l$/i) {
    $clsname = "$ARGV[0]";
    $cluster++;
    shift;
  }
  if (/-x$/i) {
    $usedefaults++;
  }
  if (/-\?$/i) {
    print "$help";
    exit;
  }
}

# Asking for options
print STDERR "\n### GENERATE SPECTRA ###\n\n\n";
$file=get("Spectra file","","(file)",$file);

unless ($time && $wdir && $prj) {
  print STDERR "\n### Project parameters ###\n\n";
}
$prj=get("Project name","","(prj)",$prj);
$wdir=get("Project parent dir","","(wdir)",$wdir);
$time=get("Flux time [s] ",3600,"(time)", $time);
$direct="$wdir/$prj";
$home = $wdir;

$user=get("User ORCID or local user","","(user)",$user);
if ($cluster) {
  $wdir="/opt/corsika-73500/run";
  $user=$clsname;
  $home = "/home/$user";
  $direct="$home/$prj";
}


unless ($usedefaults) {
    print STDERR "\n### Shower parameters ###\n\n";
}

$tMin = get("Low edge of zenith angle (THETAP) [deg]", 0, "THETPR(1)", $tMin);
$tMax = get("High edge of zenith angle (THETAP) [deg]", 90, "THETPR(2)", $tMax);
$llimit = get("Lower limit of the primary particle energy (ERANGE) [GeV]", 5e0, "LLIMIT", $llimit);
$ulimit = get("Upper limit of the primary particle energy (ERANGE) [GeV]", 1e6, "ULIMIT", $ulimit);

unless ($rigidity && $modatm) {
    print STDERR "\n### Site parameters ###\n\n";
}
$rigidity = get("Use rigidity cutoff? (0=no, Rigidity value=yes [GV])",5.,"", $rigidity);
$userllimit=$llimit;


#all predefined sites seems to be ATMOSPHERE as default mode
$atmcrd = "ATMOSPHERE";
switch ($site) {
  case "hess" {
    $modatm="E10";
    $altitude=1800e2;
    $bx=12.5;
    $bz=-25.9;
  }
  case "sac" {
    #$modatm="E32";  ###  OJO ajrm no funciona "ATMOSPHERE E32" , de hecho ATMOSPHERE no parece que le guste mucho
    $modatm="10";  ### OJO ajrm si pongo esto funciona y me lo cambia a "ATMOD 10" no sé donde 
    $altitude=3700e2;
    $bx=20.94;
    $bz=-8.91;
  }
  case "etn" {
    $modatm="E2";
    $altitude=3000e2;
    $bx=27.7623;
    $bz=36.0667;
  }
  case "ber" {
    $modatm="E1";
    $altitude=3450e2;
    $bx=26.9814;
    $bz=17.1054;
  }
  case "lim" {
    $modatm="E2";
    $altitude=168e2;
    $bx=25.28;
    $bz=-0.046;
  }
  case "glr" {
    $modatm="E1";
    $altitude=4276e2;
    $bx=27.0750;
    $bz=11.7728;
    $arrang="0";
  }
  case "mch" {
    $modatm="E1";
    $altitude=2650e2;
    $bx=27.1762;
    $bz=14.6184;
    $arrang="0";
  }
  case "bga" {
    $modatm="E1";
    $altitude=950e2;
    $bx=27.0263;
    $bz=17.1760;
  }
  case "mge" {
    $modatm="19";
    $altitude=1400e2;
    $bx=20.4367;
    $bz=-11.8217;
  }
  case "brc" {
    $modatm="E3";
    $altitude=800e2;
    $bx=19.234;
    $bz=-17.068;
  }
  case "and" {
    $modatm="19";
    $altitude=4200e2;
    $bx=19.6922;
    $bz=-14.2420;
  }
  case "mpc" {
    # Marcapomacocha
    $modatm="E1";
    $altitude=4500e2;
    $bx=24.9599;
    $bz=0.4124;
  }
  case "cha" {
    # Chacaltaya
    $modatm="E2";
    $altitude=5230e2;
    $bx=23.0386;
    $bz=-3.9734;
  }
  case "cid" {
    # CIDA
    $modatm="E1";
    $altitude=3600e2;
    $bx=26.8464;
    $bz=+18.1604;
  }
  case "mor" {
    # Mordor
    $modatm="E1";
    $altitude=4400e2;
    $bx=26.8340;
    $bz=+18.2004;
  }
  case "lsc" {
    # La Serena
    $modatm="E2";
    $altitude=28e2;
    $bx=20.29;
    $bz=-11.74;
  }
  case "mbo" {
    # Base Marambio
    $modatm="E5";
    $altitude=196e2;
    $bx=19.6571;
    $bz=-30.5809;
  }
  case "ccs" {
    #Caracas, data provided by Jose Antonio López, UCV, 10.486004N -66.894461W
    $modatm="E1";
    $altitude=900E2;
    $bx=26.7364;
    $bz=+18.6777;
  }
}#switch
  
unless ($ifixmodatm) {
    $modatm = get("Atmospheric model selection (ATMOD). Start number with 'E' to use external atmospheres module (ATMOSPHERE), examples: E30=wi,E31=sp,E32=su,E33=au)", $modatm, "$atmcrd", $modatm);
}

unless ($ifixalt) {
    while (!$altitude) {
        $altitude = get("Observation level above sea level [cm]",0,"OBSLEV", $altitude);
        if (!$altitude) { print STDERR "ERROR: Observation level is mandatory > 0\n"; }
      }
}

while (!$bx) {
    $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX", $bx);
    if (!$bx) { print STDERR "ERROR: BX is mandatory\n"; }
}

while (!$bz) {
    $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ", $bz);
    if (!$bz) { print STDERR "ERROR: BZ is mandatory\n"; }
}

if ($ifixalt && $fixalt) {
  $altitude=$fixalt;
}
if ($ifixmodatm && $fixmodatm) {
  $modatm=$fixmodatm;
}
$modatm=uc($modatm);
# just in case :)

######################################################
### You should not modify anything below this line ###
######################################################

opendir(IMD, "$direct/") or system("mkdir -p $direct");
opendir(IMD, "$direct/") or die ("ERROR: Can't open directory $direct\n");
closedir(IMD);

open ($fh, "< $file") or die ("Error: Spectra data not found ($file)\n");

if ($flat) {
  $N = 0.5 * ((sin($tMax * $pi / 180.))**2 - (sin($tMin * $pi / 180.))**2);
}
else {
  $N = (-cos($tMax * $pi / 180.) - (-cos($tMin  * $pi / 180.)));
}

$N *= (2. * $pi * $area * $time);
$g=$nshow=$a=$j0=0.;
$z=$a=$id=0;

@nuc = ("", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni");
%spc = ();

$totalShowers = 0;

print "Number of nucleus?:";
chomp ($prim=<$fh>);
for ($i=0; $i < $prim; $i++) {
# Reading spectra data from file
  print "Nucleus?: ";
  chomp ($id=<$fh>);
  if ($id==14) {
    $z = 1;
    $m = 0;
  }
  else {
    $m = int ($id / 100);
    $z = $id - $m * 100;
  }
  print "j0? (mantisa) : ";
  chomp ($m0=<$fh>);
  $m0*=1.;
  print "e0? (exponent>0) : ";
  chomp ($e0=<$fh>*-1);
  print "Gamma (>0)?: ";
  chomp ($g=<$fh>*-1);
  $a = (1.+$g);
  $j0 = $m0 * 10**$e0;
  $mass0 = $mass {$id};
  if ($rigidity) {
    $p0 = $z * $rigidity;
    $llimit = sqrt($p0**2+$mass0**2);
    if ($llimit < $userllimit) {
      $llimit = $userllimit;
    }
  }
  if ($llimit < $mass0) {
    $llimit = ($m-$z) * 0.9396 + $z * 0.9383;
#CORSIKA uses simple superposition model for nuclei
  }
  $nshow = int($N * ($j0 / $a) * (($ulimit/1000.)**$a - ($llimit/1000.)**$a)) + 1;
# normalization in TeV
  while (defined($spc {$nshow})) {
    $nshow++;
  }
  $spc {$nshow} = "$m $z $nuc[$z] $nshow";
  $totalShowers += $nshow;
#generating input files
  $fil = sprintf("%06d-%011d.run", $id, $nshow);
  open ($fi, "> $direct/$fil") or die "Can't open file $direct/$fil\n";
  printf $fi ("1
$wdir
$prj
$user
%06d
0
$nshow
$id
$g
%.4e
%.4e
$tMin
$tMax
-180
180
$altitude
$modatm
$bx
$bz
F
F
T
F
F", $id, $llimit, $ulimit);
  close($fi);
}

#generating injection file
$file = "$direct/inject";
$altitude /=100.;
$rig = " and using rigidity cutoff.";
unless ($rigidity) {
  $rig = " and rigidity cutoff was not used.";
}
$vol=", using volumetric detector for flux calculations";
if ($flat) {
  $vol=", using flat detector for flux calculations";
}
$hig=", standard energy cuts";
if ($highsec) {
	$hig=", high energy cuts";
}
open ($fh, "> $file") or die "Can't open file $direct/$file\n";
print $fh "Flux time: $time s ($totalShowers showers, $userllimit<E<$ulimit, $tMin<q<$tMax at site $site (h=$altitude, atm=$modatm)$vol$hig$rig\n";
foreach $z (sort {$b <=> $a} keys %spc) {
  print $fh "$spc{$z}  ->  _______  \n";
}
close($fh);
print"\n";
system ("clear; echo 'Fluxes'; cat $file");
