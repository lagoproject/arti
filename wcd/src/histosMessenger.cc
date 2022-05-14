#include "histosMessenger.hh"
#include "histosRun.hh"

#include "G4UIdirectory.hh"
#include "G4UIcmdWithADoubleAndUnit.hh"
#include "G4UIcmdWithAString.hh"
#include "G4SystemOfUnits.hh"


// C++ Libraries
//
#include <string>  
#include <fstream>
#include <sstream>


histosMessenger::
  histosMessenger(histosRun* histoName)
  : G4UImessenger(),
    fhistoRun(histoName)
{
  G4cout << "...histosMessenger..." << G4endl;
  fSpecDir = new G4UIdirectory("/outroot/");
  fSpecDir->SetGuidance("OutPutName control");

  outname = new G4UIcmdWithAString("/outroot/outname", this);
}


histosMessenger::~histosMessenger()
{}


void histosMessenger::SetNewValue(
    G4UIcommand* command, G4String newValue)
{
  if ( command == outname ) {
    fhistoRun->setOutFileName(newValue);
		fhistoRun->initHistos();
	}
}
