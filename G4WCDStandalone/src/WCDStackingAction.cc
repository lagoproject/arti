#include "WCDStackingAction.hh"

#include "G4OpticalPhoton.hh"
#include "G4SystemOfUnits.hh"
#include "G4Track.hh"

#include <utility>

WCDStackingAction::WCDStackingAction(bool fastMode, std::string pmtModel,
                                     double collectionEfficiency)
    : fastMode_(fastMode), response_(std::move(pmtModel), collectionEfficiency) {}

G4ClassificationOfNewTrack WCDStackingAction::ClassifyNewTrack(const G4Track* track) {
  if (track->GetDefinition() != G4OpticalPhoton::OpticalPhotonDefinition()) return fUrgent;
  if (!fastMode_) return fUrgent;
  return response_.Detect(track->GetKineticEnergy() / eV) ? fUrgent : fKill;
}
