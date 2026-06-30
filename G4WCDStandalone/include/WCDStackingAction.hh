#pragma once

#include "G4UserStackingAction.hh"
#include "PMTResponse.hh"

class G4Track;

// Fast mode applies the PMT response when an optical photon is created; full
// mode defers that sampling until the photon reaches a PMT sensitive detector.
class WCDStackingAction final : public G4UserStackingAction {
 public:
  WCDStackingAction(bool fastMode, std::string pmtModel, double collectionEfficiency);
  G4ClassificationOfNewTrack ClassifyNewTrack(const G4Track* track) override;

 private:
  bool fastMode_;
  PMTResponse response_;
};
