#ifndef PMTSD_h
#define PMTSD_h 1


// Geant4 Libraries
//
//#include "G4DataVector.hh"
//#include "G4VSensitiveDetector.hh"
#include "G4Track.hh"


// Local Libraries
//
#include "PMTHit.hh"


// C++ Libraries
//
//#include <vector>


class G4Step;
class G4HCofThisEvent;


class PMTSD //: public G4VSensitiveDetector
{

  public:
    PMTSD();//G4String name);
    virtual ~PMTSD();
    G4int ProcessHits(const G4Step* aStep, G4double time);
    void resetPMTSD();
    G4double getPhoDetected()
    { 
      return phoDetec;
    }


  private:
   PMTHit *phoHit;
   G4int pulseNumber;
   G4int phoDetec;
   G4double kinEnergy;
   void doPulse(G4double time);//const G4Track* track, G4double time);
};
#endif
