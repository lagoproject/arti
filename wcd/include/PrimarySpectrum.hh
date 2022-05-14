#ifndef PrimarySpectrum_h
#define PrimarySpectrum_h 1


//Geant libraries
//
#include "globals.hh"
#include "G4ThreeVector.hh"


// c++ libraries
//
#include <math.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <stdlib.h>
#include <string>
#include <iomanip>


class PrimarySpectrumMessenger;


class PrimarySpectrum
{
	public:
		PrimarySpectrum();
		~PrimarySpectrum();

		void primaryPosition();

		G4ThreeVector particlePosition;
		G4ThreeVector particleDirection;
		G4String parId;

		void primaryMomento();
    std::string inputFile; //[] = "tmpMachin24h.shw.bz2";
		int openFile(std::string name);
    void setInitPosZ(G4double zz);
    void setRoArea(G4double rr);
    G4double Ro;


	private:
		G4double pi;
		//G4double Ro;
		G4double initx;
		G4double inity;
		G4double initz;
		float r;
    float theta;
		
		G4int crkId;
		G4double px;
		G4double py;
		G4double pz;
		G4double x;
		G4double y;
		G4double z;
		G4int shwId;
		G4int prmId;
		G4double prmEner;
		G4double prmThe;
		G4double prmPhi;

		FILE *inFile = NULL;
    PrimarySpectrumMessenger* fSpectMessenger;
};
#endif
