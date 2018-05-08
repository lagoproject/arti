
// Geant4 Libraries
//
#include "globals.hh"


// Local Libraries
//
#include "CerValHistograms.hh"


// C++ Libraries
//
#include <string> 


// Root Libraries
//
#include <TTree.h>
#include <TFile.h>
#include <TH1F.h>


CerValHistograms::CerValHistograms()
{
  G4cout << "...CerValHistograms..." << G4endl;
  rfCerValHist = new TFile("rfCerValHist-10e-1_10e0.root", "RECREATE");
  testTree = new TTree("testTree", "title");
}


CerValHistograms::~CerValHistograms()
{
  rfCerValHist->Write();
  rfCerValHist->Close();
}


void CerValHistograms::creatingHist(G4int runId)
{
  int id = runId;
  G4String histName = "histPhoVcm";
  histName = histName + std::to_string(id) + ".root";
  histPhoVcm = new TH1F(histName, "Phot Vs cm", 1000, 1., 1000.);
}


void CerValHistograms::doHistCerPhoCm(G4double nphoVcm)
{
  G4cout << "here doHistCerPho: " << nphoVcm << G4endl;
  histPhoVcm->Fill(nphoVcm);  
}


void CerValHistograms::creatHistStopPow(G4int runId)
{
  int id = runId;
  G4String histName = "histStopPowWater";
  histName = histName + std::to_string(id) + ".root"; 
  histPhoVcm = new TH1F(histName, "StoppingPower Vs DeepInWater", 20, 0., 2.);
}
