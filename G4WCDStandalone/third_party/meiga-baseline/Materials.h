#ifndef Materials_h
#define Materials_h 1

#include "globals.hh"
#include "G4Element.hh"
#include "G4ElementTable.hh"
#include "G4Material.hh"
#include "G4SystemOfUnits.hh"
#include "G4LogicalSkinSurface.hh"
#include "G4OpticalSurface.hh"

class Materials {
	
	/* 
		this class is intended to hold all definitions and properties related to the different materials used in the Geant4 simulations
	

		author: alvaro taboada
	*/

public:
	Materials();
	virtual ~Materials();

	// single elements
	static G4Element* elN;
	static G4Element* elO;
	static G4Element* elH;
	static G4Element* elC;
	static G4Element* elSi;
	static G4Element* elTi;
	static G4Element* elB ;
	static G4Element* elNa;
	static G4Element* elCa;
	static G4Element* elFe;
	static G4Element* elAl;
	static G4Element* elPb;
	static G4Element* elCl;
	
	// compounds
	static G4Material* SiO2;
	static G4Material* TiO2;
	static G4Material* B2O2;
	static G4Material* Na2O;
	static G4Material* PPO;
	static G4Material* POPOP;
	static G4Material* Polystyrene;
	static G4Material* Lead;

	// Materials
	static G4Material* Air;
	static G4Material* Water;
	static G4Material* Salt;
	static G4Material* StdRock;
	static G4Material* ScinPlastic;
	static G4Material* ScinCoating;
	static G4Material* PMMA;
	static G4Material* Pethylene;
	static G4Material* FPethylene;
	static G4Material* Pyrex;
	static G4Material* HDPE;
	static G4Material* Concrete;
	static G4Material* SaltyWater;
	static G4OpticalSurface* ScinOptSurf;
	static G4OpticalSurface* LinerOptSurf;
	static G4OpticalSurface* LinerOptSurf2;

	static G4MaterialPropertiesTable* waterPT1; 
	static G4MaterialPropertiesTable* waterPT2;
	static G4MaterialPropertiesTable* linerPT1;
	static G4MaterialPropertiesTable* scinPT;
	static G4MaterialPropertiesTable* scinOptSurfPT;
	static G4MaterialPropertiesTable* pmmaPT;
	static G4MaterialPropertiesTable* pethylenePT;
	static G4MaterialPropertiesTable* fpethylenePT;
	static G4MaterialPropertiesTable* pyrexPT;
	static G4MaterialPropertiesTable* linerOpticalPT;

	const G4double* GetScinPhotonEnergyArray() const;
	const G4double* GetScinRefIndexArray() const;

	void SetNaClFracMass(double fracNaCl) { fFracNaCl = fracNaCl; }
	double GetNaClFracMass() { return fFracNaCl; }
	

private:

	void CreateElements(); // function to create individual elements
	void CreateCompounds(); // function to create compunds like polystyrene, standard rock, etc...
	void CreateMaterials();
 	
	// plastic scintillator
 	const G4double fScinFastTime = 5*ns;
	const G4double fScinSlowTime = 50*ns;
	// DOI:10.15407/fm20.03.304
	const G4double fScintillationYield = 9/keV;
	const G4double fExtrusionPolish = 1;

	// pmma
	// according to datasheet BCF-92 WLS fiber
	const G4double fPMMADecayTime = 2.5*ns;

	G4double fFracNaCl = 0;




};	





#endif
