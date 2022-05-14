#ifndef ActionInitialization_h
#define ActionInitialization_h 1


// Geant4 Libraries
//


// Local Libraries
//
#include "G4VUserActionInitialization.hh"
#include "PrimarySpectrum.hh"


class B4DetectorConstruction;

/// Action initialization class.
///

class ActionInitialization : public G4VUserActionInitialization
{
  public:
    ActionInitialization();
    virtual ~ActionInitialization();

    virtual void BuildForMaster() const;
    virtual void Build() const;

    virtual G4VSteppingVerbose* InitializeSteppingVerbose() const;

    PrimarySpectrum* parCrk;
};

#endif
