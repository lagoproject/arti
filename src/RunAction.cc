
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
  startCerenkValid();

  cerVali = new CerenkovValidation();

  if(cervaliOk)
    histCerVali = new CerValHistograms();

//  if(coulombOk)
//    scatter = new coulombScattering();

  if( histRunOk )
  {
    histRun = new histosRun();
    histRun->initHistos();
  }
}


RunAction::~RunAction()
{
  if(cervaliOk)
    histCerVali->~CerValHistograms();

//  if(coulombOk)
//    scatter->~coulombScattering();

  delete fTimer;
}


void RunAction::BeginOfRunAction(const G4Run* aRun)
{
  G4cout << "### Run " << aRun->GetRunID() << " start." << G4endl;
  fTimer->Start();

  G4AccumulableManager* accumulableManager = G4AccumulableManager::Instance();
  accumulableManager->Merge();

  if(cervaliOk)
    histCerVali->creatingHist(aRun->GetRunID());


//  if(coulombOk)
//    scatter->creatingHist();

  // ---------------------------
  // Root File for Pulses On PMT
  
//  G4String rootFile = "rootPulsesOnPMT";
//  analysisManager->OpenFile(rootFile);
}


void RunAction::EndOfRunAction(const G4Run* aRun)
{
  fTimer->Stop();
  G4cout << "number of event = " << aRun->GetNumberOfEvent()
         << " " << *fTimer << G4endl;

  closeCerenkValid();
  histRun->~histosRun();
}


void RunAction::startCerenkValid()
{
  analysisManager->CreateH1("1","PhotoElectrons", 500, 0, 500);
  analysisManager->OpenFile("rootCerenkValid");
}


void RunAction::closeCerenkValid()
{
  analysisManager->Write();
  analysisManager->CloseFile();
}


void RunAction::startCoulombValid()
{
  analysisManager->CreateH1("1","CoulombSomeThing", 500, 0, 500);
  analysisManager->OpenFile("rootCoulombValid");
}


void RunAction::closeCoulombValid()
{
  analysisManager->Write();
  analysisManager->CloseFile();
}


void RunAction::fillHistPhoVcm()
{
  histCerVali->doHistCerPhoCm(cerVali->nphoVcm);
}
