// Geant4 Libraries
//
#include "G4UserEventAction.hh"
#include "G4Event.hh"
#include "G4Track.hh"
#include "g4root.hh"
#include "G4SystemOfUnits.hh"


// C++ Libraries
//
#include <cmath>


// Local Libraries
//
#include "EventAction.hh"
#include "RunAction.hh"
#include "CerenkovValidation.hh"
#include "CerValHistograms.hh"
#include "PrimaryGeneratorAction.hh"


EventAction::EventAction(RunAction* runAction, PrimaryGeneratorAction* primaryGenAction)
  : G4UserEventAction(),
  fRunAction(runAction),
  fPriGenAction(primaryGenAction)
{
  G4cout << "...EventAction..." << G4endl;
}


EventAction::~EventAction()
{}


void EventAction::BeginOfEventAction(const G4Event* event)
{
  nPhotons = 0.;
  cerenkovPhontons = 0;
  totalLength = 0.;
  //G4cout << "Begin Event: " << cerenkovPhontons << " " << event->GetEventID() << G4endl;

  muonOk = 0;
  elecOk = 0;
  gammOk = 0;
  neutOk = 0; 

  partId = fPriGenAction->primaryId;
  fRunAction->histRun->postInject(fPriGenAction->position.x() / cm, fPriGenAction->position.y()/ cm);

 
  if ( partId == "mu-" || partId == "mu+" )
  {
    muonOk = 1;
    fRunAction->histRun->distInject(0);
  }
  else if ( partId == "e-" || partId == "e+" )
  {
    elecOk = 1;
    fRunAction->histRun->distInject(1);
  }
  else if ( partId == "gamma" )
  {
    gammOk = 1;
    fRunAction->histRun->distInject(2);
  }
  else if ( partId == "neutron" )
  {
    neutOk = 1;
    fRunAction->histRun->distInject(3);
  }
  else 
    fRunAction->histRun->distInject(4);

  //fRunAction->cerVali->resetting();
}


void EventAction::EndOfEventAction(const G4Event* event)
{
  G4cout << "End Event: " << event->GetEventID() << G4endl;

  fRunAction->cerVali->printtingCerPhoCounting(1); 
  fRunAction->cerVali->resetting();

  if ( muonOk )
  {
    fRunAction->histRun->fillCerenPho(0);
    fRunAction->histRun->fillCerenPhoPmt(0);
    fRunAction->histRun->fillCerenPhoElect(0);
    fRunAction->histRun->fillTrackLengthDetec(0);
  }
  else if ( elecOk )
  {
    fRunAction->histRun->fillCerenPho(1);
    fRunAction->histRun->fillCerenPhoPmt(1);
    fRunAction->histRun->fillCerenPhoElect(1);
    fRunAction->histRun->fillTrackLengthDetec(1);
  }
  else if ( gammOk )
  {
    fRunAction->histRun->fillCerenPho(2);
    fRunAction->histRun->fillCerenPhoPmt(2);
    fRunAction->histRun->fillCerenPhoElect(2);
    fRunAction->histRun->fillTrackLengthDetec(2);
  }
  else if ( neutOk )
  {
    fRunAction->histRun->fillCerenPho(3);
    fRunAction->histRun->fillCerenPhoPmt(3);
    fRunAction->histRun->fillCerenPhoElect(3);
    fRunAction->histRun->fillTrackLengthDetec(3);
  }
  else
  {
    fRunAction->histRun->fillCerenPho(4);
    fRunAction->histRun->fillCerenPhoPmt(4);
    fRunAction->histRun->fillCerenPhoElect(4);
    fRunAction->histRun->fillTrackLengthDetec(4);
  }

  fRunAction->histRun->fillCerenPho(5);
  fRunAction->histRun->fillCerenPhoPmt(5);
  fRunAction->histRun->fillCerenPhoElect(5);
  fRunAction->histRun->fillTrackLengthDetec(5);
} 


void EventAction::countingCerenkovs(G4int cphoton)
{
  cerenkovPhontons += cphoton;
}


void EventAction::countingCerenkovs(G4double trackLength)
{
  totalLength = trackLength;
}

