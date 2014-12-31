# CRKTools Makefile
# v3r0

CC = g++
CFLAGS = -Wall

FC = gfortran
FCFLAGS = -g -fbounds-check -O2

CTARGETS = analysis showers cherenkov
FTARGETS = lagocrkread onlysecs lagocrkthin

all: $(CTARGETS) $(FTARGETS)

analysis: analysis.cc
	$(CC) -o $@ $< $(CFLAGS)

showers: showers.cc
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
