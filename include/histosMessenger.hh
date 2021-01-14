#ifndef histosMessenger_h
#define histosMessenger_h 1


// Geant4 Libraries
#include "G4UImessenger.hh"
#include "globals.hh"


class histosRun;
class G4UIdirectory;
class G4UIcmdWithAString;


class histosMessenger: public G4UImessenger
{
  public:
    histosMessenger(histosRun* histoName);
    virtual ~histosMessenger();
 
    virtual void SetNewValue(G4UIcommand*, G4String);
    
  
  private:
    histosRun* fhistoRun;
    G4UIdirectory* fSpecDir;

    G4UIcmdWithAString* outname;
};
#endif
