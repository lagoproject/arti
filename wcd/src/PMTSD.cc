
// Geant4 Libraries
//
#include "G4VPhysicalVolume.hh"
#include "G4LogicalVolume.hh"
#include "G4Track.hh"
#include "G4Step.hh"
#include "G4VTouchable.hh"
#include "G4TouchableHistory.hh"
#include "G4ios.hh"
#include "G4ParticleTypes.hh"
#include "G4ParticleDefinition.hh"
#include "g4root.hh"
#include "G4SystemOfUnits.hh"


// Local Libraries
//
#include "PMTSD.hh"
#include "PMTHit.hh"
#include "DetectorConstruction.hh"
//#include "UserTrackInformation.hh"


// C++ Libraries
//
#include <locale>
#include <string>
#include <sstream>
#include <iomanip>


PMTSD::PMTSD()
  : phoHit(),
  pulseNumber(6),
  phoDetec(0.)
//  : G4VSensitiveDetector(name),
{
  G4cout << "...PMTSD..." << G4endl;
  phoHit = new PMTHit;
  kinEnergy = 0.;
  phoDetec = 0;
}


PMTSD::~PMTSD()
{}


G4int PMTSD::ProcessHits(const G4Step* aStep, G4double time)
{
  kinEnergy = aStep->GetTrack()->GetTotalEnergy();
  phoDetec = phoHit->askDetected(kinEnergy);

  if( phoDetec )
    doPulse(time);//aStep->GetTrack(), time);

  return phoDetec;
}


void PMTSD::resetPMTSD()
{
  phoDetec = 0;
  kinEnergy = 0.;
}


void PMTSD::doPulse(G4double time)//const G4Track* track, G4double time)
{
  G4AnalysisManager* analysisManager 
    = G4AnalysisManager::Instance();
 
  analysisManager->FillH1(0, (time/(1.*ns)));
  pulseNumber++;
}
