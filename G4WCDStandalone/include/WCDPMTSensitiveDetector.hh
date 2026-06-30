#pragma once

#include "G4VSensitiveDetector.hh"
#include "PMTResponse.hh"

class WCDPMTSensitiveDetector final : public G4VSensitiveDetector {
 public:
  WCDPMTSensitiveDetector(const G4String& name, int detectorId, int pmtId,
                          const std::string& model, double collectionEfficiency,
                          bool sampleResponseAtPMT);
  G4bool ProcessHits(G4Step* step, G4TouchableHistory*) override;
 private:
  int detectorId_;
  int pmtId_;
  bool sampleResponseAtPMT_;
  PMTResponse response_;
};
