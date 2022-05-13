#include "DetectorMessenger.hh"
#include "DetectorConstruction.hh"

#include "G4UIdirectory.hh"
#include "G4UIcmdWithADoubleAndUnit.hh"
#include "G4UIcmdWithAString.hh"
#include "G4SystemOfUnits.hh"


// C++ Libraries
//
#include <string>  
#include <fstream>
#include <sstream>


DetectorMessenger::
  DetectorMessenger(DetectorConstruction* detectCons)
  : G4UImessenger(),
    fDetectCons(detectCons)
{
   G4cout << "...DetectorMessenger..." << G4endl;
  fSpecDir = new G4UIdirectory("/detect/");
  fSpecDir->SetGuidance("DetectCons control");

  radio = new G4UIcmdWithADoubleAndUnit("/detect/radio", this);
  hight = new G4UIcmdWithADoubleAndUnit("/detect/hight", this);
}


DetectorMessenger::~DetectorMessenger()
{}


void DetectorMessenger::SetNewValue(
    G4UIcommand* command, G4String newValue)
{
  if ( command == radio )
    fDetectCons->setWcdRadius( radio->GetNewDoubleValue(newValue) );

  if ( command == hight )
    fDetectCons->setWcdHight( hight->GetNewDoubleValue(newValue) );
}
