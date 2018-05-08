// Geant4 Libraries
//
#include "G4Track.hh"
#include "G4Step.hh"
#include "globals.hh"
#include "G4SystemOfUnits.hh"
#include "G4VProcess.hh"
#include "G4OpticalPhoton.hh"


// Local Libraries
//
#include "CerenkovValidation.hh"


// C++ Libraries
//


CerenkovValidation::CerenkovValidation()
  : 
  stepEner(0.),
  stepLength(0.),
  wlength(0.)
{
  nPhoton = 0;
  nphoVcm = 0.;

  cerPho = 0;
  cerPhoOnPmt = 0;
  cerPhoElect = 0;

  G4cout << "...CerenkovValidation..." << G4endl;
}

CerenkovValidation::~CerenkovValidation()
{}


void CerenkovValidation::CerPhoPerCm(const G4Track* track)
{
  // Asking for OpticalPhoton and Cerenkov Process
  //
  if(track->GetDefinition() == G4OpticalPhoton::OpticalPhotonDefinition())
    if (track->GetCreatorProcess()->GetProcessName() == "Cerenkov")
    {
      // Asking for photon wavelength
      // 
      this
        ->GetWavelength(track->GetTotalEnergy());
      if(wlength >= 300. && wlength <= 570.)
      {
        nPhoton++;
      }
    }
}

void CerenkovValidation::CerPhoPerCm(G4double dist)
{
  nphoVcm = (nPhoton*1.) / (dist/(1.*cm));
}
  

void CerenkovValidation::StopPowDeepWater(const G4Step* step)
{
  preStepEner = step->GetPreStepPoint()->GetTotalEnergy() / (1.*MeV);
  stepEner = step->GetPostStepPoint()->GetTotalEnergy() / (1.*MeV); //= step->GetTrack()->GetTotalEnergy() / (1.*MeV);
  stepLength = step->GetStepLength() / (1.*mm); //= step->GetTrack()->GetTrackLength() / (1.*mm); 

  G4cout << "deltaE/deltaX: " 
    << preStepEner << " " 
    << stepEner << " " 
    << stepLength << " "
    << (preStepEner-stepEner) / stepLength << " " 
//    << (500.51099891-stepEner) / stepLength << " "
    << step->GetTrack()->GetTrackLength() << G4endl;
}


/*G4double CerenkovValidation::CerVsIniEner(const G4Step* track)
{
  return 0.;
}*/


void CerenkovValidation::GetWavelength(G4double phoEner)
{
  //wlength = hc / ( 1.33*(phoEner/(1.*eV)) );
  wlength = hc / (phoEner/(1.*eV));

}


void CerenkovValidation::countingPho(int opt)
{
  switch(opt)
  {
    case 1:
      cerPho++;
      break;
    case 2:
      cerPhoOnPmt++;
      break;
    case 3:
      cerPhoElect++;
      break;
  }
}


void CerenkovValidation::printtingCerPhoCounting(int opt)
{
  G4AnalysisManager* analysisManager = G4AnalysisManager::Instance();
  switch(opt)
  {
    case 0:
      G4cout << "Total cerPho: " << cerPho << G4endl;
      G4cout << "Total cerPhoOnPmt: " << cerPhoOnPmt << G4endl;
      G4cout << "Total cerPhoElect: " << cerPhoElect << G4endl;
      break;
    case 1:
      analysisManager->FillH1(1, cerPhoElect);
      break;
  }
}


void CerenkovValidation::resetting()
{
  nphoVcm = 0.;
  nPhoton = 0;

  cerPho = 0;
  cerPhoOnPmt = 0;
  cerPhoElect = 0;
}
