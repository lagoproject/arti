#ifndef UserEventAction_h 
#define UserEventAction_h 1


// Geant4 Libraries
//
#include "G4UserEventAction.hh"
#include "G4Event.hh"
#include "G4Track.hh"
#include "RunAction.hh"
#include "G4ThreeVector.hh"


// Local Libraries
//
#include "CerenkovValidation.hh"
#include "PrimaryGeneratorAction.hh"


// C++ Libraries
//
#include <string>


class EventAction : public G4UserEventAction
{
  public:
    EventAction(RunAction* runAction, PrimaryGeneratorAction* primaryGenAction);
    virtual ~EventAction();

    virtual void BeginOfEventAction(const G4Event *event);
    virtual void EndOfEventAction(const G4Event *event);

    void countingCerenkovs(G4int cphoton);
    void countingCerenkovs(G4double trackLength);
    G4double nPhotons;
 
    RunAction* fRunAction;
    PrimaryGeneratorAction* fPriGenAction;  

    G4ThreeVector partMomeDir;

    int muonOk;
    int elecOk;
    int gammOk;
    int neutOk;

    std::string partId;
    
  private:
//    CerenkovValidation* validating;
    G4int cerenkovPhontons;
    G4double totalLength;
};

#endif

