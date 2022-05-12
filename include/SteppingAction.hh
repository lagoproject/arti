#ifndef SteppingAction_h
#define SteppingAction_h 1


// Geant4 Libraries
//
#include "G4UserSteppingAction.hh"
#include "globals.hh"


// Local Libraries
//
#include "DetectorConstruction.hh"
#include "PMTSD.hh"


// C++ Libraries
//


class EventAction;
class PrimaryGeneratorAction;


/// Stepping action class
/// 

class SteppingAction : public G4UserSteppingAction
{
  public:
    SteppingAction(EventAction* eventAction);
    virtual ~SteppingAction();

    // method from the base class
    virtual void UserSteppingAction(const G4Step*);
    EventAction* fEventAction;

  private:
    const DetectorConstruction *detectorConstruction;
    G4VPhysicalVolume* fwaterVolume;
    G4int fScintillationCounter;
    G4int lengthMaxOk;
    G4double initEner;
    G4int fEventNumber;
    PMTSD *pmtSD;

    G4String volumName;
    G4String cerenProc;
    G4int currStep;
    G4double lengthStep;

    double trackTime;
};

#endif
