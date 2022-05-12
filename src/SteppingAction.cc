
// Geant4 Libraries
//
#include "G4Step.hh"
#include "G4Track.hh"

#include "G4OpticalPhoton.hh"
#include "G4VProcess.hh"
#include "G4ParticleDefinition.hh"
#include "G4ParticleTypes.hh"
#include "G4SystemOfUnits.hh"

#include "G4Event.hh"
#include "G4RunManager.hh"
#include "g4root.hh"
#include "G4SDManager.hh"
#include "G4TransportationManager.hh"
#include "G4SystemOfUnits.hh"


// Local Libraries
#include "SteppingAction.hh"
#include "DetectorConstruction.hh"
#include "PMTSD.hh"
#include "EventAction.hh"
#include "PrimaryGeneratorAction.hh"



SteppingAction::SteppingAction(EventAction* eventAction)
  : G4UserSteppingAction(),
    fEventAction(eventAction)
{
  G4cout << "...SteppingAction..." << G4endl; 
  G4TransportationManager::GetTransportationManager()
    ->GetNavigatorForTracking()->SetPushVerbosity(0);
  
  fScintillationCounter = 0;
  lengthMaxOk = 0;
  fEventNumber = -1;
  initEner = 0.;
  pmtSD = new PMTSD;

  
  detectorConstruction 
     = static_cast < const DetectorConstruction* 
     > (G4RunManager::GetRunManager()
         ->GetUserDetectorConstruction());
}

SteppingAction::~SteppingAction()
{}


void SteppingAction::UserSteppingAction(const G4Step* step)
{
  // --------------------
  // Get G4Track variable 
  G4Track* track = step->GetTrack();
  volumName = step->GetPostStepPoint()->GetPhysicalVolume()->GetName();

  if( track->GetParentID() == 0 && volumName == "Ground_geo" )
    track->SetTrackStatus(fStopAndKill);

  if ( volumName == "expHall" || volumName == "Ground_geo" )
    track->SetTrackStatus(fStopAndKill);


// --------------------------------------------------------------

  if ( track->GetDefinition() == G4OpticalPhoton::OpticalPhotonDefinition() )
  {
    currStep = track->GetCurrentStepNumber();
    cerenProc = track->GetCreatorProcess()->GetProcessName();
    
    
    // =====================
    // *** For histosRun ***

    // ----------------------
    // ** Fill for Photons **
  
    // ---------------------
    // * Fill for CerenPho *
    
    if ( currStep == 1 && cerenProc == "Cerenkov" )
    {
      if ( fEventAction->muonOk )
        fEventAction->fRunAction->histRun->cerenPho(0);
      else if ( fEventAction->elecOk )
        fEventAction->fRunAction->histRun->cerenPho(1);
      else if ( fEventAction->gammOk )
        fEventAction->fRunAction->histRun->cerenPho(2);
      else if ( fEventAction->neutOk )
        fEventAction->fRunAction->histRun->cerenPho(3);
      else
        fEventAction->fRunAction->histRun->cerenPho(4);

      fEventAction->fRunAction->histRun->cerenPho(5);
    }

    
    // ------------------------
    // * Fill for CerenPhoPmt *
    if ( cerenProc == "Cerenkov" && volumName == "pmt_geo" )
    {
      if ( fEventAction->muonOk )
        fEventAction->fRunAction->histRun->cerenPhoPmt(0);
      else if ( fEventAction->elecOk )
        fEventAction->fRunAction->histRun->cerenPhoPmt(1);
      else if ( fEventAction->gammOk )
        fEventAction->fRunAction->histRun->cerenPhoPmt(2);
      else if ( fEventAction->neutOk )
        fEventAction->fRunAction->histRun->cerenPhoPmt(3);
      else
        fEventAction->fRunAction->histRun->cerenPhoPmt(4);

      fEventAction->fRunAction->histRun->cerenPhoPmt(5);
  
      // ---------------------------
      // ** Fill for Pulses ** 
      // * Fill for CerenPhoElect *
      
      if ( pmtSD->ProcessHits(step, track->GetGlobalTime()) )
      {
        trackTime = track->GetGlobalTime() / (1.*ns);
  
        if ( fEventAction->muonOk )
        {
          fEventAction->fRunAction->histRun->cerenPhoElect(0);
          fEventAction->fRunAction->histRun->meanPulse(0, trackTime);
        }
        else if ( fEventAction->elecOk )
        {
          fEventAction->fRunAction->histRun->cerenPhoElect(1);
          fEventAction->fRunAction->histRun->meanPulse(1, trackTime);
        }
        else if ( fEventAction->gammOk )
        {
          fEventAction->fRunAction->histRun->cerenPhoElect(2);
          fEventAction->fRunAction->histRun->meanPulse(2, trackTime);
        }
        else if ( fEventAction->neutOk )
        {
          fEventAction->fRunAction->histRun->cerenPhoElect(3);
          fEventAction->fRunAction->histRun->meanPulse(3, trackTime);
        }
        else
        {
          fEventAction->fRunAction->histRun->cerenPhoElect(4);
          fEventAction->fRunAction->histRun->meanPulse(4, trackTime);
        }

      fEventAction->fRunAction->histRun->cerenPhoElect(5);
      fEventAction->fRunAction->histRun->meanPulse(5, trackTime);
      }
  
      track->SetTrackStatus(fStopAndKill);
    }
  }

  // -------------------------------
  // ** Fill for Inside Detector  **

  if( track->GetParentID() == 0 && volumName == "watervol" )
  {
    lengthStep = step->GetStepLength();

    if ( fEventAction->muonOk )
      fEventAction->fRunAction->histRun->trackLengthDetec(0, lengthStep);
    else if ( fEventAction->elecOk )
      fEventAction->fRunAction->histRun->trackLengthDetec(1, lengthStep);
    else if ( fEventAction->gammOk )
      fEventAction->fRunAction->histRun->trackLengthDetec(2, lengthStep);
    else if ( fEventAction->neutOk )
      fEventAction->fRunAction->histRun->trackLengthDetec(3, lengthStep);
    else
      fEventAction->fRunAction->histRun->trackLengthDetec(4, lengthStep);

    fEventAction->fRunAction->histRun->trackLengthDetec(5, lengthStep);
  }

  fwaterVolume
    = detectorConstruction->GetWaterVolume();
}
