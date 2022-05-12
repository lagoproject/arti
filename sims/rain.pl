#!/usr/bin/perl -w
#!/usr/bin/perl -w
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   rain.pl                                                    */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Main CORSIKA imput generator files and simulation launcher */
# /*           for CORSIKA.                                               */
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

use strict;
use warnings;
use Cwd;

my $VERSION="v1r9";
my $tmp = "";
my $batch = 0;
my $runmode = 0;
my $wdir = "x";
my $crk_ver = "77402";
my $heim = "QGSII";
my $debug = 0;
my $help = 0;
my $slurm = 0;
my $highsec = 0;
my $curvout = "";
my $halley = 0;
my $ithin = 0;
my $ithinh = 0;
my $ithine = 0;
my $thin = " \n";
my $thine = " \n";
my $thinh = " \n";
my $efrcthn = 0.;
my $wmax = 0.;
my $rmax = 0.;
my $thinrath = 0.;
my $thinrate = 0.;
my $weitrath = 0.;
my $weitrate = 0.;
my $site = "";
my $monoe = 0.;
my $monoq = 0;
my $monot = 0.;
my $monop = 0;
my $cherenkov = 0;
my $grid = 0;
my $imuaddi = 0;
my $nofruns = 1;
my $ecutshe = 800.;

sub get {
  my $question = $_[0];
  my $default = $_[1];
  my $param = $_[2];
  my $get_tmp;
  print "$question?\n<$param $default>: " unless ($batch > 0);
  chomp ($get_tmp = <>);
  $get_tmp = $default if ($get_tmp eq "");
  return $get_tmp;
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
    $ecutshe = $ARGV[0];
    shift;
  }
  if (/-$/i) {
    $highsec++;
    $curvout="CURVOUT     T";
    $ecutshe = $ARGV[0];
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
  if (/-mu$/i) {
    $imuaddi=1;
  }
  if (/-l$/i) {
    $slurm++;
  }
  if (/-g$/i) {
    $grid=1;
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

my $package="corsika".$crk_ver."Linux_".$heim."_gheisha";
$package = $package . "_thin" if ($ithin != 0);

my $usage="
       $0 $VERSION\n
       A simple input files generator for CORSIKA
       (C) 2013 - H. Asorey - asoreyh\@cab.cnea.gov.ar
       Usage: See $0 -?  - If you enjoy it, please send me an email\n
       $0\n
       -b                                  Activates batch mode
       -i                                  Disable PLOTSH and PLOTSH2 modes (usual simms production)
       -d                                  Debug mode: only shows what it should do. Don't start simulation
       -r  <working directory>             Specify where corsika bin files are located
       -v  <version>                       Corsika version number
       -h  <high energy interaction model> High energy interaction model used for compilation of CORSIKA (EPOS|QGSII|SIBYLL)
       -l                                  Enables SLURM cluster compatibility (with sbatch). 
       -t  <EFRCTHN> <WMAX> <RMAX>         Enables THIN Mode (see manual for pg 62 for values)
       -th <THINRAT> <WEITRAT>             If THIN Mode, select different thining levels for Hadronic (THINH) ...
       -te <THINRAT> <WEITRAT>             ... and electromagnetic particles (THINEM)
       -a <high energy ecuts (GeV)>        Enables and set high energy cuts for ECUTS
       -z                                  Enables CHERENKOV mode
       -mu                                 Enables additional information from muons and EM particles
       -g                                  Enables GRID mode
       -s <site>                           Choice site for simulation (some predefined sites: hess|sac|etn|ber|bga|lim|glr|mch|mge|and|mpc|cha|cid|mor|ccs|lsc|mbo)
       -m <energy>                         Defines energy (in GeV) for monoenergetic showers (CHERENKOV)
       -q <theta>                          Defines zenith angle (in degs) for fixed angle showers (CHERENKOV)
       -p <prmpar>                         Defines primary particle (see table 4 pg 87) (CHERENKOV)

       \n";
die "$usage\n" if ($help != 0);

print STDERR "\nWARNING! You are running in DEBUG mode. I'll only show what I should do\n\n" if ($debug != 0);
print STDERR "\nWARNING! CHERENKOV mode is enabled.\n\n" if ($cherenkov != 0);
print STDERR "\nWARNING! Site selected for simulation: $site.\n\n" unless ($site eq "");
if ($runmode != 0) {
  die "\n\nERROR: You selected run mode without indicate working directory.\n$usage\n" if ($wdir eq "x");
}
die "\n\nERROR: -th or -te options needs -t option.\n$usage\n" if (($ithine || $ithinh) && !($ithin));
if ($ithin != 0) {
  die "\n\nERROR: You have to specify three paramters for THIN (-t).\n$usage\n" unless ($wmax && $rmax && $efrcthn);
  $thin="THIN        $efrcthn  $wmax  $rmax\n";
}
die "\n\nERROR: You can't specify both THINH and THINEM at the same time.\n$usage\n" if ($ithine && $ithinh);
if ($ithine != 0) {
  die "\n\nERROR: You have to specify two paramters for THINE (-te).\n$usage\n" unless ($thinrate && $weitrate);
  $thine="THINEM      $thinrate $weitrate\n";
}
if ($ithinh != 0) {
  die "\n\nERROR: You have to specify two paramters for THINH (-th).\n$usage\n" unless ($thinrath && $weitrath);
  $thinh="THINH       $thinrath $weitrath\n";
}
## ready to start
$nofruns = get("Number of runs", $nofruns, "RUNS") unless ($monoe || $monoq);
my $w_dir_tmp;
if ($wdir eq "x") {
  $w_dir_tmp=getcwd() . "/run";
} else {
  $w_dir_tmp = $wdir;
}
if ($batch != 0) {
  $w_dir_tmp=get("Working directory (where CORSIKA run files are located)", "$w_dir_tmp", "WDIR");
} else {
  $wdir=get("Working directory (where CORSIKA run files are located)", "$w_dir_tmp", "WDIR");
}
my $def_prj="sims";
$def_prj = "mono" . $site if (int($monoe) || $monoq);
my $prj=get("Project name (Results will go into $wdir/<project> dir)", "$def_prj", "DIRECT");
my $user=get("User name", "LAGO", "USER");
my $bin=$wdir."/".$package;
my $direct="$wdir/$prj";
my $home = $wdir;
unless ($grid != 0) {
  die "\n\nERROR: Couldn't find corsika at $bin. Please check\n$usage\n" unless (-e $bin);
}
system("clear");
unless ($batch != 0) {
  print "###################################################################\n";
  print "# I will run this script $nofruns times\n";
  print "# in $direct/\n";
  print "# Press enter to continue...\n";
  print "###################################################################\n";
  $tmp=<>;
}
for (my $i=0; $i < $nofruns; $i++) {
  my $index=$i+1;
  unless ($batch != 0) {
    system("clear");
    print "###################################################################\n";
    print "# RUN $index\n";
    print "###################################################################\n";
    print "###################################################################\n";
    print "# Simulation parameters\n";
    print "###################################################################\n";
  }
  my $run_nr;
  my $evt_nr;
  my $prmpar;
  unless ($monop != 0) {
    $run_nr=get("Corsika run number", $index, "RUNNR");
    $evt_nr=get("number of first shower event", 0 ,"EVTNR");
  } else {
    $evt_nr = 1;
    $prmpar = $monop;
    $monop = 9 if ($monop > 6); # 9=hadrons
    my $monoename = $monoe;
    $monoename = 999 if ($monoename > 999);
    $run_nr = int($monot + $monoename * 100. + $monop * 1e5);
  }
  my $N_show=get("number of showers to generate", 1, "NSHOW");
  unless ($batch != 0) {
    system("clear");
    print "###################################################################\n";
    print "# Primary particle parameters\n";
    print "###################################################################\n";
  }

  $prmpar = get("Primary particle identification (see table 4 pg 87)", 14, "PRMPAR") unless ($monop != 0);
  my $e_slope;
  my $e_low;
  my $e_high;
  unless ($monoe != 0) {
    $e_slope=get("Spectral index of primary energy spectrum", -2.7, "ESLOPE");
    $e_low=get("Lower limit of the primary particle energy (ERANGE) [GeV]", 1e4, "LLIMIT");
    $e_high=get("Upper limit of the primary particle energy (ERANGE) [GeV]", 1e4, "ULIMIT");
  } else {
    $e_slope = -2.7; # don't used for mono-energetic showers but needed
    $e_low = $e_high = $monoe;
  }
  my $t_low;
  my $t_high;
  unless ($monoq != 0) {
    $t_low=get("Low edge of zenith angle (THETAP) [deg]", 0, "THETPR(1)");
    $t_high=get("High edge of zenith angle (THETAP) [deg]", 90, "THETPR(2)");
  } else {
    $t_low = $t_high = $monot;
  }
  my $f_low=get("Low edge of azimuth angle (PHIP) [deg]", -180, "PHIPR(1)");
  my $f_high=get("High edge of azimuth angle (PHIP) [deg]", 180, "PHIPR(2)");
  unless ($batch != 0) {
    system("clear");
    print "###################################################################\n";
    print "# Observatory parameters\n";
    print "###################################################################\n";
  }
  my $atmcrd="ATMOD";
  my $modatm = "";
  my $altitude = 0.;
  my $bx = 0.;
  my $bz = 0.;
  my $arrang = 0.;
  unless ($batch != 0) {
    if ($site eq "hess") {
        $modatm=get("Atmospheric model selection ($site)", "E10", "ATMOSPHERE");
        $altitude=1800e2;
        $bx=12.5;
        $bz=-25.9;
        $arrang="-14";
	} elsif ($site eq "sac") {
        $modatm=get("Atmospheric model selection (E30=wi,E31=sp,E32=su,E33=au)", "E32", "ATMOSPHERE");
        $altitude=3700e2;
        $bx=20.94;
        $bz=-8.91;
        $arrang="0";
	} elsif ($site eq "chi") {
      $modatm="E1";
      $altitude=500000;
      $bx=26.56;
      $bz=8.758;
	  $arrang="0";
	} elsif ($site eq "ata") {
      $modatm="";
      $altitude=510500;
      $bx=20.638;
      $bz=-8.598;
	} elsif ($site eq "ima") {
      $modatm="E1";
      $altitude=460000;
      $bx=22.935;
      $bz=-3.823;
	} elsif ($site eq "sng") {
      $modatm="E2";
      $altitude=455000;
      $bx=27.333;
      $bz=27.989;
	} elsif ($site eq "etn") {
        $modatm=get("Atmospheric model selection ", "E2", "ATMOSPHERE");
        $altitude=3000e2;
        $bx=27.7623;
        $bz=36.0667;
        $arrang="0";
	} elsif ($site eq "ber") {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=3450e2;
        $bx=26.9814;
        $bz=17.1054;
        $arrang="0";
    } elsif ($site eq "bga") {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=950e2;
        $bx=27.0263;
        $bz=17.1760;
        $arrang="0";
    } elsif ($site eq "lim") {
        $modatm=get("Atmospheric model selection ", "E2", "ATMOSPHERE");
        $altitude=168e2;
        $bx=25.28;
        $bz=-0.046;
        $arrang="0";
    } elsif ($site eq "glr") {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=4276e2;
        $bx=27.0750;
        $bz=11.7728;
        $arrang="0";
    } elsif ($site eq "mch") {
        $modatm=get("Atmospheric model selection ", "E1", "ATMOSPHERE");
        $altitude=2650e2;
        $bx=27.1762;
        $bz=14.6184;
        $arrang="0";
    } elsif ($site eq "mge") {
        $modatm=get("Atmospheric model selection ", "19", "$atmcrd");
        $altitude=1400e2;
        $bx=20.4367;
        $bz=-11.8217;
        $arrang="0";
    } elsif ($site eq "brc") {
        $modatm=get("Atmospheric model selection ", "E3", "$atmcrd");
        $altitude=800e2;
        $bx=19.234;
        $bz=-17.068;
        $arrang="0";
    } elsif ($site eq "and") {
      $modatm=get("Atmospheric model selection ", "19", "$atmcrd");
      $altitude=4200e2;
      $bx=19.6922;
      $bz=-14.2420;
      $arrang="0";
    } elsif ($site eq "mpc") {
      $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
      $altitude=4500e2;
      $bx=24.9599;
      $bz=+0.4124;
    } elsif ($site eq "cha") {
      $modatm=get("Atmospheric model selection ", "E2", "$atmcrd");
      $altitude=5230e2;
      $bx=23.0386;
      $bz=-3.9734;
    } elsif ($site eq "cid") {
      $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
      $altitude=3600e2;
      $bx=26.8464;
      $bz=+18.1604;
    } elsif ($site eq "mor") {
      $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
      $altitude=4400e2;
      $bx=26.8340;
      $bz=+18.2004;
    } elsif ($site eq "lsc") {
      $modatm=get("Atmospheric model selection ", "E2", "$atmcrd");
      $altitude=28e2;
      $bx=20.29;
      $bz=-11.74;
    } elsif ($site eq "mbo") {
      $modatm=get("Atmospheric model selection ", "E5", "$atmcrd");
      $altitude=196e2;
      $bx=19.6571;
      $bz=-30.5809;
    } elsif ($site eq "ccs") {
      $modatm=get("Atmospheric model selection ", "E1", "$atmcrd");
      $altitude=900E2;
      $bx=26.7364;
      $bz=+18.6777;
    } else {
      $modatm = get("Atmospheric model selection. Start number with 'E' to use external atmospheres module, or 'G' for GDAS module", 19, "$atmcrd");
      $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
      while ($altitude == 0) {
        print STDERR "ERROR: Observation level is mandatory\n";
        $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
      }
      $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX");
      while ($bx == 0) {
        print STDERR "ERROR: BX is mandatory\n";
        $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX");
      }
      $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ");
      while ($bz == 0) {
        print STDERR "ERROR: BZ is mandatory\n";
        $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ");
      }
    }
  } else {
    $altitude = get("Observation level above sea level [cm]", 0, "OBSLEV");
    $modatm = get("Atmospheric model selection. Start number with 'E' to use external atmospheres module, or 'G' for GDAS module", 19, "$atmcrd");
    while ($altitude == 0) {
      print STDERR "ERROR: Observation level is mandatory\n";
      $altitude = get("Observation level above sea level [cm]",0,"OBSLEV");
    }
    $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX");
    while ($bx == 0) {
      print STDERR "ERROR: BX is mandatory\n";
      $bx=get("Horizontal comp. of the Earth's mag. field (MAGNET) [North,muT],\nsee values at http://www.ngdc.noaa.gov/geomagmodels/struts/calcIGRFWMM",0,"BX");
    }
    $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ");
    while ($bz == 0) {
      print STDERR "ERROR: BZ is mandatory\n";
      $bz=get("Vertical comp. of the Earth's mag. field (MAGNET) [downwards,muT]",0,"BZ");
    }
  }
  if (uc(substr($modatm,0,1)) eq "E") { # using external atmospheres bernlhor
    $atmcrd = "ATMOSPHERE";
    $modatm =~ s/E//g;
	$modatm .= " Y";
  } else {
	if (uc(substr($modatm,0,1)) eq "G") { # gdas model
		$atmcrd = "ATMFILE";
		$modatm = "'atm" . lc($modatm) . ".dat'";
		$package = $package . "-atmfile";
		$bin=$wdir."/".$package;
      die "\n\nERROR: Couldn't find corsika excecutable $package at $bin. Please check\n$usage\n" unless (-e $bin);
    }
  }
  # LAGO ECUTS, minimum possible values as for the current corsika version
  my @ecuts=(0.05, 0.01, 0.00005, 0.00005);
  if ($highsec != 0) {
    @ecuts=($ecutshe, $ecutshe, $ecutshe, $ecutshe);
    $e_low = $ecutshe if ($e_low < $ecutshe);
  }
  unless ($batch != 0) {
    print "###################################################################\n";
    print "# General (T or F) parameters\n";
    print "###################################################################\n";
  }
  my $muaddi=""; # MUADDI. For v<7.4005, EMADDI AND NUADDI does not work, only MUADDI
  if ($imuaddi != 0) {
    if ($crk_ver eq "73500") {
      $muaddi=get("Get additional info for muons",'F',"MUADDI");
    } else {
      $muaddi=get("Get additional info for muons, EM and neutrinos",'F',"MUADDI, EMADDI, NUADDI");
    }
  }
  my $plotsh=get("Write add- files for track plot of secondaries",'F',"PLOTSH");
  my $datbas=get("Write .dbase file",'T',"DATBAS");
  my $llongi=get("Track longitudinal development of secondaries (LONGI)", 'F',"LLONGI");
  my $ftabout=get("Write tab output of charged particle dev file (PAROUT)",'F',"FTABOUT");
  my $s1 = int(rand(1e7));
  my $s2 = int(rand(1e7));
  my $s3 = int(rand(1e7));
  my $s4 = int(rand(1e7));
  my $cerary = "50 50 80.E2 80.E2 25 25";
  my $cards = "";
  my $plotshs = "";
  my $direct2 = $direct;
  $llongi = "F";
  $datbas = "F";
  $direct2 = "." if ($grid != 0);
  my $muadditxt = "";
  if ($imuaddi != 0) {
    $muadditxt="MUADDI      $muaddi
EMADDI      $muaddi
NUADDI      $muaddi";
    $muadditxt = "" if ($crk_ver * 1.0 < 74005);
  }
  $plotshs = "PLOTSH      $plotsh" unless ($halley != 0);
  $plotshs = "" if ($plotsh eq "F");
  if ($cherenkov != 0) {
    $cards="RUNNR         $run_nr
EVTNR         $evt_nr
NSHOW         $N_show
PRMPAR        $prmpar
ESLOPE        $e_slope
ERANGE        $e_low $e_high
THETAP        $t_low $t_high
PHIP          $f_low $f_high
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
MAXPRT        1
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
  } else {
	$cards="RUNNR       $run_nr
EVTNR       $evt_nr
NSHOW       $N_show
PRMPAR      $prmpar
ESLOPE      $e_slope
ERANGE      $e_low $e_high
THETAP      $t_low $t_high
PHIP        $f_low $f_high
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
MAXPRT      1
ELMFLG      F   T
LONGI       $llongi  10.  T  T
ECTMAP      1.E11
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
  unless ($batch != 0) {
    system ("clear");
    print "$cards";
    print "###################################################################\n";
    print "# I will run this simulation using those parameters\n";
    print "# Please check and press ENTER to continue; CTRL-C to abort\n";
    print "###################################################################\n";
    $tmp=<>;
  }
  my $name = sprintf("%06d-%04d-%011d",$run_nr,$prmpar,$N_show);
  my $file = "$direct/DAT$name.input";
  my $binout = sprintf("$direct/DAT%06d",$run_nr);
  my $out = "$direct/DAT$name.lst";
  my $script = "$home/run-$prj-$name.sh";
  unless ($debug != 0) {
    opendir(IMD, "$direct/") or system("mkdir $direct/");
    closedir(IMD);
    open (my $fh ,">$file") or die "Can't open $file\n";
    print $fh "$cards";
    close($fh);
    unless ($grid != 0) {
      open ($fh ,">$script") or die "Can't open $script\n";
      print $fh "#!/bin/bash\n";
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
  my $cmd = "";
  unless ($grid != 0) {
    print "###################################################################\n";
    print "# Starting simulations $name\n";
    if ($slurm != 0) {
      print "###################################################################\n";
      $cmd="sbatch -p highpri2 -o ${name}_srun_%j.log ${script}";
    }
    else {
      print "# in screen $name\n";
      print "###################################################################\n";
      $cmd = "screen -d -m -a -S $name $script; screen -ls";
    }
    if ($debug != 0) {
      print "$cmd\n";
    }
    else {
      system($cmd);
    }
  }
}
unless ($grid != 0) {
  print "###################################################################\n";
  print "# BYE BYE\n";
  print "###################################################################\n";
}