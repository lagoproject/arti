#!/usr/bin/perl -w
# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   genEspectra.pl                                             */
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
$VERSION="v3r0";

# History log
# v3r0 Wed Oct  9 14:36:39 COT 2013
# Now calculates rigidities using particle momentum instead of particle energy
# Include masses calculated using mass.pl, included in crktools since this version.
#
# v2r4 Tue Aug  6 15:43:52 COT 2013
# More sites added. Now ctarain is deprecated. All the stuff in rain.pl, option -z
#
# v2r3 Fri Jun 14 09:45:11 COT 2013
# Two new sites added: ber (Paramo de Berlin), and bga (Bucaramanga)
# Change in maxtheta: 88 deg -> 90 deg
#
# v2r2 (Fri May 10 09:39:30 COT 2013)
# Major realease of full package CrkTools
# v2r0 (Sat Abr 13 07:14:58 COT 2013)
# OAR Cluster compatibility added, -l option

# v1r9 (Sat Mar 23 10:23:13 ART 2013)
# New option -s: enables cherenkov output oriented to CTA studies

# v1r8 (Thu Jan 24 22:19:15 ART 2013)
# More fun added. Now includes -h help and usage 

# v1r0 (Mon Jan 30 10:02:14 ART 2012)
# new version based on v1r0. Include some extra questions for 
# common options
# include -f option to ask for a different spectra file (default: genspectra.dat)

# defaults
use Switch;
$pi=3.1415927;

$site="unk";

$time=3600;
$tp=0;
$prj="brc";
$pp=0;
$file = "genEspectra.dat";
$area=1e4; #cm2
$wdir="/work/asoreyh/corsika-73500/run";
$wp=0;
$user="";
$cluster=0;
$clsname="";
$highsec=0;
$batch=1;
$flat=1;
$fixalt=0.;
$ifixalt=0;

# masses from stderr output of mass.pl
@mid = (0, 14, 402, 703, 904, 1105, 1206, 1407, 1608, 1909, 2010, 2311, 2412, 2713, 2814, 3115, 3216, 3517, 3919, 4018, 4020, 4521, 4822, 5123, 5224, 5525, 5626);
@mms = (0., 0.938272, 3.73338244805557, 6.53478032991106, 8.39429044902688, 10.2536061929541, 11.1787903246739, 13.045071978869, 14.898326507629, 17.6899146520668, 18.6173579550734, 21.4080199431823, 22.3362803688324, 25.1263356296296, 26.0553153433303, 28.8449660324983, 29.7745989328225, 32.5639816988633, 36.2834316370329, 37.2107457840596, 37.2142385732562, 41.8605295331555, 44.6483661801865, 47.4401999906342, 48.3681334024753, 51.1598095147594, 52.0885229269484);
%mass = ();
for ($i=0; $i<@mid; $i++) {
  $mass{$mid[$i]} = $mms[$i];
}

sub get {
  my $question = $_[0];
  my $default = $_[1];
  my $param = $_[2];
  if ($batch) {print "$question?\n<$param $default>: ";}
  chomp (my $tmp = <>);
  if ($tmp eq "") {$tmp=$default;}
  return $tmp;
}
$help="
genspectra.pl $VERSION

A simple meta script to generate input files (through rain.pl) 
for a complete set of nuclei to define the comple spectra
Read spectra data from genspectra.dat
(C) 2013 - H. Asorey
Usage: ./genspectra.pl options
Options:
 -f <file>             Use file to calculate nuclei spectra, asuming a flux of the
                       form: j(E) = j0 * E^(-gamma), where j0=a0 x 10^-e0.
                       Format (See genspectra.dat):
                          first line: number of nuclei to process. Then, for each 
                          nuclei 4 lines should be included:
                            1) corsika particle id
                            2) a0 for this nuclei
                            3) e0 for this nuclei
                            4) gamma for this nuclei 
 -u <user name>        For CORSIKA simulation
 -w <working dir>      Where corsika run files are located
 -p <project name>     name of the project
 -t <time in sec>      Flux time
 -k <altitude>         Fix altitude even for predefined sites
 -s <site>             Predefined sites parameters (sac|hess|sic|brc|cha)
 -y                    Enable volumetric detector for flux calculations (Default: flat)
 -l <cluster username> Enable OAR cluster compatibility (UIS style), use -l \$USER 
                       (and override -u)
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
    $wp++;
    shift;
  }
  if (/-t$/i) {
    $time = $ARGV[0];
    $tp++;
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
  if (/-p$/i) {
    $prj = "$ARGV[0]";
    $pp++;
    shift;
  }
  if (/-a$/i) {
    $highsec++;
  }
  if (/-y$/i) {
    $flat=0;
  }
  if (/-l$/i) {
    $clsname = "$ARGV[0]";
    $cluster++;
    shift;
  }
  if (/-\?$/i) {
    print "$help";
    exit;
  }
}

# Asking for options

unless ($tp && $wp && $pp) {
  print STDERR "\n### Project parameters ###\n\n";
}
unless ($pp) {
  $prj=get("Project name",$prj,"");
}
unless ($wp) {
  $wdir=get("Project name",$wdir,"");
}
unless ($tp) {
  $time=get("Flux time [s]",$time,"");
}

$direct="$wdir/$prj";
$home = $wdir;
if ($cluster) {
  $wdir="/opt/corsika-73500/run";
  $user=$clsname;
  $home = "/home/$user";
  $direct="$home/$prj";
}

$atmcrd = "ATMOSPHERE";

print STDERR "\n### Shower parameters ###\n\n";
$tMin = get("Low edge of zenith angle (THETAP) [deg]", 0, "THETPR(1)");
$tMax = get("High edge of zenith angle (THETAP) [deg]", 90, "THETPR(2)");
$llimit = get("Lower limit of the primary particle energy (ERANGE) [GeV]", 5e0, "LLIMIT");
$ulimit = get("Upper limit of the primary particle energy (ERANGE) [GeV]", 1e6, "ULIMIT");
print STDERR "\n### Site parameters ###\n\n";
$rigidity = get("Use rigidity cutoff? (0=no, Rigidity value=yes [GV])",5.,"");
$userllimit=$llimit;

switch ($site) {
   case "hess" {
      $modatm=get("Atmospheric model selection ($site)", "E10", "$atmcrd");
      $altitude=1800e2;
      $bx=12.5;
      $bz=-25.9;
  }
  case "sac" {
    $modatm=get("Atmospheric model selection (E30=wi,E31=sp,E32=su,E33=au)", "E32", "$atmcrd");
    $altitude=3700e2;
    $bx=20.94;
    $bz=-8.91;
  }
  case "etn" {
    $modatm=get("Atmospheric model selection ", "E2", "$atmcrd");
    $altitude=3000e2;
    $bx=27.7623;
    $bz=36.0667;
  }
  case "ber" {
    $modatm="E1"; #get("Atmospheric model selection ", "E1", "$atmcrd");
    $altitude=3450e2;
    $bx=26.9814;
    $bz=17.1054;
  }
  case "lim" {
    $modatm="E2"; #get("Atmospheric model selection ", "E1", "$atmcrd");
    $altitude=168e2;
    $bx=25.28;
    $bz=-0.046;
  }
  case "bga" {
    $modatm="E1"; #get("Atmospheric model selection ", "E1", "$atmcrd");
    $altitude=950e2;
    $bx=27.0263;
    $bz=17.1760;
  }
  case "mge" {
    $modatm=get("Atmospheric model selection ", "19", "$atmcrd");
    $altitude=1400e2;
    $bx=20.4367;
    $bz=-11.8217;
  }
  case "and" {
    $modatm=get("Atmospheric model selection ", "19", "$atmcrd");
    $altitude=5800e2;
    $bx=19.6922;
    $bz=-14.2420;
  }
  case "mpc" { # Marcapomacocha
    $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
    $altitude=4500e2;
    $bx=24.9599;
    $bz=0.4124;
  }
  case "cha" { # Chacaltaya
     $modatm=get("Atmospheric model selection ", "E2", "$atmcrd");
     $altitude=5230e2;
     $bx=23.0386;
     $bz=-3.9734;
  }
  case "cid" { # CIDA
     $modatm="E1"; #get("Atmospheric model selection ", "E1", "$atmcrd");
     $altitude=3600e2;
     $bx=26.8464;
     $bz=+18.1604;
  }
  case "mor" { # Mordor
     $modatm="E1"; #get("Atmospheric model selection ", "E1", "$atmcrd");
     $altitude=4400e2;
     $bx=26.8340;
     $bz=+18.2004;
  }
  case "ccs" { #Caracas, data provided by Jose Antonio López, UCV, 10.486004N -66.894461W
     $modatm="E1"; #get("Atmospheric model selection ", "E1", "$atmcrd");
     $altitude=900E2;
     $bx=26.7364;
     $bz=+18.6777;
  }
  else {
    $modatm = get("Atmospheric model selection. Start number with 'E' to use external atmospheres module", 19, "ATMOD");
    unless ($ifixalt) {
      $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
      while (!$altitude) {
        print STDERR "ERROR: Observation level is mandatory\n";
        $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
      }
    }
    $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX");
    while (!$bx) {
      print STDERR "ERROR: BX is mandatory\n";
      $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX");
    }
    $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ");
    while (!$bz) {
      print STDERR "ERROR: BZ is mandatory\n";
      $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ");
    }
  }
}
if ($ifixalt && $fixalt) {
  $altitude=$fixalt;
}
$modatm=uc($modatm); # just in case :)

######################################################
### You should not modify anything below this line ###
######################################################

opendir(IMD, "$direct/") or system("mkdir $direct");
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

print "Number of nucleus?:"; chomp ($prim=<$fh>);
for ($i=0; $i < $prim; $i++) {
  # Reading spectra data from file 
  print "Nucleus?: "; chomp ($id=<$fh>);
  if ($id==14) {
    $z = 1;
    $m = 0;
  }
  else {
    $m = int ($id / 100);
    $z = $id - $m * 100;
  }
  print "j0? (mantisa) : ";
  chomp ($m0=<$fh>); $m0*=1.;
  print "e0? (exponent>0) : "; 
  chomp ($e0=<$fh>*-1); 
  print "Gamma (>0)?: "; 
  chomp ($g=<$fh>*-1); 
  $a = (1.+$g);
  $j0 = $m0 * 10**$e0;
  $mass0 = $mass{$id};
  if ($rigidity) {
    $p0 = $z * $rigidity;
    $llimit = sqrt($p0**2+$mass0**2);
    if ($llimit < $userllimit) {
      $llimit = $userllimit;
    }
  }
  if ($llimit < $mass0) {
    $llimit = ($m-$z) * 0.9396 + $z * 0.9383; #CORSIKA uses simple superposition model for nuclei
  }
  $nshow = ($N * ($j0 / ($a+1.)) * (($ulimit/1000.)**($a+1.) - ($llimit/1000.)**($a+1))); # normalization in TeV
  $nshow2=int($nshow)+1;
  while (defined($spc{$nshow2})) {
    $nshow2++;
  }
  $spc{$nshow2} = "$m $z $nuc[$z] $nshow";
  $totalShowers += $nshow;
}
#generating injection file 
$file = "$direct/inject";
$altitude /=100.;
$rig = ", and using rigidity cutoff.";
unless ($rigidity) {
  $rig = ", and rigidity cutoff was not used.";
}
$vol=", using volumetric detector for flux calculations";
if ($flat) {
  $vol=", using flat detector for flux calculations";
}
open ($fh, "> $file") or die "Can't open file $direct/$file\n";
print $fh "Flux time: $time s ($totalShowers showers, $userllimit<E<$ulimit, $tMin<q<$tMax at site $site (h=$altitude, atm=$modatm)$vol$rig\n";
foreach $z (sort {$b <=> $a} keys %spc) {
  print $fh "$spc{$z}  ->  _______  \n";
}
close($fh);
print"\n";
system ("clear; echo 'Fluxes'; cat $file");
