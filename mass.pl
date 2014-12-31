#!/usr/bin/perl -w

# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   mass.pl                                                    */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: Calculate atomic mases using semiempirical mass formula.   */
# /*           Read data from genEspectra.dat                             */
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
# v3r0 Wed Oct  9 14:19:11 COT 2013
# First version. Based on works for nuclear physics

$cv = 15.85;
$cs = 18.34;
$cc =  0.71;
$ca = 23.21;
$cp = 12.00;

$mn = 939.565;
$mp = 938.272;

$Bfsm = $masa = 0.;

%masas = (); 

$tmp = <>; # discard first line

while (<>) {
  chomp;
  $id = $_;
  $tmp = <>;
  $tmp = <>;
  $tmp = <>;
  if ($id == 14) {
    $Bfsm = 0.;
    $masa = $mp/1000.;
  }
  else {
    $A=int($id/100.);
    $Z=int($id - $A * 100.);
    $N=$A-$Z;
  
    $vol = $cv * $A; 
    $sup = - $cs * $A**(2./3.);
    $cou = - $cc * $Z * ($Z-1) / $A**(1./3.);
    $asy = - $ca * (($A - 2 * $Z)**2) / $A;
    $par = $cp / (sqrt($A));
  
    if (!($A%2)) {
      if (!($Z%2)) {$par *= 1.;}
      else {$par *= -1.;}
    }
    else {
      $par = 0.;
    }
    $Bfsm = $vol + $sup + $cou + $asy + $par;
    $masa = ($N * $mn + $Z * $mp - $Bfsm)/1000.;
  }
  printf STDOUT ("%04d %.5f\n", $id, $masa);
  $masas{$id} = $masa;
}
$masaId = "(0";
$masaSt = "(0.";

foreach $x (sort {$a <=> $b} keys %masas) {
  $masaId .= ", " . $x;
  $masaSt .= ", " . $masas{$x}; 
}
print STDERR "$masaId)\n";
print STDERR "$masaSt)\n";
