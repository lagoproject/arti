// Geant4 Libraries
//
#include "G4Track.hh"
#include "G4Step.hh"


// Local Libraries
//
#include "histosRun.hh"
#include "histosMessenger.hh"


// Root Libraries
//
#include <TTree.h>
#include <TFile.h>
#include <TH1F.h>
#include <TH1I.h>
#include <TH2D.h>


histosRun::histosRun()
{
   G4cout << "...histosRun..." << G4endl;
   histoRunMess = new histosMessenger(this);
}


histosRun::~histosRun()
{
  histosOutput->Write();
  histosOutput->Close();
}


void histosRun::initHistos()
{

  int binForPhotons = 100000;
  int binForPulses = 20;
  int binInsideDetec = 400; 


  // ===================
  // *** For photons ***
  histCerenPhoMuon = new TH1F("histCerenPhoMuon", "CerenPhoMuon", binForPhotons, 1, binForPhotons+1);
  histCerenPhoElec = new TH1F("histCerenPhoElec", "CerenPhoElec", binForPhotons, 1, binForPhotons+1);
  histCerenPhoGamm = new TH1F("histCerenPhoGamm", "CerenPhoGamm", binForPhotons, 1, binForPhotons+1);
  histCerenPhoNeut = new TH1F("histCerenPhoNeut", "CerenPhoNeut", binForPhotons, 1, binForPhotons+1);
  histCerenPhoHadr = new TH1F("histCerenPhoHadr", "CerenPhoHadr", binForPhotons, 1, binForPhotons+1);
  histCerenPhoAll = new TH1F("histCerenPhoAll", "CerenPhoAll", binForPhotons, 1, binForPhotons+1);
                       
  histCerenPhoPmtMuon = new TH1F("histCerenPhoPmtMuon", "CerenPhoPmtMuon", binForPhotons, 1, binForPhotons+1);
  histCerenPhoPmtElec = new TH1F("histCerenPhoPmtElec", "CerenPhoPmtElec", binForPhotons, 1, binForPhotons+1);
  histCerenPhoPmtGamm = new TH1F("histCerenPhoPmtGamm", "CerenPhoPmtGamm", binForPhotons, 1, binForPhotons+1);
  histCerenPhoPmtNeut = new TH1F("histCerenPhoPmtNeut", "CerenPhoPmtNeut", binForPhotons, 1, binForPhotons+1);
  histCerenPhoPmtHadr = new TH1F("histCerenPhoPmtHadr", "CerenPhoPmtHadr", binForPhotons, 1, binForPhotons+1);
  histCerenPhoPmtAll = new TH1F("histCerenPhoPmtAll", "CerenPhoPmtAll", binForPhotons, 1, binForPhotons+1);
                       
  histCerenPhoElectMuon = new TH1F("histCerenPhoElectMuon", "CerenPhoElectMuon", binForPhotons, 1, binForPhotons+1);
  histCerenPhoElectElec = new TH1F("histCerenPhoElectElec", "CerenPhoElectElec", binForPhotons, 1, binForPhotons+1);
  histCerenPhoElectGamm = new TH1F("histCerenPhoElectGamm", "CerenPhoElectGamm", binForPhotons, 1, binForPhotons+1); 
  histCerenPhoElectNeut = new TH1F("histCerenPhoElectNeut", "CerenPhoElectNeut", binForPhotons, 1, binForPhotons+1); 
  histCerenPhoElectHadr = new TH1F("histCerenPhoElectHadr", "CerenPhoElectHadr", binForPhotons, 1, binForPhotons+1); 
  histCerenPhoElectAll = new TH1F("histCerenPhoElectAll", "CerenPhoElectAll", binForPhotons, 1, binForPhotons+1); 

  // ==================|:
  // *** For pulses ***
  histMeanPulseMuon = new TH1F("histMeanPulseMuon", "MeanPulseMuon", binForPulses, 0, 500);
  histMeanPulseElec = new TH1F("histMeanPulseElec", "MeanPulseElec", binForPulses, 0, 500);
  histMeanPulseGamm = new TH1F("histMeanPulseGamm", "MeanPulseGamm", binForPulses, 0, 500);
  histMeanPulseNeut = new TH1F("histMeanPulseNeut", "MeanPulseNeut", binForPulses, 0, 500);
  histMeanPulseHadr = new TH1F("histMeanPulseHadr", "MeanPulseHadr", binForPulses, 0, 500);
  histMeanPulseAll = new TH1F("histMeanPulseAll", "MeanPulseAll", binForPulses, 0, 500);

  // =======================
  // *** inside detector ***
  histTrackLengthDetecMuon = new TH1F("histTrackLengthDetecMuon", "TrackLengthDetecMuon", binInsideDetec, 1, binInsideDetec+1);
  histTrackLengthDetecElec = new TH1F("histTrackLengthDetecElec", "TrackLengthDetecElec", binInsideDetec, 1, binInsideDetec+1);
  histTrackLengthDetecGamm = new TH1F("histTrackLengthDetecGamm", "TrackLengthDetecGamm", binInsideDetec, 1, binInsideDetec+1);
  histTrackLengthDetecNeut = new TH1F("histTrackLengthDetecNeut", "TrackLengthDetecNeut", binInsideDetec, 1, binInsideDetec+1);
  histTrackLengthDetecHadr = new TH1F("histTrackLengthDetecHadr", "TrackLengthDetecHadr", binInsideDetec, 1, binInsideDetec+1);
  histTrackLengthDetecAll = new TH1F("histTrackLengthDetecAll", "TrackLengthDetecAll", binInsideDetec, 1, binInsideDetec+1);

  // ================
  // *** Injected ***
  histPartInject = new TH1I("histPartInject", "PartInject", 6, 0, 6);
  histPostInject = new TH2D("histPostInject", "PostInject", 1001, -500, 500, 1001, -500, 500);
}


void histosRun::cerenPho(int optCerenPho)
{
  switch ( optCerenPho )
  {
    case 0:
      cMuonCerPho++;
      break;
    case 1:
      cElecCerPho++;
      break;
    case 2:
      cGammCerPho++;
      break;
    case 3:
      cNeutCerPho++;
      break;
    case 4:
      cHadrCerPho++;
      break;
    case 5:
      cAllCerPho++;
      break;
  }
}


void histosRun::fillCerenPho(int optFillPho)
{
  switch ( optFillPho )
  {
    case 0:
      histCerenPhoMuon->Fill(cMuonCerPho);
      break;
    case 1:
      histCerenPhoElec->Fill(cElecCerPho);
      break;
    case 2:
      histCerenPhoGamm->Fill(cGammCerPho);
      break;
    case 3:
      histCerenPhoNeut->Fill(cNeutCerPho);
      break;
    case 4:
      histCerenPhoHadr->Fill(cHadrCerPho);
      break;
    case 5:
      histCerenPhoAll->Fill(cAllCerPho);
      break;
  }

  cMuonCerPho = 0;
  cElecCerPho = 0;
  cGammCerPho = 0;
  cNeutCerPho = 0;
  cHadrCerPho = 0;

  if ( optFillPho == 5 ) 
    cAllCerPho = 0;
}


void histosRun::cerenPhoPmt(int optCerenPhoPmt)
{
  switch ( optCerenPhoPmt )
  {
    case 0:
      cMuonPhoPmt++;
      break;
    case 1:
      cElecPhoPmt++;
      break;
    case 2:
      cGammPhoPmt++;
      break;
    case 3:
      cNeutPhoPmt++;
      break;
    case 4:
      cHadrPhoPmt++;
      break;
    case 5:
      cAllPhoPmt++;
      break;
  }
}


void histosRun::fillCerenPhoPmt(int optFillPhoPmt)
{
  switch ( optFillPhoPmt )
  {
    case 0:
      histCerenPhoPmtMuon->Fill(cMuonPhoPmt);
      break;
    case 1:
      histCerenPhoPmtElec->Fill(cElecPhoPmt);
      break;
    case 2:
      histCerenPhoPmtGamm->Fill(cGammPhoPmt);
      break;
    case 3:
      histCerenPhoPmtNeut->Fill(cNeutPhoPmt);
      break;
    case 4:
      histCerenPhoPmtHadr->Fill(cHadrPhoPmt);
      break;
    case 5:
      histCerenPhoPmtAll->Fill(cAllPhoPmt);
      break;
  }

  cMuonPhoPmt = 0;
  cElecPhoPmt = 0;
  cGammPhoPmt = 0;
  cNeutPhoPmt = 0;
  cHadrPhoPmt = 0;

  if ( optFillPhoPmt == 5 )
    cAllPhoPmt = 0;
}


void histosRun::cerenPhoElect(int optCerenPhoElect)
{
  switch ( optCerenPhoElect )
  {
    case 0:
      cMuonPhoElect++;
      break;
    case 1:
      cElecPhoElect++;
      break;
    case 2:
      cGammPhoElect++;
      break;
    case 3:
      cNeutPhoElect++;
      break;
    case 4:
      cHadrPhoElect++;
      break;
    case 5:
      cAllPhoElect++;
      break;
  }
}


void histosRun::fillCerenPhoElect(int optFillPhoElect)
{
  switch ( optFillPhoElect )
  {
    case 0:
      histCerenPhoElectMuon->Fill(cMuonPhoElect);
      break;
    case 1:
      histCerenPhoElectElec->Fill(cElecPhoElect);
      break;
    case 2:
      histCerenPhoElectGamm->Fill(cGammPhoElect);
      break;
    case 3:
      histCerenPhoElectNeut->Fill(cNeutPhoElect);
      break;
    case 4:
      histCerenPhoElectHadr->Fill(cHadrPhoElect);
      break;
    case 5:
      histCerenPhoElectAll->Fill(cAllPhoElect);
      break;
  }

  cMuonPhoElect = 0;
  cElecPhoElect = 0;
  cGammPhoElect = 0;
  cNeutPhoElect = 0;
  cHadrPhoElect = 0;

  if ( optFillPhoElect == 5 )
    cAllPhoElect = 0;
}


void histosRun::meanPulse(int optMeanPulse, double time)
{
  switch ( optMeanPulse )
  {
    case 0:
      histMeanPulseMuon->Fill(time);
      break;
    case 1:
      histMeanPulseElec->Fill(time);
      break;
    case 2:
      histMeanPulseGamm->Fill(time);
      break;
    case 3:
      histMeanPulseNeut->Fill(time);
      break;
    case 4:
      histMeanPulseHadr->Fill(time);
      break;
    case 5:
      histMeanPulseAll->Fill(time);
      break;
  }
}


void histosRun::trackLengthDetec(int optLengthDectec, double length)
{
  switch ( optLengthDectec )
  {
    case 0:
      cMuonLengthDetec += length;
      break;
    case 1:
      cElecLengthDetec += length;
      break;
    case 2:
      cGammLengthDetec += length;
      break;
    case 3:
      cNeutLengthDetec += length;
      break;
    case 4:
      cHadrLengthDetec += length;
      break;
    case 5:
      cAllLengthDetec += length;
      break;
  }
}


void histosRun::fillTrackLengthDetec(int optFillLengthDectec)
{
  switch ( optFillLengthDectec )
  {
    case 0:
      histTrackLengthDetecMuon->Fill(cMuonLengthDetec / mm2cm); 
      break;
    case 1:
      histTrackLengthDetecElec->Fill(cElecLengthDetec / mm2cm);
      break;
    case 2:
      histTrackLengthDetecGamm->Fill(cGammLengthDetec / mm2cm);
      break;
    case 3:
      histTrackLengthDetecNeut->Fill(cNeutLengthDetec / mm2cm);
      break;
    case 4:
      histTrackLengthDetecHadr->Fill(cHadrLengthDetec / mm2cm);
      break;
    case 5:
      histTrackLengthDetecAll->Fill(cAllLengthDetec / mm2cm);
      break;
  }

  cMuonLengthDetec = 0;
  cElecLengthDetec = 0;
  cGammLengthDetec = 0;
  cNeutLengthDetec = 0;
  cHadrLengthDetec = 0;

  if ( optFillLengthDectec == 5 )
    cAllLengthDetec = 0;
}


void histosRun::distInject(int part)
{
  histPartInject->Fill(part);
}


void histosRun::postInject(double partPosX, double partPosY)
{
  histPostInject->Fill(partPosX, partPosY);
}

void histosRun::setOutFileName( G4String name )
{
  histosOutput = new TFile(name, "RECREATE");
}
