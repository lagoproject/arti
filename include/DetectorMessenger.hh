#ifndef DetectorMessenger_h
#define DetectorMessenger_h 1


// Geant4 Libraries
#include "G4UImessenger.hh"
#include "globals.hh"


class DetectorConstruction;
class G4UIdirectory;
class G4UIcmdWithADoubleAndUnit;


class DetectorMessenger: public G4UImessenger
{
  public:
    DetectorMessenger(DetectorConstruction* detectCons);
    virtual ~DetectorMessenger();
 
    virtual void SetNewValue(G4UIcommand*, G4String);
    
  
  private:
    DetectorConstruction* fDetectCons;
    G4UIdirectory* fSpecDir;

    G4UIcmdWithADoubleAndUnit* radio;
    G4UIcmdWithADoubleAndUnit* hight;
};
#endif
