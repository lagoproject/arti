#include "Materials.h"
// material properties (scintillation, Cherenkov, optics)

// array of photon energies in the red-UV range for scintillation processes
static G4double scinPhotonEnergy[] = {
	2.00*eV, 2.03*eV, 2.06*eV, 2.09*eV, 2.12*eV,
	2.15*eV, 2.18*eV, 2.21*eV, 2.24*eV, 2.27*eV,
	2.30*eV, 2.33*eV, 2.36*eV, 2.39*eV, 2.42*eV,
	2.45*eV, 2.48*eV, 2.51*eV, 2.54*eV, 2.57*eV,
	2.60*eV, 2.63*eV, 2.66*eV, 2.69*eV, 2.72*eV,
	2.75*eV, 2.78*eV, 2.81*eV, 2.84*eV, 2.87*eV,
	2.90*eV, 2.93*eV, 2.96*eV, 2.99*eV, 3.02*eV,
	3.05*eV, 3.08*eV, 3.11*eV, 3.14*eV, 3.17*eV,
	3.20*eV, 3.23*eV, 3.26*eV, 3.29*eV, 3.32*eV,
	3.35*eV, 3.38*eV, 3.41*eV, 3.44*eV, 3.47*eV
};

G4int scinArrEntries = sizeof(scinPhotonEnergy)/sizeof(G4double);

static G4double scinRefIndex[] = {
	1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
	1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
	1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
	1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,
	1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5
};

static G4double scinAbsLen[] = {
	4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 
	4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 
	4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 4.0*cm, 
	24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 
	24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 24.0*cm, 
	24.0*cm, 24.0*cm
 };

static G4double scinFastComp[] = {
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
};

static G4double scinSlowComp[] = {
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
};

static G4double scinOptSurfRefIndex[] = {
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
 };

static G4double scinOptSurfEff[] = {
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
 };

static G4double pmmaRefIndex[] = {
	1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60,
	1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60,
	1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60,
	1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60,
	1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60, 1.60
};

static G4double pmmaAbsLen[] = {
	10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m,
	10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m,
	10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 10.00*m, 1.0*m,
	0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m,
	0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m, 0.0001*m
};

static G4double pmmaEmission[] = {
	0.05, 0.10, 0.30, 0.50, 0.75, 1.00, 1.50, 1.85, 2.30, 2.75,
	3.25, 3.80, 4.50, 5.20, 6.00, 7.00, 8.50, 9.50, 11.1, 12.4,
	12.9, 13.0, 12.8, 12.3, 11.1, 11.0, 12.0, 11.0, 17.0, 16.9,
	15.0, 9.00, 2.50, 1.00, 0.05, 0.00, 0.00, 0.00, 0.00, 0.00,
	0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00
};


static G4double pethyRefIndex[] = {
	1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49,
	1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49,
	1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49,
	1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49,
	1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49, 1.49
};

static G4double pethyAbsLen[] = {
	20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m,
	20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m,
	20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m,
	20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m,
	20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m, 20.0*m
};

static G4double fpethyRefIndex[] = {
	1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42,
	1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42,
	1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42,
	1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42,
	1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42, 1.42
};

static G4double pmtPhotonEnergy[] = {2.00*eV, 4.00*eV};
static G4double pmtRefIndex[] = {1.47, 1.47};
static G4double pmtAbsLength[] = {0.0005*mm, 0.0005*mm};
G4int pmtArrEntries = sizeof(pmtPhotonEnergy) / sizeof(G4double);

// ------------------- Water 1 (Pierre Auger Offline Framework) -------------------------------

// array of photon energies for Cerenkov processes in WCD tanks
// this energy range corresponds to the efficiency region of Auger WCD large PMTs
static G4double water1PhotonEnergy[] = {
	2.08*eV,  2.16*eV,  2.19*eV,  2.23*eV,  2.27*eV,  2.32*eV,
	2.36*eV,  2.41*eV,  2.46*eV,  2.50*eV,  2.56*eV,  2.61*eV,
	2.67*eV,  2.72*eV,  2.79*eV,  2.85*eV,  2.92*eV,  2.99*eV,
	3.06*eV,  3.14*eV,  3.22*eV,  3.31*eV,  3.40*eV,  3.49*eV,
	3.59*eV,  3.70*eV,  3.81*eV,  3.94*eV,  4.07*eV,  4.20*eV
};

G4int water1ArrEntries = sizeof(water1PhotonEnergy) / sizeof(G4double);
G4double scaleAbsLen = 100*m;

static G4double water1AbsLen[] = {
	0.092*scaleAbsLen, 0.133*scaleAbsLen, 0.180*scaleAbsLen, 0.203*scaleAbsLen, 0.226*scaleAbsLen, 0.258*scaleAbsLen,
	0.284*scaleAbsLen, 0.302*scaleAbsLen, 0.403*scaleAbsLen, 0.560*scaleAbsLen, 0.735*scaleAbsLen, 0.818*scaleAbsLen,
	0.923*scaleAbsLen, 0.923*scaleAbsLen, 0.993*scaleAbsLen, 0.993*scaleAbsLen, 1.000*scaleAbsLen, 0.941*scaleAbsLen,
	0.889*scaleAbsLen, 0.842*scaleAbsLen, 0.754*scaleAbsLen, 0.655*scaleAbsLen, 0.480*scaleAbsLen, 0.380*scaleAbsLen,
	0.311*scaleAbsLen, 0.257*scaleAbsLen, 0.212*scaleAbsLen, 0.171*scaleAbsLen, 0.137*scaleAbsLen, 0.102*scaleAbsLen
};


static G4double water1PhotonEnergyShort[] = {2.08*eV, 4.20*eV};
static G4double water1RefIndex[] = {1.33, 1.33};


// ---------------------- Water 2 (Geant4 OpNovice example) ----------------------

// arrays from Geant4 OpNovice example
static G4double water2PhotonEnergy[] = {
		2.034 * eV, 2.068 * eV, 2.103 * eV, 2.139 * eV, 2.177 * eV, 2.216 * eV,
		2.256 * eV, 2.298 * eV, 2.341 * eV, 2.386 * eV, 2.433 * eV, 2.481 * eV,
		2.532 * eV, 2.585 * eV, 2.640 * eV, 2.697 * eV, 2.757 * eV, 2.820 * eV,
		2.885 * eV, 2.954 * eV, 3.026 * eV, 3.102 * eV, 3.181 * eV, 3.265 * eV,
		3.353 * eV, 3.446 * eV, 3.545 * eV, 3.649 * eV, 3.760 * eV, 3.877 * eV,
		4.002 * eV, 4.136 * eV
	};

static G4double water2RefIndex[] = {
		1.3435, 1.344,  1.3445, 1.345,  1.3455, 1.346,  1.3465, 1.347,
		1.3475, 1.348,  1.3485, 1.3492, 1.35,   1.3505, 1.351,  1.3518,
		1.3522, 1.3530, 1.3535, 1.354,  1.3545, 1.355,  1.3555, 1.356,
		1.3568, 1.3572, 1.358,  1.3585, 1.359,  1.3595, 1.36,   1.3608
	};

G4double scaleAbsLen2 = 1.0*m;
static G4double water2AbsLen[] = {
		3.448*scaleAbsLen2,  4.082*scaleAbsLen2,  6.329*scaleAbsLen2,  9.174*scaleAbsLen2,  12.346*scaleAbsLen2, 13.889*scaleAbsLen2,
		15.152*scaleAbsLen2, 17.241*scaleAbsLen2, 18.868*scaleAbsLen2, 20.000*scaleAbsLen2, 26.316*scaleAbsLen2, 35.714*scaleAbsLen2,
		45.455*scaleAbsLen2, 47.619*scaleAbsLen2, 52.632*scaleAbsLen2, 52.632*scaleAbsLen2, 55.556*scaleAbsLen2, 52.632*scaleAbsLen2,
		52.632*scaleAbsLen2, 47.619*scaleAbsLen2, 45.455*scaleAbsLen2, 41.667*scaleAbsLen2, 37.037*scaleAbsLen2, 33.333*scaleAbsLen2,
		30.000*scaleAbsLen2, 28.500*scaleAbsLen2, 27.000*scaleAbsLen2, 24.500*scaleAbsLen2, 22.000*scaleAbsLen2, 19.500*scaleAbsLen2,
		17.500*scaleAbsLen2, 14.500*scaleAbsLen2
	};


static G4double water2PhotonEnergyMie[] = {
		1.56962 * eV, 1.58974 * eV, 1.61039 * eV, 1.63157 * eV, 1.65333 * eV,
		1.67567 * eV, 1.69863 * eV, 1.72222 * eV, 1.74647 * eV, 1.77142 * eV,
		1.7971 * eV,  1.82352 * eV, 1.85074 * eV, 1.87878 * eV, 1.90769 * eV,
		1.93749 * eV, 1.96825 * eV, 1.99999 * eV, 2.03278 * eV, 2.06666 * eV,
		2.10169 * eV, 2.13793 * eV, 2.17543 * eV, 2.21428 * eV, 2.25454 * eV,
		2.29629 * eV, 2.33962 * eV, 2.38461 * eV, 2.43137 * eV, 2.47999 * eV,
		2.53061 * eV, 2.58333 * eV, 2.63829 * eV, 2.69565 * eV, 2.75555 * eV,
		2.81817 * eV, 2.88371 * eV, 2.95237 * eV, 3.02438 * eV, 3.09999 * eV,
		3.17948 * eV, 3.26315 * eV, 3.35134 * eV, 3.44444 * eV, 3.54285 * eV,
		3.64705 * eV, 3.75757 * eV, 3.87499 * eV, 3.99999 * eV, 4.13332 * eV,
		4.27585 * eV, 4.42856 * eV, 4.59258 * eV, 4.76922 * eV, 4.95999 * eV,
		5.16665 * eV, 5.39129 * eV, 5.63635 * eV, 5.90475 * eV, 6.19998 * eV
	};

// Rayleigh scattering length calculated by G4OpRayleigh

// assumes 100 times larger than Rayleigh scattering length
static G4double water2Mie[] = {
		167024.4 * m, 158726.7 * m, 150742 * m,   143062.5 * m, 135680.2 * m,
		128587.4 * m, 121776.3 * m, 115239.5 * m, 108969.5 * m, 102958.8 * m,
		97200.35 * m, 91686.86 * m, 86411.33 * m, 81366.79 * m, 76546.42 * m,
		71943.46 * m, 67551.29 * m, 63363.36 * m, 59373.25 * m, 55574.61 * m,
		51961.24 * m, 48527.00 * m, 45265.87 * m, 42171.94 * m, 39239.39 * m,
		36462.50 * m, 33835.68 * m, 31353.41 * m, 29010.30 * m, 26801.03 * m,
		24720.42 * m, 22763.36 * m, 20924.88 * m, 19200.07 * m, 17584.16 * m,
		16072.45 * m, 14660.38 * m, 13343.46 * m, 12117.33 * m, 10977.70 * m,
		9920.416 * m, 8941.407 * m, 8036.711 * m, 7202.470 * m, 6434.927 * m,
		5730.429 * m, 5085.425 * m, 4496.467 * m, 3960.210 * m, 3473.413 * m,
		3032.937 * m, 2635.746 * m, 2278.907 * m, 1959.588 * m, 1675.064 * m,
		1422.710 * m, 1200.004 * m, 1004.528 * m, 833.9666 * m, 686.1063 * m
	};

G4int water2ArrEntries = sizeof(water2PhotonEnergy) / sizeof(G4double);

// gforward, gbackward, forward backward ratio
static G4double water2MieConst[3] = { 0.99, 0.99, 0.8 };



// ----------- Liner (Tyvek) --------------------------

static G4double linerAbsLen[] = {
	10*m,  10*m,  10*m,  10*m,  10*m,  10*m,
	10*m,  10*m,  10*m,  10*m,  10*m,  10*m,
	10*m,  10*m,  10*m,  10*m,  10*m,  10*m,
	10*m,  10*m,  10*m,  10*m,  10*m,  10*m,
	10*m,  10*m,  10*m,  10*m,  10*m,  10*m
};

static G4double linerRefIndex[] = {
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0
};

static G4double linerBackScatter[] = {
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0
};

static G4double scaleLinerRef = 0.94;
static G4double linerReflectivity[] = {
	0.9957*scaleLinerRef, 0.9953*scaleLinerRef, 0.9948*scaleLinerRef, 0.9942*scaleLinerRef, 0.9939*scaleLinerRef, 0.9937*scaleLinerRef,
	0.9937*scaleLinerRef, 0.9940*scaleLinerRef, 0.9945*scaleLinerRef, 0.9954*scaleLinerRef, 0.9964*scaleLinerRef, 0.9975*scaleLinerRef,
	0.9985*scaleLinerRef, 0.9993*scaleLinerRef, 1.0000*scaleLinerRef, 1.0000*scaleLinerRef, 0.9993*scaleLinerRef, 0.9977*scaleLinerRef,
	0.9948*scaleLinerRef, 0.9903*scaleLinerRef, 0.9840*scaleLinerRef, 0.9753*scaleLinerRef, 0.9642*scaleLinerRef, 0.9500*scaleLinerRef, 
	0.9334*scaleLinerRef, 0.9108*scaleLinerRef, 0.8849*scaleLinerRef, 0.8541*scaleLinerRef, 0.8178*scaleLinerRef, 0.7755*scaleLinerRef
};

// sigmaAlpha is used to model specular reflections from the surface
static G4double fSigmaAlpha = 0.17; // 0.23 in doi = 10.1364/OE.19.004199
static G4double specularLobePhotonEnergy[] = {2.08*eV, 3.0*eV, 4.20*eV};
// fraction of light reflected in a lobe with width characterized by sigmaAlpha
static G4double specularLobe[] = {0.2, 0.2, 0.2}; // same value in doi = 10.1364/OE.19.004199
static G4double specularSpike[] = {0, 0, 0};


//////
static bool isInitialized = 0;
G4Element* Materials::elN;
G4Element* Materials::elO;
G4Element* Materials::elH;
G4Element* Materials::elC;
G4Element* Materials::elSi;
G4Element* Materials::elTi;
G4Element* Materials::elB;
G4Element* Materials::elNa;
G4Element* Materials::elCa;
G4Element* Materials::elFe;
G4Element* Materials::elAl;
G4Element* Materials::elPb;
G4Element* Materials::elCl;

G4Material* Materials::SiO2;
G4Material* Materials::TiO2;
G4Material* Materials::B2O2;
G4Material* Materials::Na2O;
G4Material* Materials::PPO;
G4Material* Materials::POPOP;
G4Material* Materials::Polystyrene;

// Materials
G4Material* Materials::Air;
G4Material* Materials::Water;
G4Material* Materials::Salt;
G4Material* Materials::SaltyWater;
G4Material* Materials::StdRock;
G4Material* Materials::ScinPlastic;
G4Material* Materials::ScinCoating;
G4Material* Materials::PMMA;
G4Material* Materials::Pethylene;
G4Material* Materials::FPethylene;
G4Material* Materials::Pyrex;
G4Material* Materials::HDPE;
G4Material* Materials::Concrete;
G4Material* Materials::Lead;
G4OpticalSurface* Materials::ScinOptSurf;
G4OpticalSurface* Materials::LinerOptSurf;
G4OpticalSurface* Materials::LinerOptSurf2;

G4MaterialPropertiesTable* Materials::waterPT1;
G4MaterialPropertiesTable* Materials::waterPT2;
G4MaterialPropertiesTable* Materials::linerPT1;
G4MaterialPropertiesTable* Materials::scinPT;
G4MaterialPropertiesTable* Materials::scinOptSurfPT;
G4MaterialPropertiesTable* Materials::pmmaPT;
G4MaterialPropertiesTable* Materials::pethylenePT;
G4MaterialPropertiesTable* Materials::fpethylenePT;
G4MaterialPropertiesTable* Materials::pyrexPT;
G4MaterialPropertiesTable* Materials::linerOpticalPT;

double fracMassNaCl;

Materials::Materials() 
{

	if (isInitialized) {
		return;
	}

	isInitialized = true;
	
	CreateElements();
	CreateCompounds();
	CreateMaterials();

}

Materials::~Materials()
{

}

const G4double* 
Materials::GetScinPhotonEnergyArray() const { return scinPhotonEnergy; }

const G4double*
Materials::GetScinRefIndexArray() const { return scinRefIndex; }

void
Materials::CreateElements() 
{
	
	elN  = new G4Element("Nitrogen", "N", 7, 14.01 * g/mole);
	elO  = new G4Element("Oxygen", "O", 8, 16.00 * g/mole);
	elH  = new G4Element("Hydrogen", "H", 1, 1.01 * g/mole);
	elC  = new G4Element("Carbon", "C", 6, 12.0107 * g/mole);
	elSi = new G4Element("Silicon", "Si", 14, 28.09 * g/mole);
	elTi = new G4Element("Titanium", "Ti", 22, 47.867 * g/mole);
	elB  = new G4Element("Boron", "B", 5, 10.811 * g/mole);
	elNa = new G4Element("Sodium", "Na", 11, 22.98977 * g/mole);
	elCa = new G4Element("Calcium", "Ca", 20, 40.08 * g/mole);
	elFe = new G4Element("Iron", "Fe", 26, 55.850 * g/mole);
	elAl = new G4Element("Aluminium", "Al", 13, 26.98 * g/mole);
	elPb = new G4Element("Lead", "Pb", 82, 207.2 * g/mole);
	elCl = new G4Element("Clhorine", "Cl", 17, 70.906 * g/mole);

}

void
Materials::CreateCompounds()
{
	// silicon dioxide for "quartz"
	SiO2 = new G4Material("SiO2", 2.65 * g/cm3, 2);
	SiO2->AddElement(elSi, 1);
	SiO2->AddElement(elO, 2);
	// titanium dioxide
	TiO2 = new G4Material("TiO2", 4.26 * g/cm3, 2);
	TiO2->AddElement(elTi, 1);
	TiO2->AddElement(elO, 2);
	// diboron dioxide
	B2O2 = new G4Material("B2O2", 2.23 * g/cm3, 2);
	B2O2->AddElement(elB, 2);
	B2O2->AddElement(elO, 2);
	// sodium oxide
	Na2O = new G4Material("Na2O", 2.23 * g/cm3, 2);
	Na2O->AddElement(elNa, 2);
	Na2O->AddElement(elO, 1);

	// Polystyrene for the scintillator bars Dow STYRON 663 W
	Polystyrene = new G4Material("Polystrene", 1.04 * g/cm3, 2);
	Polystyrene->AddElement(elC, 8);
	Polystyrene->AddElement(elH, 8);

	// dopant materials for scintillator bars
	/* Scintillator made of Polystyrene ( C6H5-CH-CH2 ) + PPO + POPOP
			Plastic:
			Is a replication on an aromatic ring (C6H5) with one out of the six H
			replaced by a CH bond with another CH2.
								CH2
								//
								CH
								|
							 / \
			 C6H5:  |   |
							 \ /
	*/

	// PPO:
	PPO = new G4Material("PPO", 1.060 * g/cm3, 4);
	PPO->AddElement(elC, 15);
	PPO->AddElement(elH, 11);
	PPO->AddElement(elN, 1);
	PPO->AddElement(elO, 1);
	// POPOP:
	POPOP = new G4Material("POPOP", 1.060 * g/cm3, 4);
	POPOP->AddElement(elC, 24);
	POPOP->AddElement(elH, 16);
	POPOP->AddElement(elN, 2);
	POPOP->AddElement(elO, 2);
	
	// H2O:


	// Salt
	Salt = new G4Material("Salt", 2.165 * g/cm3, 2);
	Salt->AddElement(elCl, 1);
	Salt->AddElement(elNa, 1);

}

void
Materials::CreateMaterials()
{

	// --------------------------------------------------------------------
	// Air
	// --------------------------------------------------------------------
	Air = new G4Material("Air", 1.29e-3 * g/cm3, 2);
	Air->AddElement(elN, 0.7);
	Air->AddElement(elO, 0.3);
	// --------------------------------------------------------------------
	// Water
	// --------------------------------------------------------------------
	Water = new G4Material("Water", 1 * g/cm3, 2);
	Water->AddElement(elH, 2);
	Water->AddElement(elO, 1);

	// Define different PropertiesTable for different water "types"
	waterPT1 = new G4MaterialPropertiesTable();
	waterPT1->AddProperty("RINDEX", water1PhotonEnergyShort, water1RefIndex, 2);
	waterPT1->AddProperty("ABSLENGTH", water1PhotonEnergy, water1AbsLen, water1ArrEntries);
	
	// --- Material Properties Table from Geant4 OpNovice example.
	waterPT2 = new G4MaterialPropertiesTable();
	waterPT2->AddProperty("RINDEX", water2PhotonEnergy, water2RefIndex, water2ArrEntries);
	waterPT2->AddProperty("ABSLENGTH", water2PhotonEnergy, water2AbsLen, water2ArrEntries);
	waterPT2->AddProperty("MIEHG", water2PhotonEnergyMie, water2Mie, water2ArrEntries);
	waterPT2->AddConstProperty("MIEHG_FORWARD", water2MieConst[0]);
	waterPT2->AddConstProperty("MIEHG_BACKWARD", water2MieConst[1]);
	waterPT2->AddConstProperty("MIEHG_FORWARD_RATIO", water2MieConst[2]);

	// function to set waterPT from configuration file
	Water->SetMaterialPropertiesTable(waterPT1);


	// --------------------------------------------------------------------
	// Rocks
	// --------------------------------------------------------------------
	StdRock = SiO2;

	// --------------------------------------------------------------------
	// Plastic Scintillator Bars
	// --------------------------------------------------------------------

	// Scintillator material:
	ScinPlastic = new G4Material("ScinPlastic", 1.060 * g/cm3, 3);
	ScinPlastic->AddMaterial(Polystyrene, 98.7*perCent);
	ScinPlastic->AddMaterial(PPO, 1*perCent);
	ScinPlastic->AddMaterial(POPOP, 0.3*perCent);

	// Scintillator Coating - 15% TiO2 and 85% polystyrene by weight.
	ScinCoating = new G4Material("ScinCoating", 1.52 * g/cm3, 2);
	ScinCoating->AddMaterial(TiO2, 15*perCent);
	ScinCoating->AddMaterial(Polystyrene, 85*perCent);

	// Add scintillator property table
	scinPT = new G4MaterialPropertiesTable();
	scinPT->AddProperty("RINDEX", scinPhotonEnergy, scinRefIndex, scinArrEntries);
	scinPT->AddProperty("ABSLENGTH", scinPhotonEnergy, scinAbsLen, scinArrEntries);
	scinPT->AddProperty("SCINTILLATIONCOMPONENT1", scinPhotonEnergy, scinFastComp, scinArrEntries);
	scinPT->AddProperty("SCINTILLATIONCOMPONENT2", scinPhotonEnergy, scinSlowComp, scinArrEntries);
	scinPT->AddConstProperty("SCINTILLATIONYIELD", fScintillationYield);
	scinPT->AddConstProperty("RESOLUTIONSCALE", 1);
	scinPT->AddConstProperty("SCINTILLATIONTIMECONSTANT1", fScinFastTime);
	scinPT->AddConstProperty("SCINTILLATIONTIMECONSTANT2", fScinSlowTime);
	scinPT->AddConstProperty("SCINTILLATIONYIELD1", 1);
	ScinPlastic->SetMaterialPropertiesTable(scinPT);

	// Add optical skin properties of scintillator (coating)
	ScinOptSurf = new G4OpticalSurface("ScinOptSurf", glisur, ground, dielectric_metal, fExtrusionPolish);

	scinOptSurfPT = new G4MaterialPropertiesTable();
	scinOptSurfPT->AddProperty("REFLECTIVITY", scinPhotonEnergy, scinOptSurfRefIndex, scinArrEntries);
	scinOptSurfPT->AddProperty("EFFICIENCY", scinPhotonEnergy, scinOptSurfEff, scinArrEntries);
	ScinOptSurf->SetMaterialPropertiesTable(scinOptSurfPT);

	// --------------------------------------------------------------------
	// PMMA (for WLS fibers)
	// --------------------------------------------------------------------
	

	PMMA = new G4Material("PMMA", 1.190 * g/cm3, 3);
	PMMA->AddElement(elC, 5);
	PMMA->AddElement(elH, 8);
	PMMA->AddElement(elO, 2);

	// Add properties to table
	pmmaPT = new G4MaterialPropertiesTable();
	pmmaPT->AddProperty("RINDEX", scinPhotonEnergy, pmmaRefIndex, scinArrEntries);
	pmmaPT->AddProperty("WLSABSLENGTH", scinPhotonEnergy, pmmaAbsLen, scinArrEntries);
	pmmaPT->AddProperty("WLSCOMPONENT", scinPhotonEnergy, pmmaEmission, scinArrEntries);
	pmmaPT->AddConstProperty("WLSTIMECONSTANT", fPMMADecayTime); // 
	PMMA->SetMaterialPropertiesTable(pmmaPT);

	/* WLS fibers are made of polymethylmethacrylate (PMMA)
		and a double cladding made of polyethylene and 
		fluorinated polyethylene

		PMMA: C5O2H8
		Pethylene: C2H4
	*/

	// Polyethylene (for internal cladding of WLS fibers)
	Pethylene = new G4Material("Pethylene", 1.200 * g/cm3, 2);
	Pethylene->AddElement(elC, 2);
	Pethylene->AddElement(elH, 4);

	// Add properties to table
	pethylenePT = new G4MaterialPropertiesTable();
	pethylenePT->AddProperty("RINDEX", scinPhotonEnergy, pethyRefIndex, scinArrEntries);
	pethylenePT->AddProperty("ABSLENGTH", scinPhotonEnergy, pethyAbsLen, scinArrEntries);
	Pethylene->SetMaterialPropertiesTable(pethylenePT);

	// Fluorinated Polyethylene (for external cladding of WLS fibers)
	FPethylene = new G4Material("FPethylene", 1.400 * g/cm3, 2);
	FPethylene->AddElement(elC, 2);
	FPethylene->AddElement(elH, 4);

	// Add properties to table
	fpethylenePT = new G4MaterialPropertiesTable();
	fpethylenePT->AddProperty("RINDEX", scinPhotonEnergy, fpethyRefIndex, scinArrEntries);
	fpethylenePT->AddProperty("ABSLENGTH", scinPhotonEnergy, pethyAbsLen, scinArrEntries);
	FPethylene->SetMaterialPropertiesTable(fpethylenePT);


	// --------------------------------------------------------------------
	// Borosilicate glass "Pyrex" (for SiPM & PMT active surfaces)
	// --------------------------------------------------------------------
	/*
		NOTE : The "face" is actually an ellipsoidal surface
		The active area (photocathode) covers 90% of it.
		The refractive index is the same as the dome
		refractive index. The absorption length is set
		so that no photons propagate through the
		photocathode.
	*/

	// from PDG:
	// 80% SiO2 + 13% B2O2 + 7% Na2O
	// by fractional mass?

	Pyrex = new G4Material("Pyrex", 2.23 * g/cm3, 3);
	Pyrex->AddMaterial(SiO2, 0.80);
	Pyrex->AddMaterial(B2O2, 0.13);
	Pyrex->AddMaterial(Na2O, 0.07);

	// Add properties to table
	#warning "This properties are for PMTs! Check Pyrex optical properties for SiPMs!!"
	pyrexPT = new G4MaterialPropertiesTable();
	pyrexPT->AddProperty("RINDEX", pmtPhotonEnergy, pmtRefIndex, pmtArrEntries);
	pyrexPT->AddProperty("ABSLENGTH", pmtPhotonEnergy, pmtAbsLength, pmtArrEntries);
	Pyrex->SetMaterialPropertiesTable(pyrexPT);

	// --------------------------------------------------------------------
	// HDPE for WCD liner material (Tyvek®)
	// --------------------------------------------------------------------
	// 
	HDPE = new G4Material("HDPE", 0.94 * g/cm3, 2);
	HDPE->AddElement(elC, 2);
	HDPE->AddElement(elH, 4);

	linerPT1 = new G4MaterialPropertiesTable();
	linerPT1->AddProperty("ABSLENGTH", water1PhotonEnergy, linerAbsLen, water1ArrEntries);
	HDPE->SetMaterialPropertiesTable(linerPT1);

	// Liner optical surface properties
	linerOpticalPT = new G4MaterialPropertiesTable();
	linerOpticalPT->AddProperty("SPECULARLOBECONSTANT", specularLobePhotonEnergy, specularLobe, 3);
	linerOpticalPT->AddProperty("SPECULARSPIKECONSTANT", specularLobePhotonEnergy, specularSpike, 3);
	linerOpticalPT->AddProperty("REFLECTIVITY", water1PhotonEnergy, linerReflectivity, water1ArrEntries);
	linerOpticalPT->AddProperty("BACKSCATTERCONSTANT", water1PhotonEnergy, linerBackScatter, water1ArrEntries);
	linerOpticalPT->AddProperty("RINDEX", water1PhotonEnergy, linerRefIndex, water1ArrEntries);

	LinerOptSurf =  new G4OpticalSurface("WallSurface");
	LinerOptSurf->SetModel(unified);
	LinerOptSurf->SetType(dielectric_metal);
	LinerOptSurf->SetFinish(ground);
	LinerOptSurf->SetSigmaAlpha(fSigmaAlpha);
	LinerOptSurf->SetMaterialPropertiesTable(linerOpticalPT);

	// LAGO WCD parameters
	LinerOptSurf2 =  new G4OpticalSurface("WallSurface");
	LinerOptSurf2->SetType(dielectric_LUT);
	LinerOptSurf2->SetFinish(groundtyvekair);
	LinerOptSurf2->SetModel(LUT);

	// --------------------------------------------------------------------
	// Concrete
	// --------------------------------------------------------------------
	// 
	Concrete = new G4Material("Concrete", 2.5 *g/cm3, 6);
	Concrete->AddElement(elO, 0.52);
	Concrete->AddElement(elSi, 0.325);
	Concrete->AddElement(elCa, 0.06);
	Concrete->AddElement(elNa, 0.015);
	Concrete->AddElement(elFe, 0.04);
	Concrete->AddElement(elAl, 0.04);

	// define lead as material, not element
	Lead = new G4Material("Lead", 82., 207.2 * g/mole, 11.35 * g/cm3);
}
