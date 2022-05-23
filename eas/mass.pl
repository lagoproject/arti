#!/usr/bin/perl -w
# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   mass.pl                                                    */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Calculate nuclei masses using the semi-empirical mass      */
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
#

use strict;
use warnings;
my $VERSION="v1r9";

my $cv = 15.85;
my $cs = 18.34;
my $cc =  0.71;
my $ca = 23.21;
my $cp = 12.00;
my $mn = 939.565;
my $mp = 938.272;
my $BFSM = 0.;
my $mass = 0.;
my $id = 0;
my %masses = ();
my $tmp = <>; # discard first line
my $A = 0;
my $Z = 0;

while (<>) {
  chomp;
  $id = $_;
  $tmp = <>;
  $tmp = <>;
  $tmp = <>;
  if ($id == 14) {
    $BFSM = 0.;
    $mass = $mp/1000.;
  }
  else {
    $A = int($id / 100.);
    $Z = int($id - $A * 100.);
    my $N = $A - $Z;
  
    my $vol = $cv * $A;
    my $sup = - $cs * $A**(2./3.);
    my $cou = - $cc * $Z * ($Z-1) / $A**(1./3.);
    my $asy = - $ca * (($A - 2 * $Z)**2) / $A;
    my $par = $cp / (sqrt($A));
  
    if (!($A%2)) {
      if (!($Z%2)) {
        $par *= 1.;
      }
      else {
        $par *= -1.;
      }
    }
    else {
      $par = 0.;
    }
    $BFSM = $vol + $sup + $cou + $asy + $par;
    $mass = ($N * $mn + $Z * $mp - $BFSM) / 1000.;
  }
  printf STDOUT ("%04d %.5f\n", $id, $mass);
  $masses{$id} = $mass;
}
my $mass_id = "(0";
my $mass_st = "(0.";

foreach my $x (sort {$a <=> $b} keys %masses) {
  $mass_id .= ", " . $x;
  $mass_st .= ", " . $masses{$x};
}
print STDERR "$mass_id)\n";
print STDERR "$mass_st)\n";