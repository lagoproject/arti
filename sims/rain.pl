#!/usr/bin/perl -w
# /************************************************************************/
# /*                                                                      */
# /* Package:  ARTI                                                       */
# /* Module:   rain.pl                                                    */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Main CORSIKA imput generator files and simulation launcher */
# /*           for CORSIKA.                                               */
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

$VERSION="v1r0";

use Switch;
use Cwd;

$tmp = "";
$batch = 0;
$runmode = 0;
$wdir = "x";
$crk_ver = "74005";
$heim = "QGSII";
$debug = 0;
$help = 0;
$cluster = 0;
$clsname = "";
$highsec = 0;
$curvout = "";
$halley = 0;
$ithin = $ithinh = $ithine = 0;
$thin = $thine = $thinh = " \n";
$efrcthn = $wmax = $rmax = $thinrath = $thinrate = $weitrath = $weitrate = 0.;
$site="";
$monoe = 0.;
$monoq = 0;
$monot = 0.;
$monop = 0;
$cherenkov = 0;
$grid = 0;

sub get {
  my $question = $_[0];
  my $default = $_[1];
  my $param = $_[2];
  unless ($batch) {
    print "$question?\n<$param $default>: ";
  }
  chomp (my $tmp = <>);
  if ($tmp eq "") {
    $tmp=$default;
  }
  return $tmp;
}

while ($_ = $ARGV[0]) {
  last unless /^-/;
  shift;
  if (/-b$/i) {
    $batch++;
  }
  if (/-i$/i) {
    $halley++;
  }
  if (/-a$/i) {
    $highsec++;
    $curvout="CURVOUT     T";
  }
  if (/-$/i) {
    $highsec++;
    $curvout="CURVOUT     T";
  }
  if (/-l$/i) {
    $cluster++;
    $clsname = $ARGV[0];
    shift;
  }
  if (/-t$/i) {
    $ithin=1;
    $efrcthn = $ARGV[0];
    shift;
    $wmax = $ARGV[0];
    shift;
    $rmax = $ARGV[0];
    shift;
  }
  if (/-s$/i) {
    $site = $ARGV[0];
    shift;
  }
  if (/-m$/i) {
    $monoe = $ARGV[0];
    shift;
  }
  if (/-p$/i) {
    $monop = $ARGV[0];
    shift;
  }
  if (/-q$/i) {
    $monoq = 1;
    $monot = $ARGV[0];
    shift;
  }
  if (/-th$/i) {
    $ithinh=1;
    $thinrath = $ARGV[0];
    shift;
    $weitrath = $ARGV[0];
    shift;
  }
  if (/-te$/i) {
    $ithine=1;
    $thinrate = $ARGV[0];
    shift;
    $weitrate = $ARGV[0];
    shift;
  }
  if (/-\?$/i) {
    $help++;
  }
  if (/-d$/i) {
    $debug++;
  }
  if (/-g$/i) {
    $grid++;
  }
  if (/-\?$/i) {
    $help++;
  }
  if (/-r$/i) {
    $runmode++;
    $wdir = $ARGV[0];
    shift;
  }
  if (/-v$/i) {
    $crk_ver = $ARGV[0];
    shift;
  }
  if (/-z$/i) {
    $cherenkov = 1;
  }
  if (/-h$/i) {
    $heim = $ARGV[0];
    shift;
  }
}


$package="corsika".$crk_ver."Linux_".$heim."_gheisha";
if ($ithin) {
  $package= $package . "_thin";
}

$usage="
       $0 $VERSION\n
       A simple input files generator for CORSIKA
       (C) 2013 - H. Asorey - asoreyh\@cab.cnea.gov.ar
       Usage: See $0 -?  - If you enjoy it, please send me an email\n
       $0\n
       -b                                  Activates batch mode
       -i                                  Halley mode
       -d                                  Debug mode: only shows what it should do. Don't start simulation
       -r  <working directory>             Specify where corsika bin files are located
       -v  <version>                       Corsika version number
       -h  <high energy interaction model> High energy interaction model used for compilation of CORSIKA (EPOS|QGSII|SIBYLL)
       -l  <cluster user name>             Enables OAR cluster compatibility (UIS style), use -l \$USER
       -t  <EFRCTHN> <WMAX> <RMAX>         Enables THIN Mode (see manual for pg 62 for values)
       -th <THINRAT> <WEITRAT>             If THIN Mode, select different thining levels for Hadronic (THINH) ...
       -te <THINRAT> <WEITRAT>             ... and electromagnetic particles (THINEM)
       -a                                  Enables high energy cuts for ECUTS - for now, hardcoded
       -z                                  Enables CHERENKOV mode
       -g                                  Enables GRID mode
       -s <site>                           Choice site for simulation (some predefined sites: hess|sac|etn|ber|bga|lim|glr|mch|mge|and|mpc|cha|cid|mor|ccs)
       -m <energy>                         Defines energy (in GeV) for monoenergetic showers (CHERENKOV)
       -q <theta>                          Defines zenith angle (in degs) for fixed angle showers (CHERENKOV)
       -p <prmpar>                         Defines primary particle (see table 4 pg 87) (CHERENKOV)

       \n";


if ($help) {
  die "$usage\n";
}

if ($debug) {
  print STDERR "\nWARNING! You are running in DEBUG mode. I'll only show what I should do\n\n";
}

if ($cherenkov) {
  print STDERR "\nWARNING! CHERENKOV mode is enabled.\n\n";
}

unless ($site eq "") {
  print STDERR "\nWARNING! Site selected for simulation: $site.\n\n";
}

if ($runmode) {
  if ($wdir eq "x") {
    die "\n\nERROR: You selected run mode without indicate working directory.\n$usage\n";
  }
}

if (($ithine || $ithinh) && !($ithin)) {
  die "\n\nERROR: -th or -te options needs -t option.\n$usage\n";
}

if ($ithin) {
  unless ($wmax && $rmax && $efrcthn) {
    die "\n\nERROR: You have to specify three paramters for THIN (-t).\n$usage\n";
  }
  $thin="THIN        $efrcthn  $wmax  $rmax\n";
}


if ($ithine && $ithinh) {
  die "\n\nERROR: You can't specify both THINH and THINEM at the same time.\n$usage\n";

}

if ($ithine) {
  unless ($thinrate && $weitrate) {
    die "\n\nERROR: You have to specify two paramters for THINE (-te).\n$usage\n";
  }
  $thine="THINEM      $thinrate $weitrate\n";
}

if ($ithinh) {
  unless ($thinrath && $weitrath) {
    die "\n\nERROR: You have to specify two paramters for THINH (-th).\n$usage\n";
  }
  $thinh="THINH       $thinrath $weitrath\n";
}

$nofruns = 1;

unless ($monoe || $monoq) {
# XXX Could be a problem with generate_spectra.pl XXX
  $nofruns=get("Number of runs", $nofruns, "RUNS");
}


if ($wdir eq "x") {
  $wdirtmp=getcwd() . "/run";
}
else {
  $wdirtmp=$wdir
}
if ($batch) {
  $wdirtmp=get("Working directory (where CORSIKA run files are located)", "$wdirtmp", "WDIR");
}
else {
  $wdir=get("Working directory (where CORSIKA run files are located)", "$wdirtmp", "WDIR");
}

$defprj="sims";
if (int($monoe) || $monoq) {
  $defprj="mono".$site;
}
$prj=get("Project name (Results will go into $wdir/<project> dir)", "$defprj", "DIRECT");

$user=get("User name", "LAGO", "USER");
if ($cluster) {
  $user=$clsname;
}

$bin=$wdir."/".$package;

$direct="$wdir/$prj";
$home = $wdir;
if ($cluster) {
  $wdir="/opt/corsika-73500/run";
  $bin=$wdir."/".$package;
  $home = "/home/$user";
  $direct="$home/$prj";
}
unless ($cluster or $grid) {
  unless (-e $bin) {
    die "\n\nERROR: Couldn't find corsika at $bin. Please check\n$usage\n";
  }
}
system("clear");

unless ($batch) {
  print "###################################################################\n";
  print "# I will run this script $nofruns times\n";
  print "# in $direct/\n";
  print "# Press enter to continue...\n";
  print "###################################################################\n";
  $tmp=<>;
}

for ($i=0; $i<$nofruns; $i++) {
  $index=$i+1;
  unless ($batch) {
    system("clear");
    print "###################################################################\n";
    print "# RUN $index\n";
    print "###################################################################\n";
    print "###################################################################\n";
    print "# Simulation parameters\n";
    print "###################################################################\n";
  }
  unless ($monop) {
    $runnr=get("Corsika run number", $index, "RUNNR");
    $evtnr=get("number of first shower event", 0 ,"EVTNR");
  }
  else {
    $evtnr = 1;
    $prmpar = $monop;
    if ($monop > 6) {
      $monop = 9;
# 9=hadrons
    }
    $monoename=$monoe;
    if ($monoename>999) {
      $monoename=999;
    }
    $runnr = int($monot + $monoename * 100. + $monop * 1e5);
  }
  $nshow=get("number of showers to generate", 100000,"NSHOW");
  unless ($batch) {
    system("clear");
    print "###################################################################\n";
    print "# Primary particle parameters\n";
    print "###################################################################\n";
  }

  unless ($monop) {
    $prmpar=get("Primary particle identification (see table 4 pg 87)", 14, "PRMPAR");
  }
  unless ($monoe) {
    $eslope=get("Spectral index of primary energy spectrum", -2.7, "ESLOPE");
    $elow=get("Lower limit of the primary particle energy (ERANGE) [GeV]", 1e4, "LLIMIT");
    $ehigh=get("Upper limit of the primary particle energy (ERANGE) [GeV]", 1e4, "ULIMIT");
  }
  else {
    $eslope = -2.7;
# for completitude
    $elow = $ehigh = $monoe;
  }
  unless ($monoq) {
    $tlow=get("Low edge of zenith angle (THETAP) [deg]", 0, "THETPR(1)");
    $thigh=get("High edge of zenith angle (THETAP) [deg]", 90, "THETPR(2)");
  }
  else {
    $tlow = $thigh = $monot;
  }
  $flow=get("Low edge of azimuth angle (PHIP) [deg]", -180, "PHIPR(1)");
  $fhigh=get("High edge of azimuth angle (PHIP) [deg]", 180, "PHIPR(2)");

  unless ($batch) {
    system("clear");
    print "###################################################################\n";
    print "# Observatory parameters\n";
    print "###################################################################\n";

  }
  $atmcrd="ATMOD";

  unless ($batch) {
    switch ($site) {
    case "hess" {
        $modatm=get("Atmospheric model selection ($site)", "E10", "ATMOSPHERE");
        $altitude=1800e2;
        $bx=12.5;
        $bz=-25.9;
        $arrang="-14";
      }
    case "sac" {
        $modatm=get("Atmospheric model selection (E30=wi,E31=sp,E32=su,E33=au)", "E32", "ATMOSPHERE");
        $altitude=3700e2;
        $bx=20.94;
        $bz=-8.91;
        $arrang="0";
      }
    case "etn" {
        $modatm=get("Atmospheric model selection ", "E2", "ATMOSPHERE");
        $altitude=3000e2;
        $bx=27.7623;
        $bz=36.0667;
        $arrang="0";
      }
    case "ber" {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=3450e2;
        $bx=26.9814;
        $bz=17.1054;
        $arrang="0";
      }
    case "bga" {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=950e2;
        $bx=27.0263;
        $bz=17.1760;
        $arrang="0";
      }
    case "lim" {
        $modatm=get("Atmospheric model selection ", "E2", "ATMOSPHERE");
        $altitude=168e2;
        $bx=25.28;
        $bz=-0.046;
        $arrang="0";
      }
    case "glr" {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=4276e2;
        $bx=27.0750;
        $bz=11.7728;
        $arrang="0";
      }
    case "mch" {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=2650e2;
        $bx=27.1762;
        $bz=14.6184;
        $arrang="0";
      }
    case "mge" {
        $modatm=get("Atmospheric model selection ", "19", "$atmcrd");
        $altitude=1400e2;
        $bx=20.4367;
        $bz=-11.8217;
        $arrang="0";
      }
    case "and" {
        $modatm=get("Atmospheric model selection ", "19", "$atmcrd");
        $altitude=5800e2;
        $bx=19.6922;
        $bz=-14.2420;
        $arrang="0";
      }
    case "mpc" {
# Marcapomacocha
        $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
        $altitude=4500e2;
        $bx=24.9599;
        $bz=+0.4124;
      }
    case "cha" {
# Chacaltaya
        $modatm=get("Atmospheric model selection ", "E2", "$atmcrd");
        $altitude=5230e2;
        $bx=23.0386;
        $bz=-3.9734;
      }
    case "cid" {
# CIDA
        $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
        $altitude=3600e2;
        $bx=26.8464;
        $bz=+18.1604;
      }
    case "mor" {
# Mordor
        $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
        $altitude=4400e2;
        $bx=26.8340;
        $bz=+18.2004;
      }
    case "ccs" {
#Caracas, data provided by Jose Antonio López, UCV, 10.486004N -66.894461W
        $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
        $altitude=900E2;
        $bx=26.7364;
        $bz=+18.6777;
      }
      else {
        $modatm = get("Atmospheric model selection. Start number with 'E' to use external atmospheres module", 19, "$atmcrd");
        $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
        while (!$altitude) {
          print STDERR "ERROR: Observation level is mandatory\n";
          $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
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
  }
  else {
    $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
    $modatm = get("Atmospheric model selection. Start number with 'E' to use external atmospheres module", 19, "$atmcrd");
    while (!$altitude) {
      print STDERR "ERROR: Observation level is mandatory\n";
      $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
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
  if (uc(substr($modatm,0,1)) eq "E") {
# using external atmospheres bernlhor
    $atmcrd = "ATMOSPHERE";
    $modatm =~ s/E//g;
             $modatm .= " Y";
  }

#LAGO ECUTS
# @ecuts=(0.05,0.05,1E-4,1E-4);
  @ecuts=(0.05, 0.05, 0.00005, 0.00005);
  if ($highsec) {
    @ecuts=(10., 10., 10., 10.); # using 10 GeV
	# if you want to use your own cuts, please add a site and use an if like
	# the one show below for andes:
    if ($site eq "and") {
      @ecuts=(800.,800.,800.,800.); # ecuts for ANDES
    }
  }

#true of false
  unless ($batch) {
    print "###################################################################\n";
    print "# General (T or F) parameters\n";
    print "###################################################################\n";
  }

# MUADDI. For v<7.4005, EMADDI AND NUADDI does not work, only MUADDI
  $muaddi="";
  if ($crk_ver eq "73500") {
    $muaddi=get("Get additional info for muons",'F',"MUADDI");
  } else {
    $muaddi=get("Get additional info for muons, EM and neutrinos",'F',"MUADDI, EMADDI, NUADDI");
  }

  $plotsh=get("Write add- files for track plot of secondaries",'F',"PLOTSH");
  $datbas=get("Write .dbase file",'T',"DATBAS");
  $llongi=get("Track longitudinal development of secondaries (LONGI)", 'F',"LLONGI");
  $ftabout=get("Write tab output of charged particle dev file (PAROUT)",'F',"FTABOUT");
  $s1 = int(rand(1e7));
  $s2 = int(rand(1e7));
  $s3 = int(rand(1e7));
  $s4 = int(rand(1e7));
  $cerary = "50 50 80.E2 80.E2 25 25";


##################################################################################
# END OF INTERACTIVE QUESTIONS
##################################################################################
  $cards="";
  $plotshs="";
  $direct2 = $direct;
  if ($grid) {
    $direct2 = "."
  }
  $muadditxt="MUADDI      $muaddi
EMADDI      $muaddi
NUADDI      $muaddi";
  if ($crk_ver*1.0 < 74005) {
	  $muadditxt = "";
  }

  unless ($halley) {
    $plotshs="PLOTSH      $plotsh";
  }
  if ($plotsh eq "F") {
    $plotshs="";
  }
  if ($cherenkov) {
    $cards="RUNNR         $runnr
EVTNR         $evtnr
NSHOW         $nshow

PRMPAR        $prmpar
ESLOPE        $eslope
ERANGE        $elow $ehigh
THETAP        $tlow $thigh
PHIP          $flow $fhigh
VIEWCONE      0. 0.

OBSLEV        $altitude
$atmcrd       $modatm
MAGNET        $bx $bz
ARRANG        $arrang
CERARY        $cerary

FIXHEI        0. 0
FIXCHI        0.
SEED          $s1   0   0
SEED          $s2   0   0
SEED          $s3   0   0
SEED          $s4   0   0
ECUTS         $ecuts[0] $ecuts[1] $ecuts[2] $ecuts[3]

$muadditxt
MUMULT        T
MAXPRT        0
ELMFLG        F   T
LONGI         $llongi 20.  T  T
ECTMAP        1.E3

CERSIZ        1.
CERFIL        T
CWAVLG        250.  700.

$plotshs
DIRECT        $direct2/
DATBAS        $datbas
PAROUT        T $ftabout
USER          $user
EXIT
";
  }
  else {
    $cards="RUNNR       $runnr
EVTNR       $evtnr
NSHOW       $nshow

PRMPAR      $prmpar
ESLOPE      $eslope
ERANGE      $elow $ehigh
THETAP      $tlow $thigh
PHIP        $flow $fhigh

OBSLEV      $altitude
$atmcrd     $modatm
MAGNET      $bx $bz
FIXCHI      0.
SEED        $s1   0   0
SEED        $s2   0   0
SEED        $s3   0   0
SEED        $s4   0   0
ECUTS       $ecuts[0] $ecuts[1] $ecuts[2] $ecuts[3]

$curvout
$muadditxt
MUMULT      T
MAXPRT      0
ELMFLG      F   T
LONGI       $llongi  10.  T  T
ECTMAP      1.E3

$plotshs
DIRECT      $direct2/
DATBAS      $datbas
PAROUT      T $ftabout
$thin
$thine
$thinh
USER        $user
EXIT
";
  }

  unless ($batch) {
    system ("clear");
    print "$cards";

    print "###################################################################\n";
    print "# I will run this simulation using those parameters\n";
    print "# Please check and press ENTER to continue; CTRL-C to abort\n";
    print "###################################################################\n";
    $tmp=<>;
  }

  $name=sprintf("%06d-%04d-%011d",$runnr,$prmpar,$nshow);
  $file="$direct/DAT$name.input";
  $binout=sprintf("$direct/DAT%06d",$runnr);
  $out="$direct/DAT$name.lst";
  $script = "$home/run-$prj-$name.sh";

  unless ($debug) {
    opendir(IMD, "$direct/") or system("mkdir $direct/");
    closedir(IMD);

    open ($fh ,">$file") or die "Can't open $file\n";
    print $fh "$cards";
    close($fh);
    unless ($cluster or $grid) {
      open ($fh ,">$script") or die "Can't open $script\n";
      print $fh "echo $name\n";
      print $fh "echo -n \"Starting simulation on \"; date\n";
      print $fh "cd $wdir\n";
      print $fh "$bin < $file > $out\n";
      print $fh "echo -n \"Simulation ended on \"; date\n";
      print $fh "echo \"compressing output files...\"\n";
      print $fh "bzip2 -9v $binout\n";
      print $fh "bzip2 -9v $out\n";
      print $fh "rm $script\n";
      close($fh);
      system("chmod 777 $script");
    }
  }
  $name = $name . "-$prj";
  $cmd = "";
  unless ($grid) {
    print "###################################################################\n";
    print "# Starting simulations $name\n";
    if ($cluster) {
      $cmd="./$package < $file > $out";
      print "###################################################################\n";
    }
    else {
      print "# in screen $name\n";
      print "###################################################################\n";
      $cmd = "screen -d -m -a -S $name $script; screen -ls";
    }
    if ($debug) {
      print "$cmd\n";
    }
    else {
      system($cmd);
    }
  }
}
unless ($grid) {
  print "###################################################################\n";
  print "# BYE BYE\n";
  print "###################################################################\n";
}
