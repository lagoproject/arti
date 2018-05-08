#ifndef CerenkovValidation_h
#define CerenkovValidation_h 1


// Geant4 Libraries
//
#include "globals.hh"
#include "G4Step.hh" 
#include "G4Track.hh"
#include "g4root.hh"


// Local Libraries
//


// C++ Libraries
//


class CerenkovValidation
{
  public:
    
    CerenkovValidation();
    virtual ~CerenkovValidation(); 

    void CerPhoPerCm(const G4Track* track);
    void CerPhoPerCm(G4double dist);

    void StopPowDeepWater(const G4Step* step);
    void countingPho(int opt);
    void printtingCerPhoCounting(int opt);

    //G4double CerVsIniEner(const G4Step* track);
    void resetting();

    G4double nphoVcm;

  private:
    void GetWavelength(G4double);
    G4int nPhoton;

    G4double preStepEner;
    G4double stepEner;
    G4double stepLength;

    int cerPho;
    int cerPhoOnPmt;
    int cerPhoElect;
 
    G4double wlength;
    G4double const hc = 1239.8419;
};
#endif
