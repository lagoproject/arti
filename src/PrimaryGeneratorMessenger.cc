#include "PrimaryGeneratorMessenger.hh"

#include "PrimaryGeneratorAction.hh"
#include "G4UIdirectory.hh"
#include "G4UIcmdWithADoubleAndUnit.hh"
#include "G4SystemOfUnits.hh"


// C++ Libraries
//
#include <string>  
#include <fstream>
#include <sstream>


PrimaryGeneratorMessenger::
  PrimaryGeneratorMessenger(PrimaryGeneratorAction* Gun)
  : G4UImessenger(),
    fAction(Gun)
{
   G4cout << "...PrimaryGeneratorMessenger..." << G4endl;
  fGunDir = new G4UIdirectory("/gun/");
  fGunDir->SetGuidance("PrimaryGenerator control");

  fPolarCmd =
           new G4UIcmdWithADoubleAndUnit("/gun/optPhotonPolar",this);
  fPolarCmd->SetGuidance("Set linear polarization");
  fPolarCmd->SetGuidance("  angle w.r.t. (k,n) plane");
  fPolarCmd->SetParameterName("angle",true);
  fPolarCmd->SetUnitCategory("Angle");
  fPolarCmd->SetDefaultValue(-360.0);
  fPolarCmd->SetDefaultUnit("deg");
  fPolarCmd->AvailableForStates(G4State_Idle);

  valueForTest = new G4UIcmdWithADoubleAndUnit("/gun/testVal", this);
  valueForTest->SetGuidance("Just for learning how this class works");
  valueForTest->SetDefaultUnit("MeV");
}

//....oooOO0OOooo........oooOO0OOooo........oooOO0OOooo........oooOO0OOooo......

PrimaryGeneratorMessenger::~PrimaryGeneratorMessenger()
{
  delete fPolarCmd;
  delete fGunDir;
  delete valueForTest;
}

//....oooOO0OOooo........oooOO0OOooo........oooOO0OOooo........oooOO0OOooo......

void PrimaryGeneratorMessenger::SetNewValue(
                                        G4UIcommand* command, G4String newValue)
{
  if( command == fPolarCmd ) {
      G4double angle = fPolarCmd->GetNewDoubleValue(newValue);
      if ( angle == -360.0*deg ) {
         fAction->SetOptPhotonPolar();
      } else {
         fAction->SetOptPhotonPolar(angle);
      }
  }
  
  if( command == valueForTest )
  {
    G4cout << "Testing Messenger Class" << G4endl;
    G4cout << valueForTest->GetNewDoubleValue(newValue) << G4endl;
  } 

}


void PrimaryGeneratorMessenger::SetParticleMomentum(G4ThreeVector direction)
{
  double px = direction.x();
  double py = direction.y();
  double pz = direction.z();

  std::string sPx = std::to_string(px);
  std::string sPy = std::to_string(py);
  std::string sPz = std::to_string(pz);
  std::string momentum = "momentum " + sPx + " " + sPy + " " + sPz + " GeV";

  G4UIcmdWithADoubleAndUnit* testCmd = new G4UIcmdWithADoubleAndUnit("gun/energy 100 MeV", this);

  testCmd->SetGuidance(momentum.c_str());
//  testCmd->SetGuidance("100 MeV");
}
