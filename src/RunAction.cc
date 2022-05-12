
// Geant4 Libraries
//
#include "G4Timer.hh"
#include "G4Run.hh"
#include "g4root.hh"
#include "G4AccumulableManager.hh"


// Root Libraries
//
#include <TFile.h> 


// Local Libraries
//
#include "RunAction.hh"


RunAction::RunAction()
 : G4UserRunAction(),
   fTimer(0)
{
  G4cout << "...RunAction..." << G4endl;
  fTimer = new G4Timer;

  // -----------------------
  // Histogram for One Pulse
  analysisManager->CreateH1("0","Time at Pmt", 1000, 0., 1000.);


  if( histRunOk )
  {
    histRun = new histosRun();
  }
}


RunAction::~RunAction()
{
  delete fTimer;
}


void RunAction::BeginOfRunAction(const G4Run* aRun)
{
  G4cout << "### Run " << aRun->GetRunID() << " start." << G4endl;
  fTimer->Start();

  G4AccumulableManager* accumulableManager = G4AccumulableManager::Instance();
  accumulableManager->Merge();
}


void RunAction::EndOfRunAction(const G4Run* aRun)
{
  fTimer->Stop();
  G4cout << "number of event = " << aRun->GetNumberOfEvent()
         << " " << *fTimer << G4endl;

  histRun->~histosRun();
}

