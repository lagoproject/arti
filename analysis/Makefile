# /************************************************************************/
# /* Package:  ARTI                                                       */
# /* Module:   Makefile                                                   */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
# /************************************************************************/
# /* Comments: Compile the LAGO ARTI analysis tools                       */
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
VERSION="v1r9";
CC = g++
CFLAGS = -Wall

FC = gfortran
FCFLAGS = -g -fbounds-check -O2

CTARGETS = analysis showers cherenkov primaries
FTARGETS = lagocrkread onlysecs lagocrkthin

all: $(CTARGETS) $(FTARGETS)

analysis: analysis.cc
	$(CC) -o $@ $< $(CFLAGS)

showers: showers.cc
	$(CC) -o $@ $< $(CFLAGS)

primaries: primaries.cc
	$(CC) -o $@ $< $(CFLAGS)

lagocrkread: lagocrkread.f
	$(FC) -o $@ $< $(FCFLAGS)

lagocrkthin: lagocrkthin.f
	$(FC) -o $@ $< $(FCFLAGS)

onlysecs: onlysecs.f
	$(FC) -o $@ $< $(FCFLAGS)

.PHONY: clean

clean:
	rm -f $(CTARGETS) $(FTARGETS)
