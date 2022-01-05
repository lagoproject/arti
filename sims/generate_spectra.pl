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
$VERSION="v1r2";

# defaults
# use Switch;
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
$ecut=800;
$batch=1;
$flat=1;
$fixalt=0.;
$ifixalt=0;
#ajrm vars
$modatm="";
$fixmodatm=0;
$ifixmodatm=0;
$tMin = 0;
$tMax = 0;
$llimit = 0.;
$ulimit = 0.;
$rigidity = 0.;
$usedefaults=0;
$gensite = 0; 
my $modatm="";
my $altitude=0.;
my $bx=0.;
my $bz=0.;


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
  -s <site>             Choice predefined site for simulation (Default: unknown)
                          - Predefined sites: check the code)
                          - Predefined parameters: altitude, BX, BZ, and Atmospheric Model.
  -k <altitude>         Fix altitude even for predefined sites (It cannot be 0)
  -c <Atmosph. Model>   Fix Atmospheric Model even for predefined sites. 
                           (Note: Start number with 'E' to use external atmospheres module)
  -y                    Enable volumetric detector for flux calculations (Default: flat)
  -a <HE ecuts (GeV)>   Enables and set high energy cuts for ECUTS
  -b <rigidity cutoff>  0 = disabled; value in GV = enabled (Default: 5.)
  -m                    Low edge of zenith angle (THETAP) [deg] (Default: 0)
  -n                    High edge of zenith angle (THETAP) [deg] (Default: 90)
  -r                    Lower limit of the primary particle energy (ERANGE) [GeV] (Default: 5e0) 
  -i                    Upper limit of the primary particle energy (ERANGE) [GeV] (Default: 1e6)
Fix parameters for generic sites:
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
    $ecut = $ARGV[0]; 
    shift;
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
  if (/-i$/i) {
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

# New set of LAGO sites in preparation for EOSC challenge. 
# For pre-challenge we will simulate some of this new sites. 
# HA - Apr 08, 2021
# switch case replaced by if-elsif-else

if ($site eq "sawb") {
    $modatm="E5";
    $altitude=20000;
    $bx=19.366;
    $bz=-30.222;
} elsif ($site eq "mapi") {
    $modatm="E5";
    $altitude=1000;
    $bx=19.309;
    $bz=-28.693;
} elsif ($site eq "brc") {
    $modatm="E3";
    $altitude=86500;
    $bx=18.952;
    $bz=-17.05;
} elsif ($site eq "bue") {
    $modatm="E2";
    $altitude=1000;
    $bx=17.09;
    $bz=-14.673;
} elsif ($site eq "kna") {
    $modatm="E2";
    $altitude=34700;
    $bx=19.56;
    $bz=-13.333;
} elsif ($site eq "lsc") {
    $modatm="E2";
    $altitude=2800;
    $bx=19.975;
    $bz=-11.826;
} elsif ($site eq "tuc") {
    $modatm="E2";
    $altitude=43000;
    $bx=19.487;
    $bz=-10.647;
} elsif ($site eq "asu") {
    $modatm="E1";
    $altitude=13600;
    $bx=18.233;
    $bz=-11.73;
} elsif ($site eq "sao") {
    $modatm="E1";
    $altitude=76000;
    $bx=16.484;
    $bz=-14.48;
} elsif ($site eq "vcp") {
    $modatm="E1";
    $altitude=64000;
    $bx=16.751;
    $bz=-14.104;
} elsif ($site eq "lpb") {
    $modatm="E2";
    $altitude=363000;
    $bx=22.362;
    $bz=-4.708;
} elsif ($site eq "cha") {
    $modatm="E2";
    $altitude=523000;
    $bx=22.38;
    $bz=-4.62;
} elsif ($site eq "cuz") {
    $modatm="E1";
    $altitude=340000;
    $bx=23.676;
    $bz=-2.02;
} elsif ($site eq "lim") {
    $modatm="E1";
    $altitude=16800;
    $bx=24.723;
    $bz=-0.476;
} elsif ($site eq "cpv") {
    $modatm="E1";
    $altitude=55000;
    $bx=21.174;
    $bz=-12.612;
} elsif ($site eq "serb") {
    $modatm="E1";
    $altitude=275000;
    $bx=26.577;
    $bz=8.499;
} elsif ($site eq "quie") {
    $modatm="E1";
    $altitude=285000;
    $bx=26.717;
    $bz=9.971;
} elsif ($site eq "bga") {
    $modatm="E1";
    $altitude=95000;
    $bx=26.793;
    $bz=16.055;
} elsif ($site eq "pam") {
    $modatm="E1";
    $altitude=234200;
    $bx=26.743;
    $bz=15.955;
} elsif ($site eq "gua") {
    $modatm="E1";
    $altitude=149000;
    $bx=27.532;
    $bz=24.932;
} elsif ($site eq "tac") {
    $modatm="E1";
    $altitude=406000;
    $bx=27.53;
    $bz=25.353;
} elsif ($site eq "chia") {
    $modatm="E2";
    $altitude=52200;
    $bx=27.405;
    $bz=27.024;
} elsif ($site eq "chi") {
    $modatm="E1";
    $altitude=500000;
    $bx=26.56;
    $bz=8.758;
} elsif ($site eq "sng") {
    $modatm="E2";
    $altitude=455000;
    $bx=27.358;
    $bz=28.038;
} elsif ($site eq "and") {
    $modatm="E2";
    $altitude=420000;
    $bx=19.658;
    $bz=-11.951;
} elsif ($site eq "mge") {
    $modatm="E2";
    $altitude=145000;
    $bx=18.987;
    $bz=-14.326;
} elsif ($site eq "ber") {
    $modatm="E1";
    $altitude=345000;
    $bx=26.751;
    $bz=16.029;
} elsif ($site eq "sac") {
    $modatm="E2";
    $altitude=482000;
    $bx=20.06;
    $bz=-9.616;
} elsif ($site eq "cop") {
    $modatm="E2";
    $altitude=200000;
    $bx=19.04;
    $bz=-15.493;
} elsif ($site eq "sgd") {
    $modatm="E2";
    $altitude=25000;
    $bx=18.108;
    $bz=-16.891;
} elsif ($site eq "casp") {
    $modatm="E2";
    $altitude=260000;
    $bx=19.473;
    $bz=-12.436;
} elsif ($site eq "ppet") {
    $modatm="E2";
    $altitude=350000;
    $bx=19.139;
    $bz=-14.27;
} elsif ($site eq "mad") {
    $modatm="E2";
    $altitude=70000;
    $bx=25.647;
    $bz=36.933;
} elsif ($site eq "truj") {
    $modatm="E2";
    $altitude=56000;
    $bx=26.223;
    $bz=35.844;
} elsif ($site eq "pozn") {
    $modatm="E2";
    $altitude=10000;
    $bx=18.598;
    $bz=46.45;
} elsif ($site eq "juli") {
    $modatm="E2";
    $altitude=10000;
    $bx=19.676;
    $bz=44.928;
} elsif ($site eq "sudb") {
    $modatm="E2";
    $altitude=210000;
    $bx=17.037;
    $bz=51.991;
} elsif ($site eq "viri") {
    $modatm="E2";
    $altitude=285000;
    $bx=19.061;
    $bz=-16.289;
} elsif ($site eq "ima") {
    $modatm="E1";
    $altitude=460000;
    $bx=22.969;
    $bz=-3.79;
} elsif ($site eq "ata") {
    $modatm="E1";
    $altitude=510500;
    $bx=20.638;
    $bz=-8.598;
} elsif ($site eq "gen") {
    $gensite=1;
} elsif ($site eq "air") {
    $gensite=1;
} elsif ($site eq "unk") {
    $gensite=1;
}

unless ($ifixmodatm) {
    $modatm = get("Atmospheric model selection (ATMOD). Start number with 'E' to use external atmospheres module (ATMOSPHERE), examples: E30=wi,E31=sp,E32=su,E33=au)", $modatm, "$atmcrd", $modatm);
}

unless ($ifixalt) {
    while (!$altitude) {
        $altitude = get("Observation level above sea level [cm]",0,"OBSLEV", $altitude);
		if (!$altitude) { die "ERROR: Observation level is mandatory > 0\n"; }
      }
}

while (!$bx) {
    $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX", $bx);
	if (!$bx) { die "ERROR: BX is mandatory\n"; }
}

while (!$bz) {
    $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ", $bz);
	if (!$bz) { die "ERROR: BZ is mandatory\n"; }
}

if ($ifixalt && $fixalt) {
  $altitude=$fixalt;
}
if ($ifixmodatm && $fixmodatm) {
  $modatm=$fixmodatm;
}

if ($gensite) { 
	unless ($modatm ne "" && $bx && $bz && $altitude) {
		die "ERROR: For generic sites, altitude (-k), atmospheric model (-c) and geomagnetic coordinates (-o, -q) are mandatory\n"; 
	}
}
# $modatm=uc($modatm);
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
F
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
	$hig=", high energy cuts at $ecut GeV";
}
open ($fh, "> $file") or die "Can't open file $direct/$file\n";
print $fh "Flux time: $time s ($totalShowers showers, $userllimit<E<$ulimit, $tMin<q<$tMax at site $site (h=$altitude, atm=$modatm)$vol$hig$rig\n";
foreach $z (sort {$b <=> $a} keys %spc) {
  print $fh "$spc{$z}  ->  _______  \n";
}
close($fh);
print"\n";
system ("echo; echo; echo 'Fluxes'; cat $file");
