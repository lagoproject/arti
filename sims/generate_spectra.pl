#!/usr/bin/perl -w
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   generate_spectrum.pl                                       */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /************************************************************************/
# /* Comments: Simple meta script to generate input files from spectrum   */
# /*           for all nuclei (data is read from genEspectra.dat)         */
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
# official policies, either expressed or implied, of Lab DPR.
# 
# */
# /************************************************************************/
#
use strict;
use warnings;
my $VERSION="v1r9";

# defaults
my $pi=3.1415927;
my $site="unk";
my $time=0;
my $prj="";
my $file = "spectra.dat";
my $area=1e4;
my $wdir="";
my $user="";
my $cluster=0;
my $clsname="";
my $grid=0;
my $highsec=0;
my $ecut=800;
my $batch=1;
my $flat=1;
my $fixalt=0.;
my $ifixalt=0;
my $fixmodatm=0;
my $ifixmodatm=0;
my $tMin = 0;
my $tMax = 0;
my $llimit = 0.;
my $ulimit = 0.;
my $rigidity = 0.;
my $usedefaults=0;
my $gensite = 0;
my $modatm="";
my $altitude=0.;
my $bx=0.;
my $bz=0.;


# masses from stderr output of mass.pl
my @mid = (0, 14, 402, 703, 904, 1105, 1206, 1407, 1608, 1909, 2010, 2311, 2412, 2713, 2814, 3115, 3216, 3517, 3919, 4018, 4020, 4521, 4822, 5123, 5224, 5525, 5626);
my @mms = (0., 0.938272, 3.73338244805557, 6.53478032991106, 8.39429044902688, 10.2536061929541, 11.1787903246739, 13.045071978869, 14.898326507629, 17.6899146520668, 18.6173579550734, 21.4080199431823, 22.3362803688324, 25.1263356296296, 26.0553153433303, 28.8449660324983, 29.7745989328225, 32.5639816988633, 36.2834316370329, 37.2107457840596, 37.2142385732562, 41.8605295331555, 44.6483661801865, 47.4401999906342, 48.3681334024753, 51.1598095147594, 52.0885229269484);
my %mass = ();
for (my $i=0; $i<@mid; $i++) {
  $mass {$mid[$i]} = $mms[$i];
}

sub get {
    my $question = $_[0];
    my $default = $_[1];
    my $param = $_[2];
    my $var = $_[3];
    unless ($var || $usedefaults){
        print "$question?\n<$param $default>: " if ($batch != 0);
        chomp (my $tmp = <STDIN>);
        $var = $tmp;
    }
    $var = $default if (!defined $var);
    print "Fixed param: $param $var\n";
    return $var;
}

my $help="

$0 $VERSION

A simple meta script to generate input files (through rain.pl)
for a complete set of nuclei to define the complete spectra
Read spectra data from file spectra.dat unless other provided 
(C) 2022 - H. Asorey

Usage: $0 options

Mandatory:
  -w <working dir>      Where CORSIKA run files are located
  -p <project name>     name of the project 
Recommended:
  -f <file>             Use file to calculate nuclei spectra, assuming a flux of the form:
                             j(E) = j0 * E^(-gamma), where j0=a0 x 10^-e0.
                        Format (See genspectra.dat):
                          - First line: number of nuclei to process. 
                          - Then, for each nuclei 4 lines should be included:
                             1) CORSIKA particle id
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
    if (/-l$/i) {
        $clsname = "$ARGV[0]";
        $cluster++;
        shift;
    }
    $grid++ if (/-g$/i);
    $usedefaults++ if (/-x$/i);
    $flat = 0 if (/-y$/i);
    if (/-\?$/i) {
        print "$help";
        exit;
    }
}

# Asking for options
print STDERR "\n### GENERATE SPECTRA ###\n\n\n";
$file=get("Spectra file","","(file)",$file);
print STDERR "\n### Project parameters ###\n\n" unless ($time && $wdir && $prj);
$prj=get("Project name","","(prj)",$prj);
$wdir=get("Project parent dir","","(wdir)",$wdir);
$time=get("Flux time [s] ",3600,"(time)", $time);
my $direct="$wdir/$prj";
my $home = $wdir;

$user=get("User ORCID or local user","","(user)",$user);
if ($cluster != 0) {
    $wdir="/opt/corsika-73500/run";
    $user=$clsname;
    $home = "/home/$user";
    $direct="$home/$prj";
}

print STDERR "\n### Shower parameters ###\n\n" unless ($usedefaults != 0);
$tMin = get("Low edge of zenith angle (THETAP) [deg]", 0, "THETPR(1)", $tMin);
$tMax = get("High edge of zenith angle (THETAP) [deg]", 90, "THETPR(2)", $tMax);
$llimit = get("Lower limit of the primary particle energy (ERANGE) [GeV]", 5e0, "LLIMIT", $llimit);
$ulimit = get("Upper limit of the primary particle energy (ERANGE) [GeV]", 1e6, "ULIMIT", $ulimit);
print STDERR "\n### Site parameters ###\n\n" unless ($rigidity && $modatm);
$rigidity = get("Use rigidity cutoff? (0=no, Rigidity value=yes [GV])",5.,"", $rigidity);
my $userllimit=$llimit;
#all predefined sites seems to be ATMOSPHERE as default mode
my $atmcrd = "ATMOSPHERE";

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

my $fh;
open ($fh, "< $file") or die ("Error: Spectra data not found ($file)\n");

my $N = 0.;
if ($flat > 0) {
  $N = 0.5 * ((sin($tMax * $pi / 180.))**2 - (sin($tMin * $pi / 180.))**2);
}
else {
  $N = (-cos($tMax * $pi / 180.) - (-cos($tMin  * $pi / 180.)));
}
$N *= (2. * $pi * $area * $time);

my $gamma = 0.;
my $N_show= 0.;
my $j0 = 0.;
my $A = 0.;
my $alpha = 0.;
my $mantissa = 0.;
my $exponent = 0.;
my $Z = 0;
my $id = 0;
my $N_prim = 0;
my @nuc = ("", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni");
my $mass_0 = 0.;
my %spc = ();
my $totalShowers = 0;
print "Number of nucleus?:";
chomp ($N_prim=<$fh>);
for (my $i = 0; $i < $N_prim; $i++) {
# Reading spectra data from file
  print "Nucleus?: ";
  chomp ($id = <$fh>);
  if ($id == 14) {
    $Z = 1;
    $A = 0;
  }
  else {
    $A = int ($id / 100);
    $Z = $id - $A * 100;
  }
  print "j0? (mantissa) : ";
  chomp ($mantissa = <$fh>);
  $mantissa *= 1.;
  print "e0? (exponent>0) : ";
  chomp ($exponent=(<$fh>) * -1);
  print "Gamma (>0)?: ";
  chomp ($gamma=(<$fh>) * -1);
  $alpha = (1. + $gamma);
  $j0 = $mantissa * 10**$exponent;
  $mass_0 = $mass {$id};
  if ($rigidity > 0) {
    my $p0 = $Z * $rigidity;
    $llimit = sqrt($p0**2 + $mass_0**2);
    $llimit = $userllimit if ($llimit < $userllimit);
  }
  #CORSIKA uses simple superposition model for nuclei
  $llimit = ($A - $Z) * 0.9396 + $Z * 0.9383 if ($llimit < $mass_0);
  # and finally...
  my $E_reference = 1000.;  # 1 TeV
  $N_show = int($N * ($j0 / $alpha) * (($ulimit / $E_reference)**$alpha - ($llimit / $E_reference)**$alpha));
  $N_show = 1 if ($N_show == 0);
  while (defined(${$N_show})) {
    $N_show++;
  }
  $spc{$N_show} = "$A $Z $nuc[$Z] $mass{$id} $llimit $N_show";
  $totalShowers += $N_show;
  #generating input files
  my $filename = sprintf("%06d-%011d.run", $id, $N_show);
  my $fi;
  open ($fi, "> $direct/$filename") or die "Can't open file $direct/$filename\n";
  printf $fi ("1
$wdir
$prj
$user
%06d
0
$N_show
$id
$gamma
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

#generating inject file
$file = "$direct/inject";
$altitude /= 100.;
# building descriptors
my $rig = " and using rigidity cutoff.";
$rig = " and rigidity cutoff was not used." if ($rigidity == 0);
my $vol=", using volumetric detector for flux calculations";
$vol = ", using flat detector for flux calculations" if ($flat != 0);
my $hig=", standard energy cuts";
$hig = ", high energy cuts at $ecut GeV" if ($highsec > 0);

open ($fh, "> $file") or die "Can't open file $direct/$file\n";
print $fh "Flux time: $time s ($totalShowers showers, $userllimit<E<$ulimit, $tMin<q<$tMax at site $site (h=$altitude, atm=$modatm)yy$vol$hig$rig\n";
print $fh "$spc{$_}\n" foreach (sort {$b <=> $alpha} keys %spc);
close($fh);
print"\n";
system ("echo; echo; echo 'Fluxes'; cat $file");