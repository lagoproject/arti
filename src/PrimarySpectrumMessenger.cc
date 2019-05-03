#include "PrimarySpectrumMessenger.hh"

#include "PrimaryGeneratorAction.hh"
#include "G4UIdirectory.hh"
#include "G4UIcmdWithADoubleAndUnit.hh"
#include "G4UIcmdWithAString.hh"
#include "G4SystemOfUnits.hh"


// C++ Libraries
//
#include <string>  
#include <fstream>
#include <sstream>


PrimarySpectrumMessenger::
  PrimarySpectrumMessenger(PrimarySpectrum* spectrum)
  : G4UImessenger(),
    fSpectrum(spectrum)
{
  G4cout << "...PrimarySpectrumMessenger..." << G4endl;
  fSpecDir = new G4UIdirectory("/spectrum/");
  fSpecDir->SetGuidance("PrimarySpectrum control");

  inFile = new G4UIcmdWithAString("/spectrum/readfile", this); 
  zInit = new G4UIcmdWithADoubleAndUnit("/spectrum/iniposZ", this);

  rAreaDist = new G4UIcmdWithADoubleAndUnit("/spectrum/radArea", this);
}


PrimarySpectrumMessenger::~PrimarySpectrumMessenger()
{}


void PrimarySpectrumMessenger::SetNewValue(
    G4UIcommand* command, G4String inFl)
{
  if ( command == inFile )
  {
    fSpectrum->inputFile = inFl;
    fSpectrum->openFile(inFl);
  }

  if ( command == zInit )
    fSpectrum->setInitPosZ( zInit->GetNewDoubleValue( inFl ) ); 

  if ( command == rAreaDist )
    fSpectrum->setRoArea( rAreaDist->GetNewDoubleValue( inFl ) );

}
